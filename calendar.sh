#!/bin/sh

case "$1" in
    --popup)
        yad --calendar --class calendar --undecorated --close-on-unfocus \
            --no-buttons --fixed --on-top --skip-taskbar \
            --title "Calendar"
        ;;
    *)
        echo ""
        ;;
esac
