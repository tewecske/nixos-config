# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.

# .bashrc is sourced separately by ~/.bash_profile (home-manager generated);
# no need to include it here too.

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/bin/scripts" ] ; then
    PATH="$HOME/bin/scripts:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# >>> coursier install directory >>>
# `cs setup` is no longer used; metals comes from nix now. Kept so anything
# installed via `cs install` (e.g. metals fetched by nvim-metals' :MetalsInstall)
# stays on PATH.
if [ -d "$HOME/.local/share/coursier/bin" ] ; then
    PATH="$PATH:$HOME/.local/share/coursier/bin"
fi
# <<< coursier install directory <<<
