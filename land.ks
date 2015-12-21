RUN ONCE LIB.

PRINT "Initiating reentry routine.".

WAIT UNTIL SHIP:VERTICALSPEED < -5.

PRINT "Deploying gear to dispel speed".
GEAR ON.
SAS OFF.

LOCK STEERING to -VELOCITY:SURFACE.

LOCK G TO SHIP:SENSORS:GRAV:MAG.

UNTIL SHIP:VERTICALSPEED > -5 {
	IF TICKED(88) {
		LOCAL THROTTLE_LAG_OFFSET TO SHIP:VERTICALSPEED * THROTTLE_LAG_TICKS * DELTA_T.

		//find the downwards component of the thrust
		LOCAL VERTICAL_THRUST IS SHIP:FACING:FOREVECTOR * SHIP:UP:FOREVECTOR * SHIP:AVAILABLETHRUST * 1000.

		PRINT SHIP:FACING:FOREVECTOR * SHIP:UP:FOREVECTOR.

		LOCAL CRITICAL_H IS ((SHIP:VERTICALSPEED * SHIP:VERTICALSPEED) / (2 * ((VERTICAL_THRUST / MASS_KG()) - G))).

		IF ALT:RADAR - ROCKET_HEIGHT - 1 + THROTTLE_LAG_OFFSET <= CRITICAL_H {
			SET THROTTLE_TARGET TO 1.0.
		}
		ELSE {
			ADD_THROTTLE(-0.15).
		}
	}
}

LOCK STEERING TO UP.
SET T TO 0.

PRINT "Burn complete, releasing control.".
