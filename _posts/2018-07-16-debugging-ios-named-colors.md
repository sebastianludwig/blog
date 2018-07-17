---
title: Debugging iOS Named Colors
actually_should: refurbish the floor in my flat
---

iOS Named Colors are awesome. Until they are not. I took LLDB for a spin to find out why.

# The Problem

iOS 11 [introduced named colors](https://developer.apple.com/videos/play/wwdc2017/201/). You define the colors you want to use throughout your app in the Asset Catalog. They are referenced in code via `UIColor+colorNamed:` and they get a special section in the color selection dropdown in Interface Builder (not in the ones of custom `IBInspectable` properties, but that's another sad story). They can even be specialized for different device trait such as wide gamut displays.

![Color dropdown with named colors in Interface Builder](/media/images/named_colors/dropdown.png)

I really like named colors and use them whenever possible. Yesterday I assigned a named background color to a button which I then changed to a disabled gray in `viewWillAppear:`. To my surprise the button was still in full color when I ran the app.

Next I created a dead simple test app: It contains three labels, each with a background color. The top one has an assigned RGB value from the color picker, the second one references a SDK color and the third one uses a named color. 

![UIViewController storyboard with three buttons](/media/images/named_colors/storyboard.png)

The view controller's `viewWillAppear:` looks like this

```objc
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.rgbColorLabel.backgroundColor = [UIColor greenColor];
    self.sdkColorLabel.backgroundColor = [UIColor greenColor];
    self.namedColorLabel.backgroundColor = [UIColor greenColor];
}
```

So all three labels should be green when the app is run. But the third label stubbornly stays red. So I started digging...

![App screen with two green buttons and one red button](/media/images/named_colors/two_green_one_red.png)

# The Analysis

This section is a detour into advanced debugging techniques. If you're not interested, skip ahead to [the soloution](#the-soloution). If you _are_ interested, check out my [test project](/data/NamedColorBug.zip) if you want to debug along. I'm using an iOS 11.4 (15F79) simulator, your experience might slightly differ, if you're using something else. Also I'm using [Chisel](https://github.com/facebook/chisel) - highly recommended for any debugging session. All set up? Let's dive in!

I started with a breakpoint on the closing brace of `viewWillAppear:` and checked the label background color:

```
(lldb) po self.namedColorLabel.backgroundColor
UIExtendedSRGBColorSpace 0 1 0 1
```

Green. So some time between now and when the label is displayed, something else changes the background color back to red. To find how this happens, let's see when `setBackgroundColor:` is called on the label by setting a breakpoint using Chisel's [`bmessage`](https://github.com/facebook/chisel/wiki#bmessage) command:

```
(lldb) bmessage -[`self.namedColorLabel` setBackgroundColor:]
Setting a breakpoint at -[UILabel setBackgroundColor:] with condition (void*)(id)$rdi == 0x00007fdcb4b1a3c0
Breakpoint 3: where = UIKit`-[UILabel setBackgroundColor:], address = 0x0000000109a9cc98
```

Note:  Stuff in backticks is evalueted before the rest of the expression. Here it returns the memory address of the label.

Next, let's hit continue and see what happens. Sure enough the breakpoint is triggered - time to poke around a little bit:

```
(lldb) po $arg1
<UILabel: 0x7fdcb4b1a3c0; frame = (75 280; 225 40); text = 'Named Color'; opaque = NO; autoresize = RM+BM; userInteractionEnabled = NO; layer = <_UILabelLayer: 0x608000285910>>

(lldb) po (SEL)$arg2
"setBackgroundColor:"

(lldb) po $arg3
kCGColorSpaceModelRGB 1 0 0 1 
```

These `$argN` variables are LLDB register aliases that represent the N-th argument in the correct calling convention, so you don't have to remember that the first argument is stored in `$rdi` on x86_64 (the simulator) and `$x0` on arm64 (the device). In Objective-C every method has two normally hidden arguments: The first one is the object on which a selector is performed, the second argument is the selector and `$arg3` and onwards store the method parameters. Here we can see that `setBackgroundColor:` is performed on our label and that the background color is set to red. So we're at the right spot.

The next goal is to find out what leads to the color being set to red. Unfortunately Xcode's stack trace is everything but helpful. I just don't think that `UIApplicationMain` directly called `setBackgroundColor:` on my label.

![Stack trace: main -> UIApplicationMain -> setBackgroundColor](/media/images/named_colors/stack_trace.png)

Turns out that yes, the call stack is actually different. You can reconstruct it by repeatadly clicking "Step Out". This is the reconstructed call stack (to be read from bottom to top):

```
__CFRunLoopRun ()
  __CFRunLoopDoBlocks ()
    __CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__ ()
      __34-[UIApplication _firstCommitBlock]_block_invoke_2 ()
        CA::Transaction::commit() ()
          CA::Context::commit_transaction(CA::Transaction*) ()
            CA::Layer::layout_if_needed(CA::Transaction*) ()
              -[CALayer layoutSublayers] ()
                -[UIView(CALayerDelegate) layoutSublayersOfLayer:] ()
                  -[UIView _processDidChangeRecursivelyFromOldTraits:toCurrentTraits:forceNotification:] ()
                    -[UIView(AdditionalLayoutSupport) _withUnsatisfiableConstraintsLoggingSuspendedIfEngineDelegateExists:] ()
                      -[UIView _wrappedProcessTraitCollectionDidChange:forceNotification:] ()
                        -[UIView _traitCollectionDidChangeInternal:] ()
(3)                        -[NSObject(_UITraitStorageAccessors) _applyTraitStorageRecordsForTraitCollection:] ()
(2)                         -[_UIColorAttributeTraitStorage applyRecordsMatchingTraitCollection:] ()
(1)                           -[NSObject(UIIBPrivate) _uikit_applyValueFromTraitStorage:forKeyPath:] ()
                                -[UIView(CALayerDelegate) setValue:forKey:] ()
                                  -[NSObject(NSKeyValueCoding) setValue:forKey:] ()
                                    -[UILabel setBackgroundColor:] ()
```

(1) gives us a first hint that this issue might have something to do with trait collections. In (2) `po $r15` reveals the trait collection that's apparently being applied. The same one is stored in `$r13` in (3).

Okay, so the relevant steps are:

1. `viewWillAppear:` is called and sets the background color of all buttons to green
1. A trait collection is applied which re-sets the storyboard defined background color - **but only** for the button with a named background color!

What do named colors have to do with trait collections? Right, you can specialize them for different device capabilities! And that's why _they_ are part of a trait collection application but other colors are not.

Well, that's something to know. But I really want my button to be green. My next idea was to use the provided hook to react to trait collection changes. Sure that this would work, I implemented `traitCollectionDidChange:` as follows:

```objc
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    self.namedColorLabel.backgroundColor = [UIColor greenColor];
}
``` 

I ran the app aaaand - still red 🤬. An additional breakpoint in `traitCollectionDidChange:` revealed that this method is called *before* the `setBackgroundColor:` breakpoint. So we can add one more step to our list:

1. `viewWillAppear:` is called and sets the background color of all buttons to green
1. **`traitCollectionDidChange:` is called**
1. A trait collection is applied which re-sets the storyboard defined background color

Let's see how and when `traitCollectionDidChange:` is called:

```
__CFRunLoopRun ()
  __CFRunLoopDoBlocks ()
    __CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__ ()
      __34-[UIApplication _firstCommitBlock]_block_invoke_2 ()
        CA::Transaction::commit() ()
          CA::Context::commit_transaction(CA::Transaction*) ()
            CA::Layer::layout_if_needed(CA::Transaction*) ()
              -[CALayer layoutSublayers] ()
                -[UIView(CALayerDelegate) layoutSublayersOfLayer:] ()
                  -[UIViewController _updateTraitsIfNecessary] ()
                    -[UIViewController _traitCollectionDidChange:] ()
                      -[ViewController traitCollectionDidChange:]
```

Now _this_ looks a whole lot similar to the upper part of the `setBackgroundColor:` call stack. It's basically the same from `-[UIView(CALayerDelegate) layoutSublayersOfLayer:]` onwards (further up). If we check the lines in the ASM code at which we enter `-layoutSublayersOfLayer:`, we see that we're in 229 for `traitCollectionDidChange:` and 307 for `setBackgroundColor:`. So we can refine our steps even further:

1. `viewWillAppear:` is called and sets the background color of all buttons to green
1. `-[UIView(CALayerDelegate) layoutSublayersOfLayer:]` calls:
  1. `traitCollectionDidChange:`
  1. A trait collection is applied which re-sets the storyboard defined background color
  1. ?

We'd be set, if we could find a method, one we can override, that's called by `layoutSublayersOfLayer:` after the trait collection application. Luckily the ASM code has those handy comments behind the `;`, translating a little bit what's going on. For example every selector that's performed is listed, like `_updateTraitsIfNecessary` in the following snippet:

```
222    0x105ea35d8 <+1051>: testb  %al, %al
223    0x105ea35da <+1053>: jne    0x105ea363d               ; <+1152>
224    0x105ea35dc <+1055>: movq   0x140c4cd(%rip), %rsi     ; "_updateTraitsIfNecessary"
225    0x105ea35e3 <+1062>: movq   %r15, %rdi
226    0x105ea35e6 <+1065>: movq   0x108c06b(%rip), %rax     ; (void *)0x000000010554e980: objc_msgSend
```

Scorolling around below line 307, there is

```
409    0x105ea3913 <+1878>: movq   0x140c1fe(%rip), %rsi     ; "viewDidLayoutSubviews"
```

Jackpot! 💪


# The Soloution

A quick recap: Named colors can be specified by trait. When presenting a view controller, first `viewWillAppear:` is called, then `traitCollectionDidChange:`, then the trait collection specific storyboard properties are applied. That's why any code changes done in the first two methods have no effect. However `viewDidLayoutSubviews` is called after that. A simple implementation turns all three buttons green:

```objc
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.namedColorLabel.backgroundColor = [UIColor greenColor];
}
```

![App screen with three green buttons](/media/images/named_colors/three_green.png)

# Closing Thoughts

The behaviour is unchanged in iOS 12 (tested with Xcode 10.0 beta 2 (10L177m) simulator only). And I mentioned it in passing before, but this does not only apply to `UILabel` background colors, but _all_ trait specialized Interface Builder properties: Colors, fonts, `hidden` properties - everything. I think it's not correct that these trait collection specifications are applied _after_ `traitCollectionDidChange:` is called, so I opened [a radar](https://openradar.appspot.com/radar?id=4980463923888128). Please file a duplicate at [bugreport.apple.com](https://bugreport.apple.com), if you agree.

