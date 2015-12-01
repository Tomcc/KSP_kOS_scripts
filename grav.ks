
run once lib. //import common functions

FUNCTION THROTTLE_TO_TWR {
	DECLARE PARAMETER TARGET.
	SET THROTTLE_TARGET TO THROTTLE_MIN.
	UNTIL TWR() > TARGET {
		IF TICKED() {
			ADD_THROTTLE(0.05).
			WAIT TICK_DURATION_S * THROTTLE_LAG_TICKS. //wait enough for the engine to respond to the change
		}
	}
	PRINT "TWR reached: " + TWR() + ", " + TWR() / TARGET * 100 + "% of target".
}

LOCK STEERING TO HEADING(90, 89.9). //head slightly east t balance the rotation of the planet

LIFTOFF().

GEAR OFF.

THROTTLE_TO_TWR(1.5).

WAIT UNTIL SHIP:ALTITUDE > 1000.