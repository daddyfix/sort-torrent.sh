#!/bin/bash

##TR_TORRENT_NAME='Mark Ronson - Uptown Funk (feat. Bruno Mars) - Single'
#TR_TORRENT_NAME='01 Chandelier.mp3'
#TR_TORRENT_ID='54'
#TR_TORRENT_DIR='/mnt/usb/media/movies'


# --------------------------------
#
# Debug Level
# ON = display to console and logfile
# OFF = display just to console
#
# --------------------------------
if [[ "$DEBUG" == "on" ]]; then
	echo -e "Debug is ON"
fi

#echo "TORRENT NAME: $TR_TORRENT_NAME"

# --------------------------------
# 
# Debug and Logger
#
# --------------------------------
function debug() {

	if [ "$DEBUG" == "OFF" ]; then
		echo -en "$1\n" 1>&2
	else
		echo -en "$1\n" | tee -a $LOGFILE
	fi

}



debug "=========================================================="
debug "$(date)"
debug "Torrent ID: ${TR_TORRENT_ID}"
debug "Torrent Dir: ${TR_TORRENT_DIR}"
debug "Torrent Name: ${TR_TORRENT_NAME}"



# Media root folder
MEDIA_ROOT='/mnt/usb/media'

# This is the different root directories and type for what the media has been determined as.
# The values here correspond to the directory name in the Media Root Folder.
MEDIA_TYPES=( 'movies' 'tv' 'music' 'downloads' )

# If we can't figure out wht type of media it is then we figure it is Movies
MY_MEDIA_TYPE=''

# This will hold an array files
declare -a MEDIA_FILES

# Media Folder Name
MEDIA_FOLDER_NAME=''

#TV_TYPES=( 's[[:digit:]]*e[[:digit:]]*' 'S[[:digit:]]*E[[:digit:]]*' 'S[[:digit:]]*' 's[[:digit:]]*' 'HDTV' 'PDTV' 'Complete Season' )
TV_TYPES=( '(s|S)[0-9]{1,2}(e|E)[0-9]{1,2}' '(s|S)[0-9]{1,2}' 'HDTV' 'PDTV' 'Complete Season' )

MUSIC_TYPES=( '.mp3' '.wav' '.m4a' '.ogg' '.wma' )
EXE_TYPES=( '.exe' '.rar' '.zip' '.tar' '.png' '.jpg' )

FILE_TYPES=( 'directory' 'file' )
FILE_TYPE=''

