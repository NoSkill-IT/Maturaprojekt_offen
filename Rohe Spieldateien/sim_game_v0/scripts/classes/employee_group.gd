extends Object
class_name employee_group
var target_employees: int
var active_employees: int
var employee_rating: float
var happiness: float
var other_happiness_modifiers: float
var work_hours: float
var effectivity_per_hour: float
var effectivity_per_day: float
var average_salary 
var salary: int
var job_supply: int
var game_ref
var hr_happiness_modifiers: float
var id

func _init(id_, gr) -> void:
	game_ref = gr
	id = id_
	var data
	if FileAccess.file_exists("user://saves/slot_{0}/employees/{1}.json".format({"0":Utility.selected_slot,"1":id})):
		data = Utility.read_to_dict("user://saves/slot_{0}/employees/{1}.json".format({"0":Utility.selected_slot,"1":id}))
	else:
		data = Utility.read_to_dict("res://data/employee_base_values/{0}.json".format({"0":id}))
	target_employees = data["target_employees"]
	active_employees = data["active_employees"]
	employee_rating = data["employee_rating"]
	other_happiness_modifiers = data["happiness_modifiers"]
	hr_happiness_modifiers = 0
	work_hours = data["work_hours"]
	average_salary = data["average_salary"]
	salary = data["salary"]
	job_supply = data["job_supply"]
	update_values()
	
func update_values():
	happiness = (7.739167225/work_hours+0.03493296094-5.295223815*pow(10,-16)*pow(work_hours,14))*min(average_salary*1.2,salary)/(average_salary)+(hr_happiness_modifiers+other_happiness_modifiers)*0.2
	effectivity_per_hour = happiness*employee_rating
	effectivity_per_day = effectivity_per_hour*work_hours
func employee_shifts():
	if happiness <= 0.8:
		active_employees = min(int(active_employees*(happiness+0.2)),target_employees)
	elif target_employees > active_employees:
		active_employees = min(target_employees,active_employees+log(game_ref.publicity)*(1+game_ref.sentiment)*job_supply/10000)

func pay_salary():
	game_ref.player_money -= active_employees*salary*3


func save():
	var data = {}
	data["target_employees"] = target_employees
	data["active_employees"] = active_employees
	data["employee_rating"] = employee_rating
	data["happiness_modifiers"] = other_happiness_modifiers
	data["work_hours"] = work_hours
	data["average_salary"] = average_salary
	data["salary"] = salary
	data["job_supply"] = job_supply
	Utility.save_to_file("user://saves/slot_{0}/employees/{1}.json".format({"0":Utility.selected_slot,"1":id}),data)
