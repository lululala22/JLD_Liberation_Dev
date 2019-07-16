SeatSwitching = false;

groupTags = ["[보병]", "[차량화1]", "[기계화1]", "[특수]", "[기갑]", "[포병1]", "[해상1]", "[전투]", "[기동]"];

groupType = {
	params ["_player"];
	_type = -1; 
	{
		if(typeName _player == "GROUP")then{
			if(groupId _player find _x != -1)then{_type = _forEachIndex};
		} else {
			if(groupId group _player find _x != -1)then{_type = _forEachIndex};
		};
	}foreach groupTags;
	_type
};

groundSquads = {
	_groundSquads = 0;
	{
		if(!(_x call groupType in [-1,7,8]))then{_groundSquads=_groundSquads+1};
	}foreach allGroups;
	_groundSquads
};

allowedVehicles = [
[], //0보병
[], //1차량화 - 사라짐
[], //2기계화
[], //3특수
[], //4기갑
["MBT_01_mlrs_base_F", "MBT_01_arty_base_F", "Truck_02_MRL_base_F", "MBT_02_arty_base_F"], //5포병 - 사라짐
[], //6해상 X
[], //7전투 
[]//8기동
];

isAllowedGetIn = {
	params ["_groupType", "_vehicle"];
	_isAllowedGetIn = false;

	if ((leader group player == player) && (count units player > 2)) then {	_isAllowedGetIn = true;
	} else {
		switch (_groupType)
		do {
		case 0: {
				if (_vehicle isKindOf "StaticWeapon" || _vehicle isKindOf "Car" && !(_vehicle isKindOf "Wheeled_APC_F") || _vehicle isKindOf "Ship")
				then {
					_isAllowedGetIn = true;
				};
			}; //0보병
		case 1: {
				if (_vehicle isKindOf "StaticWeapon" || _vehicle isKindOf "Car" && !(_vehicle isKindOf "Wheeled_APC_F"))
				then {
					_isAllowedGetIn = false;
				};
			}; //1차량화 사라짐
		case 2: {
				if (_vehicle isKindOf "StaticWeapon" || _vehicle isKindOf "Wheeled_APC_F")
				then {
					_isAllowedGetIn = true;
				};
			}; //2기계화 사라짐
		case 3: {
				if (_vehicle isKindOf "StaticWeapon")
				then {
					_isAllowedGetIn = true;
				};
			}; //3특수
		case 4: {
				if (_vehicle isKindOf "Tank" || _vehicle isKindOf "Truck_02_MRL_base_F" || _vehicle isKindOf "Wheeled_APC_F")
				then {
					_isAllowedGetIn = true;
				};
			}; //4기갑
		case 5: {
				if (_vehicle isKindOf "StaticWeapon" || _vehicle isKindOf "Truck_F" || _vehicle isKindOf "MBT_01_mlrs_base_F" || _vehicle isKindOf "MBT_01_arty_base_F" || _vehicle isKindOf "Truck_02_MRL_base_F" || _vehicle isKindOf "MBT_02_arty_base_F")
				then {
					_isAllowedGetIn = false;
				};
			}; //5포병 사라짐
		case 6: {
				if (_vehicle isKindOf "Ship")
				then {
					_isAllowedGetIn = true;
				};
			}; //6해상 사라짐
		case 7: {
				if (_vehicle isKindOf "Air" || _vehicle isKindOf "Truck_F" || ( typeOf _vehicle == "B_APC_Tracked_01_CRV_F"))
				then {
					if(typeOf player == "B_Pilot_F")then{_isAllowedGetIn = true}else{systemChat "항공장비를 조작하기 위해서는 조종사 슬롯으로 접속해야 합니다."};
				};
			}; //7전투
		case 8: {
				if (_vehicle isKindOf "Air" || _vehicle isKindOf "Truck_F" || ( typeOf _vehicle == "B_APC_Tracked_01_CRV_F"))
				then {
					if(typeOf player == "B_Pilot_F")then{_isAllowedGetIn = true}else{systemChat "항공장비를 조작하기 위해서는 조종사 슬롯으로 접속해야 합니다."};
				};
			}; //8기동
			default {
				_isAllowedGetIn = false;
			};
		};
	};
	_isAllowedGetIn
};

