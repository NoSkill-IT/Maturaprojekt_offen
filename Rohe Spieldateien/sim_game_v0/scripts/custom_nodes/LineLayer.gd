extends Control
# LineLayer zeichnet die Linien hinter den GraphNodes.
# Dieses Script ist unabhängig pro rnd_tab-Instanz, damit mehrere Tabs parallel sauber arbeiten.

@export var line_color: Color = Color(1,1,1)
@export var line_width: float = 3.0

var tree_ref = null            # Wird von rnd_tab gesetzt
var coordinates_dict = null    # Wird von rnd_tab gesetzt
var graph_ref = null           # Wird von rnd_tab gesetzt
var node_half_size := Vector2(100, 50) # half of node size; anpassen falls nötig

func _ready() -> void:
	# Startgröße auf GraphEdit anpassen (falls GraphEdit schon Layout hat)
	if graph_ref:
		size = graph_ref.size

func _process(delta: float) -> void:
	# Nur neu zeichnen, wenn dieses Layer sichtbar ist (verhindert Linien in hinteren Tabs)
	if not is_visible_in_tree():
		return
	# Synce Größe mit GraphEdit (falls sich Fenster/Container ändert)
	if graph_ref and size != graph_ref.size:
		size = graph_ref.size
	# Nur zeichnen, wenn wir alle Referenzen haben
	if tree_ref and coordinates_dict and graph_ref:
		queue_redraw()

func _draw() -> void:
	# Zeichne nur wenn sichtbar (zusätzliche Absicherung) und Daten vorhanden sind
	if not is_visible_in_tree():
		return
	if not tree_ref or not coordinates_dict or not graph_ref:
		return

	var zoom = graph_ref.zoom
	var offset = -graph_ref.scroll_offset

	for i in range(tree_ref.all_nodes.size()):
		for node_data in tree_ref.all_nodes[i]:
			for parent_id in node_data.parents:
				if not coordinates_dict.has(parent_id):
					continue

				var from_pos = coordinates_dict[parent_id]
				var to_pos = coordinates_dict[node_data.id]

				# Mittelpunkt (korrigierbar, wenn Node-Größe sich ändert)
				var from_center = from_pos + node_half_size
				var to_center = to_pos + node_half_size

				# transformiere mit Scroll/Zoom (GraphEdit-Koordinatensystem)
				var a = (from_center + offset) * zoom
				var b = (to_center + offset) * zoom

				# Sichtbarkeit prüfen: nur zeichnen, wenn Segment mindestens teilweise in rect (optional)
				# if not _segment_visible(a, b):
				#     continue

				draw_line(a, b, line_color, line_width)

# Optional helper: prüft ob Linie wenigstens teilweise im sichtbaren Layer liegt.
func _segment_visible(a: Vector2, b: Vector2) -> bool:
	var r = Rect2(Vector2.ZERO, size)
	if r.has_point(a) or r.has_point(b):
		return true
	# einfache Bounding-Box-Check
	var minx = min(a.x, b.x)
	var maxx = max(a.x, b.x)
	var miny = min(a.y, b.y)
	var maxy = max(a.y, b.y)
	return r.intersects(Rect2(Vector2(minx, miny), Vector2(maxx-minx, maxy-miny)))
