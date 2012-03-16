.. Copyright (c) 2011 - 2012, Eric Van Dewoestine
   All rights reserved.

   Redistribution and use of this software in source and binary forms, with
   or without modification, are permitted provided that the following
   conditions are met:

   * Redistributions of source code must retain the above
     copyright notice, this list of conditions and the
     following disclaimer.

   * Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the
     following disclaimer in the documentation and/or other
     materials provided with the distribution.

   * Neither the name of Eric Van Dewoestine nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission of
     Eric Van Dewoestine.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

========
Overview
========

This project is a culmination of scripts and plugins to help use gnome-keyring
as a single password store for various apps.

**Note:** Most of the plugins provided expect the bin/keyring script included
in the repository to be available in your path.

Dependencies:
  - gnome-keyring
  - python-gnomekeyring

bin/keyring
-----------

This script allows you to perform some basic operations on your keyring:

::

  Usage: keyring [options] <command> [command args]

  Commands:
    list - list all stored keys
    set [<key>] - set a key
    get/password <key> - get a password for the given key
    delete <key> - delete the entry for the given key
    username <domain> - get the username for the given domain
    smtp - set a smtp password (msmtp format)

  Options:
    -h, --help            show this help message and exit
    -k KEYRING, --keyring=KEYRING
                          the keyring to use (default: login)
    -t TEMPFILE, --tempfile=TEMPFILE
                          write get/password/username to a tempfile (deleted 1s
                          after creation)
    -c, --clipboard       write get/password/username to a clipboard (cleared
                          10s after being set)

vimperator
----------

A vimperator plugin is provided which can be used to populate username/password
fields on web site login forms by pulling the information from the keyring
based on the current domain.

The first step is to store your credentials for a domain in the keyring using
the format `username@domain` where username can be an email address if
necessary:

::

  ./bin/keyring set myuser@somesite.com
  ./bin/keyring set myuser@gmail.com@somesite.com

When deciding what domain to suffix the key with, please be aware that the
vimperator plugin will use the full domain name, but will strip off common
prefixes (www, www\\d*, wwws, us, login, sitekey, secure):

::

    www.site.com -> site.com
    www1.site.com -> site.com
    users.site.com -> users.site.com (no change)

Once you've added your credentials for a given site to the keyring, you can
then navigate to that site's login page and simply run `:keyring login` and the
username/password fields should be populated, allowing you to then manually
submit the form.

Note that the plugin will log some general debug info to the firebug console
allowing to get an idea of what is happening behind the scenes.

Here is a full usage for the `:keyring` command:

::

  Usage:
    :keyring login
       Attempt to find the username/password fields and populate them.
    :keyring username
       Populate the current (or last) focused input with the username.
    :keyring password
       Populate the current (or last) focused password input with the password.
       Note: this will only populate the input if it is of type 'password'.

irssi
-----

An irssi plugin is provided allowing you to authenticate all or individually
configured accounts using gnome-keyring.

You can install the plugin by copying or symlinking the
irssi/scripts/keyring.pl file to your irssi scripts directory
(~/.irssi/scripts) and then adding a corresponding load line to your irssi
startup file (~/.irssi/startup):

::

  load keyring.pl

After installing the keyring.pl plugin, you then need to create a `login` file
in your irssi config directory (~/.irssi/login) with a list of connection
commands, one per line, where the special `<password>` token is replaced with
the password obtained from the keyring.

Here is an example file to authenticate a freenode account and a google talk account:

::

  connect irc.freenode.net 6667 <password> mynick
  xmppconnect -host talk.google.com myuser@gmail.com <password>

Note that if the actual key used in the keyring for that account differs from
the username specified in the connection string, you can use the
`<password:key>` syntax to specify the key to use when looking up the password:

::

  xmppconnect -host talk.google.com myuser@gmail.com <password:myuser@gmail.com@irssi>


Once you created the login file, you can then use the `/keyring [username]`
command in irssi to authenticate all or individual accounts:

::

  /keyring
  /keyring username


offlineimap
-----------

The keyring python module included at bin/keyring can also be used in
conjunction with offlineimap.

The first step is to set the `pythonfile` setting in your ~/.offlineimaprc
file:

::

  pythonfile = /path/to/keyring/bin/keyring

Then for each of your email repository configs in your ~/.offlineimaprc, you
can set the `remotepasseval` setting to pull the password from the keyring:

::

  remotepasseval = Keyring().get('me@domain.com')

msmtp
-----

When configured using `--with-gnome-keyring`, msmtp supports pulling
credentials from gnome-keyring. The only caveat is that msmtp requires that the
credentials be stored in a very specific format in the keyring. To store keys in
the proper format, the bin/keyring script provides a dedicated `smtp` command
which will prompt you for the appropriate values:

::

  ./bin/keyring smtp
