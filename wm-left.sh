if pgrep -x bspwm > /dev/null; then
  bspc desktop -f prev.local
else
  cur=$(wmctrl -d | awk '$2=="*"{print $1}')
  if [ "$cur" -gt 0 ]; then
    wmctrl -s $((cur-1))
  fi

fi

