extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Back button is connected in the editor (Node tab > Signals)




func _on_back_button_pressed() -> void:
	SceneHistory.go_back()
