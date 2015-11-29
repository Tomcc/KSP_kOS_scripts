
//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.

SET M TO 0.

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

PRINT "CURRENT MASS " + M.
