extends Control
class_name rnd_tab

var tree: rnd_tree
var tree_id: String
var game_ref
var node_dict: Dictionary = {}
var coordinates_dict: Dictionary = {}

signal node_pressed(node_id, tree_id, i, j)

@onready var graph: GraphEdit = $graph
@onready var line_layer: Control = $graph/LineLayer


func setup(tree_: rnd_tree, gr, tree_id_, lang_dict) -> void:
	game_ref = gr
	tree = tree_
	tree_id = tree_id_

	node_dict.clear()
	coordinates_dict.clear()

	# Alte GraphNodes löschen
	for child in graph.get_children():
		if child is GraphNode:
			child.queue_free()

	# GraphEdit konfigurieren
	graph.show_grid = true
	graph.minimap_enabled = true
	graph.scroll_offset = Vector2.ZERO
	graph.zoom = 1.0
	graph.zoom_min = 0.3
	graph.zoom_max = 2.5
	graph.zoom_step = 1.1
	graph.right_disconnects = false
	graph.mouse_filter = Control.MOUSE_FILTER_STOP
	graph.mouse_default_cursor_shape = Control.CURSOR_MOVE
	graph.clip_contents = true
	var max_column_size = 0
	for i in tree.all_nodes:
		max_column_size = max(max_column_size,(i.size()-1)*200)
	# Nodes erstellen & Positionen speichern
	for i in range(tree.all_nodes.size()):
		for j in range(tree.all_nodes[i].size()):
			var node_data: rnd_node = tree.all_nodes[i][j]
			var nid = node_data.id

			var gnode := GraphNode.new()
			gnode.name = nid
			gnode.title = lang_dict[nid]["name"]
			gnode.draggable = false
			gnode.visible = true

			# Style
			var sb := StyleBoxFlat.new()
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.border_width_left = 2
			sb.border_color = Color(1, 1, 1, 0.3)
			if node_data.active:
				sb.bg_color = Color(0.2, 0.7, 0.2)
			elif node_data.unlocked:
				sb.bg_color = Color(0.2, 0.4, 0.8)
			elif node_data.check_buy_availability():
				sb.bg_color = Color(0.8, 0.8, 0.8)
			else:
				sb.bg_color = Color(0.7, 0.0, 0.0)
			gnode.add_theme_stylebox_override("panel", sb)
			
			# Größe und Position
			gnode.custom_minimum_size = Vector2(200, 100)
			var pos = Vector2(i * 400, max_column_size/2-(tree.all_nodes[i].size()-1)*100+j*200)
			gnode.position_offset = pos
			coordinates_dict[nid] = pos

			# Slots & Button
			gnode.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
			var btn := Button.new()
			btn.text = "Select"
			btn.size_flags_horizontal = Control.SIZE_FILL
			btn.connect("pressed", Callable(self, "_on_graph_node_pressed").bind(nid, i, j))
			gnode.add_child(btn)

			graph.add_child(gnode)
			node_dict[nid] = node_data

	# sicherstellen, dass GraphEdit Layout gemacht hat
	await get_tree().process_frame
	await get_tree().process_frame

	# LineLayer mit Referenzen versorgen (pro Instanz)
	if line_layer:
		# type-cast: das Layer-Skript erwartet diese Felder
		line_layer.set("tree_ref", tree)
		line_layer.set("coordinates_dict", coordinates_dict)
		line_layer.set("graph_ref", graph)
		# Node-Halbgröße anpassen falls du andere Node-Größe verwendest:
		# line_layer.set("node_half_size", Vector2(gnode.custom_minimum_size.x/2, gnode.custom_minimum_size.y/2))
		# Größe synchronisieren
		line_layer.size = graph.size

	# initiales Redraw nur wenn sichtbar
	if line_layer.is_visible_in_tree():
		line_layer.queue_redraw()

	update_nodes(tree)
	_center_view_on_graph()


func _on_graph_node_pressed(nid: String, i: int, j: int) -> void:
	emit_signal("node_pressed", nid, tree_id, i, j)


func update_nodes(tree_) -> void:
	tree = tree_
	for nid in node_dict.keys():
		if not graph.has_node(nid):
			continue
		var data: rnd_node = node_dict[nid]
		var node: GraphNode = graph.get_node(nid)
		var sb := StyleBoxFlat.new()
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_width_left = 2
		sb.border_color = Color(1, 1, 1, 0.3)
		if data.active:
			sb.bg_color = Color(0.2, 0.7, 0.2)
		elif data.unlocked:
			sb.bg_color = Color(0.2, 0.4, 0.8)
		elif data.check_buy_availability():
			sb.bg_color = Color(0.8, 0.8, 0.8)
		else:
			sb.bg_color = Color(0.7, 0.0, 0.0)
		node.remove_theme_stylebox_override("panel")
		node.add_theme_stylebox_override("panel", sb)


func _center_view_on_graph() -> void:
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)

	for n in graph.get_children():
		if n is GraphNode:
			var p = n.position_offset
			min_pos.x = min(min_pos.x, p.x)
			min_pos.y = min(min_pos.y, p.y)
			max_pos.x = max(max_pos.x, p.x + n.size.x)
			max_pos.y = max(max_pos.y, p.y + n.size.y)

	if min_pos.x == INF:
		return

	var graph_size := graph.custom_minimum_size
	var center := (min_pos + max_pos) * 0.5
	graph.scroll_offset = center - graph_size * 0.5
