extends Control
var resources: Dictionary[String,resource_type] = {}
var language_file: String
var language_dict: Dictionary
var settings_dict: Dictionary
var resources_lang_dict: Dictionary
var player_money: float
var other_expenses: Array
var turn: int
var general_save_info: Dictionary
var last_event_id: int
var active_events: Array[active_event]
var events_dict: Dictionary [String,event_type]
var special_events_dict: Dictionary[String,special_event_type]
var publicity
var sentiment
var rnd_trees: Dictionary[String,rnd_tree]
var employee_groups: Dictionary[String,employee_group]
var rp_companies: Dictionary[String,rp_company]
var rival_companies: Dictionary[String,rival_company]
var production_methods: Dictionary[String,production_method]
var demand
var sale_price
var quarter
var running_expenses: float
var cheat_mode = true
var ip_displayed_event
var unlocked_methods
var PM_GUI = preload("res://scenes/production_method_gui.tscn")
var EG_GUI = preload("res://scenes/employee_group_gui.tscn")
var RND_GUI = preload("res://scenes/rnd_tab.tscn")
var info_node = preload("res://scenes/info_node.tscn")
var selected_resource_id
var selected_rc_id
var selected_rival_id
var viewed_contract
var viewed_contract_id
var new_price
var viewed_rnd_node_info
var production_multiplier
var old_production_multiplier

var last_viewed_tab
var rnd_queue: Array
var money_trace = []
var loss_cf = 0
var total_tax_rate = 0
var canton_tax_rate = 0
var federal_tax_rate = 0
var seed_
var price_modifier
var old_price_modifier
var inflation_value
var old_inflation_value
var salary_multiplier
var resource_price_modifier
var old_rp_modifier

func load_node_info(node_id,tree_id,i,j):
	if viewed_rnd_node_info[0] == node_id:
		$main_tabs/rnd/rnd_info.visible = false
		viewed_rnd_node_info = ["","",0,0]
		return
	viewed_rnd_node_info = [node_id,tree_id,i,j]
	var node_:rnd_node = rnd_trees[tree_id].all_nodes[i][j]
	$main_tabs/rnd/rnd_info.visible = true
	$main_tabs/rnd/rnd_info/content/name.text = language_dict["dynamic"]["rnd_trees"][tree_id][node_id]["name"]
	$main_tabs/rnd/rnd_info/content/description.text = language_dict["dynamic"]["rnd_trees"][tree_id][node_id]["description"]
	$main_tabs/rnd/rnd_info/content/requirements.text = language_dict["dynamic"]["rnd_node_info"]["requirements"] + Utility.generate_requirement_text(node_.buy_requirements,0,"",language_dict["dynamic"])
	$main_tabs/rnd/rnd_info/content/cost.text = language_dict["dynamic"]["rnd_node_info"]["cost"].format({"0":Utility.shorten_number(node_.base_price*node_.price_modifier)[0]})
	$main_tabs/rnd/rnd_info/content/success_chance.text = language_dict["dynamic"]["rnd_node_info"]["success_chance"].format({"0":str(max(min(1,node_.base_success_probability+node_.success_probability_modifier),0)*100)+"%"})
	if not node_.unlocked:
		$main_tabs/rnd/rnd_info/content/duration.visible = true
		if node_.total_upgrade_time == 0: 
			$main_tabs/rnd/rnd_info/content/duration.text = language_dict["dynamic"]["rnd_node_info"]["instantly"]
		elif node_.total_upgrade_time == node_.upgrade_time_left:
			$main_tabs/rnd/rnd_info/content/duration.text = language_dict["dynamic"]["rnd_node_info"]["total_time"].format({"0":node_.total_upgrade_time, "1":ceil(node_.total_upgrade_time/(employee_groups[node_.employee_type].effectivity_per_day*employee_groups[node_.employee_type].active_employees*65))/4,"2":node_.employee_type})
		else:
			$main_tabs/rnd/rnd_info/content/duration.text = language_dict["dynamic"]["rnd_node_info"]["remaining_time"].format({"1":node_.total_upgrade_time,"0":Utility.shorten_number(node_.total_upgrade_time-node_.upgrade_time_left)[0],"2":ceil(node_.upgrade_time_left/(employee_groups[node_.employee_type].effectivity_per_day*employee_groups[node_.employee_type].active_employees*65)/4),"3":node_.employee_type})
	if node_.unlocked:
		$main_tabs/rnd/rnd_info/content/duration.visible = false
		$main_tabs/rnd/rnd_info/content/active.text = language_dict["dynamic"]["rnd_node_info"]["toggle_effect"]
		$main_tabs/rnd/rnd_info/content/active.disabled = false
		$main_tabs/rnd/rnd_info/content/unlock.disabled = true
		$main_tabs/rnd/rnd_info/content/unlock.text = language_dict["dynamic"]["rnd_node_info"]["already_unlocked"]
		if node_.active:
			$main_tabs/rnd/rnd_info/content/active.button_pressed = true
		else:
			$main_tabs/rnd/rnd_info/content/active.button_pressed = false
	elif node_.check_buy_availability():
		$main_tabs/rnd/rnd_info/content/active.disabled = true
		
		var isinq = false
		for k in rnd_queue:
			if viewed_rnd_node_info[0] == k[0] and viewed_rnd_node_info[1] == k[1] and viewed_rnd_node_info[2] == k[2] and viewed_rnd_node_info[3] == k[3]:
				isinq = true
				break
		if isinq:
			$main_tabs/rnd/rnd_info/content/unlock.disabled = true
			$main_tabs/rnd/rnd_info/content/unlock.text = language_dict["dynamic"]["rnd_node_info"]["in_progress"]
		else:
			$main_tabs/rnd/rnd_info/content/unlock.disabled = false
			$main_tabs/rnd/rnd_info/content/unlock.text = language_dict["dynamic"]["rnd_node_info"]["unlock"]
		$main_tabs/rnd/rnd_info/content/active.text = language_dict["dynamic"]["rnd_node_info"]["active_not_unlocked"]
	else:
		$main_tabs/rnd/rnd_info/content/active.disabled = true
		$main_tabs/rnd/rnd_info/content/unlock.disabled = true
		$main_tabs/rnd/rnd_info/content/unlock.text = language_dict["dynamic"]["rnd_node_info"]["locked"]
		$main_tabs/rnd/rnd_info/content/active.text = language_dict["dynamic"]["rnd_node_info"]["active_not_unlocked"]
func load_rnd_tab():
	for child in $main_tabs/rnd/rnd_tabs.get_children():
		child.queue_free()
	for tree:rnd_tree in rnd_trees.values():
		for i in range(rnd_trees.size()):
			if tree.num_id == i:
				var tab:rnd_tab = RND_GUI.instantiate()
				await get_tree().process_frame
				await get_tree().process_frame
				$main_tabs/rnd/rnd_tabs.add_child(tab)
				await get_tree().process_frame
				await get_tree().process_frame
				tab.setup(tree,self,tree.id,language_dict["dynamic"]["rnd_trees"][tree.id])
				tab.node_pressed.connect(load_node_info)
				tab.name = tree.id
				
				$main_tabs/rnd/rnd_tabs.set_tab_title(i,language_dict["dynamic"]["rnd_trees"][tree.id]["tab_title"])
				$main_tabs/rnd/rnd_tabs.set_tab_tooltip(i,language_dict["dynamic"]["rnd_trees"][tree.id]["tab_tooltip"])
				break
	$main_tabs/rnd/rnd_tabs.current_tab = last_viewed_tab
func setup_overview_tab():
	var info_node_ids = Utility.read_to_array("res://data/info_nodes/node_ids.txt")
	for i in info_node_ids:
		var node_data = Utility.read_to_dict("res://data/info_nodes/{0}.json".format({"0":i}))
		var new_node:i_node = info_node.instantiate()
		new_node.info = node_data["info"][settings_dict["language"]]
		new_node.title = node_data["title"][settings_dict["language"]]
		new_node.custom_size = Vector2(node_data["size"][0],node_data["size"][1])
		new_node.custom_position = Vector2(node_data["position"][0],node_data["position"][1])
		$main_tabs/start.add_child(new_node)
		await get_tree().process_frame
		new_node.format()
		
func unload_overview_tab():
	for i in $main_tabs/start.get_children():
		if i is i_node:
			i.queue_free()
func change_sort():
	if resources[selected_resource_id].usage_priority == 0:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_0)
	elif resources[selected_resource_id].usage_priority == 1:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_1)
	elif resources[selected_resource_id].usage_priority == 2:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_2)
	elif resources[selected_resource_id].usage_priority == 3:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_3)
	elif resources[selected_resource_id].usage_priority == 4:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_4)
	elif resources[selected_resource_id].usage_priority == 5:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_5)
	elif resources[selected_resource_id].usage_priority == 6:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_6)
	elif resources[selected_resource_id].usage_priority == 7:
		resources[selected_resource_id].stored.sort_custom(Utility.sort_7)
	reload_resource_info(selected_resource_id)
func unload_resource_tab():
	$main_tabs/resources/resource_overview/resource_info/ri_container/stored_batches.clear()
	$main_tabs/resources/resource_overview/resource_info/ri_container/contracts.clear()
	$main_tabs/resources/resource_overview/resource_info.visible = false
	$main_tabs/resources/rp_contracts/rc_info.visible = false
	selected_rc_id = ""
	selected_resource_id = ""
	viewed_contract = ""
	viewed_contract_id = -1
	$main_tabs/resources/extend_contract.visible = false
	$main_tabs/resources/new_contract.visible = false
func load_resource_info(resource_name):
	if selected_resource_id == resource_name:
		selected_resource_id = ""
		$main_tabs/resources/resource_overview/resource_info.visible = false
		$main_tabs/resources/resource_overview/resource_info/ri_container/stored_batches.clear()
		$main_tabs/resources/resource_overview/resource_info/ri_container/contracts.clear()
		return
	$main_tabs/resources/resource_overview/resource_info.visible = true
	$main_tabs/resources/resource_overview/resource_info/ri_container/stored_batches.clear()
	selected_resource_id = resource_name
	if resource_name == "chocolate":
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort.visible = false
		$main_tabs/resources/resource_overview/resource_info/ri_container/contracts.visible = false
		$main_tabs/resources/resource_overview/resource_info.visible = true
	else:
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort.visible = true
		$main_tabs/resources/resource_overview/resource_info/ri_container/contracts.visible = true
		$main_tabs/resources/resource_overview/resource_info/ri_container/contracts.clear()
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/sort_by_option.clear()
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/age_sort_option.clear()
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/quality_sort_option.clear()
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/sort_by_option.add_item(language_dict["dynamic"]["resources"]["sort_options"]["age"])
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/sort_by_option.add_item(language_dict["dynamic"]["resources"]["sort_options"]["quality"])
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/age_sort_option.add_item(language_dict["dynamic"]["resources"]["sort_options"]["old"])
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/age_sort_option.add_item(language_dict["dynamic"]["resources"]["sort_options"]["young"])
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/quality_sort_option.add_item(language_dict["dynamic"]["resources"]["sort_options"]["best"])
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/quality_sort_option.add_item(language_dict["dynamic"]["resources"]["sort_options"]["worst"])
		var prio_minus:int =resources[resource_name].usage_priority
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/quality_sort_option.select(prio_minus%2)
		prio_minus -= prio_minus%2
		prio_minus /= 2
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/age_sort_option.select(prio_minus%2)
		prio_minus -= prio_minus%2
		prio_minus /= 2
		$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/sort_by_option.select(prio_minus%2)
		prio_minus -= prio_minus%2
		prio_minus /= 2
		
	reload_resource_info(resource_name)
func discard_batch(_item,_column,id,_mouse_button_index):
	resources[selected_resource_id].remove_from_storage(resources[selected_resource_id].stored[id-1])
	resources[selected_resource_id].save_current_storage()
	reload_resource_info(selected_resource_id)
