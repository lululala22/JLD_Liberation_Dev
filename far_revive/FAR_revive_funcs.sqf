﻿GRLIB_replace_ai = false;

////////////////////////////////////////////////
// Player Actions
////////////////////////////////////////////////
FAR_Player_Actions =
{
	params ["_unit"];
	if (alive _unit && _unit isKindOf "Man") then
	{
		// addAction args: title, filename, (arguments, priority, showWindow, hideOnUse, shortcut, condition, positionInModel, radius, radiusView, showIn3D, available, textDefault, textToolTip)
		_unit addAction ["<t color=""#C90000"">" + "되살리기" + "</t>", "[_this select 3 select 0, cursorTarget, _this select 1] spawn FAR_handleAction", ["action_revive"], 10, true, true, "", "([cursorTarget] call FAR_Check_Revive)",2];
		_unit addAction ["<t color=""#C90000"">" + "심신안정" + "</t>", "[_this select 3 select 0, cursorTarget, _this select 1] spawn FAR_handleAction", ["action_stabilize"], 10, true, true, "", "([cursorTarget] call FAR_Check_Stabilize)",2];
		_unit addAction ["<t color=""#C90000"">" + "재투입하기" + "</t>", "[_this select 3 select 0, player, player] spawn FAR_handleAction", ["action_suicide"], 9, false, true, "", "([cursorTarget] call FAR_Check_Suicide)",2];
		_unit addAction ["<t color=""#C90000"">" + "끌어가기" + "</t>", "[_this select 3 select 0, cursorTarget, _this select 1] spawn FAR_handleAction", ["action_drag"], 9, false, true, "", "([cursorTarget] call FAR_Check_Dragging)",2];
	};
};

////////////////////////////////////////////////
// Handle Death
////////////////////////////////////////////////
FAR_HandleDamage_EH =
{

	params [ "_unit", "_selectionName", "_amountOfDamage", "_killer", "_projectile", "_hitPartIndex" ];
	private [ "_isUnconscious", "_olddamage", "_damageincrease", "_vestarmor", "_vest_passthrough", "_vestobject", "_helmetarmor",  "_helmet_passthrough", "_helmetobject" ];

	_isUnconscious = _unit getVariable "FAR_isUnconscious";

	if (alive _unit && _amountOfDamage >= 1.0 && _isUnconscious == 0 && (_selectionName in ["","head","face_hub","neck","spine1","spine2","spine3","pelvis","body"] )) then
	{
		_unit setDamage 0.75;
		_unit allowDamage false;
		_amountOfDamage = 0;
		[_unit, _killer] spawn FAR_Player_Unconscious;
	};

	_amountOfDamage
};

