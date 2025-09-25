cur=$(wmctrl -d | awk '$2=="*"{print $1}')
if [ "$cur" -gt 0 ]; then
  wmctrl -s $((cur-1))
fi