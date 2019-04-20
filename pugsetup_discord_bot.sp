#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <autoexec>

#include <kento_csgocolors>

#include "include/pugsetup.inc"
#include "pugsetup/util.sp"

#include <json>
#include <system2>

#include <base64>

#pragma semicolon 1

char g_Error[255];
char tags[] = "{BLUE}[Discord Bot]";
char g_SteamIDs[128][512];
char obj[128][128][512];
Database db;
//#define PLUGIN_VERSION "1.2"

public Plugin myinfo = {
    name = "CS:GO PugSetup: Discord Bot",
    author = "SoLo",
    description = "Discord supportation",
    version = PLUGIN_VERSION,
    url = "https://github.com/splewis/csgo-pug-setup"
};

public void OnPluginStart(){
    RegConsoleCmd("sm_link", linkDiscord, "[Discord Bot] link to discord");
    //RegConsoleCmd("sm_discord", Discord, "[Discord Bot] Test Command");

    if(SQL_CheckConfig("pugsetupDiscord")){
        db = SQL_Connect("pugsetupDiscord", true, g_Error, sizeof(g_Error));
    }else{
        db = SQL_Connect("default", true, g_Error, sizeof(g_Error));
    }
    
    if(db == null){
        LogError("[Discord Bot] Could not connect to database \"default\": %s", g_Error);
        return;
    }else{
        PrintToServer("[Discord Bot] Succeed to connect to the database");
    }
}

char generateRandomBase64(){
    char randomint[8];
    char randomB64[10];
    char urlrandomB64[10];
    IntToString(GetRandomInt(2048, 16777215), randomint, 8);
    EncodeBase64(randomB64, sizeof(randomB64), randomint, 10);
    Base64MimeToUrl(urlrandomB64, sizeof(urlrandomB64), randomB64);
    return urlrandomB64;
}

public Action linkDiscord(int client, int args){
    if(!isValidClient(client)){
        return Plugin_Handled;
    }
    char steamid[255];
    char query[255];
    GetClientAuthId( client, AuthId_Steam2, steamid, sizeof(steamid));
    Format(query, sizeof(query), "SELECT * FROM `link-ac` WHERE `steam` = '%s';", steamid);
    DBResultSet result = SQL_Query(db, query);
    char l_message[255];
    char code[255];
    Format(code, sizeof(code), "%s", generateRandomBase64());
    if(SQL_GetRowCount(result) > 0){
        Format(query, sizeof(query), "UPDATE `link-ac` SET `code` = '%s' WHERE `steam` = '%s';", code, steamid);
        if(SQL_FastQuery(db,query)){
            Format(l_message, sizeof(l_message), "Send this code to the HKHBC Mix Discord Bot: !link %s", code);
            PPrintToChat(client, l_message);
        }else{
            PPrintToChat(client, "Failed to generate code");
        }
    }else{
        Format(query, sizeof(query), "INSERT INTO `link-ac` ( `id`, `steam`, `code`, `created`) VALUES ( null, '%s', '%s', CURRENT_TIMESTAMP) ;", steamid, code);
        if(SQL_FastQuery(db,query)){
            Format(l_message, sizeof(l_message), "Send this code to the HKHBC Mix Discord Bot: !link %s", code);
            PPrintToChat(client, l_message);
        }else{
            PPrintToChat(client, "Failed to generate code");
        }
    }
    return Plugin_Handled;
}

