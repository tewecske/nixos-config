# ~/.bashrc: executed by bash(1) for non-login shells.
#
# Interactive-shell guard, history settings (HISTCONTROL/HISTIGNORE/HISTSIZE/
# HISTFILESIZE), histappend/checkwinsize, ls/grep/ll/la/l aliases and bash
# completion all come from programs.bash.* in home/programs/bash.nix. The
# prompt comes from programs.starship. Only PATH ordering + extra aliases live
# here.

# sync history across panes/sessions immediately
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Alias definitions (see ~/.bash_aliases).
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# pnpm global install dir (the pnpm binary itself comes from nix)
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# nix / home-manager
# Deliberately LAST: anything that prepends to PATH after this shadows the nix
# profile. ~/.profile prepends a few more dirs *after* sourcing this file -
# keep those nix-free or they will shadow the nix profile again.
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
for _d in "/nix/var/nix/profiles/default/bin" "$HOME/.nix-profile/bin"; do
  case ":$PATH:" in
    *":$_d:"*) ;;
    *) [ -d "$_d" ] && PATH="$_d:$PATH" ;;
  esac
done
unset _d
export PATH