////////////////////////////////////////////////
// Make Player Unconscious
////////////////////////////////////////////////
FAR_Player_Unconscious =
{
	params [ "_unit", "_killer" ];

	// Death message
	if (FAR_EnableDeathMessages && !isNil "_killer" && isPlayer _killer && _killer != _unit) then
	{
		FAR_deathMessage = [_unit, _killer];
		publicVariable "FAR_deathMessage";
		["FAR_deathMessage", [_unit, _killer]] call FAR_public_EH;
	};

	if (isPlayer _unit) then
	{
		disableUserInput true;
		playSound "combat_deafness";
	};

	_unit setVariable ["GREUH_isUnconscious", 1, true];

	// Eject unit if inside vehicle
	if (vehicle _unit != _unit && alive vehicle _unit) then
	{
		unAssignVehicle _unit;
		_unit action ["eject", vehicle _unit];
		_unit action ["getout", vehicle _unit];
		if ( vehicle _unit != _unit && alive vehicle _unit ) then
		{
			sleep 0.5;
			unAssignVehicle _unit;
			_unit action ["eject", vehicle _unit];
			_unit action ["getout", vehicle _unit];
		};
		sleep 1.25;
	};

	if (vehicle _unit != _unit) then {
		_unit setVariable ["GREUH_isUnconscious", 0, true];
		_unit setDamage 1;
		if (isPlayer _unit) then
		{
			disableUserInput false;
			disableUserInput true;
			disableUserInput false;
		};
	} else {

		_random_medic_message = floor (random 3);
		_medic_message = localize "STR_FAR_Need_Medic1";
		switch (_random_medic_message) do {
			case 0 : { _medic_message = localize "STR_FAR_Need_Medic1"; };
			case 1 : { _medic_message = localize "STR_FAR_Need_Medic2"; };
			case 2 : { _medic_message = localize "STR_FAR_Need_Medic3"; };
		};
		public_medic_message = [_unit,_medic_message]; publicVariable "public_medic_message";

		_unit setDamage 0.7;
		_unit setVelocity [0,0,0];
		_unit allowDamage false;
		_unit setCaptive true;
		_unit playMove "AinjPpneMstpSnonWrflDnon_rolltoback";

		sleep 3;		
		
		_unit allowDamage true;

		[] spawn {
			sleep 30;
			player setCaptive false;
		};

		if (isPlayer _unit) then
		{
			disableUserInput false;
			disableUserInput true;
			disableUserInput false;

			// Mute ACRE
			_unit setVariable ["ace_sys_wounds_uncon", true];
		};

		_unit switchMove "AinjPpneMstpSnonWrflDnon";
		_unit enableSimulation false;
		_unit setVariable ["FAR_isUnconscious", 1, true];

		// Call this code only on players
		if (isPlayer _unit) then
		{
			_bleedOut = time + FAR_BleedOut;

			while { !isNull _unit && alive _unit && _unit getVariable "FAR_isUnconscious" == 1 && _unit getVariable "FAR_isStabilized" == 0 && (FAR_BleedOut <= 0 || time < _bleedOut) } do
			{
				hintSilent format[localize "STR_BLEEDOUT_MESSAGE" + "\n\n%2", round (_bleedOut - time), call FAR_CheckFriendlies];
				public_bleedout_message = format [localize "STR_BLEEDOUT_MESSAGE", round (_bleedOut - time)];
				public_bleedout_timer = round (_bleedOut - time);

				sleep 0.5;
			};

			if (_unit getVariable "FAR_isStabilized" == 1) then {
				//Unit has been stabilized. Disregard bleedout timer and umute player
				_unit setVariable ["ace_sys_wounds_uncon", false];

				while { !isNull _unit && alive _unit && _unit getVariable "FAR_isUnconscious" == 1 } do
				{
					hintSilent format["%1\n\n%2", localize "STR_BLEEDOUT_STABILIZED", call FAR_CheckFriendlies];
					public_bleedout_message = localize "STR_BLEEDOUT_STABILIZED";
					public_bleedout_timer = FAR_BleedOut;

					sleep 0.5;
				};
			};

			// Player bled out
			if ((FAR_BleedOut > 0 && {time > _bleedOut} && {_unit getVariable ["FAR_isStabilized",0] == 0}) || (vehicle _unit != _unit)) then
			{
				_unit setDamage 1;
			}
			else
			{
				// Player got revived
				_unit setVariable ["FAR_isStabilized", 0, true];
				if ( !GRLIB_replace_ai ) then {
					sleep 6;
				};

				// Clear the "medic nearby" hint
				hintSilent "";

				// Unmute ACRE
				if (isPlayer _unit) then
				{
					_unit setVariable ["ace_sys_wounds_uncon", false];
				};

				_unit enableSimulation true;
				_unit allowDamage true;
				_unit setCaptive false;

				if ( GRLIB_replace_ai ) then {
					if ( primaryWeapon player == "" ) then {
						_unit switchMove "";
					} else {
						_unit switchMove "AidlPknlMstpSrasWrflDnon_G02";
					};

					GRLIB_replace_ai = false;
				} else {
					_unit playMove "amovppnemstpsraswrfldnon";
					_unit playMove "";
				};
			};
		}
		else
		{
			// [Debugging] Bleedout for AI
			_bleedOut = time + FAR_BleedOut;

			while { !isNull _unit && alive _unit && _unit getVariable "FAR_isUnconscious" == 1 && _unit getVariable "FAR_isStabilized" == 0 && (FAR_BleedOut <= 0 || time < _bleedOut) } do
			{
				sleep 0.5;
			};

			if (_unit getVariable "FAR_isStabilized" == 1) then {
				while { !isNull _unit && alive _unit && _unit getVariable "FAR_isUnconscious" == 1 } do
				{
					sleep 0.5;
				};
			};

			// AI bled out
			if (FAR_BleedOut > 0 && {time > _bleedOut} && {_unit getVariable ["FAR_isStabilized",0] == 0}) then
			{
				_unit setDamage 1;
				_unit setVariable ["FAR_isUnconscious", 0, true];
				_unit setVariable ["FAR_isDragged", 0, true];
			}
		};
	};
};

