//
// Farooq's Revive 1.5
//

//------------------------------------------//
// Parameters - Feel free to edit these
//------------------------------------------//

// Seconds until unconscious unit bleeds out and dies. Set to 0 to disable.
FAR_BleedOut = 300;

// Enable teamkill notifications
FAR_EnableDeathMessages = true;

// If enabled, unconscious units will not be able to use ACRE radio, hear other people or use proximity chat
FAR_MuteACRE = false;

/*
	0 = Only medics can revive
	1 = All units can revive
	2 = Same as 1 but a medikit is required to revive
*/
//FAR_ReviveMode = ( GRLIB_revive - 1 );
FAR_ReviveMode = 1;

//------------------------------------------//

call compile preprocessFile "FAR_revive\FAR_revive_funcs.sqf";
FAR_handleAction = compileFinal preprocessFileLineNumbers "FAR_revive\FAR_handleAction.sqf";

#define SCRIPT_VERSION "1.5"

FAR_isDragging = false;
FAR_isDragging_EH = [];
FAR_deathMessage = [];
FAR_Debugging = true;

////////////////////////////////////////////////
// Player Initialization
////////////////////////////////////////////////
[] spawn
{
    waitUntil { !isNull player };

	// Public event handlers
	"FAR_isDragging_EH" addPublicVariableEventHandler FAR_public_EH;
	"FAR_deathMessage" addPublicVariableEventHandler FAR_public_EH;

	[player] spawn FAR_Player_Init;
	FAR_PlayerSide = side player;

	if (FAR_MuteACRE) then
	{
		[] spawn FAR_Mute_ACRE;
	};
	// Event Handlers
	player addEventHandler
	[
		"Respawn",
		{
			[_this select 0] spawn FAR_Player_Init;
		}
	];
};

FAR_Player_Init =
{
	params ["_unit"];
	// Cache player's side
	//FAR_PlayerSide = side player;

	// Clear event handler before adding it
	_unit removeAllEventHandlers "HandleDamage";

	_unit addEventHandler ["HandleDamage", FAR_HandleDamage_EH];
	if (isPlayer _unit) then {
		_unit addEventHandler
		[
			"Killed",
			{
				// Remove dead body of player (for missions with respawn enabled)
				_body = _this select 0;

				[_body] spawn
				{

					waitUntil { alive player };
					_body = _this select 0;
					deleteVehicle _body;
				}
			}
		];
	};
	

	_unit setVariable ["GREUH_isUnconscious", 0, true];
	_unit setVariable ["FAR_isUnconscious", 0, true];
	_unit setVariable ["FAR_isStabilized", 0, true];
	_unit setVariable ["FAR_isDragged", 0, true];
	_unit setVariable ["ace_sys_wounds_uncon", false];
	_unit setCaptive false;

	FAR_isDragging = false;
	if (isPlayer _unit) then {
		[_unit] spawn FAR_Player_Actions;
	} else {
		[_unit, ["Local", {(_this select 0) spawn FAR_Player_Init; (_this select 0) removeEventHandler ["Local", _thisEventHandler];}]] remoteExec ["addEventHandler", 0, true];
	};
};

// Drag & Carry animation fix
[] spawn
{
	while {true} do
	{
		if (animationState player == "acinpknlmstpsraswrfldnon_acinpercmrunsraswrfldnon" || animationState player == "helper_switchtocarryrfl" || animationState player == "AcinPknlMstpSrasWrflDnon") then
		{
			if (FAR_isDragging) then
			{
				player switchMove "AcinPknlMstpSrasWrflDnon";
			}
			else
			{
				player switchMove "amovpknlmstpsraswrfldnon";
			};
		};

		sleep 3;
	}
};

FAR_Mute_ACRE =
{
	waitUntil { time > 0 };

	waitUntil
	{
		if (alive player) then
		{
			// player getVariable ["ace_sys_wounds_uncon", true/false];
			if ((player getVariable["ace_sys_wounds_uncon", false])) then
			{
				private["_saveVolume"];

				_saveVolume = acre_sys_core_globalVolume;

				player setVariable ["acre_sys_core_isDisabled", true, true];

				waitUntil
				{
					acre_sys_core_globalVolume = 0;

					if (!(player getVariable["acre_sys_core_isDisabled", false])) then
					{
						player setVariable ["acre_sys_core_isDisabled", true, true];
						[true] call acre_api_fnc_setSpectator;
					};

					!(player getVariable["ace_sys_wounds_uncon", false]);
				};

				if ((player getVariable["acre_sys_core_isDisabled", false])) then
				{
					player setVariable ["acre_sys_core_isDisabled", false, true];
					[false] call acre_api_fnc_setSpectator;
				};

				acre_sys_core_globalVolume = _saveVolume;
			};
		}
		else
		{
			waitUntil { alive player };
		};

		sleep 0.25;

		false
	};
};

////////////////////////////////////////////////
// [Debugging] Add revive to playable AI units
////////////////////////////////////////////////
if (!FAR_Debugging || isMultiplayer) exitWith {};

{
	if (!isPlayer _x) then
	{
		_x addEventHandler ["HandleDamage", FAR_HandleDamage_EH];
		_x setVariable ["FAR_isUnconscious", 0, true];
		_x setVariable ["FAR_isStabilized", 0, true];
		_x setVariable ["FAR_isDragged", 0, true];
	};
} forEach switchableUnits;