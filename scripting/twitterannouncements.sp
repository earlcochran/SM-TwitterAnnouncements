#include <sourcemod>

#include <base64>
#include <cURL>

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

char g_consumerKey[];
char g_consumerSecret[];

char g_bearerToken[];

// CVARS

ConVar DisplayType = CreateConVar("sm_twitterannounce_displaytype", "0", "Announcement display type. 0 = say, 1 = msay", 0, true, "0.0", true, "1.0");

public void OnPluginStart()
{
	PrintToServer("Hello, World!");
	RegConsoleCmd("sm_twittertest", GetBearerToken);
}

public Action GetBearerToken(int client, int args)
{
	char configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, PLATFORM_MAX_PATH, "configs/twitterannouncements.cfg");

	KeyValues apiKeys = new KeyValues("");
	apiKeys.ImportFromFile(configPath);

	char consumerKey[32];
	char consumerSecret[64];

	apiKeys.GetString("consumer_key", consumerKey, sizeof(consumerKey), "INVALID");
	apiKeys.GetString("consumer_secret", consumerSecret, sizeof(consumerSecret), "INVALID");

	PrintToServer("%s:%s", consumerKey, consumerSecret);
}	