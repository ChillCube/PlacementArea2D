extends Area2D
class_name PlacementArea2D

@export var occupied : bool = false
var held_object : Node2D = null

func _ready() -> void:
	# Connect our own area signals to detect incoming draggables
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if occupied: return
	
	# Look for the DragWithMouse component on the incoming object
	# We search the area's parent or the area itself
	var drag_component = _find_drag_component(area)
	
	if drag_component:
		# If we found the component, listen for when the player lets go
		if not drag_component.is_connected("object_placed", _on_drag_released):
			drag_component.object_placed.connect(_on_drag_released.bind(drag_component, area.get_parent()), CONNECT_ONE_SHOT)

func _on_area_exited(area: Area2D) -> void:
	var drag_component = _find_drag_component(area)
	if drag_component and drag_component.is_connected("object_placed", _on_drag_released):
		drag_component.object_placed.disconnect(_on_drag_released)

func _find_drag_component(area: Area2D) -> DragWithMouse:
	# We look at the children of the object (the parent of the collision area)
	var parent = area.get_parent()
	for child in parent.get_children():
		if child is DragWithMouse:
			return child
	return null

func _on_drag_released(drag_node: DragWithMouse, object_to_snap: Node2D) -> void:
	# Double check proximity/occupancy at the moment of release
	if occupied: return
	
	snap_object(object_to_snap)

func snap_object(obj: Node2D) -> void:
	held_object = obj
	occupied = true
	
	# 1. Try to find the drag component safely
	var drag_node = _get_drag_component(obj)
	
	# 2. Universal Snap logic
	if obj.has_method("move_to_position"):
		obj.call("move_to_position", global_position)
	else:
		# If the object doesn't have a move method, we force the drag node's 
		# target_position so it doesn't try to fly back to where the mouse was.
		if drag_node:
			drag_node.target_position = global_position
		obj.global_position = global_position

	# 3. Listen for the object being picked up again
	if drag_node:
		# Double check connection to prevent duplicate signal errors
		if not drag_node.is_connected("object_picked_up", _on_object_picked_up):
			drag_node.object_picked_up.connect(_on_object_picked_up, CONNECT_ONE_SHOT)

## Helper function to avoid the find_child parse errors
func _get_drag_component(node: Node) -> DragWithMouse:
	for child in node.get_children():
		if child is DragWithMouse:
			return child
	return null

func _on_object_picked_up() -> void:
	held_object = null
	occupied = false
