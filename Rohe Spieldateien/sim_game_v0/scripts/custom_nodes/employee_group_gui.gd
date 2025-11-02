extends Panel
class_name employee_group_gui
@onready var group_name: Label = $container/name
@onready var description: Label = $container/description
@onready var active_employees: Label = $container/active_employees
@onready var job_supply: Label = $container/job_supply
@onready var column_titles: Array = [$container/grid/value_title,$container/grid/now_title,$container/grid/new_title]
@onready var target: Array = [$container/grid/target_title,$container/grid/target_now,$container/grid/target_new]
@onready var salary: Array = [$container/grid/salary_title,$container/grid/salary_now,$container/grid/salary_new]
@onready var hours: Array = [$container/grid/hours_title,$container/grid/hours_now,$container/grid/hours_new]
@onready var happiness: Array = [$container/grid/happiness_title,$container/grid/happiness_now,$container/grid/happiness_new]
@onready var effectivity: Array = [$container/grid/effectivity_title,$container/grid/effectivity_now,$container/grid/effectivity_new]
@onready var sph: Array = [$container/grid/sph_title,$container/grid/sph_now,$container/grid/sph_new]
@onready var cancel: Button = $container/buttons/cancel
@onready var confirm: Button =$container/buttons/confirm
var id: String
var lang_dict
var game_ref
var eg: employee_group

signal change(id: String, work_hours: float, salary: int, target: int)

func _process(_delta: float) -> void:
	if self.is_visible_in_tree():
		var new_happiness = (7.739167225/hours[2].value+0.03493296094-5.295223815*pow(10,-16)*pow(hours[2].value,14))*min(eg.average_salary*1.2,salary[2].value)/(eg.average_salary)+0.2*(eg.hr_happiness_modifiers+eg.other_happiness_modifiers)
		happiness[2].text = str(Utility.shorten_number(new_happiness)[0])
		effectivity[2].text = str(Utility.shorten_number(new_happiness*hours[2].value)[0])
		sph[2].text = str(Utility.shorten_number(salary[2].value*3/(65*hours[2].value))[0])
		var is_changed = target[2].value == eg.target_employees and salary[2].value == eg.salary and hours[2].value == eg.work_hours
		if is_changed:
			cancel.disabled = true
			confirm.disabled = true
		else:
			cancel.disabled = false
			confirm.disabled = false
	
func setup(eg_:employee_group,lang_dict_):
	id = eg_.id
	eg = eg_
	game_ref = eg.game_ref
	lang_dict = lang_dict_
	
func set_values():
	group_name.text = lang_dict["employee_groups"][eg.id]["name"]
	description.text = lang_dict["employee_groups"][eg.id]["description"]
	active_employees.text = lang_dict["employee_group_info"]["active_employees"].format({"0":eg.active_employees,"1":eg.employee_rating})
	var progress_quarter = ""
	if eg.target_employees < eg.active_employees:
		progress_quarter = Utility.round_to_date(game_ref.turn+1)
	elif eg.target_employees == eg.active_employees:
		progress_quarter = Utility.round_to_date(game_ref.turn)
	else:
		progress_quarter = Utility.round_to_date(game_ref.turn+ceil((eg.target_employees-eg.active_employees)/(game_ref.publicity*max(0.01,1+game_ref.sentiment)*eg.job_supply/10000)))
	active_employees.tooltip_text = lang_dict["employee_group_info"]["active_employees_tt"].format({"0":eg.target_employees,"1":progress_quarter})
	job_supply.text = lang_dict["employee_group_info"]["job_supply"].format({"0":eg.job_supply})
	job_supply.tooltip_text = lang_dict["employee_group_info"]["job_supply_tt"]
	column_titles[0].text = lang_dict["employee_group_info"]["value_title"]
	column_titles[1].text = lang_dict["employee_group_info"]["now_title"]
	column_titles[2].text = lang_dict["employee_group_info"]["new_title"]
	target[0].text = lang_dict["employee_group_info"]["target"]
	salary[0].text = lang_dict["employee_group_info"]["salary"]
	hours[0].text = lang_dict["employee_group_info"]["hours"]
	happiness[0].text = lang_dict["employee_group_info"]["happiness"]
	effectivity[0].text = lang_dict["employee_group_info"]["effectivity"]
	sph[0].text = lang_dict["employee_group_info"]["sph"]
	target[1].text = str(int(eg.target_employees))
	salary[1].text = str(int(eg.salary))+ " CHF"
	hours[1].text = str(eg.work_hours)+ " h"
	happiness[1].text = str(Utility.shorten_number(eg.happiness)[0])
	effectivity[1].text = str(Utility.shorten_number(eg.effectivity_per_day)[0])
	sph[1].text = str(Utility.shorten_number(float(eg.salary*3)/(65*hours[2].value))[0])
	target[2].value = int(eg.target_employees)
	salary[2].value = int(eg.salary)
	hours[2].value = eg.work_hours
	cancel.text = lang_dict["employee_group_info"]["cancel"]
	confirm.text = lang_dict["employee_group_info"]["confirm"]
	print("values_set")
func update_eg(eg_):
	eg = eg_
	set_values()

		
func _ready() -> void:
	set_values()

func _on_cancel() -> void:
	target[2].value = int(eg.target_employees)
	salary[2].value = int(eg.salary)
	hours[2].value = eg.work_hours

func _on_confirm() -> void:
	print("change")
	emit_signal("change",eg.id,hours[2].value,salary[2].value,target[2].value)
