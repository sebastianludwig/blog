---
title: "Install Python 3.4 on Raspberry Pi"
actually_should: code something in Python
---

The resulting setup will use virtualenv + [convenience wrapper](https://bitbucket.org/dhellmann/virtualenvwrapper/) and install Python 3.4 under `/opt` to prevent any (future) collisions with the system Python. 

**Disclaimer**

1. Apparently all the you are supposed to use `pyenv` now, but that's too much new stuff at once for me.
1. My Linux fu is pretty weak, so this was a lot of try and error. Please leave a comment, if you have any improvements.


## Preparation

Create a backup of your SD card!

```bash
sudo apt-get install rpi-update
sudo rpi-update				# update the firmware
sudo reboot					# reboot needed
sudo apt-get update 		# update package information
sudo apt-get dist-upgrade	# upgrade everything, resolving dependencies
# now we should be up to date - yay

# update pip
sudo pip install -IU pip

# virtualenv and a handy wrapper
sudo pip install -IU virtualenv virtualenvwrapper
```

During my fist attempt I later ran into the following error while installing pip:

```bash
Installing setuptools, pip...
  Complete output from command /home/pi/.virtualenvs/python34/bin/python3.4 -c "import sys, pip; sys...d\"] + sys.argv[1:]))" setuptools pip:
  Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/local/lib/python2.7/dist-packages/virtualenv_support/pip-1.5.6-py2.py3-none-any.whl/pip/__init__.py", line 10, in <module>
  File "/usr/local/lib/python2.7/dist-packages/virtualenv_support/pip-1.5.6-py2.py3-none-any.whl/pip/util.py", line 18, in <module>
  File "/usr/local/lib/python2.7/dist-packages/virtualenv_support/pip-1.5.6-py2.py3-none-any.whl/pip/_vendor/distlib/version.py", line 14, in <module>
  File "/usr/local/lib/python2.7/dist-packages/virtualenv_support/pip-1.5.6-py2.py3-none-any.whl/pip/_vendor/distlib/compat.py", line 66, in <module>
ImportError: cannot import name 'HTTPSHandler'
----------------------------------------
...Installing setuptools, pip...done.
Traceback (most recent call last):
  File "/usr/local/lib/python2.7/dist-packages/virtualenv.py", line 2338, in <module>
    main()
  File "/usr/local/lib/python2.7/dist-packages/virtualenv.py", line 824, in main
    symlink=options.symlink)
  File "/usr/local/lib/python2.7/dist-packages/virtualenv.py", line 992, in create_environment
    install_wheel(to_install, py_executable, search_dirs)
  File "/usr/local/lib/python2.7/dist-packages/virtualenv.py", line 960, in install_wheel
    'PIP_NO_INDEX': '1'
  File "/usr/local/lib/python2.7/dist-packages/virtualenv.py", line 902, in call_subprocess
    % (cmd_desc, proc.returncode))
OSError: Command /home/pi/.virtualenvs/python34/bin/python3.4 -c "import sys, pip; sys...d\"] + sys.argv[1:]))" setuptools pip failed with error code 1
```

Aparently SSL is needed as dependency and needs to be install _before_ compiling python, so I did this whole thing twice. Luckily I don't have anything else to do...

To make sure I don't have to do this a third time, I started digging around, trying to find a complete list of dependencies. First, I installed apt-rdepends `sudo apt-get install apt-rdepends` and ran it:

```bash
pi@whatever ~ $ apt-rdepends python3.2 | grep ^lib
Reading package lists... Done
Building dependency tree       
Reading state information... Done
libbz2-1.0
libc6
libc-bin
libgcc1
libdb5.1
libffi5
libncursesw5
libtinfo5
libreadline6
liblzma5
libselinux1
libsqlite3-0
libssl1.0.0
libexpat1
```

Unfortunately Python 3.4 is not in the index yet, which is the reason why we're compiling from source in the first place. I was just hoping the dependencies didn't change too much since Python 3.2.

To see what already _is_ installed, you can search for packages with `dpkg --get-selections | grep -v deinstall | grep ^libbz`.

I just installed the whole buch plus the corresponding dev packages.

```bash
sudo apt-get install libbz2-1.0 libbz2-dev libffi5 libffi-dev libncursesw5 libncursesw5-dev libreadline6 libreadline6-dev liblzma5 liblzma-dev libsqlite3-0 libsqlite3-dev libexpat1 libexpat1-dev libssl-dev openssl
```


## Installation

Head over to https://www.python.org/downloads/ and copy the link to the gzipped source tarball of the Python version you want to install. 3.4.1 was the latest version as of writing this.

```bash
# get the source
cd /tmp
wget https://www.python.org/ftp/python/3.4.1/Python-3.4.1.tgz
tar xvzf Python-3.4.1.tgz
cd Python-3.4.1/

# configure, make, make install
./configure --prefix=/opt/python3.4 		# this takes a little bit (~ 5 minutes)
make										# this takes aaages (about an hour)
sudo make install 							# this is rather quick again (~ 7 minutes)
```

Add `source /usr/local/bin/virtualenvwrapper_lazy.sh` to your `~/.bashrc`.

I rebooted at this point. Don't know if it's really necessary.

Finally, create a virtual python environment with `mkvirtualenv python34 -p /opt/python3.4/bin/python3.4`. Fingers crossed, no errors and you get:

```bash
(python34)pi@whatever /tmp/Python-3.4.1 $ python --version
Python 3.4.1
```

To find out how to work with python virtual environments, check out the [virtualenvwrapper command documentation](http://virtualenvwrapper.readthedocs.org/en/latest/command_ref.html).