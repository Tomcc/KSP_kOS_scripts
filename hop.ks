//hellolaunch

DECLARE PARAMETER TARGET_APOAPSIS.

SET ROCKET_HEIGHT TO ALT:RADAR.

SET ORIG_LONG TO LONGITUDE.
SET ORIG_LAT TO LATITUDE.

//Next, we'll lock our throttle to 100%.
SET T TO 0.
LOCK THROTTLE TO T.   // 1.0 is the max, 0.0 is idle.
LOCK STEERING TO HEADING(90, 89.9). //head slightly east t balance the rotation of the planet
LOCK MASS_KG TO SHIP:MASS * 1000.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}

PRINT "LIFTOFF!!!".

GEAR OFF.
SET T TO 1.0.
STAGE.

//enter throttleable regime
//until Apoapsis is reached
UNTIL ALT:RADAR > TARGET_APOAPSIS - 200 {
	IF SHIP:APOAPSIS > TARGET_APOAPSIS {
		SET T TO 0.
	}
	ELSE IF SHIP:DYNAMICPRESSURE > 0.26 {
		SET T TO 0.5.
	}
	ELSE IF SHIP:DYNAMICPRESSURE < 0.24 OR SHIP:APOAPSIS < TARGET_APOAPSIS - 50 {
		SET T TO MIN(1, T + 0.0005).
	}
}

SET T TO 0.
PRINT "Coasting to Apoapsis".

WAIT UNTIL SHIP:VERTICALSPEED < 0.

PRINT "Apoapsis reached at " + APOAPSIS.
PRINT "Deploying gear to dispel speed".
GEAR ON.

WAIT UNTIL SHIP:VERTICALSPEED < -5.
PRINT "Initiating reentry".

LOCK STEERING to -VELOCITY:SURFACE.

LOCK G TO SHIP:SENSORS:GRAV:MAG.

UNTIL SHIP:VERTICALSPEED > -5 {
	LOCAL CRITICAL_H IS ((SHIP:VERTICALSPEED * SHIP:VERTICALSPEED) / (2 * ((SHIP:AVAILABLETHRUST * 1000 / MASS_KG) - G))).

	IF ALT:RADAR - ROCKET_HEIGHT - 1 <= CRITICAL_H {
		SET T TO 1.0.
	}
	ELSE {
		SET T TO MAX(0, T - 0.005). //back off
	}

	Lock steering to -VELOCITY:SURFACE.
}

LOCK STEERING TO UP.
SET T TO 0.

PRINT "Burn complete, releasing control.".

//ensure that the throttle remains 0
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
