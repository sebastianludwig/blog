---
title: Sensation Suit
actually_should: have done something easier
---

I've sewn 90 WiFi controlled vibration motors into a full body suit. Here's why and how.

## But..why?

Virtual environments are getting more and more realistic. The latest most prominent advance were consumer head mounted displays like the [Oculus Rift](http://oculusrift.com). However, most improvements have been made with visual and audible output, little has been done to improve the haptic feedback from the virtual world to the human body. But it's so promising!

Interesting experiments have been conducted in recent years, most famously the [Rubber Hand Illusion](https://www.youtube.com/watch?v=sxwn1w7MJvk). Subsequently the Swedish professor [Henrik Ehrsson](http://www.ehrssonlab.se) has shown, that what's possible for single body parts is also possible as Body Transfer Illusion. You can literally shake hands with yourself without noticing it's actually you. Check out his  experiments, they're [really](http://www.nature.com/news/out-of-body-experience-master-of-illusion-1.9569) [mind](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0020195) [blowing](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0003832).

All this left me convinced that what's possible in the real world should also be possible with VR as _Avatar Transfer Illusion_: make people believe the avatar they're seeing is their own body. A [few](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0010564) [experiments](http://journal.frontiersin.org/article/10.3389/neuro.09.006.2008/full) have been done in this direction and the results are promising.

According to Ehrsson three conditions have to be satisfied for a transfer illusion to be possible

> 1. The usage of a sufficiently humanoid body
> 1. The adoption of a first person visual perspective of the body
> 1. A continuous match between visual and somatosensory information about the state of the body
> 
> [Source](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0003832)

The first two are pretty easy to meet in virtual environments. I set out to get a step closer to be able to see what happens if you meet all three.

## Hardware

I used 88 10mm coin vibration motors from [Precision Microdrives](http://precisionmicrodrives.com) (thanks again guys - you are awesome!) They were sewn into elastic sporting cloths, each one held in place by a [custom modelled and 3D printed mount](/data/motor_mount.skp).

Six [TLC5947 chips](https://www.modmypi.com/adafruit-24-channel-12-bit-pwm-led-driver) drive up to 16 motors each. Because the motors draw more current than the chip can handle, I've built six boards with 16 simple amplifier circuits. Stacked on top of each other they are put into [custom cases](/data/case.skp) which are also sewn onto the cloths.

The chips are all connected to an I2C bus. So is a Raspberry Pi which acts as central controller. It sits in a small pouch above the left hip.

Everything is powered by a modded ATX power supply.

{% gallery hardware %}
sensation_suit/actor_placement.png
sensation_suit/sketchup_mount.png
sensation_suit/sketchup_case.png
sensation_suit/IMG_8035.jpg
sensation_suit/IMG_8043.jpg
sensation_suit/IMG_8138.jpg
sensation_suit/IMG_8197.jpg
sensation_suit/IMG_8207.jpg
sensation_suit/IMG_8395.jpg
sensation_suit/IMG_8211.jpg
sensation_suit/IMG_8152.jpg
sensation_suit/IMG_8436.jpg
sensation_suit/IMG_8438.jpg
sensation_suit/IMG_8444.jpg
sensation_suit/IMG_8452.jpg
sensation_suit/IMG_8456.jpg
sensation_suit/IMG_2785.jpg
sensation_suit/IMG_7967.jpg
sensation_suit/IMG_7969.jpg
sensation_suit/IMG_8574.jpg
{% endgallery %}

## Software

The server software running on the Raspberry Pi is written in Python and based around the new [asyncio](https://docs.python.org/3/library/asyncio.html) library. I've chosen [Google Protocol Buffers](https://developers.google.com/protocol-buffers/) for the network communication. The source code is available on [GitHub](https://github.com/sebastianludwig/SensationDriver).

Unfortunately the pure Python implementation of Protobuf is painfully slow on the Raspberry. I've profiled and optimized a lot but didn't manage to get above 350 messages per second which means a mere 4 messages per motor per second. These messages are handled in a median time of 90 ms.

I also developed a [Unity Plugin](https://github.com/sebastianludwig/SensationPlugin) as reference client implementation. It's on [GitHub](https://github.com/sebastianludwig/SensationPlugin), too.

## Usage

I'd have loved to find out, if an Avatar Transfer Illusion is possible, what factors contribute to it and what needs to be improved. But simply time was up and I had to hand in my thesis.

However I pimped the [Unity Angry Bots](https://www.assetstore.unity3d.com/en/#!/content/12175) project to demonstrate how everything comes together. I changed the perspective to first person, added Oculus Rift support, Wiimote controls and, last but not least, the sensation plugin. You feel the distance to obstacles to your side or behind you, a radar lets you sense the direction and distance of enemies, your lower arms vibrate while you fire your weapon and different zones vibrate depending on where you've been hit.

## Next up

The list what should be improved or could be done next is long. The prominent items are:

- Find cloths that are easier to put on
- Design a custom board with SMD components to shrink the worn hardware
- Speed up Python + Protocol Buffers
  - The C++ backed implementation should bring some improvements. I will try them over easter (if they are [released for Python 3.4](https://github.com/google/protobuf/issues/7) by then)
  - The faster [Raspberry Pi 2](http://www.raspberrypi.org/products/raspberry-pi-2-model-b/) with a quad core could help
- Experiment with different actors - I'd _love_ to test the potential of electronic muscle stimulation!


And, last but not least, study what's neccessary to induce an Avatar Transfer Illusion. After all that's why I built the thing. 

What do you think? Just leave any questions or comments below - I'm happy to elaborate!

## Links

- [Thesis (German)](/data/SensationSuit.pdf)
- [Server](https://github.com/sebastianludwig/SensationDriver)
- [Unity Plugin](https://github.com/sebastianludwig/SensationPlugin)
- [Modified Angry Bots demo](https://github.com/sebastianludwig/SensationDemo/)
- [Case SketchUp model](/data/case.skp)
- [Motor mount SketchUp model](/data/motor_mount.skp)