func reload_resource_info(resource_name):
	$main_tabs/resources/resource_overview/resource_info/ri_container/name.text = resources_lang_dict[resource_name]
	$main_tabs/resources/resource_overview/resource_info/ri_container/average_total/amount_val.text = str(Utility.shorten_number(resources[resource_name].total_stored_amount)[0])+ "kg"
	var average_quality = 0
	for j in resources[resource_name].stored:
		average_quality += j.quality*j.amount
	$main_tabs/resources/resource_overview/resource_info/ri_container/average_total/quality_val.text = str(Utility.shorten_number(average_quality/resources[resource_name].total_stored_amount)[0])
	var sb = $main_tabs/resources/resource_overview/resource_info/ri_container/stored_batches
	sb.clear()
	var root:TreeItem = sb.create_item()
	sb.hide_root = false

	root.set_expand_right(0,true)
	root.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	root.set_text(0,language_dict["dynamic"]["resources"]["stored_batches"])
	var titles:TreeItem = sb.create_item(root)
	titles.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	titles.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
	titles.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
	titles.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
	titles.set_text(0,language_dict["dynamic"]["resources"]["amount"])
	titles.set_text(1,language_dict["dynamic"]["resources"]["quality"])
	titles.set_text(2,language_dict["dynamic"]["resources"]["expiration"])
	titles.set_text(3,language_dict["dynamic"]["resources"]["discard"])
	
	for i:stored_resource in resources[resource_name].stored:
		var item:TreeItem = sb.create_item(root)
		titles.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
		titles.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
		titles.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text(0, str(Utility.shorten_number(i.amount)[0]))
		item.set_text(1, str(Utility.shorten_number(i.quality)[0]))
		item.set_text(2, str(int(i.expiration)))
		item.add_button(3,preload("res://textures/x.png"))
func cancel_extension():
	viewed_contract = ""
	viewed_contract_id = -1
	$main_tabs/resources/extend_contract.visible = false
func accept_extension():
	rp_companies[selected_rc_id].contracts[viewed_contract_id] = viewed_contract
	$main_tabs/resources/extend_contract.visible = false
	rp_companies[selected_rc_id].sentiment += 0.4
	reload_rc_values()
func cancel_new_contract():
	viewed_contract = ""
	viewed_contract_id = -1
	$main_tabs/resources/new_contract.visible = false
	$main_tabs/resources/new_contract/terms/duration_val.value = 0
	$main_tabs/resources/new_contract/terms/amount_val.value = 0
func accept_new_contract():
	viewed_contract = ""
	viewed_contract_id = -1
	rp_companies[selected_rc_id].add_contract($main_tabs/resources/new_contract/terms/duration_val.value*4,new_price,$main_tabs/resources/new_contract/terms/amount_val.value)
	$main_tabs/resources/new_contract.visible = false
	$main_tabs/resources/new_contract/terms/duration_val.value = 0
	$main_tabs/resources/new_contract/terms/amount_val.value = 0
	reload_rc_values()
func load_rc_info(rc: String):
	if selected_rc_id == rc:
		selected_rc_id = ""
		$main_tabs/resources/rp_contracts/rc_info.visible = false
		return
	selected_rc_id = rc
	$main_tabs/resources/rp_contracts/rc_info.visible = true
	reload_rc_values()
func modify_contract(_item,column,id,_mouse_button_index):
	if column == 3:
		rp_companies[selected_rc_id].cancel_contract(id,max(rp_companies[selected_rc_id].cancel_notice,rp_companies[selected_rc_id].duration_range[0]-rp_companies[selected_rc_id].contracts[id].duration_left),true)
		reload_rc_values()
	else:
		cancel_new_contract()
		viewed_contract_id = id
		viewed_contract = rp_companies[selected_rc_id].get_contract_extension_terms(id)
		$main_tabs/resources/extend_contract/terms/amount_val.text = str(viewed_contract.expected_amount) + " kg"
		$main_tabs/resources/extend_contract/terms/price_val.text = str(Utility.shorten_number(viewed_contract.price*viewed_contract.expected_amount)[0]) + " CHF"
		$main_tabs/resources/extend_contract/terms/duration_left_val.text = str(float(viewed_contract.duration_left)/4)+ " "+language_dict["dynamic"]["resource_companies"]["years"]
		$main_tabs/resources/extend_contract.visible = true
func open_new_contract_window():
	var company = rp_companies.get(selected_rc_id)
	if company == null:
		push_warning("No valid company selected.")
		return
	$main_tabs/resources/new_contract.visible = true
	$main_tabs/resources/extend_contract.visible = false
	viewed_contract = "new"
	viewed_contract_id = company.active_contracts
	await get_tree().process_frame
	var duration_val = $main_tabs/resources/new_contract/terms/duration_val
	duration_val.min_value = company.duration_range[0]/4
	duration_val.max_value = company.duration_range[1]/4
	duration_val.value = clamp(company.duration_range[0]/4, duration_val.min_value, duration_val.max_value)
	$main_tabs/resources/new_contract/terms/amount_val.min_value = 0
	$main_tabs/resources/new_contract/terms/amount_val.max_value = rp_companies[selected_rc_id].capacity-rp_companies[selected_rc_id].used_capacity
func reload_rc_values():
	var children = $main_tabs/resources/rp_contracts/rc_scroll/rc_grid.get_children()
	var selected
	for i in children:
		print(selected_rc_id)
		print(i.name)
		if i.name == selected_rc_id:
			selected = i
			break
	selected.text = language_dict["dynamic"]["resource_companies"]["button"].format({"0":language_dict["dynamic"]["resource_companies"]["names"][selected_rc_id],"1":language_dict["dynamic"]["resources"][rp_companies[selected_rc_id].resource],"2":rp_companies[selected_rc_id].active_contracts})
	$main_tabs/resources/rp_contracts/rc_info/container/name.text = language_dict["dynamic"]["resource_companies"]["names"][rp_companies[selected_rc_id].id]
	$main_tabs/resources/rp_contracts/rc_info/container/info/resource_name.text =  language_dict["dynamic"]["resources"][rp_companies[selected_rc_id].resource]
	$main_tabs/resources/rp_contracts/rc_info/container/info/reliability_val.text = str(Utility.shorten_number(rp_companies[selected_rc_id].reliability)[0])
	$main_tabs/resources/rp_contracts/rc_info/container/info/quality_val.text = str(Utility.shorten_number(rp_companies[selected_rc_id].quality)[0])
	$main_tabs/resources/rp_contracts/rc_info/container/info/price_val.text = str(Utility.shorten_number(rp_companies[selected_rc_id].base_price)[0]) + " CHF"
	$main_tabs/resources/extend_contract.visible = false
	$main_tabs/resources/new_contract.visible = false
	rp_companies[selected_rc_id].recalculate_used_capacity()
	viewed_contract = ""
	viewed_contract_id = -1
	var used_capacity = 0
	for i in rp_companies[selected_rc_id].contracts:
		used_capacity += i.expected_amount
	$main_tabs/resources/rp_contracts/rc_info/container/info/capacity_val.text = str(Utility.shorten_number(used_capacity)[0])  + " kg/ "+str(Utility.shorten_number(rp_companies[selected_rc_id].capacity)[0])+ " kg"
	$main_tabs/resources/rp_contracts/rc_info/container/info/duration_val.text = str(rp_companies[selected_rc_id].duration_range[0]/4)+ " "+language_dict["dynamic"]["resource_companies"]["years"] + " - "+ str(rp_companies[selected_rc_id].duration_range[1]/4)+ " "+language_dict["dynamic"]["resource_companies"]["years"]
	$main_tabs/resources/rp_contracts/rc_info/container/info/cancel_notice_val.text = str(rp_companies[selected_rc_id].cancel_notice/4)+ " "+language_dict["dynamic"]["resource_companies"]["years"]
	$main_tabs/resources/rp_contracts/rc_info/container/info/sentiment_val.text = str(rp_companies[selected_rc_id].sentiment)
	var contracts = $main_tabs/resources/rp_contracts/rc_info/container/contracts
	contracts.clear()
	var root:TreeItem = contracts.create_item()
	contracts.hide_root = false
	root.set_expand_right(0,true)
	root.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	root.set_text(0,language_dict["dynamic"]["resource_companies"]["contracts"])
	var titles:TreeItem = contracts.create_item(root)
	titles.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	titles.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
	titles.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
	titles.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
	titles.set_text_alignment(4,HORIZONTAL_ALIGNMENT_RIGHT)
	titles.set_text(0,language_dict["dynamic"]["resource_companies"]["amount"])
	titles.set_text(1,language_dict["dynamic"]["resource_companies"]["price"])
	titles.set_text(2,language_dict["dynamic"]["resource_companies"]["duration_left"])
	titles.set_text(3,language_dict["dynamic"]["resource_companies"]["cancel_contract"])
	titles.set_text(4,language_dict["dynamic"]["resource_companies"]["renew"])
	titles.set_tooltip_text(4,language_dict["dynamic"]["resource_companies"]["renew_tooltip"])
	for i:resource_contract in rp_companies[selected_rc_id].contracts:
		var item:TreeItem = contracts.create_item(root)
		titles.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
		titles.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
		titles.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text(0, str(Utility.shorten_number(i.expected_amount)[0])+ " kg")
		item.set_text(1, str(Utility.shorten_number(i.price*i.expected_amount)[0])+ " CHF")
		item.set_text(2, str(float(i.duration_left)/4)+" "+language_dict["dynamic"]["resource_companies"]["years"])
		if i.duration_left <= rp_companies[selected_rc_id].cancel_notice:
			item.set_text(3, language_dict["dynamic"]["resource_companies"]["cant_cancel"])
		else:
			item.add_button(3,preload("res://textures/x.png"))
		if rp_companies[selected_rc_id].sentiment <= -10 or i.duration_left == i.original_duration:
			item.set_text(4, language_dict["dynamic"]["resource_companies"]["cant_extend"])
		else:
			item.add_button(4,preload("res://textures/renew.png"))
	$main_tabs/resources/rp_contracts/rc_info.visible = true
	if rp_companies[selected_rc_id].sentiment <= -10:
		$main_tabs/resources/rp_contracts/rc_info/container/new_contract.text = language_dict["dynamic"]["resource_companies"]["no_new_contract_sentiment"]
		$main_tabs/resources/rp_contracts/rc_info/container/new_contract.disabled = true
	elif rp_companies[selected_rc_id].used_capacity > rp_companies[selected_rc_id].capacity:
		$main_tabs/resources/rp_contracts/rc_info/container/new_contract.text = language_dict["dynamic"]["resource_companies"]["no_new_contract_capacity"]
		$main_tabs/resources/rp_contracts/rc_info/container/new_contract.disabled = true
	else:
		$main_tabs/resources/rp_contracts/rc_info/container/new_contract.text = language_dict["dynamic"]["resource_companies"]["new_contract"]
		$main_tabs/resources/rp_contracts/rc_info/container/new_contract.disabled = false
	if rp_companies[selected_rc_id].canceled_contracts:
		$main_tabs/resources/rp_contracts/rc_info/container/canceled_contracts.text = language_dict["dynamic"]["resource_companies"]["canceled_contracts"]
func load_rc_buttons():
	for i in $main_tabs/resources/rp_contracts/rc_scroll/rc_grid.get_children():
		i.queue_free()
	for i:rp_company in rp_companies.values():
		for j in range(rp_companies.size()):
			if j == i.sim_order:
				if i.active:
					var btn: Button = Button.new()
					btn.text = language_dict["dynamic"]["resource_companies"]["button"].format({"0":language_dict["dynamic"]["resource_companies"]["names"][i.id],"1":language_dict["dynamic"]["resources"][i.resource],"2":i.active_contracts})
					btn.name = i.id
					btn.pressed.connect( Callable(self,"load_rc_info").bind(i.id))
					btn.custom_minimum_size = Vector2(300,100)
					$main_tabs/resources/rp_contracts/rc_scroll/rc_grid.add_child(btn)
				break
func setup_resource_tab():
	
	selected_rc_id = ""
	selected_resource_id = ""
	viewed_contract = ""
	viewed_contract_id = -1
	$main_tabs/resources/resource_overview/resource_info.visible = false
	$main_tabs/resources/rp_contracts/rc_info.visible = false
	$main_tabs/resources/extend_contract.visible = false
	$main_tabs/resources/new_contract.visible = false
	load_rc_buttons()
