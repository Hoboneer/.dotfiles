# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

if [ "$HAVE_PROFILE" != 1 ]
then export HAVE_PROFILE=1

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Non-shell specific environment variables.

# Add scripts directory to path so that I don't have to install them into `usr/bin` (spooky!).
export PATH="$HOME/.scripts:$PATH"

# The one true editor
export EDITOR='vim'
export VISUAL=$EDITOR

# Synchronise BROWSER with debian's alternatives system.
# This should be w3m.
export BROWSER='www-browser'

fi
