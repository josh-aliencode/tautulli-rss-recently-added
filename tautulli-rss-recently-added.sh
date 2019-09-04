#!/bin/sh
##
##  ________________   ____ __________________ ___.____    .____    .___ 
##  \__    ___/  _  \ |    |   \__    ___/    |   \    |   |    |   |   |
##    |    | /  /_\  \|    |   / |    |  |    |   /    |   |    |   |   |
##    |    |/    |    \    |  /  |    |  |    |  /|    |___|    |___|   |
##    |____|\____|__  /______/   |____|  |______/ |_______ \_______ \___|
##                    \/                                    \/       \/  
##   __________  _________ _________                     .__        __   
##   \______   \/   _____//   _____/   ______ ___________|__|______/  |_ 
##    |       _/\_____  \ \_____  \   /  ___// ___\_  __ \  \____ \   __\
##    |    |   \/        \/        \  \___ \\  \___|  | \/  |  |_> >  |  
##    |____|_  /_______  /_______  / /____  >\___  >__|  |__|   __/|__|  
##           \/        \/        \/       \/     \/         |__|     
##    _________________________________________________________________.
##                                        | For Recently Added Content |
##										   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
##                                                              [ v1.0 ]
##
##	Created by: Josh McIntyre |  joshlee[at]hotmail.ca
##	Facebook: https://www.facebook.com/joshua.lee.mcintyre
##	Twitter: https://twitter.com/excidius
##                             
##	____________
##	INSTALLATION
##	‾‾‾‾‾‾‾‾‾‾‾‾
##	You'll need a WEB Server to store and access the RSS/XML file. I recommend Apache2.
##
##	Under Tautulli > Settings > Notification Agents
##	Add a new notification agent > Script
##	Choose the script folder, script file. (This File Location)
##	Set Script Timeout to 0
##	Write a description if you wish.
##	Click the 'Triggers' tab, choose 'Recently Added'
##	Click the 'Arguments' tab, choose 'Recently Added' and add this line:
## {filename} {media_type!c}<movie> {title} {year} {rating} </movie><episode> {show_name} {season_num00} {episode_num00} </episode>{poster_url} {imdb_url} {summary} {genres} {actors} {directors} {plex_url} {tagline}
##
##	If you want Images in your RSS
##	You need an Imgur.com account and also to register for a new application.
##	Register a new application here: https://api.imgur.com/oauth2/addclient
##	Enter an Application Name, Email, and Description, and select the option "OAuth 2 authorization without a callback URL".
##	You will receive a new client_id for your application. Enter this value for the "Imgur Client ID" in the Tautulli Settings > Notification and Newsletters
##	_______________
##	TROUBLESHOOTING
##	‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
##	Nothing will show up right away, it'll only add items to your RSS as Tautulli discovers new content added to your PLEX server.
##	Only Movies and Episodes will be put into the feed. Deleted items in your PLEX library will remain in the feed.
##	If by some chance your RSS/XML gets corrupt.. Just delete the XML file and let the script create a new one.
##	I've only tested this script in an Ubuntu Server enviroment. It should be compatible with most linux distros.


## XML_File: RSS File Location..
	XML_File="/var/www/html/rss/rss.xml"
## TMPFOLDER: Folder location for temp file needed for the script.
	TMPFOLDER="/tmp" 
## RSSTITLE: Title of RSS Feed.
	RSSTITLE="My Plex Server"
## RSSLINK: URL for RSS Feed.
	RSSLINK="https://app.plex.tv/desktop"
## RSSDESCRIPTION: Descrption of RSS Feed.
	RSSDESCRIPTION="Recently added content.."
## RSSAMOUNT: The amount of items in the feed.
	RSSAMOUNT="20"
## LINK_IMDB_OR_PLEX: Choose Item Link. 1 for IMDB URL. 2 for a PLEX URL of the item on your server.
	LINK_IMDB_OR_PLEX="1"
## SUMMARY_OR_TAGLINE: Choose Item Description. 1 for Summary or 2 for a short Tagline.
	SUMMARY_OR_TAGLINE="1"


