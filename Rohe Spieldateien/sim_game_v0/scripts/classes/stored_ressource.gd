class_name stored_resource
extends Object
var amount: float
var expiration: int
var quality: float
var id: int
var game_ref

func _init(game_ref_, amount_: int, expiration_: int, quality_: float, id_: int = 0) -> void:
	game_ref = game_ref_
	amount = amount_
	quality = quality_
	expiration = expiration_
	id = id_

func get_as_dict() -> Dictionary:
	return {"amount":amount,"quality": quality, "expiration":expiration, "id":id}
