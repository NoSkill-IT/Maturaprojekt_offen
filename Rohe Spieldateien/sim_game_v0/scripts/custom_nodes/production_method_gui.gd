extends Panel
class_name production_method_gui

@onready var method_name: Label = $grid/infos/name
@onready var required_workers: Label = $grid/infos/required_workers
@onready var price_info: Label = $grid/infos/price_info
@onready var quality_modifier: Label = $grid/infos/quality_modifier
@onready var recipe: Label = $grid/infos/recipe
@onready var active_machines_name: Label = $grid/infos/numbers/active_machines_name
@onready var active_machines_num: Label = $grid/infos/numbers/active_machines_num
@onready var active_machines_new: SpinBox = $grid/infos/numbers/active_machines_new
@onready var buy_machines: Label = $grid/infos/numbers/buy_machines
@onready var machines_bought: Label = $grid/infos/numbers/machines_bought
@onready var buy_amount: SpinBox = $grid/infos/numbers/buy_amount
@onready var priority_max: Button = $grid/buttons/priority_max
@onready var priority_up: Button = $grid/buttons/priority_up
@onready var priority_down: Button = $grid/buttons/priority_down
@onready var disable: Button = $grid/buttons/disable
@onready var cancel: Button = $grid/buttons/cancel
@onready var confirm_active: Button = $grid/buttons/confirm_active
@onready var confirm_purchase: Button = $grid/buttons/confirm_purchase
@onready var c_max_production: Label = $grid/infos/current_max_production
var id: String
var lang_dict
var game_ref
var pm: production_method



signal priority_upped(id: String, old_priority:int)
signal priority_downed(id: String, old_priority:int)
signal priority_maxed(id: String, old_priority:int)
signal activation(id: String, new_active:int)
signal purchase(id: String, new_total:int)
signal disabled(id: String, old_priority:int)




func _process(_delta: float) -> void:
	if self.is_visible_in_tree():
		if pm.active_machines == active_machines_new.value:
			confirm_active.text = lang_dict["production_method_info"]["confirm_active"].format({"0":"","1":0})
			confirm_active.disabled = true
		elif pm.active_machines > active_machines_new.value:
			confirm_active.text = lang_dict["production_method_info"]["confirm_active"].format({"0":"de","1":int(pm.active_machines-active_machines_new.value)})
			confirm_active.disabled = false
		else:
			confirm_active.disabled = false
			confirm_active.text = lang_dict["production_method_info"]["confirm_active"].format({"0":"","1":int(active_machines_new.value-pm.active_machines)})
		if buy_amount.value == 0:
			confirm_purchase.text = lang_dict["production_method_info"]["confirm_purchase"].format({"0":0})
			confirm_purchase.disabled = true
		else:
			confirm_purchase.text = lang_dict["production_method_info"]["confirm_purchase"].format({"0":int(buy_amount.value)})
			confirm_purchase.disabled = false
		if buy_amount.value == 0 and pm.active_machines == active_machines_new.value:
			cancel.disabled = true
		elif pm.unlocked:
			cancel.disabled = false
	
func setup(pm_:production_method,lang_dict_):
	id = pm_.id
	pm = pm_
	game_ref = pm.game_ref
	lang_dict = lang_dict_
	
func set_values():
	method_name.text = lang_dict["production_methods"][pm.id]
	required_workers.text = lang_dict["production_method_info"]["required_workers"].format({"0":pm.required_workers_per_machine,"1":pm.output_per_hour})
	price_info.text = lang_dict["production_method_info"]["price_info"].format({"0":Utility.shorten_number(pm.price_per_machine)[0],"1":Utility.shorten_number(pm.maintenance_cost)[0]})
	recipe.text = lang_dict["production_method_info"]["recipe"].format({"0":pm.ingredient_per_kg["sugar"],"1":pm.ingredient_per_kg["milk_powder"],"2":pm.ingredient_per_kg["nuts"],"3":pm.ingredient_per_kg["cocoa"]})
	active_machines_name.text = lang_dict["production_method_info"]["active_machines_name"]
	active_machines_num.text = lang_dict["production_method_info"]["active_machines_num"].format({"0":pm.active_machines})
	active_machines_new.value = pm.active_machines
	active_machines_new.max_value = pm.unlocked_machines
	buy_machines.text = lang_dict["production_method_info"]["buy_machines"]
	machines_bought.text = lang_dict["production_method_info"]["machines_bought"].format({"0":pm.unlocked_machines})
	priority_max.text = lang_dict["production_method_info"]["priority_max"]
	priority_up.text = lang_dict["production_method_info"]["priority_up"]
	priority_down.text = lang_dict["production_method_info"]["priority_down"]
	quality_modifier.text = lang_dict["production_method_info"]["quality_modifier"].format({"0":pm.quality_modifier})
	disable.text = lang_dict["production_method_info"]["disable"]
	cancel.text = lang_dict["production_method_info"]["cancel"]
	c_max_production.text = lang_dict["production_method_info"]["max_production"].format({"0":Utility.shorten_number(game_ref.employee_groups["workers"].effectivity_per_day*pm.output_per_hour*65)[0]})
	buy_amount.value = 0
	if pm.priority == 0:
		priority_max.disabled = true
		priority_up.disabled = true
	elif pm.priority == game_ref.unlocked_methods-1:
		priority_down.disabled = true
	if pm.priority > 0:
		priority_up.disabled = false
		priority_max.disabled = false
	if pm.priority < game_ref.unlocked_methods-1:
		priority_down.disabled = false
	if pm.unlocked == false:
		active_machines_new.editable = false
		buy_amount.editable = false
		priority_max.disabled = true
		priority_up.disabled = true
		priority_down.disabled = true
		disable.disabled = true
		cancel.disabled = true
		confirm_active.disabled = true
		confirm_purchase.disabled = true
	elif pm.unlocked_machines == 0:
		confirm_active.disabled = true
		active_machines_new.editable = false
		buy_amount.editable = true
		buy_amount.max_value = floor(game_ref.player_money/pm.price_per_machine)
	else:
		active_machines_new.editable = true
		buy_amount.editable = true
		buy_amount.max_value = floor(game_ref.player_money/pm.price_per_machine)
func update_pm(pm_):
	pm = pm_
	set_values()

		
func _ready() -> void:
	set_values()



func _on_priority_max() -> void:
	emit_signal("priority_maxed",pm.id,pm.priority)

func _on_priority_up() -> void:
	emit_signal("priority_upped",pm.id,pm.priority)

func on_priority_down() -> void:
	emit_signal("priority_downed",pm.id,pm.priority)

func _on_disable() -> void:
	emit_signal("disabled",pm.id,pm.priority)

func _on_cancel() -> void:
	active_machines_new.value = pm.active_machines
	buy_amount.value = 0

func _on_confirm_active() -> void:
	emit_signal("activation",pm.id,active_machines_new.value)

func _on_confirm_purchase_pressed() -> void:
	emit_signal("purchase",pm.id,buy_amount.value+pm.unlocked_machines)
	buy_amount.value = 0
