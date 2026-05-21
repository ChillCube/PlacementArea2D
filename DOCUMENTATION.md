# PlacementArea2D API Reference
Generated: 2026-05-20

a node that lets you define areas to place objects (like cards) onto the screen

## Class: PlacementArea2D
@export
@export
	var
func
**Inherits:** [Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html)


### ⚙️ Inspector Variables (Exported)
| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| **max_capacity** | `int` | `1` | Maximum number of objects this area can hold at once |
| **spacing** | `float` | `60.0` | Distance between held objects when snap_to_layout is true |
| **horizontal_layout** | `bool` | `true` | If true, objects are laid out in a row; if false, in a column |
| **accepted_classes** | `Array[String]` | `["PlaceAbleUIObject2D"]` | If non-empty, only objects whose class_name is in this list are accepted |
| **rejected_classes** | `Array[String]` | `[]` | Objects whose class_name is in this list are always rejected |
| **lock_cards_on_drop** | `bool` | `false` | Disable dragging for objects after they are placed here |

### 🔔 Signals
| Signal | Arguments | Description |
| :--- | :--- | :--- |
| **object_snapped** | `obj: Node2D` |  Emitted when an object is successfully snapped into this area |
| **object_removed** | `obj: Node2D` |  Emitted when an object leaves this area |
| **area_full** | - |  Emitted when the area reaches max_capacity |
| **area_emptied** | - |  Emitted when the last held object leaves the area |

### 🛠️ Methods
| Method | Arguments | Returns | Description |
| :--- | :--- | :--- | :--- |
| **is_full()** | - | `bool` |  Returns true when the number of held objects has reached max_capacity |
| **can_accept()** | `obj: Node2D` | `bool` |  Returns false if obj's class is rejected or not in the accepted list |
| **snap_object()** | `obj: Node2D` | `void` |  Reparents obj into this area, preserving its world position, then optionally snaps to the layout |

---

