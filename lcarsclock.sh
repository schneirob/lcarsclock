#! /usr/bin/env bash

framebuffer=/dev/fb1

function perc2width()
{
	# convert percentage into tpl width of bar
	full='50.270832'
	width=$(echo 'scale=6;('$full'*'"$1"')/1' | bc | sed 's/^\./0./')
}

function dayofyear()
{
	date -d $(date -d "$1" '+%Y')'-02-29' &>/dev/null && diy=366 || diy=365;
	doy=$(date -d "$1" '+%j')
	perc2width $doy'.000000/'$diy'.00000'
	doywidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "dayofyear - "$doy" - "$diy" - "$doywidth
	fi
}

function dayofmonth()
{
	for dim in $(cal $(date -d "$1" '+%m %Y') | sed 's/[^0-9 ]//g')
	do 
		true
	done
	dom=$(date -d "$1" '+%d')
	perc2width $dom'.0000/'$dim'.0000'
	domwidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "dayofmonth - "$dom" - "$dim" - "$domwidth
	fi
}

function hourofday()
{
	hod=$(date -d "$1" '+%H')
	perc2width $hod'.0000/23.0000'
	hodwidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "hourofday - "$hod" - "$hodwidth
	fi
}

function minuteofhour()
{
	moh=$(date -d "$1" '+%M')
	perc2width $moh'.0000/59.0000'
	mohwidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "minuteofhour - "$moh" - "$mohwidth
	fi
}

function clock()
{
	if [ -z ${1+x} ]
	then
		epoch=$(( $(date '+%s') + 60 ))
	else
		if [ "$1" == "now" ]
		then
			epoch=$(date '+%s')
		else
			epoch=$(date -d "$1" '+%s')
		fi
	fi

	date=$(date -d@$epoch '+%Y-%m-%d %H:%M')
	filename=$(echo $date | sed 's/[ :\-]//g')

	bmpfile=$filename'.bmp'
	if [ -f $bmpfile ]
	then
		if [ ${DEBUG+x} ]
		then
			echo "file exists: "$bmpfile
		fi
		return 0
	fi

	if [ ${DEBUG+x} ]
	then
		echo $epoch' - '$date' - '$filename
	fi

	dayofyear "$date"		# red
	dayofmonth "$date"		# blue
	hourofday "$date"		# green
	minuteofhour "$date"		# yellow

	cp lcarsclock.tpl $filename'.svg'

	sed -i 's/===RED===/'$doywidth'/g;s/===BLUE===/'$domwidth'/g;s/===GREEN===/'$hodwidth'/g;s/===YELLOW===/'$mohwidth'/g;' $filename'.svg'

	convert -density 384 -flatten $filename'.svg' -resize '320x240!' \
		$filename'.png'

	convert -font swiss2.ttf -pointsize 50 -gravity center \
		-fill white -background black \
		-size '280x58' \
		label:"$(date -d@$epoch '+%Y %m %d . %H %M')" \
		$filename'-font.png'

	convert $filename'.png' $filename'-font.png' -geometry +20+11 \
		-composite \
		png32:$filename'.png'

	convert $filename'.png' -flip -type truecolor \
		-define bmp:subtype=RGB565 \
		$bmpfile

	if [ ${DEBUG+x} ]
	then
		rm $filename'.svg' $filename'-font.png'
	else
		rm $filename'.svg' $filename'-font.png' $filename'.png'
	fi
}

if [ -z ${1+x} ]
then
	# operational: create current image if not existent
	clock "now"
	tail --bytes 153600 $bmpfile > $framebuffer

	# remove old images and pre-create next minute
	rm *.bmp
	clock
else
	DEBUG="DEBUG"
	if [ "$1" == "-d" ]
	then
		clock
	else
		clock "$1"
	fi
fi
