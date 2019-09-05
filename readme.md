**INSTALLATION**  

You'll need a **WEB Server** to store and access the RSS/XML file. I recommend **Apache2**.  

Under **Tautulli** > **Settings** > **Notification Agents**  
**Add a new notification agent** > **Script**  
Choose the script folder, & script file location.  
Set **Script Timeout** to *0* & Write a **Description**.  
Click the **Triggers** tab, choose **Recently Added**.  
Click the **Arguments** tab, choose **Recently Added** and add this line:  

<pre><code><movie>{filename} {media_type!c} {title} {year} {rating} {poster_url} {imdb_url} {summary} {genres} {actors} {directors} {plex_url} {tagline}</movie><episode>{filename} {media_type!c} {title} {season_num00} {episode_num00} {poster_url} {imdb_url} {summary} {genres} {actors} {directors} {plex_url} {tagline}</episode></code></pre>


If you want **Images** in your RSS...  
You need an **Imgur.com** account and also to register for a new application.  
**Register a new application** here: https://api.imgur.com/oauth2/addclient  
Enter an **Application Name**, **Email**, and **Description**, and select the option "**OAuth 2 authorization without a callback URL**".  
You will receive a new **client_id** for your application.  
Enter this value for the "**Imgur Client ID**" in the **Tautulli Settings** > **Notification and Newsletters**  

**TROUBLESHOOTING**  

* Nothing will show up right away, it'll only add items to your RSS as Tautulli discovers new content added to your PLEX server.  

* Only Movies and Episodes will be put into the feed. Deleted items in your PLEX library will remain in the feed.  

* If your XML File doesn't create itself, check your location and see if Tautulli has permissions to write there.  

* If by some chance your RSS/XML gets corrupt.. Just delete the XML file and let the script create a new one.  

* I've only tested this script in an Ubuntu Server enviroment. It should be compatible with most linux distros.  



Created by: Josh McIntyre  
Email: joshlee[at]hotmail.ca  
Facebook: https://www.facebook.com/joshua.lee.mcintyre  
Twitter: https://twitter.com/excidius  
					

