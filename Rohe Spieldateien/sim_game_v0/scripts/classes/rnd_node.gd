extends Object
class_name rnd_node
var game_ref
var buy_available: bool
var base_price: float
var price_modifier
var parents
var total_upgrade_time: float
var upgrade_time_left: float
var buy_requirements
var unlocked: bool
var active: bool
var effects: Array[effect]
var base_success_probability: float
var success_probability_modifier: float
var parents_required: Array
var id
var tree_id
var employee_type
var auto_activate
func check_buy_availability():
	buy_available = buy_requirements.is_met() and (base_price*price_modifier <= game_ref.player_money)
	return buy_available


func _init(gr,id_,saved_data,tree):
	id = id_
	print(id)
	var data = Utility.read_to_dict("res://data/rnd/nodes/{0}.json".format({"0":id}))
	base_price = data["base_price"]
	price_modifier = saved_data["price_modifier"]
	parents = data["parents"]
	if parents != []:
		parents_required = data["parent_requirement_type"]
	total_upgrade_time = data["upgrade_time"]
	if saved_data["upgrade_time_left"] == 0 and not saved_data["unlocked"]:
		upgrade_time_left = data["upgrade_time"]
	else:
		upgrade_time_left = saved_data["upgrade_time_left"]
	if total_upgrade_time > 0:
		employee_type = data["employee_type"]
	unlocked = saved_data["unlocked"]
	active = saved_data["active"]
	base_success_probability = data["base_success_probability"]
	success_probability_modifier = saved_data["success_probability_modifier"]
	game_ref = gr
	auto_activate = data["auto_activate"]
	buy_requirements = create_requirement(data["buy_requirements"])
	if parents != []:
		var _update_requirements = []
		for i in parents:
			var j = -1
			var k = -1
			for l in range(tree.all_nodes_names.size()):
				for m in range(tree.all_nodes_names[l].size()):
					if tree.all_nodes_names[l][m] == i:
						j = l
						k = m
						break
				if j != -1:
					break
			_update_requirements.append(requirement.new("rnd_trees.{0}.all_nodes.{1}.{2}.unlocked".format({"0":tree.id,"1":j,"2":k}),"==",true,game_ref))
		var _update_requirements_linked = 	req_link.new(_update_requirements,parents_required[0], parents_required[1])
		buy_requirements = req_link.new([buy_requirements,_update_requirements_linked],"and")
		buy_requirements.simplify()
	var count = 0
	if data["start_unlocked"]:
		unlocked = true
		if auto_activate:
			active = true
	for i in data["effects"]:
		if i["effect_type"] == "func":
			effects.append(effect.new(i["effect_type"],game_ref,id,saved_data["executed"][count],"",0,"",i["function"],i["parameters"],create_requirement(i["effect_requirements"]),saved_data["time_since_last_execution"][count],i["period"]))
		else:
			effects.append(effect.new(i["effect_type"],game_ref,id,saved_data["executed"][count],i["variable"],i["value"],i["op"],"",[],create_requirement(i["effect_requirements"]),saved_data["time_since_last_execution"][count],i["period"]))
func create_requirement(dict):
	if dict["type"] == "none":
		return req_link.new([],"none")
	if dict["type"] == "req":
		return requirement.new(dict["variable"],dict["comp"],dict["value"], game_ref)
	var reqs = []
	for i in dict["requirements"]:
		reqs.append(create_requirement(i))
	if dict["link_type"] == "x_of":
		return req_link.new(reqs,dict["link_type"],dict["link_num"])
	return req_link.new(reqs,dict["link_type"])

	
func buy():
	game_ref.player_money -= base_price*price_modifier
	game_ref.money_trace[5][1].append([id,game_ref.player_money,"rnd_node"])
	upgrade_time_left = total_upgrade_time
	if upgrade_time_left == 0:
		unlock()
		
func progress(progress_):
	upgrade_time_left -= progress_
	if upgrade_time_left <= 0:
		game_ref.rnd_queue.pop_front()
		unlock()
	
func unlock():
	if randf() <= base_success_probability+success_probability_modifier:
		unlocked = true
		if auto_activate:
			active = true
		else:
			active = false
	
func apply_effect():
	for i in effects:
		i.execute()
		
func save():
	var executed = []
	var tsle = []
	for i in effects:
		executed.append(i.executed)
		tsle.append(i.turns_since_last_execution+1) 

	return {"executed":executed,"time_since_last_execution":tsle,"unlocked":unlocked,"active":active,"upgrade_time_left":upgrade_time_left,"success_probability_modifier": success_probability_modifier,"price_modifier":price_modifier} 
	
