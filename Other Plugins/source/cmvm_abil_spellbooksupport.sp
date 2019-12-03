#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sm_chaosmvm>

// Defines
#define ABIL_VERSION "1.0"
new SpellCosts[12] = {10,20,40,30,20,50,60,100,80,120,120,100};
new Handle:spell_HUD;

// Plugin Info
public Plugin:myinfo =
{
	name = "[Chaos MVM Ability]Spell Book Support",
	author = "X Kirby",
	description = "Allows the Spellbooks to work! They use Magic Points instead of Ammo.",
	version = ABIL_VERSION,
	url = "n/a",
}

// Variables
new Float:fl_AbilLevel[MAXPLAYERS+1] = 0.0;
new Float:fl_MPRegen[MAXPLAYERS+1] = 0.0;
new Float:fl_MP[MAXPLAYERS+1] = 0.0;
new HudFrames = 0;

// On Plugin Start
public OnPluginStart()
{
	// Hook Event for Inventory Reset
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);

	// Spell Changing Commands
	RegConsoleCmd("spellnext", Command_SpellSelectNext, "Swaps your spellbook's current spell.");
	RegConsoleCmd("spellprevious", Command_SpellSelectPrevious, "Swaps your spellbook's current spell.");

	// HUD Sync
	spell_HUD = CreateHudSynchronizer();

	// Explosion Effect Precache
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(!IsValidEntity(i)){continue;}
		fl_AbilLevel[i] = 0.0;
		fl_MPRegen[i] = 0.0;
		fl_MP[i] = 0.0;
	}
}

// On Map Start
public OnMapStart()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(!IsValidEntity(i)){continue;}
		fl_AbilLevel[i] = 0.0;
		fl_MPRegen[i] = 0.0;
		fl_MP[i] = 0.0;
	}
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	fl_AbilLevel[client] = 0.0;
	fl_MPRegen[client] = 0.0;
	fl_MP[client] = 0.0;
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		fl_AbilLevel[client] = 0.0;
		fl_MPRegen[client] = 0.0;
		fl_MP[client] = 0.0;
	}
}

public Action:Command_SpellSelectNext(client, args)
{
	// Look for SpellBooks
	new Wear = -1;
	while((Wear = FindEntityByClassname(Wear, "tf_weapon_spellbook")) != -1)
	{
		// If not valid, skip.
		if(!IsValidEntity(Wear)){continue;}
		
		// If you're the owner of this wearable.
		if(client == GetEntPropEnt(Wear, Prop_Send, "m_hOwnerEntity"))
		{
			new Spell = GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex") + 1;
			if(Spell >= 12)
			{
				Spell = 0;
			}
			fl_MP[client] += (GetEntProp(Wear, Prop_Send, "m_iSpellCharges") * SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")]);
			SetEntProp(Wear, Prop_Send, "m_iSpellCharges", 0);
			SetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex", Spell);
			CheckSpell(client);
			break;
		}
	}
	return Plugin_Handled;
}

public Action:Command_SpellSelectPrevious(client, args)
{
	// Look for SpellBooks
	new Wear = -1;
	while((Wear = FindEntityByClassname(Wear, "tf_weapon_spellbook")) != -1)
	{
		// If not valid, skip.
		if(!IsValidEntity(Wear)){continue;}
		
		// If you're the owner of this wearable.
		if(client == GetEntPropEnt(Wear, Prop_Send, "m_hOwnerEntity"))
		{
			new Spell = GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex") - 1;
			if(Spell < 0)
			{
				Spell = 11;
			}
			fl_MP[client] += (GetEntProp(Wear, Prop_Send, "m_iSpellCharges") * SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")]);
			SetEntProp(Wear, Prop_Send, "m_iSpellCharges", 0);
			SetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex", Spell);
			CheckSpell(client);
			break;
		}
	}
	return Plugin_Handled;
}

// Set Attribute Value
public SetAttribValue(client, Handle:plugin, String:effname[128], value)
{
	if(StrEqual(effname, "cmvm_abil_spellbooksupport"))
	{
		fl_AbilLevel[client] = Float:value;
	}
	if(StrEqual(effname, "cmvm_abil_spellbooksupport_regen"))
	{
		fl_MPRegen[client] = Float:value;
	}
}

// Get Attribute Value
public any:GetAttribValue(client, Handle:plugin, String:effname[128])
{
	if(StrEqual(effname, "cmvm_abil_spellbooksupport"))
	{
		return any:fl_AbilLevel[client];
	}
	if(StrEqual(effname, "cmvm_abil_spellbooksupport_regen"))
	{
		return any:fl_MPRegen[client];
	}
	return any:CMVM_GetAttribValue(client, plugin, effname);
}

// Fully Resupply MP
public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidEntity(client))
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			fl_MP[client] = fl_AbilLevel[client];
			CheckSpell(client);
		}
	}
}

