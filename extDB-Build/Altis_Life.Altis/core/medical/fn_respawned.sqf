#include <macro.h>
/*
	File: fn_respawned.sqf
	Author: Bryan "Tonic" Boardwine
	
	Description:
	Sets the player up if he/she used the respawn option.
*/
private["_handle"];
//Reset our weight and other stuff
life_use_atm = TRUE;
life_hunger = 100;
life_thirst = 100;
life_cash = 0; //Make sure we don't get our cash back.
life_respawned = false;
player playMove "amovpercmstpsnonwnondnon";

life_corpse setVariable["Revive",nil,TRUE];
life_corpse setVariable["name",nil,TRUE];
life_corpse setVariable["Reviving",nil,TRUE];
player setVariable["Revive",nil,TRUE];
player setVariable["name",nil,TRUE];
player setVariable["Reviving",nil,TRUE];

//Load gear for a 'new life'
if(!(playerSide in life_death_save_gear)) then {
	switch(playerSide) do
	{
		//cops keep their gear
		case west: {
			_handle = [] spawn life_fnc_copLoadout;
			life_carryWeight = 0;
		};
		case civilian: {
			_handle = [] spawn life_fnc_civLoadout;
			life_carryWeight = 0;
		};
		case independent: {
			_handle = [] spawn life_fnc_medicLoadout;
			life_carryWeight = 0;
		};
		waitUntil {scriptDone _handle};
	};
}
else {
	[] spawn life_fnc_loadGear;
};
//Cleanup of weapon containers near the body & hide it.
if(!isNull life_corpse) then {
	private["_containers"];
	life_corpse setVariable["Revive",TRUE,TRUE];
	//only if people keep their gear we get rid of the weapon so it doesn't get duplicated
	// otherwise the weapons stays on the ground for anybody to pick up, if the player respawns
	// then wait for the revive the weapon is still at the same spot.
	if(!(playerSide in life_death_save_gear)) then {
		_containers = nearestObjects[life_corpse,["WeaponHolderSimulated"],5];
		{deleteVehicle _x;} forEach _containers; //Delete the containers.
	};
	hideBody life_corpse;
};

//Destroy our camera...
life_deathCamera cameraEffect ["TERMINATE","BACK"];
camDestroy life_deathCamera;

//Bad boy
if(life_is_arrested) exitWith {
	hint localize "STR_Jail_Suicide";
	life_is_arrested = false;
	[player,TRUE] spawn life_fnc_jail;
	[] call SOCK_fnc_updateRequest;
};

//Johnny law got me but didn't let the EMS revive me, reward them half the bounty.
if(!isNil "life_copRecieve") then {
	[[player,life_copRecieve,true],"life_fnc_wantedBounty",false,false] spawn life_fnc_MP;
	life_copRecieve = nil;
};

//So I guess a fellow gang member, cop or myself killed myself so get me off that Altis Most Wanted
if(life_removeWanted) then {
	[[getPlayerUID player],"life_fnc_wantedRemove",false,false] spawn life_fnc_MP;
};

[] call SOCK_fnc_updateRequest;
[] call life_fnc_hudUpdate; //Request update of hud.