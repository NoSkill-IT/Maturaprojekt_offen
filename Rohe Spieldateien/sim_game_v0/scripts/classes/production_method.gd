extends Object
class_name production_method
var ingredient_per_kg
var required_workers_per_machine
var output_per_hour
var active_machines
var price_per_machine
var unlocked_machines
var maintenance_cost
var quality_modifier
var unlocked
var id
var game_ref
var priority

func _init(gr,id_) -> void:
	id = id_
	game_ref = gr
	var saved_data
	if FileAccess.file_exists("user://saves/slot_{0}/production_methods/{1}.json".format({"0":Utility.selected_slot,"1":id})):
		saved_data = Utility.read_to_dict("user://saves/slot_{0}/production_methods/{1}.json".format({"0":Utility.selected_slot,"1":id}))
	else:
		saved_data = Utility.read_to_dict("res://data/production_methods/{0}.json".format({"0":id}))
	print(saved_data)
	required_workers_per_machine = int(saved_data["rwpm"])
	unlocked = saved_data["unlocked"]
	output_per_hour = saved_data["kgph"]
	active_machines = int(saved_data["active_machines"])
	price_per_machine = saved_data["price_per_machine"]
	unlocked_machines = int(saved_data["unlocked_machines"])
	maintenance_cost = int(saved_data["maintenance_cost"])
	ingredient_per_kg = saved_data["ingredients"]
	quality_modifier = saved_data["quality_modifier"]
	priority = saved_data["priority"]
	print(typeof(self))
	
func maintenance():
	game_ref.player_money -= active_machines*maintenance_cost





func save():
	var save_dict = {}
	save_dict["rwpm"] = required_workers_per_machine
	save_dict["kgph"] = output_per_hour
	save_dict["unlocked_machines"] = unlocked_machines
	save_dict["active_machines"] = active_machines	
	save_dict["price_per_machine"] = price_per_machine
	save_dict["unlocked_machines"] = unlocked_machines
	save_dict["maintenance_cost"] = maintenance_cost
	save_dict["ingredients"] = ingredient_per_kg
	save_dict["quality_modifier"] = quality_modifier
	save_dict["unlocked"] = unlocked
	save_dict["priority"] = priority
	Utility.save_to_file("user://saves/slot_{0}/production_methods/{1}.json".format({"0":Utility.selected_slot,"1":id}),save_dict)
