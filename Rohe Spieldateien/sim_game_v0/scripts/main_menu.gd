extends Control
var current_interface
var language_file
var settings_file = "user://settings.json"
var language_dict 
var languages
var utils
var settings_dict
var selected_slot = 0
var resolutions = {
	"1920x1080":Vector2i(1920,1080),
	"2560x1440":Vector2i(2560,1440),
	"3840x2160":Vector2i(3840,2160),
	"1366x768":Vector2i(1366,768),
	"1600x900":Vector2i(1600,900),
	"1280x720":Vector2i(1280,720),
	"3440x1440":Vector2i(3440,1440),
	"1920x1200":Vector2i(1920,1200)}
	
var window_modes = ["fullscreen","windowed","windowed_bl"]

func close_settings():
	$main_menu_content.visible = true
	$settings.visible = false
	current_interface = "main"

func set_screen_mode(mode: String):
	if mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif mode == "windowed_bl":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)

func _input(event):
	if event.is_action_pressed("escape"):
		if current_interface == "main":
			get_tree().quit()
		elif current_interface == "settings":
			close_settings()
		elif current_interface == "new_game":
			$main_menu_content.visible = true
			$new_game.visible = false
			current_interface = "main"
		elif current_interface == "new_game_confirm":
			$new_game/confirm.visible = false
			$new_game/slot_selection.visible = true
			current_interface = "new_game"
		elif current_interface == "load_game":
			$main_menu_content.visible = true
			$load_game.visible = false
			current_interface = "main"
		elif current_interface == "load_game_confirm":
			$load_game/confirm.visible = false
			$load_game/slot_selection.visible = true
			current_interface = "load_game"

func _on_leave_game_pressed() -> void:
	get_tree().quit()





func _on_slot_new_pressed(slot: int):
	current_interface = "new_game_confirm"
	var save_file_string = "user://saves/slot_{0}/general_info.json".format({"0":slot})
	$new_game/confirm/seed/seed.text = str(randi())
	var save_data = utils.read_to_dict(save_file_string)
	if save_data["played"]:
		$new_game/confirm/confirm_text.text = $new_game/confirm/confirm_text.text.format({"0":language_dict["main_menu"]["new_game"]["dynamic"]["overwrite"].format({"0":slot})})
	else:
		$new_game/confirm/confirm_text.text = $new_game/confirm/confirm_text.text.format({"0":""})
	$new_game/slot_selection.visible = false
	$new_game/confirm.visible = true
	selected_slot = slot

func _on_slot_load_pressed(slot: int):
	current_interface = "load_game_confirm"
	var save_file_string = "user://saves/slot_{0}/general_info.json".format({"0":slot})
	var save_data = utils.read_to_dict(save_file_string)
	$load_game/confirm/custom_name.text = save_data["custom_name"]
	$load_game/confirm/confirm_text.text = $new_game/confirm/confirm_text.text.format({"0":""})
	$load_game/slot_selection.visible = false
	$load_game/confirm.visible = true
	selected_slot = slot
	
func _on_new_game_pressed() -> void:
	$main_menu_content.visible = false
	$new_game.visible = true
	$new_game/confirm.visible = false
	current_interface = "new_game"

func _on_load_game_pressed() -> void:
	$main_menu_content.visible = false
	$load_game.visible = true
	$load_game/confirm.visible = false
	current_interface = "load_game"

func apply_settings():
	settings_dict = {"language": "placeholder","resolution":"placeholder","window_mode":"placeholder"}
	for key in languages.keys():
		if languages[key][0] == $settings/all_settings/language_setting/language_option.get_selected_id():
			settings_dict["language"] = key
	for key in resolutions.keys():
		if resolutions[key][0] == $settings/all_settings/resolution_setting/resolution_option.get_selected_id():
			settings_dict["resolution"] = key
	settings_dict["window_mode"] = window_modes[$settings/all_settings/window_mode_setting/window_mode_option.get_selected_id()]
	set_screen_mode(settings_dict["window_mode"])
	await get_tree().process_frame
	utils.save_to_file(settings_file, settings_dict)
	DisplayServer.window_set_size(resolutions[settings_dict["resolution"]][1])
	update_language()

