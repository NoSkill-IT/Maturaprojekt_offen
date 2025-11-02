extends Object
class_name req_link
var reqs
var type: String
var num: int

func _init(reqs_, type_, num_: int = 0) -> void:
	reqs = reqs_
	type = type_
	num = num_
func is_met():
	var is_true
	if type == "none":
		return true
	elif type == "and":
		is_true = true
		for i in reqs:
			is_true = is_true and i.is_met()
	elif type == "or":
		is_true = false
		for i in reqs:
			is_true = is_true or i.is_met()
	elif type == "x_of":
		var met_count = 0
		for i in reqs:
			if i.is_met():
				met_count += 1
		if met_count >= num: 
			return true
		else:
			return false
	return is_true


func simplify():
	if reqs.size() == 1:
		if reqs[0] is req_link:
			reqs = reqs[0].reqs
			type = reqs[0].type
			num = reqs[0].num
			simplify()
	elif type == "or":
		for i in reqs:
			if i is requirement:
				continue
			if i.type == "or":
				for j in i.reqs:
					reqs.append(j)
				reqs.erase(i)
			elif i.type == "none":
				reqs.erase(i)
		for i in reqs:
			if i is req_link:
				i.simplify()
	elif type == "and":
		for i in reqs:
			if i is requirement:
				continue
			if i.type == "and":
				for j in i.reqs:
					reqs.append(j)
				reqs.erase(i)
			elif i.type == "none":
				reqs.erase(i)
		for i in reqs:
			if i is req_link:
				i.simplify()
				
	
