extends Object
class_name requirement
var value
var comp
var variable: String
var game_ref

func _init(vari, com, val, gr) -> void:
	value = val
	comp = com
	variable = vari
	game_ref = gr
	
func is_met() -> bool:
	var parts = variable.replace("[", ".").replace("]", "").split(".")
	var variable_value
	var obj = game_ref
	for i in range(parts.size() - 1):
		var key = parts[i]
		if obj is Dictionary:
			obj = obj[key]
		elif obj is Array:
			obj = obj[int(key)]
		else:
			obj = obj.get(key)
	var last_key = parts[-1]
	if obj is Dictionary:
		obj = obj[last_key]
	elif obj is Array:
		obj = obj[int(last_key)]
	else:
		variable_value = obj.get(last_key)
	if comp == "!=":
		if variable_value != value:
			return true
		else:
			return false
	elif comp == "==":
		if variable_value == value:
			return true
		else:
			return false
	elif comp == ">=":
		if variable_value >= value:
			return true
		else:
			return false
	elif comp == "<=":
		if variable_value <= value:
			return true
		else:
			return false
	elif comp == ">":
		if variable_value > value:
			return true
		else:
			return false
	elif comp == "<":
		if variable_value < value:
			return true
		else:
			return false
	elif comp == "in_":
		if variable_value in value:
			return true
		else:
			return false	
	elif comp == "_in":
		if value in variable_value:
			return true
		else:
			return false
	else:
		return false
