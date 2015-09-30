#include <sourcemod>

#include <base64>
#include <SteamWorks>
#include <smjansson>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "Twitter Server Announcements",
	author      = "stretch",
	description = "Displays announcements made from a twitter account to your server.",
	version     = "0.5.0",
	url         = "http://whocares.net"
};

// GLOBALS
char gConfigPath[PLATFORM_MAX_PATH];

KeyValues gApiKeys;

char gTwitterAccount[64];
char gConsumerKey[64];
char gConsumerSecret[64];
char gBearerToken[256];
char gLastTweet[256];

// CVARS
ConVar DisplayType;

public void OnPluginStart()
{
	gApiKeys = new KeyValues("");

	DisplayType = CreateConVar("sm_ta_displaytype", "0", "Announcement display type. 0 = hintbox, 1 = msay", 0, true, 0.0, true, 1.0);
	LoadConfig();

	CreateTimer(30.0, CheckForNewTweet, _, TIMER_REPEAT);
}

public void LoadConfig()
{
	// get config path
	BuildPath(Path_SM, gConfigPath, PLATFORM_MAX_PATH, "configs/twitterannouncements.cfg");

	// Import data from the config into the KeyValues store.
	if(gApiKeys.ImportFromFile(gConfigPath))
	{
		// Try and store the account, key, secret, and bearer token.
		gApiKeys.GetString("twitter_account", gTwitterAccount, sizeof(gTwitterAccount), "INVALID");
		gApiKeys.GetString("consumer_key", gConsumerKey, sizeof(gConsumerKey), "INVALID");
		gApiKeys.GetString("consumer_secret", gConsumerSecret, sizeof(gConsumerSecret), "INVALID");
		gApiKeys.GetString("bearer_token", gBearerToken, sizeof(gBearerToken), "INVALID");

		if (strcmp(gTwitterAccount, "INVALID") == 0 || strcmp(gConsumerKey, "INVALID") == 0 || strcmp(gConsumerSecret, "INVALID") == 0)
		{
			SetFailState("%s", "Your config is missing the twitter_account, consumer_key, or consumer_secret keys.");
			delete gApiKeys;
		}
		else if (strcmp(gBearerToken, "INVALID") == 0)
		{
			LogMessage("%s", "No bearer token was present in the config, lets try and get one.");
			GetBearerToken();
		}
		else 
		{
			LogMessage("%s", "Config loaded successfully!");
			delete gApiKeys;
		}
	}
	else
	{
		SetFailState("%s", "Something went wrong when we tried to import the config file.");
		delete gApiKeys;
	}
}

public void GetBearerToken()
{
	// Concatenate key:secret
	char twitterKey[128];
	Format(twitterKey, sizeof(twitterKey), "%s:%s", gConsumerKey, gConsumerSecret);

	// Base64 encode the concatenated key:secret
	char encodedKey[128];
	EncodeBase64(encodedKey, sizeof(encodedKey), twitterKey);

	// Format the Authorization header
	char authorizationHeader[256];
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
		int bodySize;
		SteamWorks_GetHTTPResponseBodySize(request, bodySize);

		char[] body = new char[bodySize];
		SteamWorks_GetHTTPResponseBodyData(request, body, bodySize);

		switch(eStatusCode)
		{
			case k_EHTTPStatusCode200OK:
			{
				LogMessage("%s", "Successfully retrieved a bearer token from twitter. Saving it to the config.");
				
				// Create JSON handle, load the response, and retreive the token.
				Handle response = json_load(body);
				char bearerToken[140];
				json_object_get_string(response, "access_token", bearerToken, sizeof(bearerToken));

				// Set the token in the KeyValues store, and save it to the config file.
				gApiKeys.SetString("bearer_token", bearerToken);
				if(gApiKeys.ExportToFile(gConfigPath))
				{
					LogMessage("%s", "Config saved successfully!");
					delete gApiKeys;
				}
				else
				{
					SetFailState("%s", "There was an error while trying to save the bearer token to the config.");
				}
				// Free the request & response Handles
				delete request;
				delete response;
			}
			case k_EHTTPStatusCode403Forbidden:
			{
				SetFailState("%s", "The request for a bearer token was refused. Please check your consumer_key/consumer_secret, and reload the plugin.");
				delete request;
			}
			/*
			case k_EHTTPStatusCode500InternalServerError, k_EHTTPStatusCode503ServiceUnavailable:
			{
				LogError("%s", "The Twitter API servers are not working, or under heavy load. Trying again...");
				SteamWorks_SendHTTPRequest(request);
			}*/
		}
		delete request;
	}
	else
	{
		SetFailState("%s", "The request to obtain a bearer token failed.");
	}
}

public bool GetMostRecentTweet()
{
	// Format the Authorization header
	char authorizationHeader[256];
	Format(authorizationHeader, sizeof(authorizationHeader), "Bearer %s", gBearerToken);

	// Create the request
	Handle request_GetMostRecentTweet = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://api.twitter.com/1.1/statuses/user_timeline.json");
	SteamWorks_SetHTTPRequestHeaderValue(request_GetMostRecentTweet, "Authorization", authorizationHeader);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request_GetMostRecentTweet, "screen_name", gTwitterAccount);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request_GetMostRecentTweet, "count", "1");
	SteamWorks_SetHTTPRequestGetOrPostParameter(request_GetMostRecentTweet, "exclude_replies", "true");
	
	// Set the callback, and send the request
	SteamWorks_SetHTTPCallbacks(request_GetMostRecentTweet, GotMostRecentTweetData);
	SteamWorks_SendHTTPRequest(request_GetMostRecentTweet);

}

public int GotMostRecentTweetData(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode eStatusCode)
{
	if (requestSuccessful)
	{
		int bodySize;
		SteamWorks_GetHTTPResponseBodySize(request, bodySize);

		char[] body = new char[bodySize];
		SteamWorks_GetHTTPResponseBodyData(request, body, bodySize);

		switch(eStatusCode)
		{
			case k_EHTTPStatusCode200OK:
			{
				// Create JSON handle, load the response, and retreive the latest tweet.
				Handle response = json_load(body);
				response = json_array_get(response, 0);

				char currentTweet[256];
				json_object_get_string(response, "text", currentTweet, sizeof(currentTweet));

				// Compare current tweet to the last tweet, if they are different:
				if(strcmp(currentTweet, gLastTweet) != 0)
				{
					PrintToChatAll("[ANNOUNCEMENT]: %s", currentTweet);
					if (DisplayType.IntValue == 0)
					{
						PrintCenterTextAll("%s", currentTweet);
					}
					if (DisplayType.IntValue == 1)
					{
						ServerCommand("sm_msay %s", currentTweet);
					}

					gLastTweet = currentTweet;
				}
				delete request;
				delete response;

			}
			case k_EHTTPStatusCode401Unauthorized:
			{
				SetFailState("%s", "The supplied bearer token is expired, or invalid.");
				delete request;
			}
			case k_EHTTPStatusCode403Forbidden:
			{
				SetFailState("%s", "The request was denied.");
				delete request;
			}
		}
	}
	else
	{
		LogError("%s", "We failed to retrieve the last tweet.");
	}
}

public Action CheckForNewTweet(Handle timer)
{
	GetMostRecentTweet();
}