func sales_estimate_new():
	var unallocated_workers = employee_groups["workers"].active_employees
	var resource_copies: Dictionary
	for i:resource_type in resources.values():
		resource_copies[i.type_name] = i.copy()
	for i in resource_copies.keys():
		if i == "chocolate":
			continue
		if resource_copies[i].usage_priority == 0:
			resource_copies[i].stored.sort_custom(Utility.sort_0)
		elif resource_copies[i].usage_priority == 1:
			resource_copies[i].stored.sort_custom(Utility.sort_1)
		elif resource_copies[i].usage_priority == 2:
			resource_copies[i].stored.sort_custom(Utility.sort_2)
		elif resource_copies[i].usage_priority == 3:
			resource_copies[i].stored.sort_custom(Utility.sort_3)
		elif resource_copies[i].usage_priority == 4:
			resource_copies[i].stored.sort_custom(Utility.sort_4)
		elif resource_copies[i].usage_priority == 5:
			resource_copies[i].stored.sort_custom(Utility.sort_5)
		elif resource_copies[i].usage_priority == 6:
			resource_copies[i].stored.sort_custom(Utility.sort_6)
		elif resource_copies[i].usage_priority == 7:
			resource_copies[i].stored.sort_custom(Utility.sort_7)
	
	for i in range(production_methods.size()):
		for j in production_methods.values():
			if j.priority == i:
				var operated_machines = min(floor(unallocated_workers/j.required_workers_per_machine),j.active_machines)
				unallocated_workers -= operated_machines*j.required_workers_per_machine
				var max_production = employee_groups["workers"].effectivity_per_day*65*operated_machines*j.output_per_hour
				var total_production = max_production
				for k in resource_copies.keys():
					if k == "chocolate":
						continue
					total_production = min(total_production,resource_copies[k].total_stored_amount/j.ingredient_per_kg[k])
				var final_quality = j.quality_modifier
				for k in resource_copies.keys():
					
					if k == "chocolate":
						continue
					var leftover_amount = total_production*j.ingredient_per_kg[k]
					var quality_step = 0
					while leftover_amount > 0:
						var a = resource_copies[k].stored[0].amount
						quality_step +=min(leftover_amount,resource_copies[k].stored[0].amount)*resource_copies[k].stored[0].quality
						leftover_amount -= min(leftover_amount,a)
						resource_copies[k].remove_from_storage(stored_resource.new(self,min(leftover_amount,resource_copies[k].stored[0].amount),0,0,0))
					final_quality += (quality_step/(total_production*j.ingredient_per_kg[k]))*resource_copies[k].quality_coefficient
				if total_production > 0:
					resource_copies["chocolate"].add_to_storage(total_production,final_quality)
				break
	var supply = max(1.0, resource_copies["chocolate"].total_stored_amount)
	for i in rival_companies.values():
		supply += max(0.0, i.total_stock)
	var s_d_price = resource_copies["chocolate"].base_value * demand / max(1.0, supply)
	var supply_quality = 0
	
	if resource_copies["chocolate"].total_stored_amount > 0:
		for item in resource_copies["chocolate"].stored:
			supply_quality += item.amount * item.quality
		supply_quality /= max(1.0, resource_copies["chocolate"].total_stored_amount)
	else:
		supply_quality = 0
	var denom = sale_price - supply_quality * resource_copies["chocolate"].quality_coefficient
	if abs(denom) < 0.0001:
		denom = 0.0001
	var total_publicity := 0.0
	var percieved_publicity
	if s_d_price > 0 and sale_price > 0:
		percieved_publicity = publicity * (1.0 + max(0.0, sentiment)) * (s_d_price / denom)**2
		total_publicity = percieved_publicity
	else:
		percieved_publicity = publicity * (1.0 + max(0.0, sentiment))
		total_publicity = publicity * (1.0 + max(0.0, sentiment))
	var p_publicities: Dictionary
	for i:rival_company in rival_companies.values():
		var r_supply_quality := 0.0
		if i.total_stock > 0:
			for j in i.stock:
				r_supply_quality += j.amount * j.quality
			r_supply_quality /= max(1.0, i.total_stock)
		else:
			r_supply_quality = 0

		var r_denom = i.price - r_supply_quality * resource_copies["chocolate"].quality_coefficient
		if abs(r_denom) < 0.0001:
			r_denom = 0.0001

		if s_d_price > 0 and i.price > 0:
			p_publicities[i.id] = i.publicity * (1.0 + max(0.0, i.public_sentiment)) * (s_d_price / r_denom)**2
			total_publicity += i.publicity * (1.0 + max(0.0, i.public_sentiment)) * (s_d_price / r_denom)**2
		else:
			p_publicities[i.id] = i.publicity * (1.0 + max(0.0, i.public_sentiment))
			total_publicity += i.publicity * (1.0 + max(0.0, i.public_sentiment))
	var base_ratio := 0.0
	if total_publicity > 0:
		base_ratio = clamp(percieved_publicity / total_publicity, 0.0, 1.0)
	else:
		base_ratio = 0.0

	var sale_base := int(min(base_ratio * demand, resource_copies["chocolate"].total_stored_amount))
	if is_nan(sale_base):
		sale_base = 0
	$main_tabs/sales/contents/company_infos/player_company_info/infos/sales_new.text = str(Utility.shorten_number(sale_base)[0]) +" kg" 
	$main_tabs/sales/contents/company_infos/player_company_info/infos/revenue_new.text = str(Utility.shorten_number(sale_base*$main_tabs/sales/contents/company_infos/player_company_info/infos/price_new.value)[0])+" CHF"

func sales_estimate_current():
	var unallocated_workers = employee_groups["workers"].active_employees
	var resource_copies: Dictionary
	for i:resource_type in resources.values():
		resource_copies[i.type_name] = i.copy()
	for i in resource_copies.keys():
		if i == "chocolate":
			continue
		if resource_copies[i].usage_priority == 0:
			resource_copies[i].stored.sort_custom(Utility.sort_0)
		elif resource_copies[i].usage_priority == 1:
			resource_copies[i].stored.sort_custom(Utility.sort_1)
		elif resource_copies[i].usage_priority == 2:
			resource_copies[i].stored.sort_custom(Utility.sort_2)
		elif resource_copies[i].usage_priority == 3:
			resource_copies[i].stored.sort_custom(Utility.sort_3)
		elif resource_copies[i].usage_priority == 4:
			resource_copies[i].stored.sort_custom(Utility.sort_4)
		elif resource_copies[i].usage_priority == 5:
			resource_copies[i].stored.sort_custom(Utility.sort_5)
		elif resource_copies[i].usage_priority == 6:
			resource_copies[i].stored.sort_custom(Utility.sort_6)
		elif resource_copies[i].usage_priority == 7:
			resource_copies[i].stored.sort_custom(Utility.sort_7)
	
	for i in range(production_methods.size()):
		for j in production_methods.values():
			if j.priority == i:
				var operated_machines = min(floor(unallocated_workers/j.required_workers_per_machine),j.active_machines)
				unallocated_workers -= operated_machines*j.required_workers_per_machine
				var max_production = employee_groups["workers"].effectivity_per_day*65*operated_machines*j.output_per_hour
				var total_production = max_production
				for k in resource_copies.keys():
					if k == "chocolate":
						continue
					total_production = min(total_production,resource_copies[k].total_stored_amount/j.ingredient_per_kg[k])
				var final_quality = j.quality_modifier
				for k in resource_copies.keys():
					
					if k == "chocolate":
						continue
					var leftover_amount = total_production*j.ingredient_per_kg[k]
					var quality_step = 0
					while leftover_amount > 0:
						var a = resource_copies[k].stored[0].amount
						quality_step +=min(leftover_amount,resource_copies[k].stored[0].amount)*resource_copies[k].stored[0].quality
						leftover_amount -= min(leftover_amount,a)
						resource_copies[k].remove_from_storage(stored_resource.new(self,min(leftover_amount,resource_copies[k].stored[0].amount),0,0,0))
					final_quality += (quality_step/(total_production*j.ingredient_per_kg[k]))*resource_copies[k].quality_coefficient
				if total_production > 0:
					resource_copies["chocolate"].add_to_storage(total_production,final_quality)
				break
	$main_tabs/sales/contents/company_infos/player_company_info/infos2/stock_val.text = str(Utility.shorten_number(resource_copies["chocolate"].total_stored_amount)[1]) + " kg"
	$main_tabs/sales/contents/company_infos/player_company_info/infos/price_now.text = str(sale_price) +" CHF/kg"
	$main_tabs/sales/contents/company_infos/player_company_info/infos/price_new.value = sale_price 
	var supply = max(1.0, resource_copies["chocolate"].total_stored_amount)
	for i in rival_companies.values():
		supply += max(0.0, i.total_stock)
	var s_d_price = resource_copies["chocolate"].base_value * demand / max(1.0, supply)
	var supply_quality = 0
	
	if resource_copies["chocolate"].total_stored_amount > 0:
		for item in resource_copies["chocolate"].stored:
			supply_quality += item.amount * item.quality
		supply_quality /= max(1.0, resource_copies["chocolate"].total_stored_amount)
	else:
		supply_quality = 0.0
	$main_tabs/sales/contents/company_infos/player_company_info/infos2/quality_val.text = str(Utility.shorten_number(supply_quality)[0])
	var denom = sale_price - supply_quality * resource_copies["chocolate"].quality_coefficient
	if abs(denom) < 0.0001:
		denom = 0.0001
	var total_publicity := 0.0
	var percieved_publicity
	if s_d_price > 0 and sale_price > 0:
		percieved_publicity = publicity * (1.0 + max(0.0, sentiment)) * (s_d_price / denom)**2
		total_publicity = percieved_publicity
	else:
		percieved_publicity = publicity * (1.0 + max(0.0, sentiment))
		total_publicity = publicity * (1.0 + max(0.0, sentiment))
	var p_publicities: Dictionary
	var r_denoms = {}
	for i:rival_company in rival_companies.values():
		var r_supply_quality := 0.0
		if i.total_stock > 0:
			for j in i.stock:
				r_supply_quality += j.amount * j.quality
			r_supply_quality /= max(1.0, i.total_stock)
		else:
			r_supply_quality = 0
		i.average_quality = r_supply_quality
		r_denoms[i.id] = i.price - r_supply_quality * resource_copies["chocolate"].quality_coefficient
		if abs(r_denoms[i.id]) < 0.0001:
			r_denoms[i.id] = 0.0001

		if s_d_price > 0 and i.price > 0:
			p_publicities[i.id] = i.publicity * (1.0 + max(0.0, i.public_sentiment)) * (s_d_price / r_denoms[i.id])**2
			total_publicity += i.publicity * (1.0 + max(0.0, i.public_sentiment)) * (s_d_price / r_denoms[i.id])**2
		else:
			p_publicities[i.id] = i.publicity * (1.0 + max(0.0, i.public_sentiment))
			total_publicity += i.publicity * (1.0 + max(0.0, i.public_sentiment))
	var base_ratio := 0.0
	if total_publicity > 0:
		base_ratio = clamp(percieved_publicity / total_publicity, 0.0, 1.0)
	else:
		base_ratio = 0.0

	var sale_base := int(min(base_ratio * demand, resource_copies["chocolate"].total_stored_amount))
	for i: rival_company in rival_companies.values():
		var r_base_ratio := 0.0
		if total_publicity > 0:
			r_base_ratio = clamp(randf_range(0.9, 1.1) * p_publicities[i.id] / total_publicity, 0.0, 1.0)
		else:
			r_base_ratio = 0.0
		
		var r_sale_base = int(min(r_base_ratio * demand, max(0.0, i.total_stock)))
		i.predicted_sales = r_sale_base
	if is_nan(sale_base):
		sale_base = 0
	$main_tabs/sales/contents/company_infos/player_company_info/infos/sales_now.text = str(Utility.shorten_number(sale_base)[0]) +" kg" 
	$main_tabs/sales/contents/company_infos/player_company_info/infos/revenue_now.text = str(Utility.shorten_number(sale_base*sale_price)[0])+" CHF"
	var pm_copy: float = player_money
	if money_trace[-1][0] == "taxes":
		money_trace.remove_at(-1)
		money_trace.remove_at(-1)
		money_trace.remove_at(-1)
		money_trace.remove_at(-1)
	
	var sale_revenue:float = sale_base*sale_price
	pm_copy = pm_copy+sale_revenue
	money_trace.append(["sales",pm_copy])
	money_trace.append(["pm_maintenance",[]])
	for i:production_method in production_methods.values():
		if i.active_machines > 0:
			money_trace[-1][1].append([i.id,pm_copy-i.active_machines*i.maintenance_cost])
			pm_copy -= i.active_machines*i.maintenance_cost
	money_trace.append(["employee_salary",[]])
	for i:employee_group in employee_groups.values():
		money_trace[-1][1].append([i.id,pm_copy-i.active_employees*i.salary*3])
		pm_copy -= i.active_employees*i.salary*3
	var net_profit = pm_copy-money_trace[0][1]
	var taxable_profit = max(0,net_profit-loss_cf)
	loss_cf += taxable_profit - net_profit
	loss_cf = min(loss_cf,0)
	var kg_tax = taxable_profit*canton_tax_rate*total_tax_rate
	var federal_tax = (taxable_profit*federal_tax_rate)/(1+federal_tax_rate)
	var total_tax =  kg_tax+federal_tax
	money_trace.append(["taxes",pm_copy-total_tax])
