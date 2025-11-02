extends Object
class_name special_event_type
var function_name: String
var parameters: Array
var variable: String
var new_val
var type: String
var name: String
var num_id
var game_ref

func _init(gr, event_dict) -> void:
	num_id = event_dict["num_id"]
	type = event_dict["type"]
	name = event_dict["event_name"]
	if event_dict["type"] == "func":
		function_name = event_dict["function_name"]
		parameters = event_dict["parameters"]
	else:
		variable = event_dict["variable"]
		new_val = event_dict["new_val"]
	game_ref = gr
	
	
func get_for_event(random_value):
	if type == "func":
		var calc_params = []
		for i in parameters:
			if typeof(i) != TYPE_ARRAY:
				calc_params.append(i)
			else:
				calc_params.append((i[0]+i[1]*random_value)*randf_range(1-i[2],1+i[2]))
		return effect.new(type,game_ref,name,false,"",null,"",function_name,calc_params,req_link.new([],"none"),0,0)
	else:
		var calc_value = []
		if typeof(new_val) != TYPE_ARRAY:
			calc_value = new_val
		else:
			calc_value = (new_val[0]+new_val[1]*random_value)*randf_range(1-new_val[2],1+new_val[2])
			return effect.new(type,game_ref,false,variable,calc_value,"add","",[],req_link.new([],"none"),0,0)

	
