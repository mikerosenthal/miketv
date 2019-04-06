#!/bin/bash
#MikeTV v1.0
# Written by Mike Rosenthal - mikerosenthal@gmail.com

# TODOs:
# implement volume control
# implement playlists or something so that when one clip ends, a new one from the same folder randomly is chosen and starts playing. 
# implement a "power button" that launches the script and kills it again with the click of a button on the remote
  
original_timer=$(date +%s)
basedir=/mnt/miketv/MikeTV #Set your base directory here
channels=( "$basedir"/*/ )
chan_num=0

function load_video {
	kill $(ps aux | grep 'omxplayer' | awk '{print $2}') #makes sure no other movie is playing, kills it if it is. 
	movie_timer=$(date +%s)
	movie_seek=$((movie_timer-original_timer+randomizer[$chan_num]))
	full_movie=`readlink --canonicalize "${fullpath[$chan_num]}"` # Convert movie name to full path
	cmd_movie="omxplayer -b --blank -l / --pos "$movie_seek" $full_movie" # Start the movie
	nohup $cmd_movie & #but not in a way that takes away my ability to stop it. 
	echo $full_movie at ${randomizer[$chan_num]} #shows us whats playing and where in the movie it started
}

cmd_movie="omxplayer -b --blank -l / "$basedir"/introvideo.mkv" #Play an intro movie while the channels loads
nohup $cmd_movie & #but not in a way that takes away my ability to stop it. 

for((i=0;i<${#channels[@]};i++)) #load up the channels
do
	movie[i]=`/bin/ls -1 "${channels[$i]}" | sort --random-sort | head -1` #choose a random movie
	fullpath[i]=${channels[$i]}${movie[$i]} #set its full file path
	duration[i]=$(ffprobe -i "${fullpath[i]}" -show_entries format=duration -v quiet -of csv="p=0") #find its duration
	dur_truncated[i]=${duration[i]%.*} # kill off the decimal points
	dur2[i]=$((${dur_truncated[i]} * 35 / 100)) # make sure we are in the first 35% of the movie
    randomizer[$i]=$(shuf -i 60-"${dur2[i]}" -n 1) #choose a random seek time
	echo ${fullpath[i]} is ${dur_truncated[i]} and rando is ${randomizer[i]}
done >>movie_history.txt
kill $(ps aux | grep 'omxplayer' | awk '{print $2}')
load_video
# printf '%s\n' "${fullpath[@]}"
while true; do #main loop. Lets us flip channels. 
upperlimit=$((${#channels[@]} - 1)) # tells the system what the highest channel number is
echo $upperlimit is the upperlimit
read -sn4 key #reads input from my wireless remote
	if [ $key = "[6~" ] 
	then
		if [ "$chan_num" -le 1 ] 
		then
			echo going down! we decided that $chan_num is lower than 0: #wraps us up to highest channel if we go below lowest
			chan_num=$((${#channels[@]} - 1))
			echo $chan_num
			load_video
		else 
			chan_num=$((chan_num - 1)) #otherwise just go one channel down
			echo Channel is $chan_num
			load_video #and play that video
		fi
	
	elif [ $key = "[5~" ] 
	then
		if [ "$chan_num" -ge "$upperlimit" ] 
		then
			echo going up! we decided that $chan_num is bigger than $upperlimit. #wraps us around to lowest channel if we go above highest
			chan_num=0
			echo so we set the channel to be $chan_num
			load_video
		else
		chan_num=$((chan_num + 1)) #otherwise just go one channel up
		echo Channel is $chan_num
		load_video # and play that video
		fi
	fi
done

