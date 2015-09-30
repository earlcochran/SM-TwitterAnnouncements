#include <sourcemod>

#include <base64>
#include <SteamWorks>

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

char gConfigPath[PLATFORM_MAX_PATH];

KeyValues gApiKeys;

char gConsumerKey[64];
char gConsumerSecret[64];
char gBearerToken[256];

// CVARS
ConVar DisplayType = CreateConVar("sm_twitterannounce_displaytype", "0", "Announcement display type. 0 = say, 1 = msay, 2 = csay", 0, true, "0.0", true, "2.0");

public void OnPluginStart()
{
	gApiKeys = new KeyValues("");
	LoadConfig();
	//RegConsoleCmd("sm_twittertest", GetBearerToken);
}

public void LoadConfig()
{
	// get config
	BuildPath(Path_SM, gConfigPath, PLATFORM_MAX_PATH, "configs/twitterannouncements.cfg");

	// Import data from the config into the KeyValues store.
	if(gApiKeys.ImportFromFile(gConfigPath))
	{
		// Store the key and secret. Check for existing bearer token.
		gApiKeys.GetString("consumer_key", gConsumerKey, sizeof(gConsumerKey), "INVALID");
		gApiKeys.GetString("consumer_secret", gConsumerSecret, sizeof(gConsumerSecret), "INVALID");
		gApiKeys.GetString("bearer_token", gBearerToken, sizeof(gBearerToken), "INVALID");

		if (strcmp(gConsumerKey, "INVALID") == 0 || strcmp(gConsumerSecret, "INVALID") == 0)
		{
			SetFailState("%s", "Your config is missing either the consumer_key, or consumer_secret keys.");
		}
		else if (strcmp(gBearerToken, "INVALID") == 0)
		{
			LogMessage("%s", "No bearer token was present in the config, lets try and get one.");
			GetBearerToken();
		}
		else 
		{
			delete gApiKeys;
		}
	}
	else
	{
		SetFailState("%s", "Something went wrong when we tried to import the config file.");
	}
}
public void GetBearerToken()
{
	// Concatenate key:secret
	char twitterKey[128];
	Format(twitterKey, sizeof(twitterKey), "%s:%s", gConsumerKey, gConsumerSecret);
	PrintToServer("%s", twitterKey);

	// Base64 encode the concatenated key:secret
	char encodedKey[256];
	EncodeBase64(encodedKey, sizeof(encodedKey), twitterKey);

	char authorizationHeader[128];
	Format(authorizationHeader, sizeof(authorizationHeader), "Basic %s", encodedKey);

	// Create request
	Handle request_GetBearerToken = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://api.twitter.com/oauth2/token");
	SteamWorks_SetHTTPRequestHeaderValue(request_GetBearerToken, "Authorization", authorizationHeader);
	SteamWorks_SetHTTPRequestHeaderValue(request_GetBearerToken, "Content-Type", "application/x-www-form-urlencoded;charset=UTF-8");
	SteamWorks_SetHTTPRequestGetOrPostParameter(request_GetBearerToken, "grant_type", "client_credentials");

	// Send request
	SteamWorks_SetHTTPCallbacks(request_GetBearerToken, GotBearerTokenData);
	SteamWorks_SendHTTPRequest(request_GetBearerToken);
}

public int GotBearerTokenData(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode eStatusCode)
{
	if (requestSuccessful)
	{
		int size;
		SteamWorks_GetHTTPResponseBodySize(request, size);
		char[] body = new char[size];
		SteamWorks_GetHTTPResponseBodyData(request, body, size);

		switch(eStatusCode)
		{
			case k_EHTTPStatusCode403Forbidden:
			{
				SetFailState("%s", "The request for a bearer token was refused. Please check your consumer_key/consumer_secret, and reload the plugin.");
			}
			case k_EHTTPStatusCode200OK:
			{
				LogMessage("%s", "Successfully retrieved a bearer token from twitter. Saving it to the config.");
				char bearerToken[] = "some shit";
				gApiKeys.SetString("bearer_token", bearerToken);
				if(gApiKeys.ExportToFile(gConfigPath))
				{
					delete gApiKeys;
				}
				else
				{
					SetFailState("%s", "There was an error while trying to save the bearer token to the config.");
				}
			}
		}
	}
}

