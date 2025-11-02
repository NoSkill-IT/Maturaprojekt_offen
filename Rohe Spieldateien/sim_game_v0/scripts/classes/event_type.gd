extends Object
class_name event_type
var affected_variables: Array
var delays: Array
var phase_duration_ranges: Array
var affected_from_random: Array
var phase_base_values: Array
var value_random_range: Array
var special_events: Array
var volatility: Array
var name: String
var base_probability: float
var probability_modifier: float
var active: bool
var game_ref
var excludes: Array
var requirements
var num_id: int


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


func _init(gr, event_dict, saved_info):
	affected_variables = event_dict["affected_variables"]
	delays = event_dict["delays"]
	name = event_dict["event_name"]
	volatility = event_dict["volatility"]
	phase_duration_ranges = event_dict["phase_duration_ranges"]
	affected_from_random = event_dict["affected_from_random"]
	phase_base_values = event_dict["phase_base_values"]
	value_random_range = event_dict["value_random_range"]
	base_probability = event_dict["base_probability"]
	probability_modifier = saved_info["probability_modifier"]
	special_events = event_dict["special_events"]
	excludes = event_dict["excludes"]
	game_ref = gr
	active = saved_info["active"]
	requirements = create_requirement(event_dict["requirement"])
	game_ref = gr

func run():
	if active:
		return false
	if not requirements.is_met():
		return false
	for i in game_ref.active_events:
		for j in i.excludes:
			if j == name:
				return false
	if randf() <= base_probability+probability_modifier:
		active = true
	else:
		return false
	var total_duration: int = 0
	var phase_durations = []
	for i in phase_duration_ranges:
		var newest_value = randi_range(i[0],i[1])
		phase_durations.append(newest_value)
		total_duration += newest_value
	var random_values = []
	for i in value_random_range:
		random_values.append(randf_range(i[0],i[1]))
	var final_segment_values = []
	var count1 = 0
	for i in phase_base_values:
		final_segment_values.append([])
		var count2 = 0
		for j in i:
			final_segment_values[count1].append(j+random_values[count2]*affected_from_random[count1])
			count2 += 1
		count1 += 1
	var event_phases: Array[Array] = []
	var max_delay: int = 0
	for i in delays:
		max_delay = max(max_delay,i)
	for i in range(max_delay+total_duration):
		event_phases.append([])
	var completed_phase_times = 0
	var last_value = 0
	for i in range(affected_variables.size()):
		var last_phase_value: float = 0
		completed_phase_times = 0
		last_value = 0
		for j in range(phase_durations.size()):
			for k in range(phase_durations[j]):
				var new_value = (last_phase_value+(final_segment_values[i][j]-last_phase_value)/phase_durations[j]*(k+1))*(randf_range(1-volatility[i],1+volatility[i]))
				event_phases[completed_phase_times+k+delays[i]].append(effect.new("var",game_ref,name,false,affected_variables[i],new_value-last_value,"add"))
				last_value = new_value
			completed_phase_times += phase_durations[j]
	completed_phase_times = 0
	last_value = 0
	for j in range(phase_durations.size()):
		for i in special_events[j*2]:
			event_phases[completed_phase_times].append(game_ref.special_events_dict[i].get_for_event(random_values[j]))
		completed_phase_times += phase_durations[j]
		for i in special_events[j*2+1]:
			event_phases[completed_phase_times-1].append(game_ref.special_events_dict[i].get_for_event(random_values[j]))
	game_ref.active_events.append(active_event.new(game_ref,game_ref.last_event_id+1,name,event_phases,0,game_ref.turn,excludes))
	game_ref.last_event_id+=1
	return true
		
func return_save_info():
	return {"probability_modifier":probability_modifier,"active":active}
