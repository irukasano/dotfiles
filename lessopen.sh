#!/bin/sh

#export LC_ALL=ja_JP.utf8
#export LANG=ja_JP.utf8
#LANG=ja_JP.utf8

case "$1" in
  *.md)
    #pandoc -s -f markdown -t man "$1" | man -l > /tmp/less.$$
    #pandoc -s -f markdown -t man "$1" | groff -D utf8 -T utf8 -man > /tmp/less.$$ 2>/dev/null
    pandoc -s -f markdown -t man "$1" | groff -D utf8 -T utf8 -man > /tmp/less.$$
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


