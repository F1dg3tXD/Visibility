extends Area3D

@export_enum("Win", "Loose", "Why", "Death") var ending_type: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("show_ending"):
		body.show_ending(ending_type)