func load_new_price():
	sale_price = $main_tabs/sales/contents/company_infos/player_company_info/infos/price_new.value
	sales_estimate_current()
	var c_sri = selected_rival_id
	load_rival_info(c_sri)
	load_rival_info(c_sri)
func cancel_new_price():
	$main_tabs/sales/contents/company_infos/player_company_info/infos/price_new.value=sale_price
func load_rival_info(id):
	if id == selected_rival_id:
		selected_rival_id = ""
		$main_tabs/sales/contents/company_infos/computer_company_info.visible = false
	else:
		selected_rival_id = id
		$main_tabs/sales/contents/company_infos/computer_company_info/computer_company_title.text = language_dict["dynamic"]["rival_companies"][id]
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/price_val.text = str(Utility.shorten_number(rival_companies[id].price)[0]) + " CHF/kg"
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/sales_val.text =  str(Utility.shorten_number(rival_companies[id].predicted_sales)[0]) + " kg"
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/revenue_val.text =  str(Utility.shorten_number(rival_companies[id].predicted_sales*rival_companies[id].price)[0]) + " CHF"
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/quality_val.text = str(Utility.shorten_number(rival_companies[id].average_quality)[0])
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/stock_val.text = str(Utility.shorten_number(rival_companies[id].total_stock)[0])+" kg"
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/publicity_val.text = str(Utility.shorten_number(rival_companies[id].publicity)[0])
		$main_tabs/sales/contents/company_infos/computer_company_info/infos/sentiment_val.text = str(Utility.shorten_number(rival_companies[id].public_sentiment)[0])
		$main_tabs/sales/contents/company_infos/computer_company_info.visible = true
func setup_sales_tab():
	selected_rival_id = ""
	$main_tabs/sales/contents/company_infos/computer_company_info.visible = false
	for i in $main_tabs/sales/contents/computer_company_list/companies_scroll/companies_container.get_children():
		i.queue_free()
	for i:rival_company in rival_companies.values():
		var btn:Button = Button.new()
		btn.add_theme_font_size_override("font_size",30)
		btn.custom_minimum_size = Vector2(310,100)
		btn.text = language_dict["dynamic"]["rival_companies"][i.id]
		btn.pressed.connect( Callable(self,"load_rival_info").bind(i.id))
		$main_tabs/sales/contents/computer_company_list/companies_scroll/companies_container.add_child(btn)
		
	$main_tabs/sales/contents/company_infos/player_company_info/infos2/publicity_val.text = str(Utility.shorten_number(publicity)[0])
	$main_tabs/sales/contents/company_infos/player_company_info/infos2/sentiment_val.text = str(Utility.shorten_number(sentiment)[0])
	sales_estimate_current()
	var mt:Tree = $main_tabs/sales/contents/money_trace
	mt.clear()
	var root = mt.create_item()
	root.set_expand_right(0,true)
	mt.hide_root = false
	root.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	root.set_text(0,language_dict["dynamic"]["money_trace"]["title"])
	var column_titles = mt.create_item(root)
	column_titles.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
	column_titles.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
	column_titles.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
	column_titles.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
	column_titles.set_text(0,language_dict["dynamic"]["money_trace"]["cause"])
	column_titles.set_text(1,language_dict["dynamic"]["money_trace"]["change"])
	column_titles.set_text(2,language_dict["dynamic"]["money_trace"]["balance"])
	column_titles.set_text(3,language_dict["dynamic"]["money_trace"]["status"])
	var last_balance = 0
	for i in range(money_trace.size()):
		var row = mt.create_item(root)
		row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
		row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
		row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
		row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
		if money_trace[i][0] == "start_turn":
			row.set_text(0,language_dict["dynamic"]["money_trace"]["start_balance"])
			row.set_text(2,str(Utility.shorten_number(money_trace[i][1])[1]))
			row.set_text(3,language_dict["dynamic"]["money_trace"]["balance_indicator"])
			last_balance = money_trace[i][1]
		elif money_trace[i][0] == "contracts":
			var last_c_balance = last_balance
			for j in range(money_trace[i][1].size()):
				var company_row = mt.create_item(row)
				company_row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
				company_row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
				company_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
				company_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
				company_row.set_text(0,language_dict["dynamic"]["money_trace"]["contract_with"].format({"0":language_dict["dynamic"]["resource_companies"]["names"][money_trace[i][1][j][0]]}))
				company_row.set_text(1,str(Utility.shorten_number(money_trace[i][1][j][1]-last_c_balance)[1]))
				company_row.set_text(2,str(Utility.shorten_number(money_trace[i][1][j][1])[1]))
				company_row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
				last_c_balance = money_trace[i][1][j][1]
			row.set_text(0,language_dict["dynamic"]["money_trace"]["resource_contracts"])
			if money_trace[i][1].size() == 0:
				row.set_text(1,str(0))
				row.set_text(2,str(Utility.shorten_number(last_balance)[1]))
			else:
				row.set_text(1,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1]-last_balance)[1]))
				row.set_text(2,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1])[1]))
				last_balance = money_trace[i][1][money_trace[i][1].size()-1][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
		elif money_trace[i][0] == "events":
			var last_c_balance = last_balance
			for j in range(money_trace[i][1].size()):
				var event_row = mt.create_item(row)
				event_row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
				event_row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
				event_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
				event_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
				event_row.set_text(0,language_dict["dynamic"]["money_trace"]["event_effect"].format({"0":language_dict["dynamic"]["events"][money_trace[i][1][j][0]]["name"]}))
				event_row.set_text(1,str(Utility.shorten_number(money_trace[i][1][j][1]-last_c_balance)[1]))
				event_row.set_text(2,str(Utility.shorten_number(money_trace[i][1][j][1])[1]))
				event_row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
				last_c_balance = money_trace[i][1][j][1]
			row.set_text(0,language_dict["dynamic"]["money_trace"]["events"])
			if money_trace[i][1].size() == 0:
				row.set_text(1,str(0))
				row.set_text(2,str(Utility.shorten_number(last_balance)[1]))
			else:
				row.set_text(1,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1]-last_balance)[1]))
				row.set_text(2,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1])[1]))
				last_balance = money_trace[i][1][money_trace[i][1].size()-1][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
		elif money_trace[i][0] == "rnd_perks":
			var last_c_balance = last_balance
			for j in range(money_trace[i][1].size()):
				var perk_row = mt.create_item(row)
				perk_row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
				perk_row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
				perk_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
				perk_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
				var tree_id = ""
				for k in rnd_trees.values():
					for l in k.all_nodes:
						for m:rnd_node in l:
							if m.id == money_trace[i][1][j][0]:
								tree_id = k.id
				perk_row.set_text(0,language_dict["dynamic"]["money_trace"]["perk_effect"].format({"0":language_dict["dynamic"]["rnd_trees"][tree_id][money_trace[i][1][0]]["name"]}))
				perk_row.set_text(1,str(Utility.shorten_number(money_trace[i][1][j][1]-last_c_balance)[1]))
				perk_row.set_text(2,str(Utility.shorten_number(money_trace[i][1][j][1])[1]))
				perk_row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
				last_c_balance = money_trace[i][1][j][1]
			row.set_text(0,language_dict["dynamic"]["money_trace"]["rnd_perks"])
			if money_trace[i][1].size() == 0:
				row.set_text(1,str(0))
				row.set_text(2,str(Utility.shorten_number(last_balance)[1]))
			else:
				row.set_text(1,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1]-last_balance)[1]))
				row.set_text(2,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1])[1]))
				last_balance = money_trace[i][1][money_trace[i][1].size()-1][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
		elif money_trace[i][0] == "pre_player":
			row.set_text(0,language_dict["dynamic"]["money_trace"]["pre_player_action_balance"])
			row.set_text(2,str(Utility.shorten_number(money_trace[i][1])[1]))
			last_balance = money_trace[i][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["balance_indicator"])
		elif money_trace[i][0] == "player_actions":
			var last_c_balance = last_balance
			for j in money_trace[i][1]:
				var pa_row = mt.create_item(row)
				pa_row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
				pa_row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
				pa_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
				pa_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
				pa_row.set_text(1,str(Utility.shorten_number(j[1]-last_c_balance)[1]))
				pa_row.set_text(2,str(Utility.shorten_number(j[1])[1]))
				pa_row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
				if j[2] == "rnd_node":
					var tree_id = ""
					for k in rnd_trees.values():
						for l in k.all_nodes:
							for m:rnd_node in l:
								if m.id == j[0]:
									tree_id = k.id
					pa_row.set_text(0,language_dict["dynamic"]["money_trace"]["rnd_buy"].format({"0":language_dict["dynamic"]["rnd_trees"][tree_id][j[0]]["name"]}))
				else:
					pa_row.set_text(0,language_dict["dynamic"]["money_trace"]["pm_buy"].format({"0":language_dict["dynamic"]["production_methods"][j[0]]}))
				last_c_balance = j[1]
			row.set_text(0,language_dict["dynamic"]["money_trace"]["player_actions"])
			if money_trace[i][1].size() == 0:
				row.set_text(1,str(0))
				row.set_text(2,str(Utility.shorten_number(last_balance)[1]))
			else:
				row.set_text(1,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1]-last_balance)[1]))
				row.set_text(2,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1])[1]))
				last_balance = money_trace[i][1][money_trace[i][1].size()-1][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_completed"])
		elif money_trace[i][0] == "sales":
			row.set_text(0,language_dict["dynamic"]["money_trace"]["expected_sales"])
			row.set_text(1,str(Utility.shorten_number(money_trace[i][1]-last_balance)[1]))
			row.set_text(2,str(Utility.shorten_number(money_trace[i][1])[1]))
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_not_completed"])
			last_balance = money_trace[i][1]
		elif money_trace[i][0] == "pm_maintenance":
			var last_c_balance = last_balance
			for j in range(money_trace[i][1].size()):
				var pm_row = mt.create_item(row)
				pm_row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
				pm_row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
				pm_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
				pm_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
				pm_row.set_text(0,language_dict["dynamic"]["money_trace"]["maintenance"].format({"0":language_dict["dynamic"]["production_methods"][money_trace[i][1][j][0]]}))
				pm_row.set_text(1,str(Utility.shorten_number(money_trace[i][1][j][1]-last_c_balance)[1]))
				pm_row.set_text(2,str(Utility.shorten_number(money_trace[i][1][j][1])[1]))
				pm_row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_not_completed"])
				last_c_balance = money_trace[i][1][j][1]
			row.set_text(0,language_dict["dynamic"]["money_trace"]["pm_maintenance"])
			if money_trace[i][1].size() == 0:
				row.set_text(1,str(0))
				row.set_text(2,str(Utility.shorten_number(last_balance)[1]))
			else:
				row.set_text(1,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1]-last_balance)[1]))
				row.set_text(2,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1])[1]))
				last_balance = money_trace[i][1][money_trace[i][1].size()-1][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_not_completed"])
		elif money_trace[i][0] == "employee_salary":
			var last_c_balance = last_balance
			for j in range(money_trace[i][1].size()):
				var pm_row = mt.create_item(row)
				pm_row.set_text_alignment(0,HORIZONTAL_ALIGNMENT_LEFT)
				pm_row.set_text_alignment(1,HORIZONTAL_ALIGNMENT_RIGHT)
				pm_row.set_text_alignment(2,HORIZONTAL_ALIGNMENT_RIGHT)
				pm_row.set_text_alignment(3,HORIZONTAL_ALIGNMENT_RIGHT)
				pm_row.set_text(0,language_dict["dynamic"]["money_trace"]["employee_salary"].format({"0":language_dict["dynamic"]["employee_groups"][money_trace[i][1][j][0]]["name"]}))
				pm_row.set_text(1,str(Utility.shorten_number(money_trace[i][1][j][1]-last_c_balance)[1]))
				pm_row.set_text(2,str(Utility.shorten_number(money_trace[i][1][j][1])[1]))
				pm_row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_not_completed"])
				last_c_balance = money_trace[i][1][j][1]
			row.set_text(0,language_dict["dynamic"]["money_trace"]["employee_salaries"])
			if money_trace[i][1].size() == 0:
				row.set_text(1,str(0))
				row.set_text(2,str(Utility.shorten_number(last_balance)[1]))
			else:
				row.set_text(1,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1]-last_balance)[1]))
				row.set_text(2,str(Utility.shorten_number(money_trace[i][1][money_trace[i][1].size()-1][1])[1]))
				last_balance = money_trace[i][1][money_trace[i][1].size()-1][1]
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_not_completed"])
		elif money_trace[i][0] == "taxes":
			row.set_text(0,language_dict["dynamic"]["money_trace"]["taxes"])
			row.set_text(1,str(Utility.shorten_number(money_trace[i][1]-last_balance)[1]))
			row.set_text(2,str(Utility.shorten_number(money_trace[i][1])[1]))
			row.set_text(3,language_dict["dynamic"]["money_trace"]["transaction_not_completed"])
			last_balance = money_trace[i][1]	
