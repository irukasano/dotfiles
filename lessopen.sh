#!/bin/sh

export LANG="ja_JP.UTF8"

case "$1" in
  *.md)
    pandoc -s -f markdown -t man "$1" | man -l > /tmp/less.$$ 2>/dev/null
    #pandoc -s -f markdown -t man "$1" | groff -T utf8 -man > /tmp/less.$$ 2>/dev/null
    if [ -s /tmp/less.$$ ]; then
        echo /tmp/less.$$
    else
        rm -f /tmp/less.$$
    fi
    ;;
  *.Z) uncompress -c $1  >/tmp/less.$$  2>/dev/null
    if [ -s /tmp/less.$$ ]; then
        echo /tmp/less.$$
    else
        rm -f /tmp/less.$$
    fi
    ;;
esac

