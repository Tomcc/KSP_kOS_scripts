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

DECLARE PARAMETER TARGET_APOAPSIS.

//schedule an update for the thrust value
SET TOTALTHRUST TO 0.
when ALT:RADAR > 30 THEN {
	LIST ENGINES in ALL_ENGINES.

	FOR e in ALL_ENGINES {
		SET TOTALTHRUST TO TOTALTHRUST + e:THRUST * 1000.
	}
	PRINT "Total thrust: " + TOTALTHRUST.
}

SET ROCKET_HEIGHT TO ALT:RADAR.

//Next, we'll lock our throttle to 100%.
SET T TO 0.
LOCK THROTTLE TO T.   // 1.0 is the max, 0.0 is idle.
LOCK STEERING TO HEADING(90,89). //head slightly east t balance the rotation of the planet

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
		SET T TO MAX(0, T - 0.0002).
	}
	ELSE IF SHIP:DYNAMICPRESSURE < 0.24 OR SHIP:APOAPSIS < TARGET_APOAPSIS - 50 {
		SET T TO MIN(1, T + 0.0005).
	}
}

SET T TO 0.
PRINT "Coasting Apoapsis".

WAIT UNTIL SHIP:VERTICALSPEED < 0.

PRINT "Apoapsis reached at" + APOAPSIS.
PRINT "Deploying gear to dispel speed".
GEAR ON.

WAIT UNTIL SHIP:VERTICALSPEED < -5.
PRINT "Initiating reentry".

lock steering to -velocity:surface.

LOCK G TO SHIP:SENSORS:GRAV:MAG.

UNTIL SHIP:VERTICALSPEED > -5 {
	LOCAL CRITICAL_H IS ((SHIP:VERTICALSPEED * SHIP:VERTICALSPEED) / (2 * ((TOTALTHRUST / GET_MASS()) - G))).

	IF ALT:RADAR - 6 <= CRITICAL_H {
		SET T TO 1.0.
	}
	ELSE {
		SET T TO MAX(0, T - 0.005). //back off
	}
}

LOCK STEERING TO UP.
SET T TO 0.

PRINT "Suicide burn complete".

//ensure that the throttle remains 0
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

// NOTE that it is vital to not just let the script end right away
// here.  Once a kOS script just ends, it releases all the controls
// back to manual piloting so that you can fly the ship by hand again.
// If the program just ended here, then that would cause the throttle
// to turn back off again right away and nothing would happen.