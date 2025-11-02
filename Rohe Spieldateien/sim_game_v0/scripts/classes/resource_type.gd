class_name resource_type
extends Object
var type_name: String
var display_name: String
var base_value: float
var standard_base_value: float
var quality_coefficient: float
var stored: Array[stored_resource]
var total_stored_amount: float
var expiration_time: int
var unit: String
var usage_priority: int			#0 = old to new (best to worst), 1 = old to new (worst to best), 2 = new to old (best to worst), 3 = new to old (worst to best)
								#4 = best to worst (old to new), 5 = worst to best (old to new), 6 = best to worst (new to old), 7 = worst to best (new to old)
var game_ref

func _init(game_ref_,type_name_: String, standard_base_value_: float = 0,expiration_time_: int = 4, quality_coefficient_: float = 0):
	type_name = type_name_
	game_ref = game_ref_
	if FileAccess.file_exists("user://saves/slot_{0}/resources/{1}.json".format({"0":Utility.selected_slot,"1":type_name_})):
		var save_data = Utility.read_to_dict("user://saves/slot_{0}/resources/{1}.json".format({"0":Utility.selected_slot,"1":type_name_}))
		base_value = save_data["base_value"]
		standard_base_value = save_data["standard_base_value"]
		total_stored_amount = save_data["total_stored_amount"]
		quality_coefficient = save_data["quality_coefficient"]
		expiration_time = save_data["expiration_time"]
		usage_priority = save_data["usage_priority"]
		stored = []
		for i in save_data["stored"]:
			stored.append(stored_resource.new(game_ref,i["amount"],i["expiration"],i["quality"],i["id"]))
	else:
		usage_priority = 0
		base_value = standard_base_value_
		standard_base_value = standard_base_value_
		quality_coefficient = quality_coefficient_
		stored = []
		total_stored_amount = 0
		expiration_time = expiration_time_
		save_current_storage()
	reassign_stored_ids()

func copy():
	return resource_type.new(game_ref,type_name) 


func add_to_storage(amount: int, quality: float):
	var s = stored_resource.new(game_ref,amount,expiration_time,quality)
	total_stored_amount += s.amount
	var found_same = false
	for i in stored:
		if i.expiration == s.expiration and i.quality == s.quality:
			i.amount += s.amount
			break
	if not found_same:
		s.id = stored.size()
		stored.append(s)
	reassign_stored_ids()

func reassign_stored_ids():
	for i in range(stored.size()):
		stored[i].id = i

func remove_from_storage(s: stored_resource):
	if stored[s.id].amount == s.amount:
		stored.remove_at(s.id)
		for i in range(s.id,stored.size()):
			stored[i].id -= 1
			return true
		total_stored_amount -= s.amount
	elif stored[s.id].amount < s.amount:
		print("Error: Tried to remove more of a resource than available")
	else:
		stored[s.id].amount -= s.amount
		total_stored_amount -= s.amount
	reassign_stored_ids()
func age_products(time: int = 1):
	for i in range(stored.size()-1, -1,0):
		stored[i].expiration -= time
		if stored[i].expiration <= 0:
			#disposal warining
			stored.remove_at(i)

func quality_change(value: float = 0):
	for i in range(stored.size()-1, -1,0):
		stored[i].quality -= value

func save_current_storage():
	var save_dict = {}
	save_dict["type_name"] = type_name
	save_dict["standard_base_value"] = standard_base_value
	save_dict["quality_coefficient"] = quality_coefficient
	save_dict["base_value"] = base_value
	save_dict["total_stored_amount"] = total_stored_amount
	save_dict["unit"] = unit
	save_dict["stored"] = []
	save_dict["expiration_time"] = expiration_time
	save_dict["usage_priority"] = usage_priority
	for i in stored:
		save_dict["stored"].append(i.get_as_dict())
	Utility.save_to_file("user://saves/slot_{0}/resources/{1}.json".format({"0":Utility.selected_slot,"1":type_name}),save_dict)
	
	
