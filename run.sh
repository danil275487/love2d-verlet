#!/bin/bash

# A bash script used for mobile on-device quick LÖVE game debugging, by danil275487, MIT license

# Usage:
# ./run.sh will zip the games contents and launch LÖVE Loader, from which you must select "GAME.love" from the internal storage (or whatever game_name is set to from wherever game_path is set to)
# Passing "desktop" to the script as an argument (./run.sh desktop) will start Termux:X11 with TWM and a xterm window which LÖVE is attached to.

# Requirements:
# Termux, Termux:X11, LÖVE (android apps)
# zip, twm-xorg (from x11-repo), love (from x11-repo) termux-x11-nightly (from x11-repo)

game_name='GAME'
game_path='/sdcard/'

clear

if [ "$1" = "desktop" ]; then
	am start -S -n 'com.termux.x11/.MainActivity' 
	export DISPLAY=:1
	pkill -f com.termux.x11 
	termux-x11 :1 -xstartup 'twm & xterm -e love .'
else
	rm $game_path$game_name'.love' > /dev/null
	zip -r 'GAME.love' ./* -x '*.zip' -x '*.love' -x '*.sh' &&
	mv $game_name'.love' $game_path
	am start -S -n 'org.love2d.android/.SelectorActivity'
	ping -c 10 localhost > /dev/null &&
	rm $game_path$game_name'.love' &
fi