func update_language():
	language_file = "res://languages/%s.json"  % [settings_dict["language"]]
	language_dict = utils.read_to_dict(language_file)
	utils.apply_language_dict(language_dict["main_menu"],"")
	var save_lang = language_dict["main_menu"]["new_game"]["dynamic"]
	for i in range(1,5):
		var node_1 = get_node("new_game/slot_selection/slot_{0}".format({"0":i}))
		var node_2 = get_node("load_game/slot_selection/slot_{0}".format({"0":i}))
		var save_file_string = "user://saves/slot_{0}/general_info.json".format({"0":i})
		var save_data = utils.read_to_dict(save_file_string)
		var info_string = ""
		if save_data["played"]:
			info_string=save_lang["last_played"].format({"0":save_data["last_played"]})+"\n"+save_lang["custom_name"].format({"0":save_data["custom_name"]})+"\n"+save_lang["seed"].format({"0":int(save_data["seed"])})
		else:
			info_string=save_lang["empty_slot"]
			node_2.disabled = true
		node_1.text = node_1.text.format({"0":info_string})
		node_2.text = node_2.text.format({"0":info_string})

func _ready():
	utils = preload("res://scripts/utility.gd").new()
	utils.set_context(self)
	if not FileAccess.file_exists("user://settings.json"):
		settings_dict = {"language": "en_us","resolution":"1920x1080","window_mode":"fullscreen"}
		utils.save_to_file(settings_file, settings_dict)
	else:
		settings_dict = utils.read_to_dict(settings_file)
	set_screen_mode(settings_dict["window_mode"])
	var it = 0
	for a in window_modes:
		$settings/all_settings/window_mode_setting/window_mode_option.add_item(a, it)
		it += 1
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	dir = DirAccess.open("user://saves")
	for i in range(1,5):
		var slot_dir_name = "slot_{0}".format({"0":i})
		if not dir.dir_exists(slot_dir_name):
			dir.make_dir(slot_dir_name)
			utils.save_to_file("user://saves/{0}/general_info.json".format({"0":slot_dir_name}), {"played":false})
	update_language()
	current_interface = "main"
	languages = utils.read_to_dict("res://languages/language_ids.json")
	it = 0
	for key in languages.keys():
		var value = languages[key]
		languages[key] = [it,value]
		$settings/all_settings/language_setting/language_option.add_item(value, it)
		it += 1
	it = 0
	for key in resolutions.keys():
		var value = resolutions[key]
		resolutions[key] = [it,value]
		$settings/all_settings/resolution_setting/resolution_option.add_item(key, it)
		it += 1

func _on_settings_pressed() -> void:
	$main_menu_content.visible = false
	$settings.visible = true
	$settings/all_settings/language_setting/language_option.select(languages[settings_dict["language"]][0])
	$settings/all_settings/resolution_setting/resolution_option.select(resolutions[settings_dict["resolution"]][0])
	for i in range(3):
		if settings_dict["window_mode"] == window_modes[i]:
			$settings/all_settings/window_mode_setting/window_mode_option.select(i)
	current_interface = "settings"

func _on_apply_pressed() -> void:
	await apply_settings() 

func _on_back_to_main_pressed() -> void:
	close_settings() 

