//shared weather

waitUntil { !isNil "chosen_weather" };

while { true } do {
	1800 setOvercast chosen_weather;
	1800 setRain chosen_rain;
    1800 setFog [chosen_fog#0,chosen_fog#1,chosen_fog#2];
	500 setWaves (0.66*chosen_rain+0.8*chosen_weather);
	/*
	if ( overcast < 0.75 ) then { 2 setRain 0 };
	if ( overcast >= 0.75 && overcast < 0.95 ) then { 2 setRain 0.1 };
	if ( overcast >= 0.95 ) then { 2 setRain 0.2 }; // Removed heavy rain due to severe fps issues*/
	sleep 5;
	//systemChat "shd weather";
};