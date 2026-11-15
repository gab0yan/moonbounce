extends "res://scripts/level.gd"

const T := 16
const SPIKE := preload("res://scenes/entities/crystal_spike.tscn")
const CLING := preload("res://scenes/entities/cling_wall.tscn")
const LIFT := preload("res://scenes/entities/lift_zone.tscn")
const DRIFT := preload("res://scenes/entities/drift_zone.tscn")
const GRAPPLE := preload("res://scenes/entities/grapple_point.tscn")
const PLATFORM := preload("res://scenes/entities/moving_platform.tscn")
const PORTAL := preload("res://scenes/entities/portal.tscn")

const SEGMENTS := {
	"pit": {"deaths": 1, "rows": [
		"........", "........", "........", "........", "........",
		"........", "........", "........", "........", ".^^^^^^."]},
	"wall": {"deaths": 1, "rows": [
		"........", "........", "........", "........", "........",
		"...^^...", "...##...", "...##...", "...##...", ".^^##..."]},
	"deadweight": {"deaths": 1, "rows": [
		"........", "........", "........", "........", "........",
		".....##.", ".....##.", ".....##.", ".....##.", "...^.##."]},
	"climb": {"deaths": 0, "rows": [
		"........", "........", "........", "..R.L#..", "..R.L#..",
		"..R.L#..", "..R.L#..", "..R.L#..", "....L#..", "....L#.."]},
	"lift": {"deaths": 0, "rows": [
		".####...", "..vv....", "..UU....", "..UU....", "..UU.##.",
		"..UU.##.", "..UU.##.", "..UU.##.", "..UU.##.", "..UU.##."]},
	"swing": {"deaths": 0, "rows": [
		"........", "........", "........", "........", "...O....",
		"........", "........", "........", "........", ".^^^^^^."]},
	"ferry": {"deaths": 0, "rows": [
		"........", "........", "........", "........", "........",
		"........", "........", ".F......", "........", ".^^^^^^."]},
	"portal": {"deaths": 0, "rows": [
		"....#...", "....#...", "....#...", "....#Q..", "....#...",
		"....#...", "....#...", "....#...", "..P.#...", "....#..."]},
	"wind": {"deaths": 0, "rows": [
		"........", "........", "........", ".WWWWWW.", ".WWWWWW.",
		".WWWWWW.", ".WWWWWW.", ".WWWWWW.", ".WWWWWW.", ".^^^^^^."]},
}
const NAMES := ["Crater Run", "Dust Drift", "Low Orbit", "Moon Maze", "Night Shift", "Echo Field",
		"Crystal Gap", "Far Side", "Static Sky", "Lost Signal", "Grey Sea", "Cold Light"]

static var round_number := 1
static var round_seed := 0
static var forced_segments: Array = []

var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	if round_seed == 0:
		round_seed = randi() | 1
	_rng.seed = round_seed + round_number * 7919
	_build_round()


func _build_round() -> void:
	var picks: Array = forced_segments.duplicate()
	if picks.is_empty():
		picks = [_pick(true), _pick(false)]
		if _rng.randf() < 0.5:
			picks.reverse()
	var grid: Array = []
	for r in 12:
		var row := []
		for c in 20:
			row.append("." if r < 10 else "#")
		grid.append(row)
	grid[9][1] = "S"
	grid[8][18] = "E"
	var deaths := 0
	for i in picks.size():
		var seg: Dictionary = SEGMENTS[picks[i]]
		deaths += seg.deaths
		var x0 := 2 + i * 8
		for r in 10:
			var row: String = seg.rows[r]
			for c in 8:
				grid[r][x0 + c] = row[c]
	var dark: bool = round_number >= 4 and _rng.randf() < 0.35
	set_meta("round", round_number)
	set_meta("number_label", "Round")
	set_meta("level_name", NAMES[_rng.randi() % NAMES.size()])
	set_meta("lives", 3 + deaths * 2)
	set_meta("dark", dark)
	set_meta("light_radius", 48.0)
	_fill(grid, picks)


func _pick(must_die: bool) -> String:
	var keys := []
	for key in SEGMENTS:
		if not must_die or SEGMENTS[key].deaths > 0:
			keys.append(key)
	return keys[_rng.randi() % keys.size()]


