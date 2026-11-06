#!/bin/bash

case $- in
  *i*) ;;
  *) return ;;
esac

if [ -t 0 ] && [ -t 1 ] && [ ! -e "$HOME/.hushlogin" ] &&
  [ -z "${SSH_ORIGINAL_COMMAND:-}" ] && [ -z "${TMUX:-}" ] &&
  [ -z "${OMARCHY_BBS_SESSION:-}" ] && [ -z "${OMASHIRI_MOTD_SHOWN:-}" ]; then
  if /usr/bin/omashiri-motd; then
    export OMASHIRI_MOTD_SHOWN=1
  fi
fi