func unload_sales_tab():
	$main_tabs/sales/contents/company_infos/computer_company_info.visible = false
	for i in $main_tabs/sales/contents/computer_company_list/companies_scroll/companies_container.get_children():
		i.queue_free()
func _process(_delta):
	if $main_tabs/rnd/rnd_tabs.is_visible_in_tree():
		last_viewed_tab = $main_tabs/rnd/rnd_tabs.current_tab
	$money_display.text = language_dict["dynamic"]["displays"]["money"].format({"0":Utility.shorten_number(player_money)[1]})
	if $main_tabs/sales/contents/company_infos/player_company_info/infos2/confirm.is_visible_in_tree():
		if $main_tabs/sales/contents/company_infos/player_company_info/infos/price_new.value == sale_price:
			$main_tabs/sales/contents/company_infos/player_company_info/infos2/confirm.disabled = true
			$main_tabs/sales/contents/company_infos/player_company_info/infos2/cancel.disabled = true
		else:
			$main_tabs/sales/contents/company_infos/player_company_info/infos2/confirm.disabled = false
			$main_tabs/sales/contents/company_infos/player_company_info/infos2/cancel.disabled = false
		sales_estimate_new()
	if $main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort.is_visible_in_tree():
		if selected_resource_id != "":
			var new_usage_prio =  4*$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/sort_by_option.selected+2*$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/age_sort_option.selected+$main_tabs/resources/resource_overview/resource_info/ri_container/usage_sort/quality_sort_option.selected
			if resources[selected_resource_id].usage_priority != new_usage_prio:
				resources[selected_resource_id].usage_priority = new_usage_prio
				change_sort()
	if $main_tabs/resources/new_contract.is_visible_in_tree():
		new_price = rp_companies[selected_rc_id].base_price*(1-min(5,max(-5,rp_companies[selected_rc_id].sentiment))/100)
		$main_tabs/resources/new_contract/terms/price_val.text =str(Utility.shorten_number(new_price*$main_tabs/resources/new_contract/terms/amount_val.value)[0])+" CHF"
		$main_tabs/resources/new_contract/terms/duration_val.get_line_edit().text = "%.2f" % $main_tabs/resources/new_contract/terms/duration_val.value
func unload_event_tab():
	$main_tabs/events/event_info_panel.visible = false
	var event_wiki: GridContainer = $main_tabs/events/events_container/overview/base_event_scroll/base_event_container
	$main_tabs/events/active_event_info/info_panel_container/timeline.clear()
	for child in event_wiki.get_children():
		child.queue_free()
func setup_event_tab():
	$main_tabs/events/event_info_panel.visible = false
	var event_wiki: GridContainer = $main_tabs/events/events_container/overview/base_event_scroll/base_event_container
	for i in range(events_dict.size()):
		for j in events_dict.keys():
			if events_dict[j].num_id == i:
				var btn = Button.new()
				var affected_var_list:String = ""
				for k in range(events_dict[j].affected_variables.size()):
					affected_var_list += language_dict["dynamic"]["variable_names"][events_dict[j].affected_variables[k]] + ", "
				btn.text = language_dict["dynamic"]["event_infos"]["short_event_description"].format({"0":language_dict["dynamic"]["events"][events_dict[j].name]["name"],"1":events_dict[j].active,"2":affected_var_list})
				btn.autowrap_mode =TextServer.AUTOWRAP_WORD_SMART
				btn.connect("pressed", Callable(self,"_on_event_type_selected").bind(events_dict[j]))
				btn.custom_minimum_size = Vector2(400,200)
				event_wiki.add_child(btn)
	var special_event_wiki: HBoxContainer = $main_tabs/events/events_container/overview/short_event_scroll/short_event_container
	for child in special_event_wiki.get_children():
		child.queue_free()
	for i in range(special_events_dict.size()):
		for j in special_events_dict.keys():
			if special_events_dict[j].num_id == i:
				var btn = Button.new()
				if special_events_dict[j].type == "func":
					btn.text = language_dict["dynamic"]["event_infos"]["short_special_event_description_func"].format({"0":language_dict["dynamic"]["events"][special_events_dict[j].name]["name"],"1":language_dict["dynamic"]["function_names"][special_events_dict[j].function_name]})
				else:
					btn.text = language_dict["dynamic"]["event_infos"]["short_special_event_description_var"].format({"0":language_dict["dynamic"]["events"][special_events_dict[j].name]["name"],"1":language_dict["dynamic"]["variable_names"][special_events_dict[j].variable]})
				btn.autowrap_mode =TextServer.AUTOWRAP_WORD_SMART
				btn.connect("pressed", Callable(self,"_on_event_type_selected").bind(special_events_dict[j]))
				btn.custom_minimum_size = Vector2(400,200)
				special_event_wiki.add_child(btn)
	var active_event_container: VBoxContainer = $main_tabs/events/events_container/active_events/active_events_scroll/active_events_container
	for child in active_event_container.get_children():
		child.queue_free()
	for j in active_events:
		var btn = Button.new()
		var effects_string = ""
		for i in range(j.stages[turn-j.started_on_turn].size()-1):
			if j.stages[turn-j.started_on_turn][i].effect_type == "func":
				effects_string += language_dict["dynamic"]["event_infos"]["active_event_func_call"].format({"0":language_dict["dynamic"]["function_names"][j.stages[turn-j.started_on_turn][i].function]})
			elif j.stages[turn-j.started_on_turn][i].value >= 0:
				effects_string += language_dict["dynamic"]["variable_names"][j.stages[turn-j.started_on_turn][i].variable] + " + " + str(Utility.shorten_number(j.stages[turn-j.started_on_turn][i].value)[0])
			else:
				effects_string += language_dict["dynamic"]["variable_names"][j.stages[turn-j.started_on_turn][i].variable] + " - " + str(abs(Utility.shorten_number(j.stages[turn-j.started_on_turn][i].value)[0]))
			effects_string += "\n"
		if j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].effect_type == "func":
			effects_string += language_dict["dynamic"]["event_infos"]["active_event_func_call"].format({"0":language_dict["dynamic"]["function_names"][j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].function]})
		elif j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].value >= 0:
			effects_string += language_dict["dynamic"]["variable_names"][j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].variable] + " + " + str(Utility.shorten_number(j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].value)[0])
		else:
			effects_string += language_dict["dynamic"]["variable_names"][j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].variable] + " - " + str(abs(Utility.shorten_number(j.stages[turn-j.started_on_turn][j.stages[turn-j.started_on_turn].size()-1].value)[0]))
		btn.text = language_dict["dynamic"]["event_infos"]["active_event_short"].format({"0":language_dict["dynamic"]["events"][j.name]["name"],"1":Utility.round_to_date(j.started_on_turn),"2":effects_string})
		btn.autowrap_mode =TextServer.AUTOWRAP_WORD_SMART
		btn.connect("pressed", Callable(self,"_on_active_event_selected").bind(j))
		btn.custom_minimum_size = Vector2(610,150)
		active_event_container.add_child(btn)
func _on_event_type_selected(event):
	$main_tabs/events/active_event_info.visible = false
	var info_panel = $main_tabs/events/event_info_panel
	if info_panel.visible:
		if ip_displayed_event == event:
			info_panel.visible = false
			ip_displayed_event = null
			return
	ip_displayed_event = event
	if event is event_type:
		$main_tabs/events/event_info_panel/info_panel_container/name.text = language_dict["dynamic"]["events"][event.name]["name"]
		$main_tabs/events/event_info_panel/info_panel_container/description.text = language_dict["dynamic"]["events"][event.name]["description"]
		var affected_var_list = ""
		for k in range(event.affected_variables.size()):
			affected_var_list += language_dict["dynamic"]["variable_names"][event.affected_variables[k]] + ", "
		$main_tabs/events/event_info_panel/info_panel_container/affected_variables.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["affected_variables"].format({"0":affected_var_list})
		$main_tabs/events/event_info_panel/info_panel_container/probability.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["probability"].format({"0":Utility.shorten_number(event.base_probability*100)[0],"1":Utility.shorten_number(event.probability_modifier*100)[0],"2": Utility.shorten_number(event.probability_modifier*100+event.base_probability*100)[0]})
		$main_tabs/events/event_info_panel/info_panel_container/active.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["active"].format({"0":event.active})
		var min_dur = 0
		var max_dur = 0
		for i in event.phase_duration_ranges:
			min_dur += i[0]
			max_dur += i[1]
		$main_tabs/events/event_info_panel/info_panel_container/total_duration.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["total_duration"].format({"0":min_dur/4,"1":max_dur/4})
		$main_tabs/events/event_info_panel/info_panel_container/phases.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["phases_amount"].format({"0":event.phase_duration_ranges.size()})
		var excl_event_list = ""
		if event.excludes.size() > 0:
			for k in range(event.excludes.size()-1):
				excl_event_list += language_dict["dynamic"]["events"][event.excludes[k]]["name"] + ", "
			excl_event_list += language_dict["dynamic"]["variable_names"][event.excludes[event.excludes.size()-1]]["name"]
			$main_tabs/events/event_info_panel/info_panel_container/excludes.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["excludes"].format({"0":excl_event_list})
		else:
			$main_tabs/events/event_info_panel/info_panel_container/excludes.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["excludes_none"]
		$main_tabs/events/event_info_panel/info_panel_container/requirements.text = language_dict["dynamic"]["event_infos"]["full_event_description"]["requirements"] + Utility.generate_requirement_text(event.requirements,0,"",language_dict["dynamic"])
	else:
		$main_tabs/events/event_info_panel/info_panel_container/name.text = language_dict["dynamic"]["events"][event.name]["name"]
		$main_tabs/events/event_info_panel/info_panel_container/description.text = language_dict["dynamic"]["events"][event.name]["description"]
		$main_tabs/events/event_info_panel/info_panel_container/affected_variables.text = ""
		$main_tabs/events/event_info_panel/info_panel_container/probability.text = ""
		$main_tabs/events/event_info_panel/info_panel_container/active.text = ""
		$main_tabs/events/event_info_panel/info_panel_container/total_duration.text = ""
		$main_tabs/events/event_info_panel/info_panel_container/phases.text = ""
		$main_tabs/events/event_info_panel/info_panel_container/excludes.text = ""
		$main_tabs/events/event_info_panel/info_panel_container/requirements.text = ""
	info_panel.visible = true
