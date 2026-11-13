extends Marker3D

@export var toiletPaper: PackedScene
@export_range(0.1, 5.0, 0.1) var check_interval: float = 0.5

var _check_timer: float = 0.0


func _ready() -> void:
	call_deferred("_check_and_spawn")


func _process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = check_interval
		_check_and_spawn()


func _check_and_spawn() -> void:
	if toiletPaper == null:
		return
	# Search the entire active scene for existing toilet paper.
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root == null:
		return
	if _contains_toilet_paper(scene_root):
		return
	# Instantiate a replacement.
	var tp = toiletPaper.instantiate()
	if not tp is ToiletPaper:
		push_error("Soft-lock protection: Spawned scene is not a ToiletPaper!")
		tp.free()
		return
	# Add it to the marker's parent before setting its global position.
	var spawn_parent := get_parent()
	if spawn_parent == null:
		spawn_parent = scene_root
	spawn_parent.add_child(tp)
	# Match the Marker3D's global transform.
	tp.global_transform = global_transform
	print("Soft-lock protection: Spawned toilet paper at ", tp.global_position)


func _contains_toilet_paper(node: Node) -> bool:
	# Check this node.
	if node is ToiletPaper and not node.is_queued_for_deletion():
		return true
	# Recursively check all children.
	for child in node.get_children():
		if _contains_toilet_paper(child):
			return true
	return false
