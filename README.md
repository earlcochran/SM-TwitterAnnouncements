#Sourcemod Twitter Announcements

A sourcemod plugin that allows server admins to broadcast announcements to all of their servers via Twitter.

##Prerequisites

This plugin depends on the following extensions, and includes. Obtain them from the links below, and install them to your server before proceeding:

1. [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556)
2. [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)
3. [Base64](https://forums.alliedmods.net/showthread.php?t=101764)

##Installation

1. Download the archive to your server mod's root folder. (Ex: /csgo/, /tf2/, etc...)
2. Extract it: `tar xvzf sm-twitter-announcements.tar.gz` 


##Setup

This plugin relies on the Twitter API, and you will need a set of API keys from Twitter in order to properly use the plugin. The following instructions will walkthrough creating a new app through twitter, in order to obtain an authentication key, and secret.

1. Login to Twitter and head to https://apps.twitter.com/app/new
2. Fill out the necessary information to create a new application
3. Once the application has been created, navigate to the "Keys and Access Tokens" tab.
4. Copy the Consumer Key, and the Consumer Secret into their proper locations in `configs/twitterannouncements.cfg`
5. Replace the `screen_name` value with the desired account to monitor.