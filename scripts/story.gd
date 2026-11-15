class_name Story
extends RefCounted

const LOGS := {
	1: [
		["orbit", "Nyx-4. A survey drop, one pilot. Subject 712. Call sign: Black Dolphin."],
		["crash", "A storm of charged dust hit on the way down. The lander came apart."],
		["wake", "I can't feel my legs. But the gravity here is weak... my arms will do."],
		["hands", "Drag back. Brace. Push. Every shove turns into a flight."],
	],
	2: [
		["echo", "I died on the crystals. Then I woke up a few steps back. My body was still there."],
		["slime", "The dust turned it into slime. It bounces. I can stand on myself."],
	],
	3: [["slime", "Too high to climb. So I fall on purpose and use what's left."]],
	4: [["capsule", "The first team left escape capsules. Each one gets me closer to the beacon."]],
	5: [["updraft", "Warm vents breathe up from the rock. They carry me if I let them."]],
	6: [["updraft", "A magnetic column. It lifts me straight into the crystals. Let go in time."]],
	7: [["portal", "The Echo folds space. Two doors, one room. My speed comes with me."]],
	8: [["portal", "Lift, then fold. This planet is testing me."]],
	9: [["wind", "Ion wind sweeps the craters. Ride it, or fight it."]],
	10: [["capsule", "Halfway. On the horizon I can see the beacon's light."]],
	11: [["moss", "Green moss on the cliffs. It grips my gloves, but never for long."]],
	12: [["moss", "A chimney of moss. Jump, grab, jump. Don't stop."]],
	13: [["platform", "Rocks drift on the field lines. One of them is my ferry."]],
	14: [["rope", "Anchor nodes. My cable still works. Hold on, swing, let go."]],
	15: [["dark", "Here the Echo eats the light. Only my old bodies glow."]],
	16: [["dark", "Climbing blind. The ceiling has teeth."]],
	17: [["graves", "How many of me are back there now? Each wall needs one more."]],
	18: [["graves", "A graveyard made of my own glow. Keep dying. Keep moving."]],
	19: [["rope", "Swing through the dark and land on a floating rock. Trust the Echo."]],
	20: [["beacon", "The Last Light. One climb left, then one message home."]],
}

const ENDING := [
	["beacon", "Signal sent. For a long time, only static. Then a voice."],
	["graves", "Behind me, all the bodies I left glow in the craters. The Echo isn't done with me."],
]

static var last_level := -1


static func logs_for(level: int) -> Array:
	return LOGS.get(level, [])


static func should_play(level: int) -> bool:
	if level == last_level or not LOGS.has(level):
		return false
	last_level = level
	return true
