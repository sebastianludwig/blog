---
title: TLC5947 via SPI on Raspberry Pi
actually_should: write my master thesis
---

It's been a huge pain in the ass. As part of my "Tetris in an IKEA shelf" project (more on that in another post) I need to control and fade 8 RGB LED strips independently from a Raspberry Pi. Adafruit advertises its [24 channel 12 bit PWM LED Driver](http://www.modmypi.com/raspberry-pi/breakout-boards/adafruit/adafruit-24-channel-12-bit-pwm-led-driver-spi/) to be perfectly suited for this purpose. Even 8 strips, 3 channels each, equals 24 channels in total --- matches exactly. So I got one. This part was easy.

Using the SPI bus on the Raspberry doesn't seem to be the most common thing to do. Information is sparse. It's a lot more common on the Arduino where the protocol is [bit banged](http://en.wikipedia.org/wiki/Bit_banging). On the Pi, which has SPI support built in, people seem to use [one](https://github.com/lthiery/SPI-Py) of [few](https://github.com/doceme/py-spidev/) thin C drivers with python bindings --- years old, plenty times [forked, fixed, improved, just not ever merged](https://github.com/doceme/py-spidev/network). I ended up using the [BCM2835 C library](http://www.airspayce.com/mikem/bcm2835/) by Mike McCauley and looked at [FPulse](https://github.com/wrobell/fpulse/blob/master/fpulse/driver/tlc5947.py) how to use it from Python.

The next problem was to verify the basic setup was actually working. To be fair, all the information is in the [datasheet](http://www.ti.com/lit/ds/symlink/tlc5947.pdf), it's just not verbosely laid out for a novice. The key was to realize all outputs are wired as open collector, bound to ground, so you have to use a pull up resistor to get a signal.

The real culprit however comes when setting new values. The process is basically to transfer the values and confirm the transaction with a rising edge on the _latch_ input. This input pin (XLAT) is described as follows in the datasheet:

> The data in the grayscale shift register are moved to the grayscale data latch with a low-to-high transition on this pin. **When the XLAT rising edge is input, all constant current outputs are forced off until the next grayscale display period.** The grayscale counter is not reset to zero with a rising edge of XLAT.

In practice this means, every time you set a new value, which is quite frequently for a smoothe color fade, all outputs are high for a short period. High as in "all LEDs on full white". In my experiment I got up to 10ms high signal, wich is especially noticalbe when some of the LED strips should actually be off. Doing some simple math, you get 150 ms full brightness on average per second at 30 Hz update frequency. My math might be completely wrong, but believe me, you see the flickering. Here's a [video](/media/videos/tlc5947.mp4) where I repeatedly set 0 after 1 and 1.3 seconds.

I couldn't believe that this is the way the chip is supposed to work but then I found a [thread in the Texas Instruments forum](http://e2e.ti.com/support/power_management/led_driver/f/192/t/120587.aspx). And I quote a TI employee:

> **The IC is intended for applications which show static pictures for a longer period of time.** So whenever the picture is changing, BLANK can be set high to turn the outputs off and reset the GS counter and during BLANK=high, XLAT can be used to latch the new picture in.

Works as designed. Screw this, the TLC5947 board is going into the bin, I'll use two [PCA9685 boards](https://www.modmypi.com/adafruit-16-channel-12-bit-pwm-servo-driver).

P.S. Luckily I can use these findings for my master theses ;-)

## Edit

Ulrich Stern has been able to achieve flicker free results with the TLC59711 and put together a [library](https://github.com/ulrichstern/Tlc59711) to use it properly. Check it out, if you're looking for an alternative.