func _on_confirm_new_pressed() -> void:
	var date = Time.get_datetime_dict_from_system()
	var save_dict = {}
	var date_string = "%02d.%02d.%04d" % [date.day, date.month, date.year]
	var text:String = $new_game/confirm/seed/seed.text
	var num: int = 0
	var digit:int = 0
	var digits = ["0","1","2","3","4","5","6","7","8","9"]
	var int_ = {"0":0,"1":1,"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9}
	for i in range(text.length()-1,-1,-1):
		if text[i] in digits:
			num += (10**digit)*int_[text[i]]
			digit += 1
	if num == 0:
		save_dict["seed"] = randi()
	else:
		save_dict["seed"] = int(num)
	save_dict["played"] = true
	save_dict["last_played"] = date_string
	save_dict["custom_name"] = $new_game/confirm/custom_name.text
	save_dict["turn"] = 1
	save_dict["quarter"] = 1
	save_dict["player_money"] = 2000000
	save_dict["running_expenses"] = 0
	save_dict["demand"] = 10400000
	save_dict["supply"] = 0
	save_dict["sale_price"] = 25
	save_dict["publicity"] = 10000
	save_dict["production_multiplier"] = 1
	save_dict["inflation_value"] = 1
	save_dict["salary_multiplier"] = 1
	save_dict["price_modifier"] = 1
	save_dict["resource_price_modifier"] = 1
	save_dict["sentiment"] = 0
	save_dict["last_event_id"] = -1
	save_dict["rnd_queue"] = []
	save_dict["loss_cf"] = 0
	save_dict["canton_tax_rate"] = 0.055
	save_dict["total_tax_rate"] = 1.7
	save_dict["federal_tax_rate"] = 0.085
	utils.clear_full_dir("user://saves/slot_{0}".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/contracts".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/resources".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/rp_companies".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/rival_companies".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/employees".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/events".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/rnd".format({"0":selected_slot}))
	DirAccess.make_dir_absolute("user://saves/slot_{0}/production_methods".format({"0":selected_slot}))
	var event_data_dict = {"active_event_ids": []}
	var event_ids = Utility.read_to_array("res://data/events/event_ids.txt")
	for i in event_ids:
		event_data_dict[i] = {"probability_modifier":0,"active":false}
	utils.save_to_file("user://saves/slot_{0}/events/general.json".format({"0":selected_slot}),event_data_dict)
	var rnd_tree_ids =  Utility.read_to_array("res://data/rnd/trees/tree_ids.txt")
	for i in rnd_tree_ids:
		var tree_nodes = {}
		var nodes = Utility.read_to_dict("res://data/rnd/trees/{0}.json".format({"0":i}))["tree_members"]
		for j in nodes:
			for k in j:
				var effects = Utility.read_to_dict("res://data/rnd/nodes/{0}.json".format({"0":k}))["effects"]
				var executed = []
				var tsle = []
				for l in effects:
					executed.append(false)
					tsle.append(0)
				tree_nodes[k] = {"executed":executed,"time_since_last_execution":tsle,"unlocked":false,"active":false,"upgrade_time_left":0,"success_probability_modifier":0,"price_modifier":1} 
		Utility.save_to_file("user://saves/slot_{0}/rnd/{1}.json".format({"0":selected_slot,"1":i}),tree_nodes)
	utils.save_to_file("user://saves/slot_{0}/general_info.json".format({"0":selected_slot}),save_dict)
	Utility.selected_slot = selected_slot
	get_tree().change_scene_to_file("res://scenes/active_game.tscn")
	
func _on_confirm_load_pressed() -> void:
	var date = Time.get_datetime_dict_from_system()
	var date_string = "%02d.%02d.%04d" % [date.day, date.month, date.year]
	var save_dict = utils.read_to_dict("user://saves/slot_{0}/general_info.json".format({"0":selected_slot}))
	save_dict["last_played"] = date_string
	save_dict["custom_name"] = $load_game/confirm/custom_name.text
	utils.save_to_file("user://saves/slot_{0}/general_info.json".format({"0":selected_slot}),save_dict)
	Utility.selected_slot = selected_slot
	get_tree().change_scene_to_file("res://scenes/active_game.tscn")

func _on_cancel_new_pressed() -> void:
	$new_game/confirm.visible = false
	$new_game/slot_selection.visible = true
	current_interface = "new_game"

func _on_cancel_load_pressed() -> void:
	$load_game/confirm.visible = false
	$load_game/slot_selection.visible = true
	current_interface = "load_game"
