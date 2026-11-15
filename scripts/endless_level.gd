extends "res://scripts/level.gd"

const T := 16
const COLS := 20
const ROWS := 12
const FIRST_COL := 2
const LAST_COL := 17
const MIN_GROUND := 7
const MAX_GROUND := 10

const SPIKE := preload("res://scenes/entities/crystal_spike.tscn")
const CLING := preload("res://scenes/entities/cling_wall.tscn")
const LIFT := preload("res://scenes/entities/lift_zone.tscn")
const DRIFT := preload("res://scenes/entities/drift_zone.tscn")
const GRAPPLE := preload("res://scenes/entities/grapple_point.tscn")
const PLATFORM := preload("res://scenes/entities/moving_platform.tscn")
const PORTAL := preload("res://scenes/entities/portal.tscn")
const PROPS := [
	preload("res://assets/props/antenna_tower.png"),
	preload("res://assets/props/solar_panel.png"),
	preload("res://assets/props/fuel_tank.png"),
]

const PIECES := {
	"pit": {"min": 7, "max": 8},
	"wall": {"min": 6, "max": 7},
	"deadweight": {"min": 6, "max": 7},
	"climb": {"min": 7, "max": 7},
	"lift": {"min": 7, "max": 7},
	"swing": {"min": 7, "max": 8},
	"ferry": {"min": 7, "max": 8},
	"portal": {"min": 6, "max": 6},
	"wind": {"min": 7, "max": 8},
	"islands": {"min": 8, "max": 8},
	"step": {"min": 3, "max": 4},
	"gap": {"min": 4, "max": 5},
}
const DEATH_PIECES := ["pit", "wall", "deadweight"]
const NAMES := ["Crater Run", "Dust Drift", "Low Orbit", "Moon Maze", "Night Shift", "Echo Field",
		"Crystal Gap", "Far Side", "Static Sky", "Lost Signal", "Grey Sea", "Cold Light",
		"Ion Storm", "Glass Plain", "Hollow Ridge", "Slow Fall", "Black Tide", "Quiet Vent"]

static var round_number := 1
static var round_seed := 0
static var forced_pieces: Array = []
static var _recent: Array = []
static var _last_dark := false

var _rng := RandomNumberGenerator.new()
var _grid: Array = []
var _zones: Array = []
var _grapples: Array = []
var _platforms: Array = []
var _portals: Array = []
var _death_pieces := 0
var picks: Array = []


func _enter_tree() -> void:
	if round_seed == 0:
		round_seed = randi() | 1
	_rng.seed = round_seed + round_number * 7919
	_build_round()


func _build_round() -> void:
	_grid = []
	for r in ROWS:
		var row := []
		for c in COLS:
			row.append(".")
		_grid.append(row)
	var ground := _rng.randi_range(MAX_GROUND - 1, MAX_GROUND)
	_fill_ground(0, FIRST_COL - 1, ground)
	_grid[ground - 1][1] = "S"
	picks = _choose_pieces()
	var widths := _plan_widths(picks)
	var x := FIRST_COL
	for i in picks.size():
		ground = call("_piece_" + picks[i], x, widths[i], ground)
		x += widths[i]
	_fill_ground(x, COLS - 1, ground)
	_grid[ground - 2][18] = "E"
	_recent = picks.duplicate()
	set_meta("round", round_number)
	set_meta("number_label", "Round")
	set_meta("level_name", NAMES[_rng.randi() % NAMES.size()])
	set_meta("lives", 3 + _death_pieces * 2)
	var dark := round_number >= 4 and not _last_dark and _rng.randf() < 0.25
	_last_dark = dark
	set_meta("dark", dark)
	set_meta("light_radius", 48.0)
	_spawn_nodes()
	_reserve_space()
	_decorate()


