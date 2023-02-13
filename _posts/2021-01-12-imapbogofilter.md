---
title: iOS Mail Rules and Spam Filter
actually_should: answer my mails
---

Okay, heads up, not _really_ on iOS but on a Raspberry Pi - but it affects iOS Mail app, does that count?

I'm using a plain old IMAP mail provider and was long frustrated by the fact that macOS Mail.app rules are only applied while it is running and every time it is not and I check my inbox on iOS it is a pure mess. Let's not even talk about the state of Apple's spam filtering. I finally got around to set up a combination of [`imapfilter`](https://github.com/lefcha/imapfilter) and [`bogofilter`](https://bogofilter.sourceforge.io) on a Raspberry Pi as an always-on and always-connected IMAP client. It's my new centralized mail sorting and spam management solution.

## Imapfilter

The centerpiece is [`imapfilter`](https://github.com/lefcha/imapfilter), a headless IMAP client with a simple but powerful rule engine in Lua. I wasn't completely satisified with the way it handles password entry and wanted a way to edit the rules conveniently in the browser. So I developed [a web UI](https://github.com/sebastianludwig/imapfilter-web-ui). The installation is (hopefully) described sufficiently in the readme. If it's not, please [open an issue](https://github.com/sebastianludwig/imapfilter-web-ui/issues).

My configuration is basically a slightly customized version of the [example](https://github.com/sebastianludwig/imapfilter-web-ui/imapfilter-config.lua.example) in the repository.

## Bogofilter

[`bogofilter`](https://bogofilter.sourceforge.io) is a mature Bayesian spam filter which can neatly be integrated into the `imapfilter` setup.

### Preparation

To train `bogofilter` a corpus of mails is needed, the bigger the better. Luckily I've been collecting mails for more than a decade - including spam, because why not?

However it's no good on the server, it's needed locally and in the mbox format. Apple Mail can export mailboxes as mbox, but it failed on my multi GB _Archive_ mailbox.

Buuut I'm using `mbsync` to periodically create local backups of my mails on my Mac. You can install it with `brew install isync` (yes, `isync`, not `mbsync`, because ["isync is the project name, mbsync is the current executable name"](https://isync.sourceforge.io)...). I have the following configuration in `~/.mbsyncrc` and the program can be run with `mbsync -a`.

```
# Remote IMAP account
IMAPAccount me@domain.com
Host my.mailserver.com
Port 993
User <username>
PassCmd "security find-generic-password -s mbsync -a me@domain.com -w"
SSLType IMAPS
SSLVersions TLSv1.2

IMAPStore me@domain.com-remote
Account me@domain.com

# This section describes the local storage
MaildirStore me@domain.com-backup
Path "/path/to/local/backup/me@domain.com/"
Inbox "/path/to/local/backup/me@domain.com/INBOX"
# The SubFolders option allows to represent all
# IMAP subfolders as local subfolders
SubFolders Verbatim

# This section defines a channel, a connection between remote and local
Channel me@domain.com
Master :me@domain.com-remote:
Slave :me@domain.com-backup:
Patterns *
CopyArrivalDate yes
Sync All
Create Slave
Expunge Slave
SyncState *
```

However `mbsync` stores the mails in the Maildir format. I used [`maildir2mbox`](https://github.com/bluebird75/maildir2mbox) to convert my _Archive_ and _Junk_ mailboxs into the mbox format.

```bash
pip3 install maildir2mbox
python3 -m maildir2mbox /path/to/local/backup/me@domain.com/Archive Archive.mbox
python3 -m maildir2mbox /path/to/local/backup/me@domain.com/Junk Junk.mbox
```

### Installation

It could have been so easy...

```bash
sudo apt-get install bogofilter
```

but that only installs version 1.2.4 instead of the latest 1.2.5. Now, does that one patch version make such a big difference? Well, .4 is six _years_ older than .5. In the meantime a bunch of security and memory leak fixes accumulated and I wanted to have those. So instead of a single `apt-get install` I built `bogofilter` from source.

After downloading [1.2.5 from SourceForge](https://sourceforge.net/projects/bogofilter/files/bogofilter-stable/) and sending it over to the Pi

```bash
scp Downloads/bogofilter-1.2.5.tar.xz pi@<Pi IP>:
```

building was pretty straight forward

```bash
sudo apt-get install sqlite3 libsqlite3-dev
tar -xf bogofilter-1.2.5.tar.xz
cd bogofilter-1.2.5
./configure --with-database=sqlite
make all check
sudo make install
```

### Configuration

```bash
# Create the directory where the wordlist will be stored
sudo mkdir /var/spool/bogofilter
sudo chgrp pi /var/spool/bogofilter/
sudo chmod g+w /var/spool/bogofilter/
# Update the configuration
sudo cp /etc/bogofilter.cf.example /etc/bogofilter.cf
sudo nano /etc/bogofilter.cf
```

In the example configuration the following values were modified

```ini
...
bogofilter_dir = /var/spool/bogofilter
...
ham_cutoff = 0.6
spam_cutoff = 0.85
...
```

Bogofilter scores every mail on its spammyness and it can operate in two-state (spam, not spam) or tri-state mode (spam, not spam and unsure). I want to use tri-state mode and the following thresholds to create three intervals

- [0..0.6) - not spam
- (0.6..0.85) - unsure
- (0.85..1] - spam

A cutoff value of 0.6 for good mails is _very_ conservative and I intend to tighten it up in the future.

### Training

The Raspberry Pi could not handle my mailbox. It failed with:

```
bzcat -f ./Archive.mbox                               
bzcat: Can't open input file ./Archive.mbox: Value too large for defined data type.
```

To work around this I decided to train on my Mac and transfer the final database to the Pi. However the Homebrew version of `bogofilter` uses the default Berkeley DB and its version was many versions ahead of what was available via `apt-get`. I didn't want to go down that rabbit hole and decided to use SQLite instead because it seemed simpler and I knew the versions would be compatible. And I like SQLite.

So, on to building `bogofilter` from source on my Mac:

```bash
brew install sqlite
export LDFLAGS="$LDFLAGS -L/usr/local/opt/sqlite/lib"
export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/sqlite/include"

tar -xf bogofilter-1.2.5.tar.xz
cd bogofilter-1.2.5
./configure --with-database=sqlite
```

The first attempt failed with

```bash
clang: error: '-I-' not supported, please use -iquote instead
```

This is probably because I have Xcode installed and clang 12.0.0 fails the "is GCC4?" check in `configure.ac`. To fix this I modified `src/Makefile`

```makefile
#AM_CPPFLAGS = -I$(top_srcdir)/gnugetopt -I$(top_srcdir)/trio -I- -I. \
#       -I$(srcdir)  -I$(top_srcdir)/gsl/specfunc -I$(top_srcdir)

AM_CPPFLAGS = -iquote$(top_srcdir)/gnugetopt -iquote$(top_srcdir)/trio \
        -I$(srcdir)  -I$(top_srcdir)/gsl/specfunc -I$(top_srcdir)
```

I also had to specify `LC_CTYPE` to make the tests pass

```bash
LC_CTYPE=C make all check
```

The actual training was performed with some error margins and slightly stricter values to gain some leeway for production. I used the script [`bogominitrain.pl`](https://gitlab.com/bogofilter/bogofilter/-/blob/main/bogofilter/contrib/bogominitrain.pl) and targeted a spam threshold of 0.95 and a non-spam threshold of 0.3.

```bash
cd src
export PATH=.:$PATH
curl https://gitlab.com/bogofilter/bogofilter/-/raw/main/bogofilter/contrib/bogominitrain.pl -o bogomintrain.pl
chmod a+x bogomintrain.pl
./bogomintrain.pl -fv ./ /path/to/Archive.mbox /path/to/Junk.mbox '-o 0.95,0.3'
```

This ran for a while and after it finished I validated the results by sampling a few mails from _other_ mailboxes which were not part of the training set

```bash
bogofilter -v < /path/to/mbsync/backup/mailbox/cur/something
echo $? # 0 means spam, 1 is not spam, 2 is unsure
```

Not all of them were classified correctly, but I was happy enough. Accuracy will increase over time.

Finally the database needed to be transferred to the Pi

```bash
scp wordlist.db pi@<Pi IP>:/var/spool/bogofilter/
```

## Spam Filtering

The algorithm for spam filtering which needs to be expressed in `imapfilter` rules is

- Let `bogofilter` evaluate every newly arrived message in the inbox:
  - If it is **not spam**, leave it alone and let the user handle it as usual.
  - If it is **spam**, mark it as `Junk` and `bogofilter-junk` and move it into the _Junk_ mailbox.
  - If **unsure**, mark it as `Junk` and `bogofilter-unsure` but leave it in the inbox for the user to review.
  - In any case, mark the message as evaluated so it's only processed once.

The `Junk` label causes macOS Mail to display the message in yellow and show the "Mail thinks this message is Junk Mail" header. 

![Mail thinks this message is Junk Mail](/media/images/bogofilter/unsure.png)

Unfortunately iOS Mail does not have such an indication for spam mails. Or any indication at all. But it displays flags, so unsure messages in the inbox will also get a yellow flag.

Now, nobody is perfect and neither is `bogofilter`. All three classification results can be wrong, "unsure" can even be wrong both ways. For `bogofilter` to improve it's important to provide feedback so it learns.

When designing the feedback loop I thought about it from a user perspective and how I want to deal with it in Mail.app. 

- Good mail misclassified as spam (false positive)
  - Has been moved to the _Junk_ folder.
  - Will be moved back into the _Inbox_ by clicking the "Move to Inbox" button.
  - This will remove the macOS `Junk` label.
  - Each message in the _Inbox_ without the `Junk` label but with the `bogofilter-junk` label needs to be un-learned as spam and learned as good.
- Spam mail misclassified as good (false negative)
  - Has been left in the _Inbox_.
  - Will be moved to the _Junk_ mailbox by clicking the junk-mail button in the toolbar.
  - This will add the macOS `Junk` label.
  - Each message in the _Junk_ mailbox without the `bogofilter-junk` label needs to be un-learned as good and learned as spam.
- Good mails with an unsure result (unsure negatives)
  - Has been left in the _Inbox_ but marked as macOS `Junk`.
  - Will be marked as good by clicking the "Not Junk" button.
  - This will remove the macOS `Junk` label.
  - Each message in the _Inbox_ with the `bogofilter-unsure` label but without the macOS `Junk` label needs to be learned as good.
- Spam mails with an unsure result (unsure positives)
  - Has been left in the _Inbox_ but marked as macOS `Junk`.
  - Will be moved to the _Junk_ mailbox by clicking the "Move to Junk" button.
  - OR will directly be deleted.
  - Each message in the _Junk_ or _Trash_ mailboxes with the `bogofilter-unsure` label will be learned as spam.

In code this looks like

```lua
BOGOFILTER_EVALUATED = "bogofilter-evaluated"
BOGOFILTER_UNSURE = "bogofilter-unsure"
BOGOFILTER_JUNK = "bogofilter-junk"
YELLOW_FLAG = "$MailFlagBit1"

inbox = my_account.INBOX
junk_mailbox = my_account["Junk"]
trash_mailbox = my_account["Trash"]

-- mark as spam so macOS Mail recognizes it as such
function mark_as_junk(messages)
  messages:remove_flags({'NotJunk', '$NotJunk'})
  messages:add_flags({'Junk', '$Junk'})
end
function mark_as_good(messages)
  messages:remove_flags({'Junk', '$Junk'})
  messages:add_flags({'NotJunk', '$NotJunk'})
end

function junk(messages)
  messages:mark_seen()
  mark_as_junk(messages)
  messages:move_messages(junk_mailbox)
end

-- based on https://gist.github.com/sthalik/344d3a0db54c4c9051e4
function filter_junk()
  MIN_SIZE = 1024 * 1024 -- only evaluate mails smaller than 1 MB (spam with embedded images can be surprisingly large...)

  inbox_messages = inbox:is_smaller(MIN_SIZE)

  -- false positives
  -- messages which bogofilter previously classified as junk but since have
  -- been marked as clean in macOS Mail
  false_positives = inbox_messages:has_keyword(BOGOFILTER_JUNK):has_unkeyword("Junk")
  for _, mesg in ipairs(false_positives) do
    mbox, uid = unpack(mesg)
    message = mbox[uid]
    -- unlearn that it was spam (-S) and learn that it was okay (-n)
    pipe_to('bogofilter -nS', message:fetch_message())
  end
  false_positives:remove_flags({ BOGOFILTER_JUNK })

  -- unsure negatives
  -- messages which bogofilter classified as unsure but since have
  -- been marked as clean in macOS Mail or iOS Mail
  inbox_unsure = inbox_messages:has_keyword(BOGOFILTER_UNSURE)
  unsure_negatives = inbox_unsure:has_unkeyword("Junk") + inbox_unsure:has_unkeyword(YELLOW_FLAG)
  for _, mesg in ipairs(unsure_negatives) do
    mbox, uid = unpack(mesg)
    message = mbox[uid]
    -- learn that it was not spam (-n)
    pipe_to('bogofilter -n', message:fetch_message())
  end
  mark_as_good(unsure_negatives)
  unsure_negatives:remove_flags({ BOGOFILTER_UNSURE })
  unsure_negatives:unmark_flagged()
  unsure_negatives:remove_flags({ YELLOW_FLAG })

  -- false negatives
  -- messages which have _not_ been classified as junk by bogofilter
  -- but were moved there by macOS Mail
  false_negatives = junk_mailbox:has_unkeyword(BOGOFILTER_JUNK):is_smaller(MIN_SIZE)
  for _, mesg in ipairs(false_negatives) do
    mbox, uid = unpack(mesg)
    message = mbox[uid]
    -- unlearn that was okay (-N) and learn that it was spam (-s)
    pipe_to('bogofilter -Ns', message:fetch_message())
  end
  false_negatives:add_flags({ BOGOFILTER_JUNK })

  -- unsure positives
  -- messages which have been classified as unsure by bogofilter
  -- but were either moved to Junk or deleted
  unsure_positives = junk_mailbox:has_keyword(BOGOFILTER_UNSURE) + trash_mailbox:has_keyword(BOGOFILTER_UNSURE)
  for _, mesg in ipairs(unsure_positives) do
    mbox, uid = unpack(mesg)
    message = mbox[uid]
    -- learn that was spam (-s)
    pipe_to('bogofilter -s', message:fetch_message())
  end
  unsure_positives:remove_flags({ BOGOFILTER_UNSURE })
  unsure_positives:add_flags({ BOGOFILTER_JUNK })

  -- new messages
  new_messages = inbox_messages:has_unkeyword(BOGOFILTER_EVALUATED)
  for _, mesg in ipairs(new_messages) do
    mbox, uid = unpack(mesg)
    message = mbox[uid]
    text = message:fetch_message()
    if type(text) == 'string' then
      -- 0 for spam; 1 for non-spam; 2 for unsure
      classification = pipe_to('bogofilter -u', text)
      s = Set {mesg}
      if classification == 0 then -- spam
        s:add_flags({ BOGOFILTER_JUNK })
        junk(s)
      elseif classification == 2 then -- unsure
        s:add_flags({ BOGOFILTER_UNSURE })
        mark_as_junk(s)
        -- also add a yellow flag so it's identifiable in iOS Mail
        s:mark_flagged()
        s:add_flags({ YELLOW_FLAG })
      end
    end
  end
  new_messages:add_flags({ BOGOFILTER_EVALUATED })
end
```

## Final Thoughts

Directly starting with the above code would learn every mail in the _Junk_ mailbox as spam - again - because it matches the false negatives search. And "again" because `bogofilter` already learned them in the training phase. To avoid this every message needs the `bogofilter-junk` label. I ran the following helper method once before turning on junk filtering.

```lua
function setup_junk_filtering()
  -- Optional: mark everything in the inbox as evaluated
  -- inbox:select_all():add_flags({ BOGOFILTER_EVALUATED })
  -- mark everything in Junk as evaluated and junk
  junk_mailbox:select_all():add_flags({ BOGOFILTER_EVALUATED, BOGOFILTER_JUNK })
end
```

With all this in place it's time to disable junk mail filtering in the macOS Mail.app preferences.

And because I'm chicken I didn't start with the real _Junk_ and _Trash_ folders. I created _imapfilter-Junk_ and _imapfilter-Trash_ and used them for a while to keep an eye on what `imapfilter` and `bogofilter` are up to. So far they are doing great!