public void PugSetup_OnGoingLive(){
    int CT = 0;
    int T = 0;
    JSON json;
    new JSON:json_CT[5];
    new JSON:json_T[5];
    for(int clients = 0; clients <= MaxClients; clients++){
        if(isValidClient(clients)){
            //char SteamID[256];
            if(!GetClientAuthId(clients, AuthId_Steam2, g_SteamIDs[clients], 512, false)){
                Error("Failed to get steamid");
                return ;
            }
            if(GetClientTeam(clients) == CS_TEAM_CT){
                CT++;
                obj[0][CT] = g_SteamIDs[clients];
            }else if(GetClientTeam(clients) == CS_TEAM_T){
                T++;
                obj[1][T] = g_SteamIDs[clients];
            }
        }
    }
    if(CT > 0){
        PPrintToChatAll("CT has the following player:");
        for(int j = 1; j <= CT; j++){
            PPrintToChatAll(obj[0][j]);
            JSON CTs;
            CTs = json_create();
            json_set_string( CTs, "steam", obj[0][j]);
            json_CT[j-1] = CTs;
        }
    }
    if(T > 0){
        PPrintToChatAll("T has the following player:");
        for(int k = 1; k <= T; k++){
            PPrintToChatAll(obj[1][k]);
            JSON Ts;
            Ts = json_create();
            json_set_string( Ts, "steam", obj[1][k]);
            json_T[k-1] = Ts;
        }
    }
    json = json_create();
    json_set_array( json, "ct", json_CT, CT, _, JSON_Object);
    json_set_array( json, "t", json_T, T, _, JSON_Object);
    char json_output[4096];
    json_encode( json, json_output, sizeof(json_output));
    //Error(json_output);

    char httpRequestContent[4096];
    Format(httpRequestContent, sizeof(httpRequestContent), "%s", json_output);
    System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, "127.0.0.1:1924");
    httpRequest.Timeout = 30;
    httpRequest.SetData(httpRequestContent);
    httpRequest.POST();
    delete httpRequest;
}


public void Error(char[] err){
    char message[1024];
    Format(message, sizeof(message), "{RED}%s {NORMAL}%s", "Error:", err);
    PPrintToChatAll(message);
}

/*
public Action Discord(int client, int args){
    int CT = 0;
    int T = 0;
    JSON json;
    new JSON:json_CT[5];
    new JSON:json_T[5];
    for(int clients = 0; clients <= MaxClients; clients++){
        if(isValidClient(clients)){
            //char SteamID[256];
            if(!GetClientAuthId(clients, AuthId_Steam2, g_SteamIDs[clients], 512, false)){
                Error("Failed to get steamid");
                return Plugin_Handled;
            }
            if(GetClientTeam(clients) == CS_TEAM_CT){
                CT++;
                obj[0][CT] = g_SteamIDs[clients];
            }else if(GetClientTeam(clients) == CS_TEAM_T){
                T++;
                obj[1][T] = g_SteamIDs[clients];
            }
        }
    }
    if(CT > 0){
        PPrintToChatAll("CT has the following player:");
        for(int j = 1; j <= CT; j++){
            PPrintToChatAll(obj[0][j]);
            JSON CTs;
            CTs = json_create();
            json_set_string( CTs, "steam", obj[0][j]);
            json_CT[j-1] = CTs;
        }
    }
    if(T > 0){
        PPrintToChatAll("T has the following player:");
        for(int k = 1; k <= T; k++){
            PPrintToChatAll(obj[1][k]);
            JSON Ts;
            Ts = json_create();
            json_set_string( Ts, "steam", obj[1][k]);
            json_T[k-1] = Ts;
        }
    }
    json = json_create();
    json_set_array( json, "ct", json_CT, CT, _, JSON_Object);
    json_set_array( json, "t", json_T, T, _, JSON_Object);
    char json_output[4096];
    json_encode( json, json_output, sizeof(json_output));
    //Error(json_output);

    char httpRequestContent[4096];
    Format(httpRequestContent, sizeof(httpRequestContent), "%s", json_output);
    System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, "127.0.0.1:1924");
    httpRequest.Timeout = 30;
    httpRequest.SetData(httpRequestContent);
    httpRequest.POST();
    delete httpRequest;

    return Plugin_Handled;
}
*/

void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    char url[256];
    request.GetURL(url, sizeof(url));

    if (!success) {
        PrintToServer("ERROR: Couldn't retrieve URL %s. Error: %s", url, error);
        PrintToServer("");
        PrintToServer("INFO: Finished");
        PrintToServer("");

        return;
    }
}

void PPrintToChat(int client, char[] cmessage){
    char smessage[1024];
    Format(smessage, sizeof(smessage), "%s {NORMAL}%s", tags, cmessage);
    CPrintToChat( client, smessage);
}

void PPrintToChatAll(char[] cmessage){
    char smessage[1024];
    Format(smessage, sizeof(smessage), "%s {NORMAL}%s", tags, cmessage);
    CPrintToChatAll(smessage);
}

bool isValidClient( int client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}  