Lock_File="/run/lock/tautulli-rss-recently-added.lock"
TMP_XML_File=$(mktemp $TMPFOLDER/rss.xml.XXXXXXXXX.tmp)

CDATA_Open="<![CDATA["
CDATA_Close="]]>"
Title_Open="<title>"
Title_Close="</title>"
Link_Open="<link>"
Link_Close="</link>"
pubDate_Open="<pubDate>"
pubDate_Close="</pubDate>"
Description_Open="<description>"
Description_Close="</description>"
lastBuildDate_Open="<lastBuildDate>"
lastBuildDate_Close="</lastBuildDate>"
Item_Open="<item>"
Item_Close="</item>"

# Arguments passed to the script from Tautulli
Media_Filename=$1
Media_Type=$2
Media_Title=$3
Media_Year_or_Season=$4
Media_Rating_or_Episode=$5
Media_Poster=$6
Media_IMDB_URL=$7
Media_Summary=$8
Media_Genre=$9
Media_Actors=${10}
Media_Director=${11}
Media_PLEX_URL=${12}
Media_Tagline=${13}

Date=$(date -R)
IMG_Link='<img src="'"$Media_Poster"'" alt="'"$Media_Filename"'">'
TMP_XML_File=$(mktemp $TMPFOLDER/rss.xml.XXXXXXXXX.tmp)
SED_LINE_ITEMO="9"
SED_LINE_TITLE="10"
SED_LINE_LINK="11"
SED_LINE_PUBDATE="12"
SED_LINE_DESCRIPTION="13"
SED_LINE_ITEMC="14"
Trim_File_Range="$(($RSSAMOUNT * 6 + 10))"

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NOCOLOR=`tput sgr0`

printf "Running script...\n\n"

## Review RSS Settings in terminal.
	printf "XML file: $XML_File\n\n"
	printf "RSS Title: $RSSTITLE\n"
	printf "RSS Description: $RSSDESCRIPTION\n"
	printf "RSS Link: $RSSLINK\n"
	printf "RSS Feed Amount: $RSSAMOUNT\n\n"