func _on_active_event_selected(event: active_event):
	$main_tabs/events/event_info_panel.visible = false
	var info_panel = $main_tabs/events/active_event_info
	if info_panel.visible:
		if ip_displayed_event == event:
			info_panel.visible = false
			ip_displayed_event = null
			return
	ip_displayed_event = event
	$main_tabs/events/active_event_info/info_panel_container/name.text = language_dict["dynamic"]["events"][event.name]["name"]
	$main_tabs/events/active_event_info/info_panel_container/active.text = language_dict["dynamic"]["event_infos"]["full_active_description"]["active"].format({"0":Utility.round_to_date(turn)})
	var timeline:Tree = $main_tabs/events/active_event_info/info_panel_container/timeline
	timeline.clear()
	var root = timeline.create_item()
	root.set_expand_right(0,true)
	timeline.hide_root = false
	root.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	root.set_text(0,language_dict["dynamic"]["event_infos"]["full_active_description"]["timeline_title"])
	for i in range(event.current_stage+1):
		
		var turn_ = timeline.create_item(root)
		turn_.set_expand_right(0,true)
		turn_.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
		turn_.set_text(0,Utility.round_to_date(event.started_on_turn+i))
		for j:effect in event.stages[i]:
			var stage = timeline.create_item(turn_)
			stage.set_text_alignment(0,HORIZONTAL_ALIGNMENT_RIGHT)
			stage.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
			stage.set_text_alignment(2,HORIZONTAL_ALIGNMENT_LEFT)
			if j.effect_type == "func":
				stage.set_text(0,language_dict["dynamic"]["event_infos"]["full_active_description"]["timeline_function"])
				stage.set_text(2,language_dict["dynamic"]["function_names"][j.function])
			else:
				stage.set_text(0,language_dict["dynamic"]["variable_names"][j.variable])
				if j.value >= 0:
					stage.set_text(1,"+")
				else:
					stage.set_text(1,"-")
				stage.set_text(2,str(Utility.shorten_number(abs(j.value))[1]))
	info_panel.visible = true
func production_preview():
	var preview_tree:Tree = $main_tabs/production/employees_preview/production_preview
	preview_tree.clear()
	var root = preview_tree.create_item()
	root.set_expand_right(0,true)
	preview_tree.hide_root = false
	root.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	root.set_text(0,language_dict["dynamic"]["production_preview"]["preview_title"])
	var resource_ti: TreeItem = preview_tree.create_item(root)
	resource_ti.set_text(0,language_dict["dynamic"]["production_preview"]["resource"])
	resource_ti.set_text(1,language_dict["dynamic"]["production_preview"]["stored"])
	resource_ti.set_text(2,language_dict["dynamic"]["production_preview"]["used"])
	resource_ti.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	resource_ti.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
	resource_ti.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
	var method_ti: TreeItem = preview_tree.create_item(root)
	method_ti.set_text(0,language_dict["dynamic"]["production_preview"]["method"])
	method_ti.set_text(1,language_dict["dynamic"]["production_preview"]["workers"])
	method_ti.set_text(2,language_dict["dynamic"]["production_preview"]["produced"])
	method_ti.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	method_ti.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
	method_ti.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
	var unallocated_workers = employee_groups["workers"].active_employees
	for i in resources.keys():
		if i == "chocolate":
			continue
		if resources[i].usage_priority == 0:
			resources[i].stored.sort_custom(Utility.sort_0)
		elif resources[i].usage_priority == 1:
			resources[i].stored.sort_custom(Utility.sort_1)
		elif resources[i].usage_priority == 2:
			resources[i].stored.sort_custom(Utility.sort_2)
		elif resources[i].usage_priority == 3:
			resources[i].stored.sort_custom(Utility.sort_3)
		elif resources[i].usage_priority == 4:
			resources[i].stored.sort_custom(Utility.sort_4)
		elif resources[i].usage_priority == 5:
			resources[i].stored.sort_custom(Utility.sort_5)
		elif resources[i].usage_priority == 6:
			resources[i].stored.sort_custom(Utility.sort_6)
		elif resources[i].usage_priority == 7:
			resources[i].stored.sort_custom(Utility.sort_7)
	var full_production = {"cocoa":0,"sugar":0,"milk_powder":0,"nuts":0,"chocolate":0}
	var average_quality: float = 0
	for i in range(production_methods.size()):
		for j:production_method in production_methods.values():
			if not j.unlocked:
				continue
			if j.priority == i:
				var operated_machines = min(floor(unallocated_workers/j.required_workers_per_machine),j.active_machines)
				unallocated_workers -= operated_machines*j.required_workers_per_machine
				var max_production = employee_groups["workers"].effectivity_per_day*65*operated_machines*j.output_per_hour
				var total_production = max_production
				for k in resources.keys():
					if k == "chocolate":
						continue
					total_production = min(total_production,(resources[k].total_stored_amount-full_production[k])/j.ingredient_per_kg[k])
				var final_quality = j.quality_modifier
				for k in resources.keys():
					
					if k == "chocolate":
						continue
					var leftover_amount = total_production*j.ingredient_per_kg[k]
					var quality_step = 0
					var count = 0
					while leftover_amount > 0:
						var a = resources[k].stored[count].amount
						quality_step +=min(leftover_amount,resources[k].stored[count].amount)*resources[k].stored[count].quality
						leftover_amount -=  min(leftover_amount,a)
						count += 1
					final_quality += (quality_step/(total_production*j.ingredient_per_kg[k]))*resources[k].quality_coefficient
					full_production[k] += total_production*j.ingredient_per_kg[k]
				average_quality += total_production*final_quality
				full_production["chocolate"] += total_production
				var j_item = preview_tree.create_item(method_ti)
				j_item.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
				j_item.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
				j_item.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
				j_item.set_text(0,language_dict["dynamic"]["production_methods"][j.id])
				j_item.set_text(1,str(int(operated_machines*j.required_workers_per_machine)))
				j_item.set_text(2,str(Utility.shorten_number(total_production)[0]))
	for i in resources.keys():
		if i != "chocolate":
			var i_item = preview_tree.create_item(resource_ti)
			i_item.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
			i_item.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
			i_item.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
			i_item.set_text(0,language_dict["dynamic"]["resources"][i])
			i_item.set_text(1,str(Utility.shorten_number(resources[i].total_stored_amount)[0]))
			i_item.set_text(2,str(Utility.shorten_number(full_production[i])[0]))
	var result_ti: TreeItem = preview_tree.create_item((root))
	result_ti.set_text(0,language_dict["dynamic"]["production_preview"]["result"])
	average_quality /= full_production["chocolate"]
	result_ti.set_text(1,language_dict["dynamic"]["production_preview"]["result_quality"].format({"0":Utility.shorten_number(average_quality)[0]}))
	result_ti.set_text(2,language_dict["dynamic"]["production_preview"]["result_produced"].format({"0":Utility.shorten_number(full_production["chocolate"])[0]}))
	result_ti.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	result_ti.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
	result_ti.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
	var workers_ti: TreeItem = preview_tree.create_item((root))
	workers_ti.set_text(0,language_dict["dynamic"]["production_preview"]["total_workers"])
	workers_ti.set_text(1,language_dict["dynamic"]["production_preview"]["total"].format({"0":int(employee_groups["workers"].active_employees)}))
	workers_ti.set_text(2,language_dict["dynamic"]["production_preview"]["workers_used"].format({"0":int(employee_groups["workers"].active_employees-unallocated_workers)}))
	workers_ti.set_text_alignment(0,HORIZONTAL_ALIGNMENT_CENTER)
	workers_ti.set_text_alignment(1,HORIZONTAL_ALIGNMENT_CENTER)
	workers_ti.set_text_alignment(2,HORIZONTAL_ALIGNMENT_CENTER)
func pm_resort():
	var preview_tree:Tree = $main_tabs/production/employees_preview/production_preview
	preview_tree.clear()
	var pms = $main_tabs/production/production_methods/pm_scroll/pm_overview
	var children = pms.get_children()
	children.sort_custom(func(a:production_method_gui,b:production_method_gui): return a.pm.priority < b.pm.priority)
	for i:production_method_gui in children:
		pms.move_child(i,i.pm.priority)
		i.update_pm(production_methods[i.id])
	production_preview()
func pm_max_prio(id: String, old_priority: int):
	for i in range(old_priority):
		for j:production_method in production_methods.values():
			if j.priority  == i:
				j.priority += 1
				break
	production_methods[id].priority = 0
	pm_resort()
func pm_up_prio(id: String, old_priority: int):
	for i: production_method in production_methods.values():
		if i.priority == old_priority-1:
			i.priority = old_priority
			break
	production_methods[id].priority -= 1
	pm_resort()
func pm_down_prio(id: String, old_priority: int):
	for i: production_method in production_methods.values():
		if i.priority == old_priority+1:
			i.priority = old_priority
			break
	production_methods[id].priority += 1
	pm_resort()
func pm_disable(id: String, old_priority: int):
	for i in range(old_priority+1,unlocked_methods):
		for j:production_method in production_methods.values():
			if j.priority  == i:
				j.priority -= 1
				break
	production_methods[id].priority = unlocked_methods-1
	production_methods[id].active_machines = 0
	pm_resort()
func pm_confirm_active(id: String, new_active:int):
	production_methods[id].active_machines = new_active
	pm_resort()
func pm_confirm_purchase(id: String, new_total: int):
	player_money -= production_methods[id].price_per_machine*(new_total-production_methods[id].unlocked_machines)
	money_trace[5][1].append([id,player_money,"pm_buy"])
	production_methods[id].unlocked_machines = new_total
	pm_resort()
func eg_confirm(id: String, work_hours: float, salary: int, target: int):
	var preview_tree:Tree = $main_tabs/production/employees_preview/production_preview
	preview_tree.clear()
	employee_groups[id].target_employees = target
	employee_groups[id].work_hours = work_hours
	employee_groups[id].salary = salary
	hr_effect()
	employee_groups[id].update_values()
	for i:employee_group_gui in $main_tabs/production/employees_preview/eg_scroll/eg_overview.get_children():
		if i.id == id:
			i.update_eg(employee_groups[id])
	production_preview()
func setup_production_tab():
	unlocked_methods = 0
	for i: production_method in production_methods.values():
		if i.unlocked:
			unlocked_methods += 1
	for i in range(production_methods.size()):
		for j:production_method in production_methods.values():
			if j.priority == i:
				var pm_node:production_method_gui = PM_GUI.instantiate()
				pm_node.setup(j, language_dict["dynamic"])
				pm_node.activation.connect(pm_confirm_active)
				pm_node.disabled.connect(pm_disable)
				pm_node.priority_downed.connect(pm_down_prio)
				pm_node.priority_maxed.connect(pm_max_prio)
				pm_node.priority_upped.connect(pm_up_prio)
				pm_node.purchase.connect(pm_confirm_purchase)
				$main_tabs/production/production_methods/pm_scroll/pm_overview.add_child(pm_node)
				break
	hr_effect()
	for i in ["workers","hr","rnd","marketing"]:
		employee_groups[i].update_values()
		var eg:employee_group = employee_groups[i]
		var eg_node:employee_group_gui = EG_GUI.instantiate()
		eg_node.setup(eg,language_dict["dynamic"])
		eg_node.change.connect(eg_confirm)
		$main_tabs/production/employees_preview/eg_scroll/eg_overview.add_child(eg_node)
	production_preview()
func unload_production_tab():
	for i in $main_tabs/production/production_methods/pm_scroll/pm_overview.get_children():
		i.queue_free()
	for i in $main_tabs/production/employees_preview/eg_scroll/eg_overview.get_children():
		i.queue_free()
	var preview_tree:Tree = $main_tabs/production/employees_preview/production_preview
	preview_tree.clear()
