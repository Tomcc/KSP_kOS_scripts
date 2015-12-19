
//initialize the rocket height as it's vital for landing. From file if possible.
RUN ONCE selfconfig.

GLOBAL MASS_KG IS 0.
GLOBAL DELTA_T IS 0.
GLOBAL THROTTLE_TARGET IS 0.
GLOBAL THROTTLE_MIN IS 0.4. 
GLOBAL TICK_DURATION_S IS 1/50.
GLOBAL THROTTLE_LAG_TICKS IS 4.
GLOBAL THROTTLE_DELAY IS TICK_DURATION_S * THROTTLE_LAG_TICKS.

FUNCTION THRUST {
	LOCAL TOTALTHRUST IS 0.
	LIST ENGINES in ALL_ENGINES.

	FOR e in ALL_ENGINES {
		SET TOTALTHRUST TO TOTALTHRUST + e:THRUST.
	}
	RETURN TOTALTHRUST * 1000.
}

FUNCTION AVAILABLE_THRUST {
	LOCAL TOTALTHRUST IS 0.
	LIST ENGINES in ALL_ENGINES.

	FOR e in ALL_ENGINES {
		SET TOTALTHRUST TO TOTALTHRUST + e:AVAILABLETHRUST.
	}
	RETURN TOTALTHRUST * 1000.
}

FUNCTION MASS_KG {
	RETURN SHIP:MASS * 1000.
}

FUNCTION WEIGHT {
	RETURN SHIP:SENSORS:GRAV:MAG * MASS_KG().
}

FUNCTION TWR {
	RETURN THRUST() / WEIGHT().
}

SET MIN_PHYSICS_TICK_SPEED TO 30.
SET _LAST_TIME TO TIME.
SET _LAST_LOOP_ID TO 29093280383.

FUNCTION TICKED {
	DECLARE PARAMETER LOOP_ID.
	IF _LAST_LOOP_ID <> LOOP_ID {
		SET _LAST_LOOP_ID TO LOOP_ID.
		SET DELTA_T TO 0.
		SET _LAST_TIME TO TIME.
	}
	ELSE IF TIME <> _LAST_TIME {
		SET DELTA_T TO TIME:SECONDS - _LAST_TIME:SECONDS.
		SET _LAST_TIME TO TIME.
	}
	ELSE {
		SET DELTA_T TO 0.
	}
	RETURN DELTA_T > 0.
}

FUNCTION ADD_THROTTLE {
	DECLARE PARAMETER CHANGE.
	SET THROTTLE_TARGET TO MAX(0, MIN(1, THROTTLE_TARGET + CHANGE * DELTA_T)).
}

FUNCTION ADD_THROTTLE_NO_TURNOFF {
	DECLARE PARAMETER CHANGE.
	SET THROTTLE_TARGET TO MAX(THROTTLE_MIN, MIN(1, THROTTLE_TARGET + CHANGE * DELTA_T)).
}

FUNCTION FILTER_THROTTLE {
	IF THROTTLE_TARGET >= THROTTLE_MIN {
		RETURN THROTTLE_TARGET.
	}
	RETURN 0.
}

LOCK THROTTLE TO FILTER_THROTTLE().

FUNCTION LIFTOFF {
	//This is our countdown loop, which cycles from 10 to 0
	PRINT "Counting down:".
	FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
	    PRINT "..." + countdown.
	    WAIT 1. // pauses the script here for 1 second.
	}

	PRINT "LIFTOFF!!!".

	STAGE.
}

FUNCTION MAX_THRUST {
	RETURN SHIP:MAXTHRUST * 1000.
}

FUNCTION FUEL_FLOW {
	LOCAL TOTALFLOW IS 0.
	LIST ENGINES in ALL_ENGINES.

	FOR e in ALL_ENGINES {
		SET TOTALFLOW TO TOTALFLOW + e:FUELFLOW.
	}
	RETURN TOTALFLOW.
}

FUNCTION THROTTLE_TO_TWR_WITH_MAXTHRUST {
	DECLARE PARAMETER TARGET.
	DECLARE PARAMETER P_THRUST.
	SET THROTTLE_TARGET TO (TARGET * WEIGHT()) / P_THRUST.
}

FUNCTION THROTTLE_TO_TWR {
	DECLARE PARAMETER TARGET.
	THROTTLE_TO_TWR_WITH_MAXTHRUST(TARGET, AVAILABLE_THRUST()).
}

//ensure that the throttle remains 0
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