func _fill(grid: Array, picks: Array) -> void:
	var ground: TileMapLayer = $Ground
	ground.clear()
	for r in 12:
		for c in 20:
			var ch: String = grid[r][c]
			var pos := Vector2(c * T, r * T)
			match ch:
				"#", "L", "R":
					ground.set_cell(Vector2i(c, r), 0, _autotile(grid, c, r))
				"^":
					_add($Hazards, SPIKE, pos)
				"v":
					var s = _add($Hazards, SPIKE, pos + Vector2(T, T))
					s.rotation = PI
				"S":
					$Spawn.position = pos + Vector2(8, T)
					$Player.position = $Spawn.position
				"E":
					$ExitCapsule.position = pos
				"O":
					var g = GRAPPLE.instantiate()
					g.position = pos + Vector2(8, 8)
					g.radius = 60.0
					$GrapplePoints.add_child(g)
				"F":
					var p = PLATFORM.instantiate()
					p.position = Vector2(pos.x, pos.y + 8)
					p.travel = Vector2(64, 0)
					p.period = 4.0
					p.pause = 1.0
					$Platforms.add_child(p)
	_add_grips(grid)
	for i in picks.size():
		var x0 := 2 + i * 8
		_add_zone(grid, x0, "U", LIFT, Vector2.UP)
		_add_zone(grid, x0, "W", DRIFT, Vector2.RIGHT)
		_add_portals(grid, x0)


func _add(parent: Node, scene: PackedScene, pos: Vector2) -> Node2D:
	var n: Node2D = scene.instantiate()
	n.position = pos
	parent.add_child(n)
	return n


func _solid(grid: Array, c: int, r: int) -> bool:
	if c < 0 or c >= 20 or r >= 12:
		return true
	if r < 0:
		return false
	return grid[r][c] in ["#", "L", "R"]


func _autotile(grid: Array, c: int, r: int) -> Vector2i:
	var w := _solid(grid, c - 1, r)
	var e := _solid(grid, c + 1, r)
	var n := _solid(grid, c, r - 1)
	var s := _solid(grid, c, r + 1)
	var tx := 3 if (not w and not e) else (1 if (w and e) else (2 if w else 0))
	var ty := 3 if (not n and not s) else (1 if (n and s) else (2 if n else 0))
	if tx == 3 and ty == 3:
		return Vector2i(3, 3)
	if tx == 3:
		return Vector2i(3, mini(ty, 2))
	if ty == 3:
		return Vector2i(mini(tx, 2), 3)
	if tx == 1 and ty == 1 and _rng.randf() < 0.45:
		return Vector2i(_rng.randi_range(4, 7), _rng.randi_range(0, 1))
	return Vector2i(tx, ty)


func _add_grips(grid: Array) -> void:
	for side in ["L", "R"]:
		for c in 20:
			var r := 0
			while r < 12:
				if grid[r][c] != side:
					r += 1
					continue
				var r0 := r
				while r < 12 and grid[r][c] == side:
					r += 1
				var g = CLING.instantiate()
				g.position = Vector2(c * T - 2 if side == "L" else (c + 1) * T + 2, r0 * T)
				g.scale = Vector2(1, (r - r0) * T / 48.0)
				$ClingWalls.add_child(g)


func _add_zone(grid: Array, x0: int, ch: String, scene: PackedScene, dir: Vector2) -> void:
	var cells := []
	for r in 10:
		for c in range(x0, x0 + 8):
			if grid[r][c] == ch:
				cells.append(Vector2i(c, r))
	if cells.is_empty():
		return
	var lo: Vector2i = cells[0]
	var hi: Vector2i = cells[0]
	for v in cells:
		lo = Vector2i(mini(lo.x, v.x), mini(lo.y, v.y))
		hi = Vector2i(maxi(hi.x, v.x), maxi(hi.y, v.y))
	var z = scene.instantiate()
	z.position = Vector2(lo.x * T, lo.y * T)
	z.scale = Vector2((hi.x - lo.x + 1) * T / 32.0, (hi.y - lo.y + 1) * T / 96.0)
	if "direction" in z:
		z.direction = dir
		z.lift_accel = 200.0
	$Zones.add_child(z)


func _add_portals(grid: Array, x0: int) -> void:
	var entry := Vector2i(-1, -1)
	var exit := Vector2i(-1, -1)
	for r in 10:
		for c in range(x0, x0 + 8):
			if grid[r][c] == "P":
				entry = Vector2i(c, r)
			elif grid[r][c] == "Q":
				exit = Vector2i(c, r)
	if entry.x < 0 or exit.x < 0:
		return
	var out = PORTAL.instantiate()
	out.position = Vector2(exit * T)
	out.color = Color(0.3, 0.85, 0.95)
	var into = PORTAL.instantiate()
	into.position = Vector2(entry * T)
	into.color = out.color
	into.target = out
	$Portals.add_child(out)
	$Portals.add_child(into)


func _on_level_finished() -> void:
	Progress.record_round(round_number)


func _on_next_level_pressed() -> void:
	round_number += 1
	round_seed = randi() | 1
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_file_path)


static func start_new_run() -> void:
	round_number = 1
	round_seed = randi() | 1