# ---------------------------------------------------------------
#
# Make an Array of files
# Args are taken from Torrent NAME and DIR
# Store array a files in (MEDIA_FILES)
# Store file TR_TORRENT_NAMEtype (FILE_TYPE) as Directory or File
#
# ---------------------------------------------------------------
function makeArrayOfFiles() {

	# using bash to determine if a filename is a directory does not work on ntfs-3g.
	# So, we have to figure out if the filesname is a file to determine if it is a directory
	if isDirectory; then
		MEDIA_FILES=( $TR_TORRENT_DIR/"$TR_TORRENT_NAME"/* )
	else
		MEDIA_FILES=( "$TR_TORRENT_DIR/$TR_TORRENT_NAME" )
	fi

}

# ---------------------------------------------------------------
#
# What type of media is this 
#
# ---------------------------------------------------------------
function isKnownMediaType() {

	if [ ! -z "$MY_MEDIA_TYPE" ]; then
		return 0
	else
		return 1
	fi

}




# ---------------------------------------------------------------
#
# What type of file is this (directory or file)
#
# ---------------------------------------------------------------
function isDirectory() {

	if [ -z "$FILE_TYPE" ]; then

		#f="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}"
		if [ ! -f "${TR_TORRENT_DIR}/${TR_TORRENT_NAME}" ]; then
			debug "${TR_TORRENT_DIR}/${TR_TORRENT_NAME}"
			debug "Setting Torrent Media Type: DIRECTORY"
			FILE_TYPE=${FILE_TYPES[0]}
			return 0
		else
			debug "Setting Torrent Media Type: FILE"
			FILE_TYPE=${FILE_TYPES[1]}
			return 1
		fi

	else

		if [ "${FILE_TYPE}" == "${FILE_TYPES[0]}" ]; then
			return 0
		else
			return 1
		fi	

	fi

}






# ---------------------------------------------------------------
#
# Try and determine is the file is a TV Show
#
# ---------------------------------------------------------------
function tv() {

	if isKnownMediaType; then
		return 0
	fi

	for h in "${MEDIA_FILES[@]}"
	do
		for i in "${TV_TYPES[@]}"
		do
			#debug "isTV: Searching ${h} for ${i}"
			fn="${TR_TORRENT_NAME}"
			#fn="${h}"
			search=$(echo "$fn" | grep -Eo "${i}")
			if [[ ! -z $search ]]; then
				#RET=1
				#debug "${i} Found in ${TR_TORRENT_NAME}"
				
				debug "Setting Media Type: TV Show"

				#SEASON=$(echo "$fn" | sed 's/.*\([sS][[:digit:]]*[eE][[:digit:]]*\).*/\1/')
				#echo -e "Season: $SEASON"
				if isDirectory; then
					#parce the front EXCLUDING Season & Episode (sXXeXX)
					FOLDER_NAME=$(echo "$fn" | sed 's/[sS][[:digit:]]*[eE][[:digit:]]*.*//')

		            if [ -z "$FOLDER_NAME" ]; then
		                FOLDER_NAME=$(echo "$fn" | sed 's/[sS][[:digit:]]*.*//')
		            fi

#		            if [ -z "$FOLDER_NAME" ]; then
#		                FOLDER_NAME=$TR_TORRENT_NAME
#		            fi
					#echo -e "Before Season & Episode: $FOLDER_NAME"

					#Clean up dirty characters
					FOLDER_NAME=${FOLDER_NAME//[+=.,\(\)\[\]]/\ }

					# Remove trailing spaces
					FOLDER_NAME="${FOLDER_NAME%%*( )}"
				fi
				# tv
				MY_MEDIA_TYPE=${MEDIA_TYPES[1]}
				return 0
			fi
		done
	done
	#return 1

}

# ---------------------------------------------------------------
#
# Try and determine is the file is a Music File
#
# ---------------------------------------------------------------
function music() {

	if isKnownMediaType; then
		return 0
	fi

	for h in "${MEDIA_FILES[@]}"
	do
		for i in "${MUSIC_TYPES[@]}"
		do
			#debug "isMusic: Searching ${h} for ${i}"
			#fn="${TR_TORRENT_NAME}"
			fn="${h}"
			if [ ${fn: -4} == "$i" ]; then

				debug "Setting Media Type: Music"

				if isDirectory; then
					#Grab start of string to the Year
					FOLDER_NAME=$(echo "$TR_TORRENT_NAME" | sed -n -e 's/\([0-9][0-9][0-9][0-9]\).*/\1/p')

					FOLDER_NAME=${FOLDER_NAME//[+=.,\(\)\[\]]/\ }

					FOLDER_NAME=$(basename "$FOLDER_NAME")

					# Remove trailing spaces
					FOLDER_NAME="${FOLDER_NAME%%*( )}"

					if [ -z "$FOLDER_NAME" ]; then
						FOLDER_NAME=$TR_TORRENT_NAME
					fi
				fi
				#FOLDER_NAME=${FOLDER_NAME//[-+=.,]/\ }
				#echo -e "Title: $FOLDER_NAME"
				#debug "Trimmed Title: ${FOLDER_NAME}"

				# Music
				MY_MEDIA_TYPE=${MEDIA_TYPES[2]}
				return 0
			fi
		done

	done
	#return 1

}


# ---------------------------------------------------------------
#
# Try and determine is the file is a Download
#
# ---------------------------------------------------------------
function download() {

	if isKnownMediaType; then
		return 0
	fi

	for h in "${MEDIA_FILES[@]}"
	do
		for i in "${EXE_TYPES[@]}"
		do
			#debug "isExe: Searching ${h} for ${i}"
			fn="${TR_TORRENT_NAME}"
			#fn="${h}"
			if [ ${fn: -4} == "$i" ]; then

				debug "Setting Media Type: Download"
#				if isDirectory; then
#					#Grab start of string to the Year
#					FOLDER_NAME=$(echo "$fn" | cut -d "[" -f1)
#					FOLDER_NAME=$(echo "$FOLDER_NAME" | cut -d "(" -f1)

#					FOLDER_NAME=${FOLDER_NAME//[+=.~,/\ }

#					# Remove trailing spaces
#					FOLDER_NAME="${FOLDER_NAME%%*( )}"

#					FOLDER_NAME=$(basename "$FOLDER_NAME")
#					if [ -z "$FOLDER_NAME" ]; then
#						FOLDER_NAME=$TR_TORRENT_NAME
#					fi
#				fi
				FOLDER_NAME=""
				# Downloads
				MY_MEDIA_TYPE=${MEDIA_TYPES[3]}
				#return 0
			fi
		done

	done
	#return 1

}


# ---------------------------------------------------------------
#
# Clean the File a Movie type (cause we can't figure out what type it is
#
# ---------------------------------------------------------------
function movie() {

	if isKnownMediaType; then
		return 0
	fi

	debug "Setting Media Type: Movies"

	if isDirectory; then
		#Grab start of string to the Year
		FOLDER_NAME=$(echo "${TR_TORRENT_NAME}" | sed -n -e 's/\([0-9][0-9][0-9][0-9]\).*/\1/p')

		# Clean up special chars
		FOLDER_NAME=${FOLDER_NAME//[+=.,\(\)\[\]]/\ }

		# Remove trailing spaces
		FOLDER_NAME="${FOLDER_NAME%%*( )}"

		FOLDER_NAME=$(basename "$FOLDER_NAME")
		if [ -z "$FOLDER_NAME" ]; then
			FOLDER_NAME=$TR_TORRENT_NAME
		fi
	fi
	#FOLDER_NAME=${FOLDER_NAME//[-+=.,]/\ }
	#echo -e "Title: $FOLDER_NAME"
	#debug "Trimmed Title: ${FOLDER_NAME}"

	# Movies
	MY_MEDIA_TYPE=${MEDIA_TYPES[0]}

}


# ------------------------------------------------------------
#
#  MEAT AND POTATOES
#
# ------------------------------------------------------------

makeArrayOfFiles
tv
music
download
movie

debug "Media Type        : ${MY_MEDIA_TYPE}"
debug "File/Directory    : ${FILE_TYPE}"
debug "New Folder Name   : ${FOLDER_NAME}"


# ++++++++++++++++++++++++ MOVE FILES +++++++++++++++++++++++++++++

# ------------------------------------------------------------------
#
# Remove/Move the transmission movie from the list
# Usage: torrent-functions.py -a [move|delete] -i <id of Torrent> -u <username> -p <password> -d <destination>
#
# ------------------------------------------------------------------
allpassed=0
if [ -f "/scripts/torrent-done/trans_login.txt" ]; then
    TR_LOGIN=$(< /scripts/torrent-done/trans_login.txt)
	debug "Read Login File"
    allpassed=$(( allpassed + 1))
fi

if [ -f "/scripts/torrent-done/trans_passd.txt" ]; then
    TR_PASSD=$(< /scripts/torrent-done/trans_passd.txt)
	debug "Read Passwd File"
    allpassed=$(( allpassed + 1))
fi

if [[ $allpassed -eq 2 ]] ; then


	#if [ "${FILE_TYPE}" == "directory" ] && [ -d "${originLoc}/${nam}" ]; then
	if [ ! -z "${FOLDER_NAME}" ]; then
		FOLDER="/${FOLDER_NAME}/"
	else
		FOLDER=""
	fi

	#debug  "\n-----------------------------------------------------"
	#debug  "Getting Info for Torrent # $TR_TORRENT_ID"
	#debug  "-----------------------------------------------------\n"

	#originLoc=$(transmission-remote -n ${TR_LOGIN}:${TR_PASSD} -t ${TR_TORRENT_ID} --info | grep Location | cut -d':' -f2 | sed -e 's/^ *//')
	#nam=$(transmission-remote -n ${TR_LOGIN}:${TR_PASSD} -t ${TR_TORRENT_ID} --info | grep Name | cut -d':' -f2 | sed -e 's/^ *//')
	#debug "Response: ${nam}, ${originLoc}"



	debug  "\n-----------------------------------------------------"
	debug  "Moving Torrent ID-$TR_TORRENT_ID to New Location"
	debug  "-----------------------------------------------------\n"

	debug "New Location: ${MEDIA_ROOT}/${MY_MEDIA_TYPE}${FOLDER}"
	if [ ! -d "${MEDIA_ROOT}/${MY_MEDIA_TYPE}${FOLDER}" ]; then
		mkdir -p "${MEDIA_ROOT}/${MY_MEDIA_TYPE}${FOLDER}"
		chown -R debian-transmission:debian-transmission "${MEDIA_ROOT}/${MY_MEDIA_TYPE}${FOLDER}"
		chmod -R 777 "${MEDIA_ROOT}/${MY_MEDIA_TYPE}${FOLDER}"
	fi

	info=$(transmission-remote -n $TR_LOGIN:$TR_PASSD -t ${TR_TORRENT_ID} --move "${MEDIA_ROOT}/${MY_MEDIA_TYPE}${FOLDER}")

	debug "Response: ${info}"

	#info=$(transmission-remote -n $TR_LOGIN:$TR_PASSD -t ${TR_TORRENT_ID} --remove)

	#debug "Response: ${info}"

	debug  "\n-----------------------------------------------------"
	debug  "Verifying Transmission Location"
	debug  "-----------------------------------------------------\n"

	destLoc=$(transmission-remote -n ${TR_LOGIN}:${TR_PASSD} -t ${TR_TORRENT_ID} --info | grep Location | cut -d':' -f2 | sed -e 's/^ *//')
	nam=$(transmission-remote -n ${TR_LOGIN}:${TR_PASSD} -t ${TR_TORRENT_ID} --info | grep Name | cut -d':' -f2 | sed -e 's/^ *//')

	debug "Response: ${destLoc}/${nam}"

else
    debug "Couldn't read /scripts/torrent-done/trans_login.txt and/or /scripts/torrent-done/trans_passd.txt"
    debug "Aborting Move Function [allpassed = $allpassed]"
fi





















