extends Node

var scene_root = null
var selected_slot = 0

func set_context(root_node):
	scene_root = root_node

func read_to_array(file : String):
	var file_ = FileAccess.open(file, FileAccess.READ)
	return file_.get_as_text().split("\n",false)
func read_to_dict(file : String):
	var file_ = FileAccess.open(file, FileAccess.READ)
	var json = JSON.new()
	var json_string = file_.get_as_text()
	json.parse(json_string)
	file_.close()
	return json.data

func save_to_file(file : String, dict : Dictionary):
	var json_string = JSON.stringify(dict)
	var file_ = FileAccess.open(file, FileAccess.WRITE)
	file_.store_string(json_string)
	file_.close()


func apply_language_dict(dict: Dictionary,str_ : String):
	for key in dict.keys():
		if key == "dynamic":
			continue
		elif key.substr(key.length()-5,5) == "_tabs":
			var path
			if str_ == "":
				path = key
			else:
				path = str_+"/"+key
			var node:TabContainer = scene_root.get_node(path)
			var children_dicts = dict[key]
			var it = 0
			for i:Node in node.get_children():
				node.set_tab_title(it,children_dicts[i.name]["tab_title"])
				node.set_tab_tooltip(it,children_dicts[i.name]["tab_tooltip"])
				apply_language_dict(children_dicts[i.name]["contents"],path+"/"+i.name)
				it += 1
		elif typeof(dict[key]) == TYPE_DICTIONARY:
			if "tooltip" in dict[key]:
				var path
				if str_ == "":
					path = key
					
				else:
					path = str_+"/"+key
				var node_ = scene_root.get_node(path)
				node_.text = dict[key]["text"]
				node_.tooltip_text = dict[key]["tooltip"]
			else:
				var path
				if str_ == "":
					path = key
					
				else:
					path = str_+"/"+key
				apply_language_dict(dict[key],path)
		elif typeof(dict[key]) == TYPE_STRING:
			var path
			if str_ == "":
				path = key

			else:
				path = str_+"/"+key
			var node_ = scene_root.get_node(path)
			node_.text = dict[key]
		else:
			if key.substr(key.length()-7,7) == "_option":
				var it = 0
				var path
				if str_ == "":
					path = key

				else:
					path = str_+"/"+key
				var node_ = scene_root.get_node(path)
				for opt in dict[key]:
					node_.set_item_text(it,opt)
					it += 1
			
func clear_full_dir(path: String):
	var dirs = DirAccess.get_directories_at(path)
	for i in dirs:
		clear_full_dir(path+"/"+i)
	var files = DirAccess.get_files_at(path)
	for i in files:
		DirAccess.remove_absolute(path+"/"+i)
	DirAccess.remove_absolute(path)

func log_base(x: float, base:float) -> float:
	return log(x)/log(base)


func round_to(num, place):
	return round(num/place)*place

func shorten_number(num):
	var log_ = log_base(abs(num),10)
	if is_nan(num):
		return[0,0]
	if num == 0:
		return [0,0]
	if num is int:
		return [round_to(num,pow(10,max(floor(log_)-3,0))),num]
	else:
		return [round_to(num,pow(10,floor(log_)-3)),round_to(num,pow(10,floor(log_)-7))]

func generate_requirement_text(req,indents,build_string,lang_dict) -> String:
	var new_str = build_string + "\n"
	for i in range(indents):
		new_str += "  "
	if req is requirement:
		print(req.variable.substr(req.variable.length()-9,9))
		if req.is_met():
			new_str += "[color=green]✓ "+lang_dict["variable_names"][req.variable] + " " + req.comp + " " + str(req.value)+"[/color]"
		else:
			new_str += "[color=red]✗ "+lang_dict["variable_names"][req.variable] + " " + req.comp + " " + str(req.value)+"[/color]"
		return new_str
	elif req.type == "x_of":
		if req.is_met():
			new_str += "[color=green]✓ "+lang_dict["requirements"][req.type].format({"0":req.num})+"[/color]"
		else:
			new_str += "[color=red]✗ "+lang_dict["requirements"][req.type].format({"0":req.num})+"[/color]"
	else:
		if req.is_met():
			new_str += "[color=green]✓ "+lang_dict["requirements"][req.type]+"[/color]"
		else:
			new_str += "[color=red]✗ "+lang_dict["requirements"][req.type]+"[/color]"
	for i in req.reqs:
		print(req.reqs)
		print(typeof(i))
		new_str = generate_requirement_text(i,indents+1,new_str,lang_dict)
	return new_str


func round_to_date(turn):
	var string = ""
	if int(turn) % 4 == 0:
		string += "Q4"
	else:
		string += "Q"+str(int(turn)%4)
	string += " "
	string += str(2026+floor((turn-1)/4))
	return string



func sort_0(a: stored_resource,b: stored_resource):
	if a.expiration < b.expiration:
		return true
	if a.expiration > b.expiration:
		return false
	if a.quality > b.quality:
		return true
	return false
func sort_1(a: stored_resource,b: stored_resource):
	if a.expiration < b.expiration:
		return true
	if a.expiration > b.expiration:
		return false
	if a.quality < b.quality:
		return true
	return false
func sort_2(a: stored_resource,b: stored_resource):
	if a.expiration > b.expiration:
		return true
	if a.expiration < b.expiration:
		return false
	if a.quality > b.quality:
		return true
	return false
func sort_3(a: stored_resource,b: stored_resource):
	if a.expiration > b.expiration:
		return true
	if a.expiration < b.expiration:
		return false
	if a.quality < b.quality:
		return true
	return false
func sort_4(a: stored_resource,b: stored_resource):
	if a.quality > b.quality:
		return true
	if a.quality < b.quality:
		return false
	if a.expiration < b.expiration:
		return true
	return false
func sort_5(a: stored_resource,b: stored_resource):
	if a.quality < b.quality:
		return true
	if a.quality > b.quality:
		return false
	if a.expiration < b.expiration:
		return true
	return false
func sort_6(a: stored_resource,b: stored_resource):
	if a.quality > b.quality:
		return true
	if a.quality < b.quality:
		return false
	if a.expiration > b.expiration:
		return true
	return false
func sort_7(a: stored_resource,b: stored_resource):
	if a.quality < b.quality:
		return true
	if a.quality > b.quality:
		return false
	if a.expiration > b.expiration:
		return true
	if a.expiration < b.expiration:
		return false
	
	
#0 = old to new (best to worst), 1 = old to new (worst to best), 2 = new to old (best to worst), 3 = new to old (worst to best)
#4 = best to worst (old to new), 5 = worst to best (old to new), 6 = best to worst (new to old), 7 = worst to best (new to old)
