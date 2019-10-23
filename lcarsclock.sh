#! /usr/bin/env bash

user='schumach'
framebuffer='/dev/fb1'
lcarsdir='/home/'$user'/git/lcarsclock'
fortunedir=$lcarsdir'/fortunes'
tmpdir=$lcarsdir'/tmp'

datefont=$lcarsdir'/swiss2.ttf'
textfont=$lcarsdir'/swiss911.ttf'

fullwidth='50.270832'

fortune='/usr/games/fortune'
convert='/usr/bin/convert'
date='/bin/date'
bc='/usr/bin/bc'
cal='/usr/bin/cal'
sed='/bin/sed'

function perc2width()
{
	width=$(echo 'scale=6;('$fullwidth'*'"$1"')/1' | $bc | $sed 's/^\./0./')
}

function dayofyear()
{
	$date -d $($date -d "$1" '+%Y')'-02-29' \
		&>/dev/null && diy=366 || diy=365;
	doy=$($date -d "$1" '+%j')
	perc2width $doy'.000000/'$diy'.00000'
	doywidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "dayofyear - "$doy" - "$diy" - "$doywidth
	fi
}

function dayofmonth()
{
	for dim in $($cal $($date -d "$1" '+%m %Y') | $sed 's/[^0-9 ]//g')
	do 
		true
	done
	dom=$($date -d "$1" '+%d')
	perc2width $dom'.0000/'$dim'.0000'
	domwidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "dayofmonth - "$dom" - "$dim" - "$domwidth
	fi
}

function hourofday()
{
	hod=$($date -d "$1" '+%H')
	perc2width $hod'.0000/23.0000'
	hodwidth=$width
	if [ ${DEBUG+x} ]
	then
		echo "hourofday - "$hod" - "$hodwidth
	fi
}

function minuteofhour()
{
	moh=$($date -d "$1" '+%M')
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
		epoch=$(( $($date '+%s') + 60 ))
	else
		if [ "$1" == "now" ]
		then
			epoch=$($date '+%s')
		else
			epoch=$($date -d "$1" '+%s')
		fi
	fi

	thisdate=$($date -d@$epoch '+%Y-%m-%d %H:%M')
	filename=$tmpdir'/'$(echo $thisdate | $sed 's/[ :\-]//g')

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
		echo $epoch' - '$thisdate' - '$filename
	fi

	dayofyear "$thisdate"		# red
	dayofmonth "$thisdate"		# blue
	hourofday "$thisdate"		# green
	minuteofhour "$thisdate"	# yellow

	cp $lcarsdir'/'lcarsclock.tpl $filename'.svg'

	$sed -i 's/===RED===/'$doywidth'/g;s/===BLUE===/'$domwidth'/g;s/===GREEN===/'$hodwidth'/g;s/===YELLOW===/'$mohwidth'/g;' $filename'.svg'

	$convert -density 384 -flatten $filename'.svg' -resize '320x240!' \
		$filename'.png'

	$convert -font $datefont -gravity center \
		-fill white -background black \
		-size '1080x232' \
		label:"$($date -d@$epoch '+%Y %m %d . %H %M')" \
		$filename'-font.png'

	$convert -font $textfont -gravity center \
		-fill white -background black \
		-size '1080x212' \
		caption:"$($fortune $fortunedir)" \
		$filename'-fortune.png'

	$convert $filename'.png' \
		$filename'-font.png' -geometry 270x58+25+11 \
		-composite \
		$filename'-fortune.png' -geometry 270x53+25+177 \
		-composite \
		png32:$filename'.png'

	$convert $filename'.png' -flip -type truecolor \
		-define bmp:subtype=RGB565 \
		$bmpfile

	if [ ${DEBUG+x} ]
	then
		rm $filename'.svg' $filename'-font.png' \
			$filename'-fortune.png'
	else
		rm $filename'.svg' $filename'-font.png' $filename'.png' \
			$filename'-fortune.png'
	fi
}

if [ ! -d $tmpdir ]
then
	mkdir -p $tmpdir
fi

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
