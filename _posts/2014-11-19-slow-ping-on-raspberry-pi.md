---
title: Slow ping on Raspberry Pi
actually_should: finish the first draft of my thesis
---

## TL;DR
For me, it was caused by the network adapter power saving on the Pi _and_ my Mac.

## Long story

I'm working on a realtime hardware porject with a wifi connection from Unity on my MBP to my Raspberry Pi. Realtime as in "the less lag, the better". Today I pinged the Pi, to get a rough estimate of the connection latency. 

The results were shocking. The ping time was highly erratic and _waaay_ to long

```bash
64 bytes from 192.168.0.2: icmp_seq=2 ttl=64 time=266.042 ms
64 bytes from 192.168.0.2: icmp_seq=3 ttl=64 time=166.670 ms
64 bytes from 192.168.0.2: icmp_seq=4 ttl=64 time=66.558 ms
64 bytes from 192.168.0.2: icmp_seq=5 ttl=64 time=7.362 ms
64 bytes from 192.168.0.2: icmp_seq=6 ttl=64 time=6.677 ms
64 bytes from 192.168.0.2: icmp_seq=7 ttl=64 time=5.854 ms
64 bytes from 192.168.0.2: icmp_seq=8 ttl=64 time=172.650 ms
64 bytes from 192.168.0.2: icmp_seq=9 ttl=64 time=75.915 ms
```

I pinged around  
MBP ⇄ Pi: really bad  
MBP → AP: blazingly fast  
MBP → Rounter: blazingly fast  
Pi → AP: blazingly fast  
Pi → Rounter: blazingly fast

This didn't make any sense to me, so I did, what every tinkerer does: I googled.

To my dismay, there are _gazillion_ of possible causes. The most common suggestion is to check the power supply and ensure it's strong enough. Pretty sure it is --- my Pi is the single consumer on a full blown ATX power supply.

Next also power related possible cause, is the power saving mode of the network interface. I turned it off by adding `wireless-power off` to the Pi's `/etc/network/interfaces` and checked `iwconfig` to say `Power Management:off`. I pinged my MBP again and nothing had changed. It later turned out, I made a mistake here :-/

I tried a different AP. Just two meters away, no walls in between, a separate network. Same same, not different.

I tried to set up an ad hoc network. Man, this sucks -- I gave up.

Finally I questioned my Mac Book Pro. And it turns out Mavericks puts the network interface into power save mode, too. At this point my mistake became obvious: When I deactivated the power saving on the Pi, I pinged my MBP, not the other way round. I pinged the Pi and got decent results. A [stack exchange discussion](http://apple.stackexchange.com/questions/110777/ping-on-mavericks-on-late-2013-macbook-pro-slow-and-variable-compared-to-windows) mentions it's possible to prevent the power save mode with a higher ping freqency. With the ping Pi → Mac running, I started pinging Mac → AP every 200ms and _instantly_ the the Pi → Mac ping was below 10ms average.
