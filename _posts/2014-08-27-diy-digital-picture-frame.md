---
title: "DIY: Digital picture frame"
actually_should: finish developing the photos of my last three trips
---

I love to travel and I love my photos of these journeys. I always wanted a digital picture frame to view them, but everything available sucks: The displays are small, they aren't very stylish, they aren't cheap and the picture display time is waaay to short for my liking. So I built one myself.

## Construction

We had an TFT laying around of such bad quality, that you got eye cancer after five minutes of reading text on it. Full screen images looked all right though. I took it apart and only kept the parts I needed. The main goal here was to get the display as thin as possible. The inner aluminium frame was too shiniy, so I painted it black. Lastly I mounted it on a wooden frame, glued the electonics on the back and decorated it with sticks.

{% gallery construction %}
pictureframe/IMG_9379.jpg
pictureframe/IMG_9381.jpg
pictureframe/IMG_9392.jpg
pictureframe/IMG_0242.jpg
pictureframe/IMG_0244.jpg
pictureframe/IMG_0251.jpg
pictureframe/IMG_0247.jpg
pictureframe/IMG_0248.jpg
{% endgallery %}

The first version used my iPad as a driver. I hacked together an app which downloaded the photos provided by a [Sinatra](http://sinatrarb.com/) server running on my MBP and displayed it on the external display with smooth transitions. It had guesture support for zoom modes and changing the photo. The VGA adapter needed to be modified, to supply power at the same time.

{% gallery demogallery2 %}
pictureframe/IMG_9471.jpg
{% endgallery %}

This is what the intermediate result looked like

{% gallery first_version %}
pictureframe/IMG_0249.jpg
pictureframe/IMG_0254.jpg
pictureframe/IMG_9481.jpg
{% endgallery %}

The obvious drawbacks were the bunch of ugly cables ruining the look and the need for an iPad, which I recently gave to my mom. No iPad, no pictures. Time for revision 2.

## Revision

This time I hot glued a Raspberry Pi as driver, along with both power supplies to the back. I also added a switch to the P6 header on the Pi, to be able to restart it after a shutdown. The Pi is connected to the WiFi, announces it's network name via Bonjour and opens a network share.

Lightroom on my MBP has a publish service configured to export directly to the Pi's network share. The Pi boots to GUI mode and auto runs a Ruby Gosu-Webrick hybrid app. Gosu to display the photos, Webrick to have a web interface to select photos and shutdown the Pi. The source code is hosted on [GitHub](http://github.com/sebastianludwig/Raspicture).

{% gallery second_version %}
pictureframe/IMG_7998.jpg
pictureframe/IMG_8000.jpg
pictureframe/IMG_8001.jpg
pictureframe/IMG_8003.jpg
pictureframe/IMG_8023.jpg
pictureframe/IMG_8017.jpg
pictureframe/IMG_8021.jpg
pictureframe/iphone.jpeg
{% endgallery %}

I'm pretty happy with it. The look is nice and clean, it's easy to add new photos and with only a little bit of scripting fully customizable. However, I'm still having trouble to establish a relyable WiFi connection :-/

## Setup

The configuration steps were roughly:

- Change hostname: `sudo nano /etc/hostname`
- Update everything: `apt-get dist-upgrade`
- Zeroconf aka Bonjour: `sudo apt-get install avahi-daemon` (&lt;hostname&gt;.local)
- FileSharing (<http://4dc5.com/2012/06/12/setting-up-vnc-on-raspberry-pi-for-mac-access/>)
  - edit: <http://www.raspberrypi.org/forums/viewtopic.php?f=36&t=26826 & http://devel.datif.be/howto/serve-files-using-afp-with-netatalk-from-fedora-linux-to-mac-osx-leopard-clients/>
- WLAN: `sudo nano /etc/wpa_supplicant/wpa_supplicant.conf` (<http://www.maketecheasier.com/setup-wifi-on-raspberry-pi/>)
  - add:

        ```
        network={
          ssid="<SSID>"
          psk="<password>"
          proto=RSN
          key_mgmt=WPA-PSK
          pairwise=CCMP
          auth_alg=OPEN
        }
        ```

- ImageMagick: `sudo apt-get install imagemagick`
- [Install Gosu](https://github.com/jlnr/gosu/wiki/Getting-Started-on-Raspbian-%28Raspberry-Pi%29)
- Get Raspicture: `mkdir ~/projects/ && cd ~/projects && git clone https://github.com/sebastianludwig/Raspicture.git`
- Install other ruby gems using `bundle`
- Start Raspicture after boot: add `@sudo ruby /home/pi/projects/Raspicture/raspicture.rb 80 /pictures` to `/etc/xdg/lxsession/LXDE/autostart`


