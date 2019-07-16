
[] execVM "ctmenu\irstrobelite.sqf";

Test_Menu_Add = {
	_keyInputEH = findDisplay 46 displayaddEventHandler ["KeyDown", {
		params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
		if(_key==0xDB) then {
			if(isNull(findDisplay 100))then{
				if(!visibleMap)then{setMousePosition [0.5,0.5]};
				createDialog "Ctme";
			};
		}
	}
	];
};

Test_Menu_RClose = {_keyInputEH = findDisplay 46 displayaddEventHandler ["KeyUp",{
		params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
		if(_key==0xDB) then {closeDialog 100;};	
	}]
};

Test_Earplug = {
	if(soundVolume!=( desired_vehvolume / 100.0 ))then{1 fadeSound ( desired_vehvolume / 100.0 );systemChat "귀마개를 착용하였습니다!";}else{1 fadeSound 1;systemChat "귀마개를 해제하였습니다!";};
};

Test_PlayAnim = {
	params ["_animeMain"];
	AnimdoLoop = false;
	_delay = 1/(getNumber (configfile >> "CfgMovesMaleSdr" >> "States" >> _animeMain >> "speed"));
	if(vehicle player == player)then {
		player action ["SwitchWeapon", player, player, -1];	
		uiSleep 1;	
		_animEH = (findDisplay 46) displayaddEventHandler [ "KeyDown", {
			AnimdoLoop = true;
		}];
		waitUntil{
			[player, _animeMain] remoteExec ["switchMove", 0];
			uisleep _delay;
			AnimdoLoop
		};		
		(findDisplay 46) displayremoveEventHandler ["KeyDown", _animEH];
		[player, ""] remoteExec ["switchMove", 0];
	};
};

waitUntil{!isNull findDisplay 46};

uiSleep 3;

call Test_Menu_Add;
call Test_Menu_RClose;

systemChat "윈도우키 메뉴 스크립트 활성화!";