func _choose_pieces() -> Array:
	if not forced_pieces.is_empty():
		return forced_pieces.duplicate()
	var budget := LAST_COL - FIRST_COL + 1
	var count := 2 if round_number <= 2 else _rng.randi_range(2, 3)
	var chosen := []
	chosen.append(_pick_from(DEATH_PIECES, chosen))
	var used: int = PIECES[chosen[0]].min
	var pool := PIECES.keys().filter(func(k): return k not in DEATH_PIECES)
	while chosen.size() < count and used < budget:
		var room := budget - used
		var fitting := pool.filter(func(k): return PIECES[k].min <= room and k not in chosen)
		if fitting.is_empty():
			break
		var name := _pick_from(fitting, chosen)
		chosen.append(name)
		used += PIECES[name].min
	if budget - used >= PIECES.step.min and "step" not in chosen and _rng.randf() < 0.6:
		chosen.append("step")
		used += PIECES.step.min
	if budget - used >= PIECES.gap.min and "gap" not in chosen and _rng.randf() < 0.5:
		chosen.append("gap")
	_shuffle_with_rng(chosen)
	return chosen


func _plan_widths(names: Array) -> Array:
	var widths := []
	var used := 0
	for name in names:
		widths.append(PIECES[name].min)
		used += PIECES[name].min
	var spare := (LAST_COL - FIRST_COL + 1) - used
	while spare > 0:
		var growable := []
		for i in names.size():
			if widths[i] < PIECES[names[i]].max:
				growable.append(i)
		if growable.is_empty():
			break
		widths[growable[_rng.randi() % growable.size()]] += 1
		spare -= 1
	return widths


func _pick_from(options: Array, chosen: Array) -> String:
	var fresh := options.filter(func(k): return k not in _recent and k not in chosen)
	var source := fresh if not fresh.is_empty() else options.filter(func(k): return k not in chosen)
	if source.is_empty():
		source = options
	return source[_rng.randi() % source.size()]


