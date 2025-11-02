extends GraphEdit

@onready var connection_color := Color(0.9, 0.9, 0.9, 0.9)
@onready var connection_thickness := 3.0

func _ready():
	set_clip_contents(false)
	queue_redraw()

func _process(_delta):
	queue_redraw()

func _draw():
	_draw_connections_behind_nodes()
	# GraphNodes werden nach dem Control-Rendering gezeichnet, also erscheinen sie oben


func _draw_connections_behind_nodes():
	var connections = get_connection_list()
	if connections.is_empty():
		return

	for conn in connections:
		var from_name: String = str(conn.from_node)
		var to_name: String = str(conn.to_node)

		var from_node := get_node_or_null(from_name)
		var to_node := get_node_or_null(to_name)
		if not from_node or not to_node:
			continue

		# Positionen der Ports berechnen
		var from_slot_pos = _get_slot_position(from_node, conn.from_port, true)
		var to_slot_pos = _get_slot_position(to_node, conn.to_port, false)

		# Gerade Linie zeichnen
		draw_line(from_slot_pos, to_slot_pos, connection_color, connection_thickness)


# Berechnet lokale Position eines Input/Output-Ports in GraphNode
func _get_slot_position(node: GraphNode, port_index: int, is_output: bool) -> Vector2:
	var port_offset_y := 0.0
	var x
	var y
	if is_output:
		if node.has_method("get_connection_output_height"):
			port_offset_y = node.get_connection_output_height(port_index)
		else:
			port_offset_y = 16 + port_index * 20
		x = node.get_size().x
		y = port_offset_y
	else:
		if node.has_method("get_connection_input_height"):
			port_offset_y = node.get_connection_input_height(port_index)
		else:
			port_offset_y = 16 + port_index * 20
		x = 0.0
		y = port_offset_y

	# In Godot 4 ist node.position die Position im GraphEdit
	var node_pos: Vector2
	if "position" in node:
		node_pos = node.position
	else:
		node_pos = node.get_position()

	return node_pos + Vector2(x, y)
