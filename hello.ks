//hellolaunch

//find the current mass ------------------------------
FUNCTION GET_MASS {

	LOCAL M IS 0.

	FOR p in SHIP:PARTS {
		IF p:DRYMASS < p:WETMASS {
			for r in p:RESOURCES {
				if r:NAME = "LIQUIDFUEL" {
					SET M TO M + (p:DRYMASS + (p:WETMASS - p:DRYMASS) * (r:AMOUNT / r:CAPACITY)).
					BREAK.
				}
			}
		}
		ELSE {
			SET M TO M + p:DRYMASS.
		}
	}
	RETURN M * 1000. //convert to kg
}.

///-------------------------------------------------

//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.

//schedule an update for the thrust value
SET TOTALTHRUST TO 0.
when ALT:RADAR > 1000 THEN {
	LIST ENGINES in ALL_ENGINES.

	FOR e in ALL_ENGINES {
		SET TOTALTHRUST TO TOTALTHRUST + e:THRUST * 1000.
	}
	PRINT "Total thrust: " + TOTALTHRUST.
}

SET TARGET_APOAPSIS TO 5000.
SET ROCKET_HEIGHT TO ALT:RADAR.

//Next, we'll lock our throttle to 100%.
SET T TO 0.
LOCK THROTTLE TO T.   // 1.0 is the max, 0.0 is idle.
LOCK STEERING TO HEADING(90,89.7). //head slightly east t balance the rotation of the planet

GEAR OFF.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}

PRINT "LIFTOFF!!!".

SET T TO 1.0.
STAGE.

WAIT 2. //give the engine the time to fully throttle

//find the current mass and time
SET LIFTOFF_MASS TO GET_MASS().
SET LIFTOFF_TIME TO TIME:SECONDS.

WAIT 10. //measure at full throttle

SET BURNED_MASS_PER_S TO (LIFTOFF_MASS - GET_MASS()) / (TIME:SECONDS - LIFTOFF_TIME).
PRINT "Engines burn " + BURNED_MASS_PER_S + "kg/s".

//enter throttleable regime

SET LASTTIME TO TIME:SECONDS.
UNTIL APOAPSIS > TARGET_APOAPSIS	 {
	//every 3 seconds
	IF TIME:SECONDS > LASTTIME + 3 {
		SET LASTTIME TO TIME:SECONDS.
		//going too fast
		IF SHIP:DYNAMICPRESSURE > 0.26 {
			SET T TO MAX(0, T - 0.1).
			PRINT "SLOWDOWN".
		}
		IF SHIP:DYNAMICPRESSURE < 0.24 {
			SET T TO MIN(1, T + 0.1).
			PRINT "ACCELERATE".
		}
	}
}

SET T TO 0.

PRINT "Apoapsis set at " + APOAPSIS.

WAIT UNTIL SHIP:VERTICALSPEED < 0.

PRINT "Apoapsis reached at" + APOAPSIS.
PRINT "Deploying gear to dispel speed".
GEAR ON.
WAIT 7.

lock steering to -velocity:surface.

SET DRAG TO 0.
SET TOTAL_BURN_TIME TO 3.1.
SET M TO (GET_MASS()) - ((BURNED_MASS_PER_S * TOTAL_BURN_TIME) / 2). 
PRINT "CURRENT MASS " + M.

LOCK G TO SHIP:SENSORS:GRAV:MAG.

WHEN (ALT:RADAR + ROCKET_HEIGHT) <= ((SHIP:VERTICALSPEED * SHIP:VERTICALSPEED) / (2 * ((TOTALTHRUST / M) - G))) THEN {
	PRINT "SUICIDE BURN STARTED".
	SET BURN_START_TIME TO TIME:SECONDS.

	SET T TO 1.0.
}

SET LASTTIME TO TIME:SECONDS.
SET LASTSPEED TO SHIP:VERTICALSPEED.
UNTIL SHIP:VERTICALSPEED > -5 {
	WAIT 0.5.
	//extimate drag
	SET DRAG TO -G - ((SHIP:VERTICALSPEED - LASTSPEED) / (TIME:SECONDS - LASTTIME)).
	SET LASTTIME TO TIME:SECONDS.
	SET LASTSPEED TO SHIP:VERTICALSPEED.

	PRINT "DRAG " + DRAG + " MASS " + GET_MASS().
}

LOCK STEERING TO UP.
SET T TO 0.

PRINT "Suicide burn complete in " + (TIME:SECONDS - BURN_START_TIME) + "s".

// NOTE that it is vital to not just let the script end right away
// here.  Once a kOS script just ends, it releases all the controls
// back to manual piloting so that you can fly the ship by hand again.
// If the program just ended here, then that would cause the throttle
// to turn back off again right away and nothing would happen.