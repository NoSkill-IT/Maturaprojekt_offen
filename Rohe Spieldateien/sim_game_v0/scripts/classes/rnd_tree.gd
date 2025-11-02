extends Object
class_name rnd_tree
var requirements: Array
var root_node: rnd_node
var all_nodes: Array
var game_ref
var all_nodes_names: Array
var root_node_name
var id
var num_id
func _init(gr, id_) -> void:
	id = id_
	game_ref = gr
	var saved_info = Utility.read_to_dict("user://saves/slot_{0}/rnd/{1}.json".format({"0":Utility.selected_slot,"1":id}))
	var res_info = Utility.read_to_dict("res://data/rnd/trees/{0}.json".format({"0":id}))
	num_id = res_info["num_id"]
	for i in res_info["tree_members"]:
		all_nodes.append([])
		all_nodes_names.append([])
		for j in i:
			all_nodes_names[-1].append(j)
			all_nodes[-1].append(rnd_node.new(game_ref,j,saved_info[j],self))
	root_node = all_nodes[0][0]
	root_node_name = all_nodes_names[0][0]
	
	
func execute_effects(ctime):
	for i in all_nodes:
		for j in i:
			if j.unlocked and j.active:
				j.execute(ctime)
			
func save():
	var save_dict = {}
	for i in range(all_nodes.size()):
		for j in range(all_nodes[i].size()):
			save_dict[all_nodes_names[i][j]] = all_nodes[i][j].save()
	Utility.save_to_file("user://saves/slot_{0}/rnd/{1}.json".format({"0":Utility.selected_slot,"1":id}),save_dict)
			
