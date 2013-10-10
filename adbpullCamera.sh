#!/bin/bash

if [[ $OS =~ Windows ]]; then 
  photosDir=/cygdrive/d/Photos/PhoneCamera
else
  photosDir=/media/D/Photos/PhoneCamera
fi

mkdir -p ${photosDir}

if [ ! -d ${photosDir} ]; then 
	echo 'PhoneCamera directory not available. Quitting..'
	exit 1
fi

phoneDirs='
# /storage/sdcard0/DCIM/Camera
# /storage/sdcard1/DCIM/Camera
/storage/emulated/legacy/DCIM/100ANDRO
/storage/sdcard0/DCIM/100ANDRO
/storage/sdcard1/DCIM/100ANDRO
# /mnt/sdcard/DCIM/Camera
/storage/extSdCard/DCIM/Camera 
/mnt/sdcard/external_sd/DCIM/Camera 
/mnt/sdcard/DCIM/100ANDRO 
/mnt/sdcard/external_sd/DCIM/100ANDRO 
/mnt/sdcard/DCIM/101ANDRO 
/mnt/sdcard/external_sd/DCIM/101ANDRO'


## ----- DO NOT MODIFY ANYTHING BELOW IF YOU DONT KNOW WHAT IT DOES ----- #
if [ $(adb devices | grep -c device) -lt 2 ]; then 
	echo "No device found!"
	echo "Please connect phone with USB debugging enabled!"; 
	exit 1
fi

touch --date='2007-01-01' pulldate
adb push pulldate /data/local/tmp/
adb shell 'if [ ! -e /mnt/sdcard/DCIM/pulldate ]; then cp /data/local/tmp/pulldate /mnt/sdcard/DCIM/pulldate; fi'

nFiles=0  #number of total images
cFiles=0  #number of copied images

cd $photosDir

updateIfNew(){ 
	i=0; c=0;
	for f in $(adb shell busybox find $phoneDir -newer /mnt/sdcard/DCIM/pulldate -print)
	do 
		g=$(echo $f | tr -d [:space:]); 
		if [[ $g == *.jpg ]]; then 
			i=$(expr $i + 1)
			gbase=$(basename $g)
      gserial=$(echo $(adb get-serialno) | tr -d [:space:])
      fname="$gserial-$gbase"
			if [ ! -e $fname ]; then
				echo -n "$g [ $(adb shell "busybox du -h $g" | awk '{ print $1 }') ] : "
				adb pull $g $fname
				c=$(expr $c + 1)
			fi
		fi; 
	done
	# return nFiles
	nFiles=$i
	cFiles=$c
}

for f in $phoneDirs; do
	aX=$(adb shell "if [ -e $f ]; then echo 0; else echo 1; fi")
	aXn=$(echo $aX | tr -d [:space:])
  if [ x$aXn == 'x0' ]; then
		export phoneDir=$f
		echo "Checking directory: $phoneDir";
		updateIfNew
		echo "$cFiles / $nFiles images copied!"
	fi
done
adb shell su -c "/system/xbin/busybox touch /mnt/sdcard/DCIM/pulldate"
exit 0