func _shuffle_with_rng(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _fill_ground(from_col: int, to_col: int, ground: int) -> void:
	for c in range(from_col, to_col + 1):
		for r in range(ground, ROWS):
			_grid[r][c] = "#"


func _spikes(from_col: int, to_col: int, ground: int) -> void:
	for c in range(from_col, to_col + 1):
		_grid[ground - 1][c] = "^"


func _block(col: int, top_row: int, bottom_row: int, ch := "#") -> void:
	for r in range(maxi(top_row, 0), bottom_row + 1):
		_grid[r][col] = ch


func _piece_pit(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_spikes(x + 1, x + w - 2, g)
	_death_pieces += 1
	return g


func _piece_gap(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_spikes(x + 1, x + w - 2, g)
	return g


func _piece_wall(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	var h := _rng.randi_range(4, mini(5, g - 2))
	var wall := x + 3
	_spikes(x + 1, x + 2, g)
	_block(wall, g - h, g - 1)
	_grid[g - h - 1][wall] = "^"
	if w >= 7 and _rng.randf() < 0.5:
		_block(wall + 1, g - h, g - 1)
		_grid[g - h - 1][wall + 1] = "^"
	_death_pieces += 1
	return g


func _piece_deadweight(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	var h := _rng.randi_range(4, mini(5, g - 3))
	_spikes(x + 2, x + 2, g)
	for c in range(x + 3, x + w - 1):
		_block(c, g - h, g - 1)
	_death_pieces += 1
	return g


func _piece_climb(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	var h := _rng.randi_range(4, mini(6, g - 3))
	_block(x + 4, g - h, g - 1, "L")
	_block(x + 5, g - h, g - 1)
	_block(x + 2, g - h, g - 3, "R")
	return g


func _piece_lift(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	var h := _rng.randi_range(4, mini(6, g - 3))
	var lx := x + 1
	_zones.append({"rect": Rect2i(lx, 2, 2, g - 2), "dir": Vector2.UP, "lift": true})
	if _rng.randf() < 0.6:
		for c in range(lx - 1, lx + 3):
			_block(c, 0, 0)
		_grid[1][lx] = "v"
		_grid[1][lx + 1] = "v"
	_block(x + 4, g - h, g - 1)
	_block(x + 5, g - h, g - 1)
	return g


func _piece_swing(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_spikes(x + 1, x + w - 2, g)
	var col := x + _rng.randi_range(2, w - 4)
	var row := g - _rng.randi_range(4, 5)
	_grapples.append(Vector2(col * T + 8, row * T + 8))
	return g


func _piece_ferry(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_spikes(x + 1, x + w - 2, g)
	var lift := _rng.randi_range(1, 2)
	_platforms.append({
		"pos": Vector2((x + 1) * T, (g - lift - 1) * T),
		"travel": Vector2((w - 4) * T, 0),
		"period": _rng.randf_range(3.2, 4.8),
		"pause": _rng.randf_range(0.9, 1.4),
	})
	return g


func _piece_portal(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_block(x + 3, 0, g - 1)
	var exit_row := _rng.randi_range(maxi(g - 7, 1), g - 4)
	_portals.append({"in": Vector2i(x + 1, g - 2), "out": Vector2i(x + 4, exit_row)})
	return g


func _piece_wind(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_spikes(x + 1, x + w - 2, g)
	_zones.append({"rect": Rect2i(x + 1, g - 6, w - 2, 5), "dir": Vector2.RIGHT, "lift": false})
	return g


func _piece_islands(x: int, w: int, g: int) -> int:
	_fill_ground(x, x + w - 1, g)
	_spikes(x + 1, x + w - 2, g)
	var a := g - _rng.randi_range(2, 3)
	var b := clampi(a + _rng.randi_range(-1, 1), g - 4, g - 2)
	_block(x + 2, a, a)
	_block(x + 5, b, b)
	return g


func _piece_step(x: int, w: int, g: int) -> int:
	var options := []
	for d in [-2, -1, 1, 2]:
		if g + d >= MIN_GROUND and g + d <= MAX_GROUND:
			options.append(d)
	var ng: int = g + options[_rng.randi() % options.size()]
	var split := x + w / 2
	_fill_ground(x, split - 1, g)
	_fill_ground(split, x + w - 1, ng)
	return ng


func _spawn_nodes() -> void:
	var ground: TileMapLayer = $Ground
	ground.clear()
	for r in ROWS:
		for c in COLS:
			var ch: String = _grid[r][c]
			var pos := Vector2(c * T, r * T)
			match ch:
				"#", "L", "R":
					ground.set_cell(Vector2i(c, r), 0, _autotile(c, r))
				"^":
					_add($Hazards, SPIKE, pos)
				"v":
					var s := _add($Hazards, SPIKE, pos + Vector2(T, T))
					s.rotation = PI
				"S":
					$Spawn.position = pos + Vector2(8, T)
					$Player.position = $Spawn.position
				"E":
					$ExitCapsule.position = pos
	_add_grips()
	for z in _zones:
		var rect: Rect2i = z.rect
		var node: Node2D = (LIFT if z.lift else DRIFT).instantiate()
		node.position = Vector2(rect.position * T)
		node.scale = Vector2(rect.size.x * T / 32.0, rect.size.y * T / 96.0)
		if not z.lift:
			node.direction = z.dir
			node.lift_accel = 200.0
		$Zones.add_child(node)
	for pos in _grapples:
		var g := GRAPPLE.instantiate()
		g.position = pos
		g.radius = 60.0
		$GrapplePoints.add_child(g)
	for p in _platforms:
		var plat := PLATFORM.instantiate()
		plat.position = p.pos
		plat.travel = p.travel
		plat.period = p.period
		plat.pause = p.pause
		$Platforms.add_child(plat)
	var colors := [Color(0.3, 0.85, 0.95), Color(1.0, 0.667, 0.157), Color(0.757, 0.373, 0.698)]
	for p in _portals:
		var color: Color = colors[_rng.randi() % colors.size()]
		var out := PORTAL.instantiate()
		out.position = Vector2(p.out * T)
		out.color = color
		var into := PORTAL.instantiate()
		into.position = Vector2(p.in * T)
		into.color = color
		into.target = out
		$Portals.add_child(out)
		$Portals.add_child(into)


func _add(parent: Node, scene: PackedScene, pos: Vector2) -> Node2D:
	var n: Node2D = scene.instantiate()
	n.position = pos
	parent.add_child(n)
	return n


func _solid(c: int, r: int) -> bool:
	if c < 0 or c >= COLS or r >= ROWS:
		return true
	if r < 0:
		return false
	return _grid[r][c] in ["#", "L", "R"]


func _autotile(c: int, r: int) -> Vector2i:
	var w := _solid(c - 1, r)
	var e := _solid(c + 1, r)
	var n := _solid(c, r - 1)
	var s := _solid(c, r + 1)
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


func _add_grips() -> void:
	for side in ["L", "R"]:
		for c in COLS:
			var r := 0
			while r < ROWS:
				if _grid[r][c] != side:
					r += 1
					continue
				var r0 := r
				while r < ROWS and _grid[r][c] == side:
					r += 1
				var g := CLING.instantiate()
				g.position = Vector2(c * T - 2 if side == "L" else (c + 1) * T + 2, r0 * T)
				g.scale = Vector2(1, (r - r0) * T / 48.0)
				$ClingWalls.add_child(g)


func _reserve_space() -> void:
	for z in _zones:
		var rect: Rect2i = z.rect
		for r in range(rect.position.y, rect.end.y):
			for c in range(rect.position.x, rect.end.x):
				if _grid[r][c] == ".":
					_grid[r][c] = "z"
	for p in _portals:
		for cell in [p.in, p.out]:
			for r in range(cell.y, cell.y + 2):
				if _grid[r][cell.x] == ".":
					_grid[r][cell.x] = "z"
	for p in _platforms:
		var row := int(p.pos.y / T)
		for c in range(int(p.pos.x / T), int((p.pos.x + p.travel.x) / T) + 2):
			for r in range(maxi(row - 2, 0), row + 1):
				if _grid[r][c] == ".":
					_grid[r][c] = "z"
	for pos in _grapples:
		var cell := Vector2i(pos / T)
		for r in range(maxi(cell.y - 1, 0), mini(cell.y + 6, ROWS)):
			for c in range(maxi(cell.x - 3, 0), mini(cell.x + 4, COLS)):
				if _grid[r][c] == ".":
					_grid[r][c] = "z"


func _decorate() -> void:
	var earth: Sprite2D = $Decor/Earth
	earth.visible = _rng.randf() < 0.8
	earth.position = Vector2(_rng.randf_range(20, 270), _rng.randf_range(4, 30)).round()
	var spots := []
	for c in range(2, LAST_COL):
		var top := -1
		for r in ROWS:
			if _grid[r][c] == "#":
				top = r
				break
		if top < 4:
			continue
		var clear := true
		for r in range(top - 4, top):
			for cc in [c - 1, c, c + 1]:
				if _grid[r][cc] != ".":
					clear = false
		if clear:
			spots.append(Vector2i(c, top))
	_shuffle_with_rng(spots)
	var wanted := _rng.randi_range(1, 3)
	for spot in spots.slice(0, wanted):
		var tex: Texture2D = PROPS[_rng.randi() % PROPS.size()]
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2(0.25, 0.25)
		s.centered = false
		var size := tex.get_size() * 0.25
		s.position = Vector2(spot.x * T + (T - size.x) * 0.5, spot.y * T - size.y).round()
		s.modulate = Color(0.85, 0.88, 1.0, 0.9)
		$Decor.add_child(s)


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
	_recent = []
	_last_dark = false
