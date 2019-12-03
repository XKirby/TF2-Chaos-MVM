#pragma semicolon 1

// Includes
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sm_chaosmvm>

// Defines
#define ABIL_VERSION "1.0"
#define CABER_TIMER_RESUPPLY 300

// Plugin Info
public Plugin:myinfo =
{
	name = "[Chaos MVM Ability](Demoman) Caber Charges",
	author = "X Kirby",
	description = "Demo Caber now has ammo!",
	version = ABIL_VERSION,
	url = "n/a",
}

// Variables
new Float:fl_AbilLevel[MAXPLAYERS+1] = 0.0;
new i_CaberAmmo[MAXPLAYERS+1] = 0;
new i_RestockFrames[MAXPLAYERS+1] = 0;

// On Plugin Start
public OnPluginStart()
{
	// Hook Event for Inventory Reset
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);

	// Ability and Ammo Set
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsValidEntity(i)){continue;}
		fl_AbilLevel[i] = 0.0;
		i_CaberAmmo[i] = 0;
	}
}

// On Map Start
public OnMapStart()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsValidEntity(i)){continue;}
		fl_AbilLevel[i] = 0.0;
		i_CaberAmmo[i] = 0;
	}
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	fl_AbilLevel[client] = 0.0;
	i_CaberAmmo[client] = 0;
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		fl_AbilLevel[client] = 0.0;
		i_CaberAmmo[client] = 0;
	}
}

// Set Attribute Value
public SetAttribValue(client, Handle:plugin, String:effname[128], value)
{
	new String:e[128];
	GetPluginFilename(INVALID_HANDLE, e, sizeof(e));
	ReplaceString(e, sizeof(e), "disabled\\", "");
	ReplaceString(e, sizeof(e), ".smx", "");
	if(StrEqual(effname, e))
	{
		fl_AbilLevel[client] = Float:value;
	}
}

// Get Attribute Value
public any:GetAttribValue(client, Handle:plugin, String:effname[128])
{
	new String:e[128];
	GetPluginFilename(INVALID_HANDLE, e, sizeof(e));
	ReplaceString(e, sizeof(e), "disabled\\", "");
	ReplaceString(e, sizeof(e), ".smx", "");
	if(StrEqual(effname, e))
	{
		return any:fl_AbilLevel[client];
	}
	return any:CMVM_GetAttribValue(client, plugin, effname);
}

// Fully Resupply Caber
public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidEntity(client))
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			i_RestockFrames[client] = 0;
			i_CaberAmmo[client] = RoundToFloor(fl_AbilLevel[client]);
			CheckCaber(client);
		}
	}
}

// Every Frame
public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsValidEntity(i))
			{continue;}
		if(fl_AbilLevel[i] > 0)
		{
			i_RestockFrames[i]++;
			if(i_RestockFrames[i] >= CABER_TIMER_RESUPPLY)
			{
				i_RestockFrames[i] = 0;
				if(i_CaberAmmo[i] < RoundToFloor(fl_AbilLevel[i]))
				{
					i_CaberAmmo[i]++;
				}
			}
		}
		if(i > MaxClients || !IsClientInGame(i) || (IsClientInGame(i) && !IsPlayerAlive(i)))
		{
			i_RestockFrames[i] = 0;
		}
		CheckCaber(i);
	}
}

// Check Caber and Reset it if necessary
public CheckCaber(client)
{		
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || i_CaberAmmo[client] < 1)
		return;
	
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	if (i_CaberAmmo[client] > 0 && GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 307 && GetEntProp(iWeapon, Prop_Send, "m_iDetonated") == 1)
	{
		SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
		i_CaberAmmo[client]--;
	}
	return;
}