while true; do

	# Check if Lock_File exists
	if [ -e "$Lock_File" ]; then

		# Script is BUSY
		printf "${RED}Failed!${NOCOLOR} script is busy!\n"
		sleep 1
		printf "Trying again...\n\n"
		sleep 1

	else

		# Create temporary Lock_File to prevent the script running semitaneously
		printf "Writing lockfile to $Lock_File\n"
		touch $Lock_File
		printf "Lockfile created.\n\n"

		if [ -e "$XML_File" ]; then
			cp -f $XML_File $TMP_XML_File
		else
			## No XML yet.. Create one.
			printf '<?xml version="1.0" encoding="UTF-8" ?>\n' > "$TMP_XML_File"
			printf '<rss version="2.0">\n' >> "$TMP_XML_File"
			printf "<channel>\n" >> "$TMP_XML_File"
			printf "$Title_Open$CDATA_Open$RSSTITLE$CDATA_Close$Title_Close\n" >> "$TMP_XML_File"
			printf "$Link_Open$RSSLINK$Link_Close\n" >> "$TMP_XML_File"
			printf "$Description_Open$CDATA_Open$RSSDESCRIPTION$CDATA_Close$Description_Close\n" >> "$TMP_XML_File"
			printf "$lastBuildDate_Open$Date$lastBuildDate_Close\n" >> "$TMP_XML_File"
			printf "<language>en</language>\n" >> "$TMP_XML_File"
			printf "</channel>\n</rss>\n" >> $TMP_XML_File
		fi


		## Check if Item is already in XML.
		if grep -Fq "$Media_Filename" $TMP_XML_File; then

			printf "${RED}Error:${NOCOLOR} $Media_Filename \nalready added.\n\n"

		else

			## Check if details exist.
			if [ -z "$Media_Rating_or_Episode" ]; then
				printf "Empty" >> /dev/null
			else
				if [ "$Media_Type" = "Movie" ]; then
					Media_Rating_or_Episode='<b>['"$Media_Rating_or_Episode"'/10]</b> '
				fi
			fi
			#
				if [ -z "$Media_Genre" ]; then
					printf "Empty" >> /dev/null
				else
					Media_Genre="<br/><b>Genre:</b> $Media_Genre"
				fi
			#
					if [ -z "$Media_Actors" ]; then
						printf "Empty" >> /dev/null
					else
						Media_Actors="<br/><b>Actors:</b> $Media_Actors"
					fi
			#
						if [ -z "$Media_Director" ]; then
							printf "Empty" >> /dev/null
						else
							Media_Director="<br/><b>Director:</b> $Media_Director"
						fi

			## Write Item to XML. Also check if Movie or TVSHOW.
			sed -i "${SED_LINE_ITEMO}i $Item_Open" $TMP_XML_File

			if [ "$Media_Type" = "Movie" ]; then
				sed -i "${SED_LINE_TITLE}i $Title_Open$CDATA_Open<b>$Media_Title</b> ($Media_Year_or_Season)$CDATA_Close$Title_Close" $TMP_XML_File
			else
				sed -i "${SED_LINE_TITLE}i $Title_Open$CDATA_Open<b>$Media_Title</b> S$Media_Year_or_Season-E$Media_Rating_or_Episode$CDATA_Close$Title_Close" $TMP_XML_File
			fi

					if [ $LINK_IMDB_OR_PLEX = "1" ]; then
						sed -i "${SED_LINE_LINK}i $Link_Open$Media_IMDB_URL$Link_Close" $TMP_XML_File
					else
						sed -i "${SED_LINE_LINK}i $Link_Open$Media_PLEX_URL$Link_Close" $TMP_XML_File
					fi

					sed -i "${SED_LINE_PUBDATE}i $pubDate_Open$Date$pubDate_Close" $TMP_XML_File
				
				if [ $SUMMARY_OR_TAGLINE = "1" ]; then
					Pref_SUM="$Media_Summary"
				else
					Pref_SUM="$Media_Tagline"
				fi

			if [ "$Media_Type" = "Movie" ]; then
				sed -i "${SED_LINE_DESCRIPTION}i $Description_Open$CDATA_Open$IMG_Link$Media_Rating_or_Episode$Pref_SUM$Media_Genre$Media_Actors$Media_Director$CDATA_Close$Description_Close" $TMP_XML_File
			else
				sed -i "${SED_LINE_DESCRIPTION}i $Description_Open$CDATA_Open$IMG_Link$Pref_SUM$Media_Genre$Media_Actors$Media_Director$CDATA_Close$Description_Close" $TMP_XML_File
			fi

					sed -i "${SED_LINE_ITEMC}i $Item_Close" $TMP_XML_File

					printf "Added item: $Media_Filename\n"

					sed -i "/lastBuildDate/d" "$TMP_XML_File"
					sed -i "7i $lastBuildDate_Open$Date$lastBuildDate_Close" $TMP_XML_File
			

			## Check if XML File Needs to be trimmed.
			XML_File_Line_Count=$(grep -c ".*" $TMP_XML_File)
			if [ $XML_File_Line_Count -gt $Trim_File_Range ]; then
				printf "XML File needs trimming.\n"
				Trim_EOF=$(($Trim_File_Range-2))
				printf "$Trim_EOF\n"
				Trim_File=$(head -$Trim_File_Range $TMP_XML_File)
				Trim_File=$(echo "$Trim_File" | head -$Trim_EOF)
				printf "$Trim_File" > $TMP_XML_File
				printf "\n</channel>\n</rss>\n" >> "$TMP_XML_File"
			fi

				## Create XML from temporary file.
				mv -f $TMP_XML_File $XML_File
				chmod 755 $XML_File

		fi

		## Remove Temporary file.
		rm -f $TMP_XML_File

		# Remove Lock_File so that script can be run again.
		printf "Removing lockfile at $Lock_File\n"
		rm -f $Lock_File
		printf "Lockfile removed.\n\n"

		# Successfully Completed.
		printf "${GREEN}Script finished!${NOCOLOR}\n\n"

		exit
	fi
done