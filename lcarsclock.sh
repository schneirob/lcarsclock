#! /usr/bin/env bash

framebuffer=/dev/fb2

function perc2width()
{
	# convert percentage into tpl width of bar
	full='42.333332'
	width=$(echo 'scale=6;('$full'*'"$1"')/1' | bc | sed 's/^\./0./')
}

function dayofyear()
{
	date -d $(date -d "$1" '+%Y')'-02-29' &>/dev/null && diy=366 || diy=365;
	perc2width $(date -d "$1" '+%j')'.000000/'$diy'.00000'
	doywidth=$width
}

function dayofmonth()
{
	for dim in $(cal $(date -d "$1" '+%m %Y')); do true; done
	perc2width $(date -d "$1" '+%d')'.0000/'$dim'.0000'
	domwidth=$width
}

function hourofday()
{
	perc2width $(date -d "$1" '+%H')'.0000/23.0000'
	hodwidth=$width
}

function minuteofhour()
{
	perc2width $(date -d "$1" '+%M')'.0000/59.0000'
	mohwidth=$width
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
		# echo "file exists: "$bmpfile
		return 0
	fi

	# echo $epoch' - '$date' - '$filename

	dayofyear "$date"		# red
	dayofmonth "$date"		# blue
	hourofday "$date"		# green
	minuteofhour "$date"		# yellow

	cp lcarsclock.tpl $filename'.svg'

	sed -i 's/===RED===/'$doywidth'/g;s/===BLUE===/'$domwidth'/g;s/===GREEN===/'$hodwidth'/g;s/===YELLOW===/'$mohwidth'/g;' $filename'.svg'

	convert -density 384 -flatten $filename'.svg' -resize '320x240!' \
		$filename'.png'

	convert -font swiss911.ttf -pointsize 34 -gravity center \
		-fill white -background black \
		-size '280x34' \
		label:"$(date -d@$epoch '+%Y %m %d . %H %M')" \
		$filename'-font.png'

	convert $filename'.png' $filename'-font.png' -geometry +20+11 \
		-composite \
		png32:$filename'.png'

	convert $filename'.png' -flip -type truecolor \
		-define bmp:subtype=RGB565 \
		$bmpfile

	rm $filename'.svg' $filename'-font.png' $filename'.png'
}

clock "now"
tail --bytes 153600 $bmpfile > $framebuffer

# remove old images and pre-create next minute
rm *.bmp
clock