////////////////////////////////////////////////
// Revive Player
////////////////////////////////////////////////
FAR_HandleRevive =
{
	params ["_target", "_healer"];

	if (alive _target) then
	{
		_healer playMove "AinvPknlMstpSlayWrflDnon_medic";

                //if (!("Medikit" in (items _healer)) ) then {
                //_healer removeItem "FirstAidKit"

        _target setVariable ["FAR_isUnconscious", 0, true];
		_target setVariable ["FAR_isDragged", 0, true];

		sleep 6;

		// [Debugging] Code below is only relevant if revive script is enabled for AI
		if (!isPlayer _target) then
		{
			_target enableSimulation true;
			_target allowDamage true;
			_target setDamage 0.65;
			_target setCaptive false;

			_target playMove "amovppnemstpsraswrfldnon";
		};

	};
};

////////////////////////////////////////////////
// Stabilize Player
////////////////////////////////////////////////
FAR_HandleStabilize =
{

	params ["_target", "_healer"];

	if (alive _target) then
	{
		_healer playMove "AinvPknlMstpSlayWrflDnon_medic";

		//if (!("Medikit" in (items _healer)) ) then {
		//	_healer removeItem "FirstAidKit";
		//};

		_target setVariable ["FAR_isStabilized", 1, true];
		//[name _target] remoteExec ["systemChat", _healer, false];
		//[str (_target getVariable "FAR_isStabilized")] remoteExec ["systemChat", 0, false];
		sleep 6;
	};
};

////////////////////////////////////////////////
// Drag Injured Player
////////////////////////////////////////////////
FAR_Drag =
{
	private ["_target", "_id"];

	FAR_isDragging = true;

	_target = _this select 0;
	_caller = _this select 1;

	_target attachTo [player, [0, 1.1, 0.092]];
	_target setDir 180;
	_target setVariable ["FAR_isDragged", 1, true];

	_caller playMoveNow "AcinPknlMstpSrasWrflDnon";

	// Rotation fix
	FAR_isDragging_EH = _target;
	publicVariable "FAR_isDragging_EH";

	// Add release action and save its id so it can be removed
	_id = _caller addAction ["<t color=""#C90000"">" + "내려놓기" + "</t>", "[_this select 3 select 0, cursorTarget, _this select 1] spawn FAR_handleACtion", ["action_release"], 10, true, true, "", "true"];

	hint "움직이지 않는 경우에는 'C'를 누르세요.";

	// Wait until release action is used
	waitUntil
	{
		!alive _caller || _caller getVariable "FAR_isUnconscious" == 1 || !alive _target || _target getVariable "FAR_isUnconscious" == 0 || !FAR_isDragging || _target getVariable "FAR_isDragged" == 0
	};

	// Handle release action
	FAR_isDragging = false;

	if (!isNull _target && alive _target) then
	{
		_target switchMove "AinjPpneMstpSnonWrflDnon";
		_target setVariable ["FAR_isDragged", 0, true];
		detach _target;
	};

	_caller removeAction _id;
};

