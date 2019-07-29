combat_readiness = round (combat_readiness * 0.80);

_defenders_amount = 15 * ( sqrt ( GRLIB_unitcap ) );
if ( _defenders_amount > 15 ) then { _defenders_amount = 15 };
_fob_templates = [
"scripts\fob_templates\template5.sqf",
"scripts\fob_templates\template4.sqf",
"scripts\fob_templates\template3.sqf",
"scripts\fob_templates\template2.sqf",
"scripts\fob_templates\template1.sqf"
];

_spawn_marker = [2000,999999,false] call F_findOpforSpawnPoint;
if ( _spawn_marker == "" ) exitWith { diag_log "Could not find position for fob hunting mission"; 
combat_readiness = round (combat_readiness * 0.80);
[gamelogic, str formatText["특수임무를 생성가능한 지점이 없습니다. 첩보활동으로 적의 위협도가 20% 감소하였습니다."]] remoteExec ["globalChat"];};
};

used_positions = used_positions + [ _spawn_marker ];
_base_position = markerpos _spawn_marker;
_base_objects = [];
_base_objectives = [];
_base_defenders = [];
_template = ([] call (compile preprocessFileLineNumbers ( _fob_templates call bis_fnc_selectrandom )));

_objects_to_build = _template select 0;
_objectives_to_build = _template select 1;
_defenders_to_build = _template select 2;
_base_corners =  _template select 3;

{
	_nextclass = _x select 0;
	_nextpos = _x select 1;
	_nextpos = [((_base_position select 0) + (_nextpos select 0)),((_base_position select 1) + (_nextpos select 1)),0];
	_nextdir = _x select 2;

	_nextobject = _nextclass createVehicle _nextpos;
	_nextobject setVectorUp [0,0,1];
	_nextobject setpos _nextpos;
	_nextobject setdir _nextdir;
	_nextobject setVectorUp [0,0,1];
	_nextobject setpos _nextpos;
	_nextobject setdir _nextdir;
	_base_objects = _base_objects + [_nextobject];

} foreach _objects_to_build;

sleep 1;

{
	_nextclass = _x select 0;
	_nextpos = _x select 1;
	_nextpos = [((_base_position select 0) + (_nextpos select 0)),((_base_position select 1) + (_nextpos select 1)),0.5];
	_nextdir = _x select 2;

	_nextobject = _nextclass createVehicle [(_nextpos select 0) + (random 500),(_nextpos select 1) + (random 500),0.5];
	_nextobject setVectorUp [0,0,1];
	_nextobject setpos _nextpos;
	_nextobject setdir _nextdir;
	_nextobject setVectorUp [0,0,1];
	_nextobject setpos _nextpos;
	_nextobject setdir _nextdir;
	_nextobject lock 2;

	_base_objectives = _base_objectives + [_nextobject];
} foreach _objectives_to_build;

sleep 1;

{ _x setDamage 0; } foreach (_base_objectives + _base_objects);

_grpdefenders = createGroup GRLIB_side_enemy;
_idxselected = [];
while { count _idxselected < _defenders_amount } do {
	_idx = floor (random (count _defenders_to_build));
	if ( !(_idx in _idxselected) ) then {
		_idxselected pushback _idx;
	};
};

{
	_nextentry = _defenders_to_build select _x;
	_nextclass = _nextentry select 0;
	_nextpos = _nextentry select 1;
	_nextpos = [((_base_position select 0) + (_nextpos select 0)),((_base_position select 1) + (_nextpos select 1)),(_nextpos select 2)];
	_nextdir = _nextentry select 2;
	_nextclass createUnit [_nextpos, _grpdefenders,"nextdefender = this; this addMPEventHandler [""MPKilled"", {_this spawn kill_manager}]", 0.5, "private"];
	nextdefender setpos _nextpos;
	nextdefender setdir _nextdir;
	[nextdefender] spawn building_defence_ai;
} foreach _idxselected;

_sentry = ceil ((3 + (floor (random 4))) * ( sqrt ( GRLIB_unitcap ) ) );

_grpsentry = createGroup GRLIB_side_enemy;
_base_sentry_pos = [(_base_position select 0) + ((_base_corners select 0) select 0), (_base_position select 1) + ((_base_corners select 0) select 1),0];
for [ {_idx=0},{_idx < _sentry},{_idx=_idx+1} ] do {
	opfor_sentry createUnit [_base_sentry_pos, _grpsentry,"this addMPEventHandler [""MPKilled"", {_this spawn kill_manager}]", 0.5, "private"];
};

while {(count (waypoints _grpsentry)) != 0} do {deleteWaypoint ((waypoints _grpsentry) select 0);};
{
	_waypoint = _grpsentry addWaypoint [[((_base_position select 0) + (_x select 0)), ((_base_position select 1) + (_x select 1)),0], 0];
	_waypoint setWaypointType "MOVE";
	_waypoint setWaypointSpeed "LIMITED";
	_waypoint setWaypointBehaviour "SAFE";
	_waypoint setWaypointCompletionRadius 5;
} foreach _base_corners;

_waypoint = _grpsentry addWaypoint [[(_base_position select 0) + ((_base_corners select 0) select 0), (_base_position select 1) + ((_base_corners select 0) select 1),0], 0];
_waypoint setWaypointType "CYCLE";

_objectives_alive = true;

secondary_objective_position = _base_position;
secondary_objective_position_marker = [(((secondary_objective_position select 0) + 800) - random 1600),(((secondary_objective_position select 1) + 800) - random 1600),0];
publicVariable "secondary_objective_position_marker";
sleep 1;
GRLIB_secondary_in_progress = 0; publicVariable "GRLIB_secondary_in_progress";
[ [ 2 ] , "remote_call_intel" ] call BIS_fnc_MP;

waitUntil {
	sleep 5;
	 ( { alive _x } count _base_objectives ) <= 1
};

combat_readiness = round (combat_readiness * GRLIB_secondary_objective_impact);
stats_secondary_objectives = stats_secondary_objectives + 1;
sleep 1;
trigger_server_save = true;
sleep 3;

[ [ 3 ] , "remote_call_intel" ] call BIS_fnc_MP;

GRLIB_secondary_in_progress = -1; publicVariable "GRLIB_secondary_in_progress";