extends Area2D
class_name PlacementArea2D

@export_group("Placement Settings")
@export var max_capacity : int = 1 ## Maximum number of objects this area can hold at once
@export var spacing : float = 60.0 ## Distance between held objects when snap_to_layout is true
@export var horizontal_layout : bool = true ## If true, objects are laid out in a row; if false, in a column

## TOGGLE: If true, card slides to the layout position. If false, card stays exactly where dropped.
@export var snap_to_layout : bool = false

@export_group("Class Filter")
@export var accepted_classes : Array[String] = ["PlaceAbleUIObject2D"] ## If non-empty, only objects whose class_name is in this list are accepted
@export var rejected_classes : Array[String] = [] ## Objects whose class_name is in this list are always rejected

@export_group("Interaction Settings")
@export var lock_cards_on_drop : bool = false ## Disable dragging for objects after they are placed here

signal object_snapped(obj: Node2D) ## Emitted when an object is successfully snapped into this area
signal object_removed(obj: Node2D) ## Emitted when an object leaves this area
signal area_full ## Emitted when the area reaches max_capacity
signal area_emptied ## Emitted when the last held object leaves the area

var held_objects : Array[Node2D] = []

func _ready() -> void:
	monitoring = true
	monitorable = true
	child_exiting_tree.connect(_on_child_exited)

func is_full() -> bool: ## Returns true when the number of held objects has reached max_capacity
	return held_objects.size() >= max_capacity

func can_accept(obj: Node2D) -> bool: ## Returns false if obj's class is rejected or not in the accepted list
	var cn := _get_object_class_name(obj)
	if rejected_classes.size() > 0 and cn in rejected_classes:
		return false
	if accepted_classes.size() > 0 and cn not in accepted_classes:
		return false
	return true

func _get_object_class_name(obj: Node) -> String:
	var script = obj.get_script()
	if script and script.get_global_name() != "":
		return script.get_global_name()
	return obj.get_class()

func snap_object(obj: Node2D) -> void: ## Reparents obj into this area, preserving its world position, then optionally snaps to the layout
	if is_full() or obj in held_objects or not can_accept(obj): return

	# 1. Reparent while keeping the object's exact world position
	obj.reparent(self, true)
	obj.z_index = 1
	held_objects.append(obj)

	# 2. Update the Mover's Target
	if snap_to_layout:
		_update_layout_targets()
	else:
		_sync_mover_to_current(obj)
	
	# 5. Connect signals for removal/dragging
	_connect_drag_signals(obj)
	object_snapped.emit(obj)
	if is_full():
		area_full.emit()

func _update_layout_targets() -> void:
	var count = held_objects.size()
	for i in range(count):
		# Calculate where this specific slot is in local space
		var offset_val = (i - (count - 1) / 2.0) * spacing
		var target_local = Vector2(offset_val, 0) if horizontal_layout else Vector2(0, offset_val)
		
		# Convert that slot to a Global Position
		var target_global = global_position + target_local
		
		# Update the SmoothMovement target
		var card = held_objects[i]
		var mover = card.get_node_or_null("SmoothMovement")
		if mover:
			mover.global_target_position = target_global
		else:
			# Fallback if no mover exists
			card.global_position = target_global

func _sync_mover_to_current(obj: Node2D) -> void:
	var mover = obj.get_node_or_null("SmoothMovement")
	if mover:
		mover.global_target_position = obj.global_position

func _connect_drag_signals(obj: Node2D) -> void:
	var drag_node = _get_drag_component(obj)
	if drag_node:
		# Tell the drag node its new rest position is here
		if drag_node.has_method("force_set_target"):
			drag_node.force_set_target(obj.global_position)
			
		if not drag_node.is_connected("object_picked_up", _on_object_removed):
			drag_node.object_picked_up.connect(_on_object_removed.bind(obj))

# Ensure layout updates when cards are removed
func _on_object_removed(obj: Node2D) -> void:
	if obj in held_objects:
		held_objects.erase(obj)
		object_removed.emit(obj)
		if held_objects.is_empty():
			area_emptied.emit()
		# ... (your existing reparenting logic to scene tree) ...
		if snap_to_layout:
			_update_layout_targets()

func _apply_layout_positions() -> void:
	var count = held_objects.size()
	for i in range(count):
		# Calculate the local target based on spacing
		var offset_val = (i - (count - 1) / 2.0) * spacing
		var target_local_pos = Vector2(offset_val, 0) if horizontal_layout else Vector2(0, offset_val)
		
		# Convert to Global Position
		var target_global_pos = global_position + target_local_pos
		
		# Update the mover or the position directly
		var card = held_objects[i]
		if card.has_node("SmoothMovement"):
			card.get_node("SmoothMovement").global_target_position = target_global_pos
		else:
			card.global_position = target_global_pos

func _force_stop_movers(obj: Node2D) -> void:
	# Keep the card exactly where it was dropped
	if obj.has_node("SmoothMovement"):
		obj.get_node("SmoothMovement").global_target_position = obj.global_position

func _on_child_exited(node: Node) -> void:
	if node is Node2D and node in held_objects:
		held_objects.erase(node)
		object_removed.emit(node as Node2D)
		if held_objects.is_empty():
			area_emptied.emit()
		if snap_to_layout:
			_apply_layout_positions()

func _realign_children_smoothly() -> void:
	var count = held_objects.size()
	for i in range(count):
		var offset_val = (i - (count - 1) / 2.0) * spacing
		var target_local_pos = Vector2(offset_val, 0) if horizontal_layout else Vector2(0, offset_val)
		
		# Kill existing tweens on this object to prevent conflicts
		var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(held_objects[i], "position", target_local_pos, 0.3)
		
		# Sync the smooth mover's target so it doesn't fight the tween
		if held_objects[i].has_node("SmoothMovement"):
			var mover = held_objects[i].get_node("SmoothMovement")
			# We set the target to the local pos converted back to global
			mover.global_target_position = global_position + target_local_pos

func _get_drag_component(node: Node) -> DragWithMouse:
	for child in node.get_children():
		if child is DragWithMouse:
			return child
	return null