FAR_Release =
{
	params ["_caller"];
	// Switch back to default animation
	_caller playMove "amovpknlmstpsraswrfldnon";

	FAR_isDragging = false;
};

////////////////////////////////////////////////
// Event handler for public variables
////////////////////////////////////////////////
FAR_public_EH =
{
	if(count _this < 2) exitWith {};

	_EH  = _this select 0;
	_target = _this select 1;

	// FAR_isDragging
	if (_EH == "FAR_isDragging_EH") then
	{
		_target setDir 180;
	};

	// FAR_deathMessage
	if (_EH == "FAR_deathMessage") then
	{
		_killed = _target select 0;
		_killer = _target select 1;

		if (isPlayer _killed) then
		{
			systemChat format["%1 님이 %2 에 의해 사망하였습니다.", name _killed, name _killer];
			if(_killer == player)then{"FRIENDLY FIRE!!" hintC ["아군을 공격하였습니다. 다른 유저를 공격한 경우 즉시 사과하시기 바랍니다.","아군 오사에 대해 사과하지 않고 도주하는 경우에는 처벌될 수 있습니다.","TIP:액션메뉴 가장 아래의 추가설정에서 아군 표식을 설정할 수 있습니다.","이 창은 ESC를 눌러 닫습니다."]};
		};
	};
};

////////////////////////////////////////////////
// Revive Action Check
////////////////////////////////////////////////
FAR_Check_Revive =
{
	private ["_target", "_isTargetUnconscious", "_isDragged"];

	_return = false;

	// Unit that will excute the action
	_isPlayerUnconscious = player getVariable "FAR_isUnconscious";
	_isMedic = getNumber (configfile >> "CfgVehicles" >> typeOf player >> "attendant");
	_target = _this select 0;

	// Make sure player is alive and target is an injured unit
	if( !alive player || _isPlayerUnconscious == 1 || FAR_isDragging || isNil "_target" || !alive _target || (!isPlayer _target && !FAR_Debugging) || (_target distance player) > 2 ) exitWith
	{
		_return
	};

	_isTargetUnconscious = _target getVariable "FAR_isUnconscious";
	_isDragged = _target getVariable "FAR_isDragged";

	// Make sure target is unconscious and player is a medic (SAKY)
	// if (_isTargetUnconscious == 1 && _isDragged == 0 && (_isMedic == 1 || FAR_ReviveMode > 0) && ( ("FirstAidKit" in (items player)) || ("Medikit" in (items player)) ) ) then
	// {
	// 	_return = true;

	// 	// [ReviveMode] Check if player has a Medikit
	// 	if ( FAR_ReviveMode == 2 && !("Medikit" in (items player)) ) then
	// 	{
	// 		_return = false;
	// 	};
	// };	
	if (_isTargetUnconscious == 1 && _isDragged == 0 && (_isMedic == 1 || FAR_ReviveMode > 0) ) then
	{
		_return = true;

		// [ReviveMode] Check if player has a Medikit
		if ( FAR_ReviveMode == 2 && !("Medikit" in (items player)) ) then
		{
			_return = false;
		};
	};

	_return
};

