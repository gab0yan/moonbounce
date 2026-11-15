extends Node

const HOVER_SCALE := 1.06
const PRESS_SCALE := 0.9
const NAV_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev"]
const PREFERRED := ["ContinueButton", "PlayButton", "NextLevelButton", "RetryButton", "ResumeButton"]
const OVERLAYS := ["PauseMenu", "LevelComplete", "OutOfLives"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or get_viewport().gui_get_focus_owner() != null:
		return
	for name in OVERLAYS:
		var overlay := scene.get_node_or_null(name)
		if overlay and overlay.visible:
			var first := _first_button(overlay)
			if first:
				first.grab_focus()
			return


func _on_node_added(node: Node) -> void:
	if not (node is BaseButton) or node.has_meta("ui_fx"):
		return
	node.set_meta("ui_fx", true)
	node.resized.connect(func(): node.pivot_offset = node.size * 0.5)
	node.mouse_entered.connect(_grow.bind(node, true))
	node.mouse_exited.connect(_grow.bind(node, false))
	node.button_down.connect(_press.bind(node))


func _tween_for(node: Control) -> Tween:
	var old: Tween = node.get_meta("ui_tween", null)
	if old and old.is_valid():
		old.kill()
	var t := node.create_tween()
	node.set_meta("ui_tween", t)
	return t


func _grow(node: BaseButton, on: bool) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var target := Vector2.ONE * HOVER_SCALE if (on and not node.disabled) else Vector2.ONE
	_tween_for(node).tween_property(node, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _press(node: BaseButton) -> void:
	if node.disabled:
		return
	node.scale = Vector2.ONE * PRESS_SCALE
	var rest := Vector2.ONE * HOVER_SCALE if node.is_hovered() else Vector2.ONE
	_tween_for(node).tween_property(node, "scale", rest, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent) -> void:
	var scene := get_tree().current_scene
	if scene and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		var complete = scene.get("level_complete")
		var lost = scene.get("out_of_lives")
		if (complete and complete.visible) or (lost and lost.visible):
			get_viewport().set_input_as_handled()
			scene._restart()
			return
	if get_viewport().gui_get_focus_owner() != null:
		return
	for action in NAV_ACTIONS:
		if event.is_action_pressed(action):
			var first := _first_button(get_tree().root)
			if first:
				first.grab_focus()
				get_viewport().set_input_as_handled()
			return


func focus_first_in(root: Node) -> void:
	var first := _first_button(root)
	if first:
		first.grab_focus.call_deferred()


func _first_button(root: Node) -> BaseButton:
	var buttons := root.find_children("*", "BaseButton", true, false)
	var usable := buttons.filter(func(b): return b.is_visible_in_tree() and not b.disabled and b.focus_mode != Control.FOCUS_NONE)
	for name in PREFERRED:
		for b in usable:
			if b.name == name:
				return b
	return usable[0] if not usable.is_empty() else null
