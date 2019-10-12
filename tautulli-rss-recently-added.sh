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
##
##                                                              [ v1.1 ]
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
## 	<movie>{filename} {media_type!c} {title} {year} {rating} {poster_url} {imdb_url} {summary} {genres} {actors} {directors} {plex_url} {tagline}</movie><episode>{filename} {media_type!c} {title} {season_num00} {episode_num00} {poster_url} {imdb_url} {summary} {genres} {actors} {directors} {plex_url} {tagline}</episode>
##
##	If you want Images in your RSS...
##	You need an Imgur.com account and also to register for a new application.
##	Register a new application here: https://api.imgur.com/oauth2/addclient
##	Enter an Application Name, Email, and Description, and select the option "OAuth 2 authorization without a callback URL".
##	You will receive a new client_id for your application. Enter this value for the "Imgur Client ID" in the Tautulli Settings > Notification and Newsletters
##	_______________
##	TROUBLESHOOTING
##	‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
##	Nothing will show up right away, it'll only add items to your RSS as Tautulli discovers new content added to your PLEX server.
##	Only Movies and Episodes will be put into the feed. Deleted items in your PLEX library will remain in the feed.
##	If your XML File doesn't create itself, check your location and see if you have permissions.
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

	if [ $# -eq 0 ]; then
		echo "No arguments!\nExiting..\n"
		exit 0
	fi

## Review RSS Settings in terminal.
	printf "XML file: $XML_File\n\n"
	printf "RSS Title: $RSSTITLE\n"
	printf "RSS Description: $RSSDESCRIPTION\n"
	printf "RSS Link: $RSSLINK\n"
	printf "RSS Feed Amount: $RSSAMOUNT\n\n"

while true; do

	# Check if Lock_File exists
	if [ -e "$Lock_File" ]; then

		# Script is BUSY!
		printf "${RED}Failed!${NOCOLOR} script is busy!\n"
		sleep 1
		printf "Trying again...\n\n"
		sleep 1

	else

		# Create temporary Lock_File to prevent the script from running multiple instances.
		printf "Writing lockfile to $Lock_File\n"
		touch $Lock_File
		printf "Lockfile created.\n\n"

		if [ -e "$XML_File" ]; then
			if [ -w "$XML_File" ]; then
				cp -f $XML_File $TMP_XML_File
				chmod 750 $TMP_XML_File
			else
				printf "XML File is not writeable! Check permissions!\n\n"
				rm $Lock_File
				exit 0
			fi
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
			if [ -n "$Media_Rating_or_Episode" ]; then

				if [ "$Media_Type" = "Movie" ]; then
					Media_Rating_or_Episode='<b>['"$Media_Rating_or_Episode"'/10]</b> '
				fi
			fi

				if [ -n "$Media_Genre" ]; then
					Media_Genre="<br/><b>Genre:</b> $Media_Genre"
				fi

					if [ -n "$Media_Actors" ]; then
						Media_Actors="<br/><b>Actors:</b> $Media_Actors"
					fi

						if [ -n "$Media_Director" ]; then
							Media_Director="<br/><b>Director:</b> $Media_Director"
						fi

							if [ -z "$Media_IMDB_URL" ]; then
								if [ "$Media_Type" = "Movie" ]; then
									Google_Keyword=$(echo "$Media_Title $Media_Year_or_Season" | sed 's/[^-[:alnum:]]/+/g' | tr -s '+')
									Google='https://www.google.com/search?q='"$Google_Keyword"'+movie+imdb&btnI'
								else
									Google_Keyword=$(echo "$Media_Title" | sed 's/[^-[:alnum:]]/+/g' | tr -s '+')
									Google='https://www.google.com/search?q='"$Google_Keyword"'+tv+imdb&btnI'
								fi
									Media_IMDB_URL="$Google"
							fi

								if [ -z "$Media_PLEX_URL" ]; then
									Media_PLEX_URL="https://app.plex.tv/desktop"
								fi

			## Write Item to XML. Also check if Movie or TVSHOW.
			sed -i "${SED_LINE_ITEMO}i $Item_Open" $TMP_XML_File

			if [ "$Media_Type" = "Movie" ]; then
				sed -i "${SED_LINE_TITLE}i $Title_Open$CDATA_Open$Media_Title ($Media_Year_or_Season)$CDATA_Close$Title_Close" $TMP_XML_File
			else
				sed -i "${SED_LINE_TITLE}i $Title_Open$CDATA_Open$Media_Title S$Media_Year_or_Season-E$Media_Rating_or_Episode$CDATA_Close$Title_Close" $TMP_XML_File
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
				sed -i "${SED_LINE_DESCRIPTION}i $Description_Open$CDATA_Open$IMG_Link<p>$Media_Rating_or_Episode$Pref_SUM$Media_Genre$Media_Actors$Media_Director</p>$CDATA_Close$Description_Close" $TMP_XML_File
			else
				sed -i "${SED_LINE_DESCRIPTION}i $Description_Open$CDATA_Open$IMG_Link<p>$Pref_SUM$Media_Genre$Media_Actors$Media_Director</p>$CDATA_Close$Description_Close" $TMP_XML_File
			fi

					sed -i "${SED_LINE_ITEMC}i $Item_Close" $TMP_XML_File

					printf "Added item: $Media_Filename\n"

					sed -i "/lastBuildDate/d" "$TMP_XML_File"
					sed -i "7i $lastBuildDate_Open$Date$lastBuildDate_Close" $TMP_XML_File

			## Check if XML File Needs to be trimmed.
			XML_File_Line_Count=$(grep -c ".*" $TMP_XML_File)
			if [ $XML_File_Line_Count -gt $Trim_File_Range ]; then
				Trim_EOF=$(($Trim_File_Range-2))
				Trim_File=$(head -$Trim_File_Range $TMP_XML_File)
				Trim_File=$(echo "$Trim_File" | head -$Trim_EOF)
				printf "$Trim_File" > $TMP_XML_File
				printf "\n</channel>\n</rss>\n" >> "$TMP_XML_File"
			fi

				## Create XML from temporary file.
				mv -f $TMP_XML_File $XML_File
				chmod 775 $XML_File

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