////////////////////////////////////////////////
// Stabilize Action Check
////////////////////////////////////////////////
FAR_Check_Stabilize =
{
	private ["_target", "_isTargetUnconscious", "_isDragged"];

	_return = false;

	// Unit that will excute the action
	_isPlayerUnconscious = player getVariable "FAR_isUnconscious";
	_target = _this select 0;


	// Make sure player is alive and target is an injured unit
	if( !alive player || _isPlayerUnconscious == 1 || FAR_isDragging || isNil "_target" || !alive _target || (!isPlayer _target && !FAR_Debugging) || (_target distance player) > 2 ) exitWith
	{
		_return
	};

	_isTargetUnconscious = _target getVariable "FAR_isUnconscious";
	_isTargetStabilized = _target getVariable "FAR_isStabilized";
	_isDragged = _target getVariable "FAR_isDragged";

	// Make sure target is unconscious and hasn't been stabilized yet, and player has a FAK/Medikit
	if (_isTargetUnconscious == 1 && _isTargetStabilized == 0 && _isDragged == 0 && ( ("FirstAidKit" in (items player)) || ("Medikit" in (items player)) ) ) then
	{
		_return = true;
	};

	_return
};

////////////////////////////////////////////////
// Suicide Action Check
////////////////////////////////////////////////
FAR_Check_Suicide =
{
	_return = false;
	_isPlayerUnconscious = player getVariable ["FAR_isUnconscious",0];

	if (alive player && _isPlayerUnconscious == 1) then
	{
		_return = true;
	};

	_return
};

////////////////////////////////////////////////
// Dragging Action Check
////////////////////////////////////////////////
FAR_Check_Dragging =
{
	private ["_target", "_isPlayerUnconscious", "_isDragged"];

	_return = false;
	_target = _this select 0;
	_isPlayerUnconscious = player getVariable "FAR_isUnconscious";

	if( !alive player || _isPlayerUnconscious == 1 || FAR_isDragging || isNil "_target" || !alive _target || (!isPlayer _target && !FAR_Debugging) || (_target distance player) > 2 ) exitWith
	{
		_return;
	};

	// Target of the action
	_isTargetUnconscious = _target getVariable "FAR_isUnconscious";
	_isDragged = _target getVariable "FAR_isDragged";

	if(_isTargetUnconscious == 1 && _isDragged == 0) then
	{
		_return = true;
	};

	_return
};

////////////////////////////////////////////////
// Show Nearby Friendly Medics
////////////////////////////////////////////////
FAR_IsFriendlyMedic =
{
	private ["_unit"];

	_return = false;
	_unit = _this;
	_isMedic = getNumber (configfile >> "CfgVehicles" >> typeOf _unit >> "attendant");

	if ( alive _unit && (isPlayer _unit || FAR_Debugging) && side _unit == FAR_PlayerSide && _unit getVariable "FAR_isUnconscious" == 0 && (_isMedic == 1 || FAR_ReviveMode > 0) ) then
	{
		_return = true;
	};

	_return
};

FAR_CheckFriendlies =
{
	private ["_unit", "_units", "_medics", "_hintMsg"];

	_units = (getpos player) nearEntities [ ["Man", "Car", "Air", "Ship"], 800];
	_medics = [];
	_dist = 800;
	_hintMsg = "";

	// Find nearby friendly medics
	if (count _units > 1) then
	{
		{
			if (_x isKindOf "Car" || _x isKindOf "Air" || _x isKindOf "Ship") then
			{
				if (alive _x && count (crew _x) > 0) then
				{
					{
						if (_x call FAR_IsFriendlyMedic) then
						{
							_medics = _medics + [_x];

							if (true) exitWith {};
						};
					} forEach crew _x;
				};
			}
			else
			{
				if (_x call FAR_IsFriendlyMedic) then
				{
					_medics = _medics + [_x];
				};
			};

		} forEach _units;
	};

	// Sort medics by distance
	if (count _medics > 0) then
	{
		{
			if (player distance _x < _dist) then
			{
				_unit = _x;
				_dist = player distance _x;
			};

		} forEach _medics;

		if (!isNull _unit) then
		{
			_unitName	= name _unit;
			_distance	= floor (player distance _unit);

			_hintMsg = format["Nearby Medic:\n%1 is %2m away.", _unitName, _distance];
		};
	}
	else
	{
		_hintMsg = "No medic nearby.";
	};

	_hintMsg
};