player addEventHandler["GetInMan", {
	params["_unit", "_role", "_vehicle", "_turret"];
	if(!SeatSwitching)then{
		if (!(_vehicle isKindOf "ParachuteBase"))
		then {
			_cargos = [];
			{_cargos pushback _x#0}forEach fullCrew [vehicle player, "cargo"];
			if (!(player in _cargos))
			then {
				if (_unit call groupType == -1)
				then {
					moveOut _unit;
					unassignVehicle player;
					hintSilent "장비를 조작하기 위해서는 적절한 분대태그를 가진 그룹에 가입해야 합니다. U키를 눌러 적절한 분대에 가입하기 바랍니다.";
				}
				else {
					if (!([_unit call groupType, _vehicle] call isAllowedGetIn))
					then {
						moveOut _unit;
						unassignVehicle player;
						hintSilent "현재 분대태그로는 탑승할 수 없는 좌석입니다. ""뒤에 탑승"" 버튼을 이용하기 바랍니다."; 
						["<t color='#ff0000' size = '.55' >현재 분대태그로는 탑승할 수 없는 좌석입니다. ""뒤에 탑승"" 버튼을 이용하기 바랍니다.</t>"] spawn BIS_fnc_dynamicText;
					};
				};
			};
		};
	};
}
];


isSwitchAllowed = {				
	_isSwitchAllowed = true;	
	if(vehicle player != player)then{
		if (player call groupType == -1)
		then {
			_isSwitchAllowed = false;
		}
		else {
			if (([player call groupType, vehicle player] call isAllowedGetIn))
			then {
				_isSwitchAllowed = true;
			}else{_isSwitchAllowed = false;};
		};	
	};
	_isSwitchAllowed
};	

[] spawn {
	while{true}do{
		if(call isSwitchAllowed)then{
			inGameUISetEventHandler ["Action", ""];	
		}else{	
			inGameUISetEventHandler ["Action", "
	if (_this select 3 in ['MoveToCommander','MoveToDriver','MoveToGunner','MoveToPilot','MoveToTurret']) then {
		systemChat '현재 분대태그로는 탑승할 수 없는 좌석입니다. 객석으로 돌아갑니다.'; 
		[""<t color='#ff0000' size = '0.55' >현재 분대태그로는 탑승할 수 없는 좌석입니다. 객석으로 돌아갑니다.</t>""] spawn BIS_fnc_dynamicText;
		true
	}"];
		};
		sleep 0.1;
	};
};

[] spawn {
	while{true}do{
		sleep 10;
		if(player call groupType == -1) then {
			["<t color='#ff0000' size = '0.55' >적절한 분대태그를 사용하지 않아 모든 기능이 제한됩니다.<br/>U키를 눌러 적절한 분대태그를 가진 분대에 가입하거나 생성하십시오.<br/>자세한 정보는 지도 하단을 참조하시기 바랍니다.</t>",-1,-1,7] spawn BIS_fnc_dynamicText;
		};
	};
};

/*
player addEventHandler["SeatSwitchedMan", {
	params["_unit1", "_unit2", "_vehicle"];
	if (!(_vehicle isKindOf "ParachuteBase"))
	then {	
		_cargos = [];
		{_cargos pushback _x#0}forEach fullCrew [vehicle player, "cargo"];
		if (!(player in _cargos))
		then {
			SeatSwitching = true;
			if ((_unit1 call groupType == -1))
			then {
				moveOut _unit1;
				_unit1 assignAsCargo _vehicle;
				//_unit1 moveInCargo _vehicle;				
				[[_unit1, _vehicle],{params ["_unit1", "_vehicle"];_unit1 moveInCargo _vehicle;}] remoteExec ["call", _vehicle];				
				hintSilent "장비를 조작하기 위해서는 적절한 분대태그를 가진 그룹에 가입해야 합니다. U키를 눌러 적절한 분대에 가입하시기 바랍니다.";
			}
			else {
				if (!([_unit1 call groupType, _vehicle] call isAllowedGetIn))
				then {
					moveOut _unit1;
					_unit1 assignAsCargo _vehicle;
					[[_unit1, _vehicle],{params ["_unit1", "_vehicle"];_unit1 moveInCargo _vehicle;}] remoteExec ["call", _vehicle];
					hintSilent "가입하신 분대에서 사용할 수 없는 장비입니다. 서버 규정을 확인하시기 바랍니다.";
				};
			};
			SeatSwitching = false;
		};
	};
}
];
*/


PilotRestriction = { 	
	params ["_minSquads"];
	sleep 1;
	"=PILOT RULES=" hintC [
	str formatText ["조종사 슬롯으로 접속하였습니다. [전투], [기동]분대에 가입하여 항공기를 사용할 수 있습니다."],	
	str formatText ["이 슬롯으로 플레이하기 위해선 최소 %1개의 지상분대가 있어야 합니다.",_minSquads,call groundSquads],
	str formatText ["현재 지상분대 수는 %2분대로, 지상분대 수가 %1분대 아래로 떨어지는 경우 자동으로 로비로 돌아갑니다.",_minSquads,call groundSquads],
	str formatText ["지나친 자원 낭비나 무단 CAS등은 서버룰에 의거하여 킥, 밴 조치될 수 있으니 책임감있는 플레이 부탁드립니다."],	
	str formatText ["조종사 보직으로 플레이 하는 동안은 항상 전술통신망을 유지하고 점검할 의무가 있습니다. (무전기 슬롯에 무전기를 장착하면 자동 가입됩니다.)"],	
	str formatText ["아울러 조종사 보직을 유지한 상태에서 지상분대 플레이를 엄격하게 금지합니다. 반드시 소총수, 공병, 전투의무병 보직으로 전환 후 플레이 하시기 바랍니다."],
	str formatText ["조종사는 관련된 규정을 모두 숙지하고, 서버룰을 위반한 것이 적발되는 경우 처벌될 수 있다는 것에 동의한 것으로 간주됩니다. 이에 동의하지 않는 경우 다른 보직으로 플레이 해주시기 바랍니다."]
	];
	
	while{true}do{
		sleep 1; 
		if(call groundSquads < _minSquads)then{
			if(vehicle player == player) then {
				"No more pilots!" hintC [
				str formatText ["이 슬롯으로 플레이하기 위해선 최소 %1개의 지상분대가 있어야 합니다.",_minSquads,call groundSquads],
				str formatText ["현재 지상분대 수는 %2분대로, 최소 필요 분대수를 충족하지 못해 대기실로 돌아갑니다.",_minSquads,call groundSquads],
				"지상분대로 플레이해주시면 감사드리겠습니다.",
				"ESC를 눌러 이 창을 닫고 대기실로 돌아갑니다."
				];
				endMission "End3";
			}else{
				hint formatText ["이 슬롯으로 플레이하기 위해선 최소 %1분대의 지상분대가 있어야 합니다.현재 지상분대 수는 %2분대입니다.하차후에 자동으로 로비로 돌아갑니다.",_minSquads,call groundSquads];
			};
		};
	};
};


if(typeOf player == "B_Pilot_F") then {
	waitUntil{!isNull findDisplay 46};
	sleep 3;
	systemChat str formatText ["지상분대가 %1분대 미만이 되면 자동으로 대기실로 이동합니다. 현재 지상분대 수는 %2분대입니다.",({typeOf _x == "B_Pilot_F"} count allPlayers)-1,call groundSquads,lineBreak];
	_null = [({typeOf _x == "B_Pilot_F"} count allPlayers)-1] spawn pilotRestriction;
};



systemChat "분대별 장비잠금 스크립트 활성화";