func update_current_tab(_tab):
	if $main_tabs.current_tab == 0:
		setup_overview_tab()
	else:
		unload_overview_tab()
	if $main_tabs.current_tab == 1:
		setup_event_tab()
	else:
		unload_event_tab()
	if $main_tabs.current_tab == 2:
		setup_production_tab()
	else:
		unload_production_tab()
	if $main_tabs.current_tab == 3:
		setup_resource_tab()
	else:
		unload_resource_tab()
	if $main_tabs.current_tab == 4:
		setup_sales_tab()
	else:
		unload_sales_tab()
	if $main_tabs.current_tab == 5:
		load_rnd_tab()
	else:
		unload_rnd_tab()
func _input(event):
	if event.is_action_pressed("left"):
		$main_tabs/events/event_info_panel.visible = false
		$main_tabs/events/active_event_info.visible = false
		ip_displayed_event = null
		$main_tabs.select_previous_available()
	if event.is_action_pressed("right"):
		$main_tabs/events/event_info_panel.visible = false
		$main_tabs/events/active_event_info.visible = false
		ip_displayed_event = null
		$main_tabs.select_next_available()
	if event.is_action_pressed("escape"):
		if $main_tabs/events/event_info_panel.visible:
			$main_tabs/events/event_info_panel.visible = false
		if $main_tabs/events/active_event_info.visible:
			$main_tabs/events/active_event_info.visible = false
			ip_displayed_event = null
func _ready() -> void:
	viewed_rnd_node_info = ["","",0,0]
	viewed_contract = ""
	viewed_contract_id = -1
	last_viewed_tab = 0
	selected_rc_id = ""
	selected_resource_id = ""
	Utility.scene_root = self
	general_save_info = Utility.read_to_dict("user://saves/slot_{0}/general_info.json".format({"0":Utility.selected_slot})) 
	settings_dict = Utility.read_to_dict("user://settings.json")
	language_file = "res://languages/%s.json"  % [settings_dict["language"]]
	language_dict = Utility.read_to_dict(language_file)["active_game"]
	Utility.apply_language_dict(language_dict,"")
	resources_lang_dict = language_dict["dynamic"]["resources"]
	resources["chocolate"] = resource_type.new(self,"chocolate",1,25,23)
	resources["cocoa"] = resource_type.new(self,"cocoa",3,3,0.04)
	resources["sugar"] = resource_type.new(self,"sugar",0.2,10,0)
	resources["nuts"] = resource_type.new(self,"nuts",1,3,0.08)
	resources["milk_powder"] = resource_type.new(self,"milk_powder",0.3,2,0.1)
	turn = general_save_info["turn"]
	var q
	if turn % 4 == 0:
		q = 4
	else:
		q = turn % 4
	$round_display.text = language_dict["dynamic"]["displays"]["round"].format({"0":turn,"1":q,"2":2025+ceil(float(turn)/4.0)})
	player_money = general_save_info["player_money"]
	money_trace.append(["start_turn",player_money])
	running_expenses = general_save_info["running_expenses"]
	demand = general_save_info["demand"]
	sale_price = general_save_info["sale_price"]
	inflation_value = general_save_info["inflation_value"]
	old_inflation_value = general_save_info["inflation_value"]
	salary_multiplier = general_save_info["salary_multiplier"]
	publicity = general_save_info["publicity"]
	sentiment = general_save_info["sentiment"]
	last_event_id = general_save_info["last_event_id"]
	price_modifier = general_save_info["price_modifier"]	
	old_price_modifier = general_save_info["price_modifier"]
	resource_price_modifier = general_save_info["resource_price_modifier"]
	old_rp_modifier = resource_price_modifier
	production_multiplier = general_save_info["production_multiplier"]
	old_production_multiplier = production_multiplier
	quarter = general_save_info["quarter"]
	rnd_queue = general_save_info["rnd_queue"]
	loss_cf = general_save_info["loss_cf"]
	canton_tax_rate = general_save_info["canton_tax_rate"]
	total_tax_rate = general_save_info["total_tax_rate"]
	federal_tax_rate = general_save_info["federal_tax_rate"]
	seed_ = general_save_info["seed"]
	seed(general_save_info["seed"]+general_save_info["turn"])
	employee_groups["workers"] = employee_group.new("workers",self)
	employee_groups["hr"] = employee_group.new("hr",self)
	employee_groups["rnd"] =employee_group.new("rnd",self)
	employee_groups["marketing"] = employee_group.new("marketing",self)
	var saved_event_data = Utility.read_to_dict("user://saves/slot_{0}/events/general.json".format({"0":Utility.selected_slot}))
	var s_events_to_init = Utility.read_to_array("res://data/events/special_event_ids.txt")
	for i in s_events_to_init:
		var s_event_dict = Utility.read_to_dict("res://data/events/{0}.json".format({"0":i}))
		special_events_dict[s_event_dict["event_name"]] = special_event_type.new(self, s_event_dict)
	var events_to_init = Utility.read_to_array("res://data/events/event_ids.txt")
	for i in events_to_init:
		var event_dict = Utility.read_to_dict("res://data/events/{0}.json".format({"0":i}))
		events_dict[event_dict["event_name"]] = event_type.new(self, event_dict,saved_event_data[i])
	for i in saved_event_data["active_event_ids"]:
		var event_info = Utility.read_to_dict("user://saves/slot_{0}/events/{1}.json".format({"0":Utility.selected_slot, "1":int(i)}))
		var stages = []
		var stages_count = 0
		for j in event_info["stages"]:
			stages.append([])
			for k in j:
				if k["effect_type"] == "func":
					stages[stages_count].append(effect.new(k["effect_type"],self,event_info["event_name"],false,"",null,"",k["function_name"],k["parameters"],req_link.new([],"none"),0,0))
				else:
					stages[stages_count].append(effect.new(k["effect_type"],self,event_info["event_name"],false,k["variable_name"],k["new_value"],"add","",[],req_link.new([],"none"),0,0))
			stages_count += 1
		if event_info["current_stage"] < stages_count:
			active_events.append(active_event.new(self,i,event_info["event_name"],stages,event_info["current_stage"], event_info["start_turn"],event_info["excludes"]))
		else:
			events_dict[event_info["event_name"]].active = false
	var rnd_trees_to_init = Utility.read_to_array("res://data/rnd/trees/tree_ids.txt")
	for i in rnd_trees_to_init:
		rnd_trees[i] = rnd_tree.new(self,i)
	var rp_company_ids = Utility.read_to_array("res://data/rp_companies/company_ids.txt")
	var counter = 0
	for i in rp_company_ids:
		rp_companies[i] = rp_company.new(self,i,counter)
		counter += 1
	var rival_company_ids = Utility.read_to_array("res://data/rival_companies/company_ids.txt")
	counter = 0
	for i in rival_company_ids:
		rival_companies[i] = rival_company.new(self,i,counter)
		counter += 1
	var pm_ids = Utility.read_to_array("res://data/production_methods/method_ids.txt")
	for i in pm_ids:
		production_methods[i] = production_method.new(self,i)
	for i in range(events_dict.size()):
		for j in events_dict.keys():
			if events_dict[j].num_id == i:
				events_dict[j].run()
	money_trace.append(["events",[]])
	for i in active_events:
		i.execute_current_stage_effects()
	update_inflation()
	hr_effect()
	
	
	
	
	money_trace.append(["contracts",[]])
	for i:rp_company in rp_companies.values():
		for j in range(rp_companies.size()):
			if j == i.sim_order:
				i.run_contracts()
				if i.active_contracts != 0:
					money_trace[-1][1].append([i.id,player_money])
	for i:resource_type in resources.values():
		i.save_current_storage()
	money_trace.append(["rnd_perks",[]])
	for i in rnd_trees.values():
		for j in i.all_nodes:
			for k:rnd_node in j:
				if k.unlocked and k.active:
					k.apply_effect()
	money_trace.append(["pre_player",player_money])
	money_trace.append(["player_actions",[]])
	for i: rival_company in rival_companies.values():
		for j in range(rival_companies.size()):
			if i.simulation_order == j:
				i.production()
				break
	if player_money < 0:
		$bankruptcy_alert/content/text.text = $bankruptcy_alert/content/text.text.format({"0":-Utility.shorten_number(player_money)[1]})
		$bankruptcy_alert.visible = true
		$main_tabs.visible = false
	update_current_tab(0)
	$main_tabs.tab_changed.connect(update_current_tab)
	print(saved_event_data["active_event_ids"])
func production():
	var unallocated_workers = employee_groups["workers"].active_employees
	for i in resources.keys():
		if i == "chocolate":
			continue
		if resources[i].usage_priority == 0:
			resources[i].stored.sort_custom(Utility.sort_0)
		elif resources[i].usage_priority == 1:
			resources[i].stored.sort_custom(Utility.sort_1)
		elif resources[i].usage_priority == 2:
			resources[i].stored.sort_custom(Utility.sort_2)
		elif resources[i].usage_priority == 3:
			resources[i].stored.sort_custom(Utility.sort_3)
		elif resources[i].usage_priority == 4:
			resources[i].stored.sort_custom(Utility.sort_4)
		elif resources[i].usage_priority == 5:
			resources[i].stored.sort_custom(Utility.sort_5)
		elif resources[i].usage_priority == 6:
			resources[i].stored.sort_custom(Utility.sort_6)
		elif resources[i].usage_priority == 7:
			resources[i].stored.sort_custom(Utility.sort_7)
	for i in range(production_methods.size()):
		for j in production_methods.values():
			if j.priority == i:
				var operated_machines = min(floor(unallocated_workers/j.required_workers_per_machine),j.active_machines)
				unallocated_workers -= operated_machines*j.required_workers_per_machine
				var max_production = employee_groups["workers"].effectivity_per_day*65*operated_machines*j.output_per_hour
				var total_production = max_production
				for k in resources.keys():
					if k == "chocolate":
						continue
					total_production = min(total_production,resources[k].total_stored_amount/j.ingredient_per_kg[k])
				var final_quality = j.quality_modifier
				for k in resources.keys():
					
					if k == "chocolate":
						continue
					var leftover_amount = total_production*j.ingredient_per_kg[k]
					var quality_step = 0
					while leftover_amount > 0:
						var a = resources[k].stored[0].amount
						quality_step +=min(leftover_amount,resources[k].stored[0].amount)*resources[k].stored[0].quality
						leftover_amount -= min(leftover_amount,a)
						resources[k].remove_from_storage(stored_resource.new(self,min(leftover_amount,resources[k].stored[0].amount),0,0,0))
					final_quality += (quality_step/(total_production*j.ingredient_per_kg[k]))*resources[k].quality_coefficient
				if total_production > 0:
					resources["chocolate"].add_to_storage(total_production,final_quality)
				break
func hr_effect():
	var hr_workers = employee_groups["hr"].active_employees
	var total_workers = 0
	for i:employee_group in employee_groups.values():
		total_workers += i.active_employees
	var happiness_modifier = min(0.2,max(-0.2,(employee_groups["hr"].effectivity_per_day*float(hr_workers)*20/float(total_workers))-1))
	for i:employee_group in employee_groups.values():
		i.hr_happiness_modifiers = happiness_modifier
func pay_salaries():
	for i in employee_groups.keys():
		employee_groups[i].pay_salary()