// On Game Frame
public OnGameFrame()
{
	HudFrames++;
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsValidEntity(i))
			{continue;}
		CheckSpell(i);
		if(HudFrames >= 5)
		{
			DrawHUD(i);
		}
	}
	if(HudFrames >= 5)
	{
		HudFrames = 0;
	}
}

// Check Spell
public CheckSpell(client)
{
	// Look for SpellBooks
	new Wear = -1;
	while((Wear = FindEntityByClassname(Wear, "tf_weapon_spellbook")) != -1)
	{
		// If not valid, skip.
		if(!IsValidEntity(Wear))
			{continue;}
		
		// If you're the owner of this wearable.
		if(client == GetEntPropEnt(Wear, Prop_Send, "m_hOwnerEntity"))
		{
			// Fix Bad Spell ID
			if(GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex") < 0 || GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex") > 11)
			{
				SetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex", 0);
			}
		
			// Regenerate MP
			if(fl_AbilLevel[client] > 0)
			{
				fl_MP[client] += fl_MPRegen[client] / 60.0;
			}
			
			// Cap MP Regen
			if(fl_MP[client] >= fl_AbilLevel[client] - (GetEntProp(Wear, Prop_Send, "m_iSpellCharges") * SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")]))
			{
				fl_MP[client] = fl_AbilLevel[client] - (GetEntProp(Wear, Prop_Send, "m_iSpellCharges") * SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")]);
			}
			
			// Add Spell Counts
			if(fl_MP[client] >= SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")])
			{
				fl_MP[client] -= SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")];
				SetEntProp(Wear, Prop_Send, "m_iSpellCharges", GetEntProp(Wear, Prop_Send, "m_iSpellCharges") + 1);
				break;
			}
		}
	}
}

// Function: Draw Hud
public DrawHUD(client)
{	
	// Find the Canteen or Spellbook you're wearing.
	new Wear = -1, String:PowerName[64] = "None", PowerCount = 0;
	
	// Look for SpellBooks
	while((Wear = FindEntityByClassname(Wear, "tf_weapon_spellbook")) != -1)
	{
		// If not valid, skip.
		if(!IsValidEntity(Wear)){continue;}
		
		// If you're the owner of this wearable.
		if(client == GetEntPropEnt(Wear, Prop_Send, "m_hOwnerEntity"))
		{
			// Fix Bad Spell ID
			if(GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex") < 0 || GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex") > 11)
			{
				SetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex", 0);
			}
			
			// Grab the Power Count and Spell Name
			PowerCount = (GetEntProp(Wear, Prop_Send, "m_iSpellCharges") * SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")]);
			
			// Spell Names
			switch(GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex"))
			{
				case 0:{PowerName = "Fireball";}
				case 1:{PowerName = "Ball O' Bats";}
				case 2:{PowerName = "Healing Aura";}
				case 3:{PowerName = "Pumpkin MIRV";}
				case 4:{PowerName = "Superjump";}
				case 5:{PowerName = "Invisibility";}
				case 6:{PowerName = "Teleport";}
				case 7:{PowerName = "Tesla Bolt";}
				case 8:{PowerName = "Minify";}
				case 9:{PowerName = "Meteor Shower";}
				case 10:{PowerName = "Summon Monoculus";}
				case 11:{PowerName = "Summon Skeletons";}
			}
			
			SetHudTextParams(0.05, 0.8, 3.0, 255, 255, 0, 200);
			ClearSyncHud(client, spell_HUD);
			ShowSyncHudText(client, spell_HUD, "%s (%i)- %i/%i", PowerName, SpellCosts[GetEntProp(Wear, Prop_Send, "m_iSelectedSpellIndex")], RoundToFloor(fl_MP[client] + PowerCount), RoundToFloor(fl_AbilLevel[client]));
			break;
		}
	}
}