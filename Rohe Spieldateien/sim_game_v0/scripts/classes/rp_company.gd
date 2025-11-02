extends Object
class_name rp_company
var quality: float
var reliability: float
var sentiment: float
var base_price: float
var contracts: Array[resource_contract]
var resource: String
var capacity: float
var open_capacity: float
var active: bool
var active_contracts: int
var duration_range: Array
var cancel_notice
var game_ref
var id
var canceled_contracts
var used_capacity
var sim_order
func _init(game_ref_,id_: String,so):
	canceled_contracts = false
	game_ref = game_ref_
	id = id_
	sim_order = so
	var data = Utility.read_to_dict("res://data/rp_companies/{0}.json".format({"0":id}))
	var saved_data
	if FileAccess.file_exists("user://saves/slot_{0}/rp_companies/{1}.json".format({"0":Utility.selected_slot,"1":id})):
		saved_data = Utility.read_to_dict("user://saves/slot_{0}/rp_companies/{1}.json".format({"0":Utility.selected_slot,"1":id}))
	else:
		saved_data = data["base_values"]
	quality = saved_data["quality"]
	reliability = saved_data["reliability"]
	base_price = saved_data["base_price"]
	resource = data["resource"]
	capacity = saved_data["capacity"]
	active = saved_data["active"]
	active_contracts = saved_data["contracts"].size()
	duration_range = data["duration_range"]
	cancel_notice = data["cancel_notice"]
	contracts = []
	for i in saved_data["contracts"]:
		contracts.append(resource_contract.new(game_ref,i["total_duration"],i["duration_left"],quality,resource,i["price"],i["expected_amount"],i["duration_done"],i["original_duration"]))
	used_capacity = 0
	for i in contracts:
		used_capacity += i.expected_amount
func cancel_contract(index:int,notice,apply_sentiment):
	if apply_sentiment:
		sentiment -= 2
	if notice == 0:
		capacity+= contracts[index].expected_amount
		contracts.remove_at(index)
		active_contracts -= 1
	else:
		contracts[index].duration_left = min(contracts[index].duration_left, notice)
		
func get_contract_extension_terms(index):
	if sentiment <= -10:
		return "rejected_expansion"
	var new_contract_proposal = resource_contract.new(game_ref,contracts[index].duration_done+contracts[index].original_duration,contracts[index].original_duration,quality,resource,base_price*(1-max(min(sentiment,5),-5)/100),min(capacity-used_capacity,contracts[index].expected_amount),contracts[index].duration_done,contracts[index].original_duration)
	return new_contract_proposal


func disable():
	while contracts.size() > 0:
		cancel_contract(0,cancel_notice,false)
	active = false
	capacity = 0

func add_contract(total_duration, price,expected_amount):
	contracts.append(resource_contract.new(game_ref,total_duration,total_duration,quality,resource,price,expected_amount,total_duration,total_duration))
	used_capacity += expected_amount
	sentiment += 1
	active_contracts += 1


func recalculate_used_capacity():
	used_capacity = 0
	for i in contracts:
		used_capacity += i.expected_amount

func run_contracts():
	if active_contracts > 0:
		sentiment += 0.1
	elif abs(sentiment) < 0.2:
		sentiment = 0
	else:
		sentiment -= abs(sentiment)/sentiment*0.2
	var done = []
	for i in range(contracts.size()):
		contracts[i].deliver_resources(randf_range(reliability,1.2)-1,randf_range(reliability,1.2))
		if contracts[i].duration_left == 0:
			done.append(i)
			if contracts[i].duration_done == contracts[i].total_duration:
				sentiment += 1
	
	done.reverse()
	for i in done:
		contracts.remove_at(i)
		active_contracts -= 1
	var index = active_contracts-1
	if capacity < 0:
		capacity = 0
	while used_capacity > capacity:
		used_capacity -= contracts[index].expected_amount
		canceled_contracts = true
		cancel_contract(index,0,false)
		index -= 1
func save_company():
	var save_dict: Dictionary = {}
	save_dict["quality"] = quality
	save_dict["reliability"] = reliability
	save_dict["sentiment"] = sentiment
	save_dict["base_price"] = base_price
	save_dict["capacity"] = capacity
	save_dict["active"] = active
	save_dict["open_capacity"] = open_capacity
	save_dict["contracts"] = []
	for i in contracts:
		save_dict["contracts"].append(i.get_as_dict())
	Utility.save_to_file("user://saves/slot_{0}/rp_companies/{1}.json".format({"0":Utility.selected_slot,"1":id}),save_dict)