func calculate_sales():
	var supply = max(1.0, resources["chocolate"].total_stored_amount)
	for i in rival_companies.values():
		supply += max(0.0, i.total_stock)
	var s_d_price = resources["chocolate"].base_value * demand / max(1.0, supply)
	var supply_quality = 0
	
	if resources["chocolate"].total_stored_amount > 0:
		for item in resources["chocolate"].stored:
			supply_quality += item.amount * item.quality
		supply_quality /= max(1.0, resources["chocolate"].total_stored_amount)
	else:
		supply_quality = 0
	var denom = sale_price - supply_quality * resources["chocolate"].quality_coefficient
	if abs(denom) < 0.0001:
		denom = 0.0001
	var total_publicity := 0.0
	var percieved_publicity
	if s_d_price > 0 and sale_price > 0:
		percieved_publicity = publicity * (1.0 + max(0.0, sentiment)) * (s_d_price / denom)**2
		total_publicity = percieved_publicity
	else:
		percieved_publicity = publicity * (1.0 + max(0.0, sentiment))
		total_publicity = publicity * (1.0 + max(0.0, sentiment))
	var p_publicities: Dictionary
	for i:rival_company in rival_companies.values():
		var r_supply_quality := 0.0
		if i.total_stock > 0:
			for j in i.stock:
				r_supply_quality += j.amount * j.quality
			r_supply_quality /= max(1.0, i.total_stock)
		else:
			r_supply_quality = 0

		var r_denom = i.price - r_supply_quality * resources["chocolate"].quality_coefficient
		if abs(r_denom) < 0.0001:
			r_denom = 0.0001

		if s_d_price > 0 and i.price > 0:
			p_publicities[i.id] = i.publicity * (1.0 + max(0.0, i.public_sentiment)) * (s_d_price / r_denom)**2
			total_publicity += i.publicity * (1.0 + max(0.0, i.public_sentiment)) * (s_d_price / r_denom)**2
		else:
			p_publicities[i.id] = i.publicity * (1.0 + max(0.0, i.public_sentiment))
			total_publicity += i.publicity * (1.0 + max(0.0, i.public_sentiment))
	var base_ratio := 0.0
	if total_publicity > 0:
		base_ratio = clamp(randf_range(0.9, 1.1) * percieved_publicity / total_publicity, 0.0, 1.0)
	else:
		base_ratio = 0.0  

	var sale_base := int(min(base_ratio * demand, resources["chocolate"].total_stored_amount))
	player_money += sale_price*sale_base
	while sale_base > 0 and resources["chocolate"].stored.size() > 0:
		var next_to_sell:stored_resource = resources["chocolate"].stored[0]
		resources["chocolate"].remove_from_storage(stored_resource.new(self,min(next_to_sell.amount,sale_base),0,0,0))
		sale_base -= min(next_to_sell.amount,sale_base)
	for i: rival_company in rival_companies.values():
		for j in range(rival_companies.size()):
			if i.simulation_order == j:
				var r_base_ratio := 0.0
				if total_publicity > 0:
					r_base_ratio = clamp(randf_range(0.9, 1.1) * p_publicities[i.id] / total_publicity, 0.0, 1.0)
				else:
					r_base_ratio = 0.0  
				
				sale_base = int(min(r_base_ratio * demand, max(0.0, i.total_stock)))
				while sale_base > 0:
					var next_to_sell:stored_resource = i.stock[0]
					if next_to_sell.amount >= sale_base:
						i.stock.remove_at(0)
					else:
						next_to_sell.amount -= sale_base
					sale_base -= min(next_to_sell.amount,sale_base)
				break
func turn_end(continue_: bool):
	production()
	calculate_sales()
	for i:production_method in production_methods.values():
		i.maintenance()
	
	pay_salaries()
	var net_profit = player_money-money_trace[0][1]
	var taxable_profit = max(0,net_profit-loss_cf)
	loss_cf += taxable_profit - net_profit
	loss_cf = min(loss_cf,0)
	var kg_tax = taxable_profit*canton_tax_rate*total_tax_rate
	var federal_tax = (taxable_profit*federal_tax_rate)/(1+federal_tax_rate)
	var total_tax =  kg_tax+federal_tax
	player_money -= total_tax
	for i:employee_group in employee_groups.values():
		i.employee_shifts()
	for i in resources.keys():
		resources[i].age_products()
		resources[i].save_current_storage()
	for i in employee_groups.values():
		i.save()
	rnd_work()
	for i in rnd_trees.values():
		i.save()
	var event_save_dict = {}
	for i in events_dict.keys():
		event_save_dict[i] = events_dict[i].return_save_info()
	
	for i in production_methods.keys():
		production_methods[i].save()
	for i in rival_companies.keys():
		rival_companies[i].age_stock(1)
		rival_companies[i].save()
	event_save_dict["active_event_ids"] = []
	for i in active_events:
		event_save_dict["active_event_ids"].append(i.event_id)
		i.get_save_dict()
	Utility.save_to_file("user://saves/slot_{0}/events/general.json".format({"0":Utility.selected_slot}),event_save_dict)
	for i in rp_companies.keys():
		rp_companies[i].save_company()
	
	general_save_info["player_money"] = player_money
	general_save_info["seed"] = seed_
	general_save_info["turn"] = turn+1
	general_save_info["last_event_id"] = last_event_id
	general_save_info["publicity"] = publicity
	general_save_info["sentiment"] = sentiment
	general_save_info["demand"] = demand
	general_save_info["sale_price"] = sale_price
	general_save_info["running_expenses"] = running_expenses
	general_save_info["rnd_queue"] = rnd_queue
	general_save_info["salary_multiplier"] = salary_multiplier
	general_save_info["inflation_value"] = inflation_value
	general_save_info["price_modifier"] = price_modifier
	general_save_info["resource_price_modifier"] = resource_price_modifier
	if quarter == 4:
		general_save_info["quarter"] = 1
	else:
		general_save_info["quarter"] = quarter + 1
	Utility.save_to_file("user://saves/slot_{0}/general_info.json".format({"0":Utility.selected_slot}),general_save_info)
	if continue_:
		print("reloaded")
		get_tree().change_scene_to_file("res://scenes/active_game.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _on_close_event_info_pressed():
	$main_tabs/events/event_info_panel.visible = false
	ip_displayed_event = null
func _on_close_active_event_pressed() -> void:
	$main_tabs/events/active_event_info.visible = false
	ip_displayed_event = null
func toggle_rnd_node_effect() -> void:
	rnd_trees[viewed_rnd_node_info[1]].all_nodes[viewed_rnd_node_info[2]][viewed_rnd_node_info[3]].active = not rnd_trees[viewed_rnd_node_info[1]].all_nodes[viewed_rnd_node_info[2]][viewed_rnd_node_info[3]].active
	$main_tabs/rnd/rnd_tabs.get_children()[$main_tabs/rnd/rnd_tabs.current_tab].update_nodes(rnd_trees[viewed_rnd_node_info[1]])
func unlock_rnd() -> void:
	rnd_trees[viewed_rnd_node_info[1]].all_nodes[viewed_rnd_node_info[2]][viewed_rnd_node_info[3]].buy()
	$main_tabs/rnd/rnd_tabs.get_children()[$main_tabs/rnd/rnd_tabs.current_tab].update_nodes(rnd_trees[viewed_rnd_node_info[1]])
	$main_tabs/rnd/rnd_info/content/unlock.disabled = true
	if rnd_trees[viewed_rnd_node_info[1]].all_nodes[viewed_rnd_node_info[2]][viewed_rnd_node_info[3]].unlocked:
		$main_tabs/rnd/rnd_info/content/active.disabled = false
		$main_tabs/rnd/rnd_info/content/active.text = language_dict["dynamic"]["rnd_node_info"]["toggle_effect"]
		$main_tabs/rnd/rnd_info/content/unlock.text = language_dict["dynamic"]["rnd_node_info"]["already_unlocked"]
	else:
		$main_tabs/rnd/rnd_info/content/active.text = language_dict["dynamic"]["rnd_node_info"]["active_not_unlocked"]
		$main_tabs/rnd/rnd_info/content/unlock.text = language_dict["dynamic"]["rnd_node_info"]["in_progress"]
	$main_tabs/rnd/rnd_info/content/active.button_pressed = false
	if not rnd_trees[viewed_rnd_node_info[1]].all_nodes[viewed_rnd_node_info[2]][viewed_rnd_node_info[3]].unlocked:
		rnd_queue.push_back(viewed_rnd_node_info)
func unload_rnd_tab():
	viewed_rnd_node_info = ["","",0,0]
	$main_tabs/rnd/rnd_info.visible = false
	for i in $main_tabs/rnd/rnd_tabs.get_children():
		i.queue_free()
func rnd_work():
	for i in employee_groups.keys():
		var work_time = employee_groups[i].effectivity_per_day*employee_groups[i].active_employees*65
		while work_time > 0 and not rnd_queue.is_empty():
			var has_group = false
			for j in range(rnd_queue.size()):
				if rnd_trees[rnd_queue[j][1]].all_nodes[rnd_queue[j][2]][rnd_queue[j][3]].employee_type  == i:
					var work_on_current = min(rnd_trees[rnd_queue[j][1]].all_nodes[rnd_queue[j][2]][rnd_queue[j][3]].upgrade_time_left, work_time)
					rnd_trees[rnd_queue[j][1]].all_nodes[rnd_queue[j][2]][rnd_queue[j][3]].progress(work_on_current)
					work_time -= work_on_current
					has_group = true
					break
			if not has_group:
				break
			
func end_game():
	Utility.clear_full_dir("user://saves/slot_{0}".format({"0":Utility.selected_slot}))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")



func update_inflation():
	for i:rival_company in rival_companies.values():
		i.price*=(inflation_value/old_inflation_value)*(price_modifier/old_price_modifier)
		i.prodiction_rate*=production_multiplier/old_production_multiplier
	for i:employee_group in employee_groups.values():
		i.average_salary*= inflation_value*salary_multiplier
	for i:production_method in production_methods.values():
		i.maintenance_cost *= (inflation_value/old_inflation_value)
		i.price_per_machine *= (inflation_value/old_inflation_value)
	for i:rnd_tree in rnd_trees.values():
		for j in i.all_nodes:
			for k:rnd_node in j:
				k.base_price*= inflation_value
	for i:rp_company in rp_companies.values():
		i.base_price*=(inflation_value/old_inflation_value)*(resource_price_modifier/old_rp_modifier)
	resources["chocolate"].base_value *= (inflation_value/old_inflation_value)
	resources["chocolate"].quality_coefficient *= (inflation_value/old_inflation_value)




func event_disable_rp_companies():
	var chance_list = [["none",0]]
	for i:rp_company in rp_companies.values():
		chance_list.append([i.id,1/i.reliability])
	var sum = 0
	for i in chance_list:
		sum += i[1]
		i[1] = sum
	var affected_companies = randi_range(2,7)
	for i in range(affected_companies):
		var chosen_num = randf_range(0,sum-0.000001)
		var chosen_company
		for j in range(rp_companies.size()):
			if chance_list[j][1] <= chosen_num and chance_list[j+1] > chosen_num:
				chosen_company = chance_list[j+1][0]
		if rp_companies[chosen_company].active:
			rp_companies[chosen_company].disable()





func event_reduce_capacity():
	var chance_list = [["none",0]]
	for i:rp_company in rp_companies.values():
		chance_list.append([i.id,1/i.reliability])
	var sum = 0
	for i in chance_list:
		sum += i[1]
		i[1] = sum
	var affected_companies = randi_range(2,7)
	for i in range(affected_companies):
		var chosen_num = randf_range(0,sum-0.000001)
		var chosen_company
		for j in range(rp_companies.size()):
			if chance_list[j][1] <= chosen_num and chance_list[j+1] > chosen_num:
				chosen_company = chance_list[j+1][0]
		if rp_companies[chosen_company].active:
			rp_companies[chosen_company].capacity = randi_range(0.5*rp_companies[chosen_company].capacity,rp_companies[chosen_company].capacity)
			
func event_cancel_contracts():
	var chance_list = [["none",0]]
	for i:rp_company in rp_companies.values():
		chance_list.append([i.id,1/i.reliability])
	var sum = 0
	for i in chance_list:
		sum += i[1]
		i[1] = sum
	var affected_companies = randi_range(2,10)
	for i in range(affected_companies):
		var chosen_num = randf_range(0,sum-0.000001)
		var chosen_company
		for j in range(rp_companies.size()):
			if chance_list[j][1] <= chosen_num and chance_list[j+1][1] > chosen_num:
				chosen_company = chance_list[j+1][0]
		if rp_companies[chosen_company].active_contracts == 0:
			continue
		if rp_companies[chosen_company].active:
			var canceled_contracts = randi_range(1,min(rp_companies[chosen_company].active_contracts,3))
			for j in range(canceled_contracts):
				var chosen_contract = randi_range(0,rp_companies[chosen_company].active_contracts-1)
				rp_companies[chosen_company].cancel_contract(chosen_contract,max(rp_companies[chosen_company].cancel_notice,rp_companies[chosen_company].duration_range[0]-rp_companies[chosen_company].contracts[chosen_contract].duration_left),false)
