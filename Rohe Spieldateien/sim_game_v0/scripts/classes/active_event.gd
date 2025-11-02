extends Object
class_name active_event
var game_ref
var stages: Array
var current_stage: int
var started_on_turn: int
var total_stages
var event_id: int
var name: String
var excludes: Array
func _init(game_ref_, e_id: int, name_: String = "",stages_: Array= [], current: int = 0, started: int = 0, excludes_: Array = []):
	game_ref = game_ref_
	name = name_
	excludes = excludes_
	current_stage = current
	started_on_turn = started
	stages = stages_
	event_id = e_id
	total_stages = stages.size()
	
func execute_current_stage_effects():
	for i in stages[current_stage]:
		i.execute()


func get_save_dict():
	var save_dict = {}
	save_dict["event_name"] = name
	save_dict["start_turn"] = started_on_turn
	save_dict["excludes"] = excludes
	save_dict["event_id"] = event_id
	save_dict["current_stage"] = current_stage + 1
	var stages_dicts = []
	for i in stages:
		stages_dicts.append([])
		for j:effect in i:
			if j.effect_type == "func":
				stages_dicts[stages_dicts.size()-1].append({"function_name":j.function, "parameters":j.parameters,"effect_type":j.effect_type,"execution_time":j.execution_time})
			else:
				stages_dicts[stages_dicts.size()-1].append({"variable_name":j.variable, "new_value":j.value,"effect_type":j.effect_type,"execution_time":j.execution_time})
	save_dict["stages"] = stages_dicts
	Utility.save_to_file("user://saves/slot_{0}/events/{1}.json".format({"0":Utility.selected_slot,"1":int(event_id)}),save_dict)
