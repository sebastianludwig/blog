---
title: "SMbus for Python 3.4 on Raspberry Pi"
actually_should: sort out some financial issues
---

Now, that I had [Python 3.4 running]({% post_url 2014-07-20-install-python34-on-raspberry-pi %}), I tried my I2C using project and it failed miserably with

```python
ImportError: No module named 'smbus'
```

This is because the `python-smbus` package only contains Python 2 bindings. 

```bash
pi@whatever ~ $ dpkg -s python-smbus
Package: python-smbus
[...]
Source: i2c-tools
Version: 3.1.0-2
Provides: python2.6-smbus, python2.7-smbus
Depends: libc6 (>= 2.13-28), python2.7 | python2.6, python (>= 2.6), python (<< 2.8)
```

The solution was actually pretty easy and described in the [official Raspberry Pi forum](http://www.raspberrypi.org/forums/viewtopic.php?f=32&t=22348).

```bash
sudo apt-get install libi2c-dev 	# install dependency

wget http://ftp.de.debian.org/debian/pool/main/i/i2c-tools/i2c-tools_3.1.0.orig.tar.bz2 	# download i2c-tools source
tar xf i2c-tools_3.1.0.orig.tar.bz2
cd i2c-tools-3.1.0/py-smbus
mv smbusmodule.c smbusmodule.c.orig  # backup
wget https://gist.githubusercontent.com/sebastianludwig/c648a9e06c0dc2264fbd/raw/f4e5c3eb0ea768f30c9d7c5aa6961331dab7228a/smbusmodule.c 	# download patched (Python 3) source
```

The next steps need to be run with Python 3.4. For me, this meant activating a virtual environment ([see previous post]({% post_url 2014-07-20-install-python34-on-raspberry-pi %})) - as root.

```bash
sudo bash
source /home/pi/.virtualenvs/python34/bin/activate
python --Version 		# should output 'Python 3.4.1'

python setup.py build
python setup.py install
```

That's it. However, I start disliking the virtualenv approach, because simple ```sudo python3.4``` commands don't work. I think I'll just add it to the path...