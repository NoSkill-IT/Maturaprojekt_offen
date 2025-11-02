extends Object
class_name rival_company
var stock: Array[stored_resource]
#var last_earnings: Array[float]
var target_quality: float
var publicity: float
var public_sentiment: float
var game_ref
var price: float
var reliability: float
var total_stock: float
var prodiction_rate: float
var simulation_order
var id
var predicted_sales
var average_quality
func _init(gr,id_,so):
	simulation_order = so
	id = id_
	game_ref = gr
	var save_data
	var data = Utility.read_to_dict("res://data/rival_companies/{0}.json".format({"0":id}))
	if FileAccess.file_exists("user://saves/slot_{0}/rival_companies/{1].json".format({"0":Utility.selected_slot,"1":id})):
		save_data = Utility.read_to_dict("user://saves/slot_{0}/rival_companies/{1].json".format({"0":Utility.selected_slot,"1":id}))
	else:
		save_data = data["base_values"]
	target_quality = data["target_quality"]
	reliability = save_data["reliability"]
	public_sentiment = save_data["sentiment"]
	publicity = save_data["publicity"]
	price = save_data["price"]
	prodiction_rate = save_data["production_rate"]
	stock = []
	total_stock = 0
	for i in save_data["stock"]:
		stock.append(stored_resource.new(game_ref,i["amount"],i["expiration"],i["quality"],i["id"]))
		total_stock += i["amount"]

func production():
	stock.append(stored_resource.new(game_ref,int(prodiction_rate*randf_range(reliability,1)),game_ref.resources["chocolate"].expiration_time,target_quality*randf_range(reliability,1),stock.size()))
	total_stock = 0
	for i in stock:
		total_stock += i.amount

func reassign_id():
	for i in range(stock.size()):
		stock[i].id = i
		
	
func age_stock(time):
	for i in range(stock.size()-1, -1,0):
		stock[i].expiration -= time
		if stock[i].expiration <= 0:
			#disposal warining
			stock.remove_at(i)

func save():
	var save_dict = {}
	save_dict["reliability"] = reliability
	save_dict["public_sentiment"] = public_sentiment
	save_dict["publicity"] = publicity
	save_dict["sentiment"] = public_sentiment
	save_dict["price"] = price
	save_dict["production_rate"] = prodiction_rate
	save_dict["stock"] = []
	for i in stock:
		save_dict["stock"].append(i.get_as_dict())
	Utility.save_to_file("user://saves/slot_{0}/rival_companies/{1}.json".format({"0":Utility.selected_slot,"1":id}),save_dict)
