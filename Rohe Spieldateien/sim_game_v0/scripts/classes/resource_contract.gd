extends Object
class_name resource_contract
var total_duration: int
var duration_left: int
var expected_quality: float
var resource: String
var expected_amount: float
var price: float
var duration_done
var original_duration
var game_ref

func _init(game_ref_,total_duration_: int, duration_left_:int, expected_quality_: float, resource_: String,price_:float, expected_amount_: float, duration_done_: int,od) -> void:
	total_duration = total_duration_
	duration_left = duration_left_
	expected_quality = expected_quality_
	resource = resource_
	expected_amount = expected_amount_
	game_ref = game_ref_
	price = price_
	duration_done = duration_done_
	original_duration= od
	
func deliver_resources(quality_modifiers: float, amount_modifiers: float):
	var final_price
	final_price = price*expected_amount
	duration_left -= 1
	duration_done += 1
	if game_ref.player_money >= final_price:
		game_ref.resources[resource].add_to_storage(expected_amount*amount_modifiers, expected_quality+quality_modifiers)
		game_ref.player_money -= final_price
	else:
		#bankrupcy?
		pass

func get_as_dict():
	var dict: Dictionary = {}
	dict["total_duration"] = total_duration
	dict["duration_left"] = duration_left
	dict["expected_amount"] = expected_amount
	dict["price"] = price
	dict["duration_done"] = duration_done
	dict["original_duration"] = original_duration
	return dict
	
