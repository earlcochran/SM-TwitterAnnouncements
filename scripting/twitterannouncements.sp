#include <sourcemod>

#include <base64>
//#include <cURL>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "Twitter Server Announcements",
	author      = "stretch",
	description = "Displays announcements made from a twitter account to your server.",
	version     = "0.1.0",
	url         = "http://whocares.net"
};

// GLOBALS
char g_bearerToken[256];

// CVARS

ConVar DisplayType = CreateConVar("sm_twitterannounce_displaytype", "0", "Announcement display type. 0 = say, 1 = msay", 0, true, "0.0", true, "1.0");


// Should probably load the config inside OnPluginStart, and check that the 
// key, the secret, and a bearer token are present. 
// If key/secret are not: throw an error.
// If bearer token is not: attempt to get one.

public void OnPluginStart()
{
	PrintToServer("Hello, World!");
	RegConsoleCmd("sm_twittertest", GetBearerToken);
}

public void GetBearerToken()
{
	// get config
	char configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, PLATFORM_MAX_PATH, "configs/twitterannouncements.cfg");

	// initialize KeyValues store, and import data from the config
	KeyValues apiKeys = new KeyValues("");
	apiKeys.ImportFromFile(configPath);

	// Store the key and secret
	char consumerKey[64];
	char consumerSecret[64];
	apiKeys.GetString("consumer_key", consumerKey, sizeof(consumerKey), "INVALID");
	apiKeys.GetString("consumer_secret", consumerSecret, sizeof(consumerSecret), "INVALID");
	
	// Concatenate key:secret
	char twitterKey[128];
	Format(twitterKey, sizeof(twitterKey), "%s:%s", consumerKey, consumerSecret);
	PrintToServer("%s", twitterKey);

	// Base64 encode the concatenated key:secret
	char encodedKey[128];
	EncodeBase64(encodedKey, 64, twitterKey);
	PrintToServer("%s", encodedKey);
}	

