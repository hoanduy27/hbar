#!/bin/bash
if pgrep -x bspwm > /dev/null; then
  bspc desktop -f next.local
else
  cur=$(wmctrl -d | awk '$2=="*"{print $1}')
  max=$(wmctrl -d | tail -n1 | awk '{print $1}')
  if [ "$cur" -lt "$max" ]; then
    wmctrl -s $((cur+1))
  fi
fi