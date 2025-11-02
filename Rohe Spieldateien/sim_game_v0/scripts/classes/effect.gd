extends Object
class_name effect
var value
var parameters: Array
var op: String
var variable: String
var function: String
var game_ref
var effect_type: String
var requirements
var executed: bool
var execution_time: String
var period: int
var turns_since_last_execution: int
var origin_id
func _init(et, gr, oid = "",executed_ = false, vari = "", val = null,op_ = "",funct = "", pr = [], req = req_link.new([],"none"), tsle: int = 100, peri: int = 0) -> void:
	value = val
	variable = vari
	game_ref = gr
	function = funct
	effect_type = et
	parameters = pr
	op = op_
	requirements = req
	executed = executed_
	period = peri
	effect_type = et
	turns_since_last_execution = tsle
	origin_id = oid
	
func execute():
	if not requirements.is_met():
		return
	if period == 0:
		if executed:
			return
	if turns_since_last_execution < period:
		return
	executed = true
	turns_since_last_execution = 0
	if effect_type == "func":
		var parts = function.replace("[", ".").replace("]", "").split(".")
		var obj = game_ref
		for i in range(parts.size() - 1):
			var key = parts[i]
			if obj is Dictionary or obj is Array:
				obj = obj[key]
			else:
				obj = obj.get(key)
		var last_key = parts[-1]
		if parameters.size() == 0:
			obj.call(last_key)
		elif parameters.size() == 1:
			obj.call(last_key,parameters[0])
		elif parameters.size() == 2:
			obj.call(last_key,parameters[0],parameters[1])
		elif parameters.size() == 3:
			obj.call(last_key,parameters[0],parameters[1],parameters[2])
		elif parameters.size() == 4:
			obj.call(last_key,parameters[0],parameters[1],parameters[2],parameters[3])
		elif parameters.size() == 5:
			obj.call(last_key,parameters[0],parameters[1],parameters[2],parameters[3],parameters[4])
	if effect_type == "var":
		var parts = variable.replace("[", ".").replace("]", "").split(".")
		var obj = game_ref
		for i in range(parts.size() - 1):
			var key = parts[i]
			if obj is Dictionary or obj is Array:
				obj = obj[key]
			else:
				obj = obj.get(key)
		var last_key = parts[-1]
		if op == "add":
			if obj is Dictionary or obj is Array:
				obj[last_key]+=value
			else:
				obj.set(last_key,obj.get(last_key) + value)
		elif op == "set":
			if obj is Dictionary or obj is Array:
				obj[last_key]=value
			else:
				obj.set(last_key, value)
		elif op == "mult":
			if obj is Dictionary or obj is Array:
				obj[last_key]*=value
			else:
				obj.set(last_key, obj.get(last_key)*value)
		if variable == "player_money":
			game_ref.money_trace[-1][1].append([origin_id,game_ref.player_money,op])
func get_as_dict():
	return {"value": value, "parameters":parameters, "variable": variable, "function": function, "effect_type": effect_type, "execution_time": execution_time, "op": op}
func end_turn():
	turns_since_last_execution += 1
