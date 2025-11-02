extends Panel
class_name i_node
var info
var title
var custom_size
var custom_position

func format():
	self.custom_minimum_size = Vector2(custom_size.x*475-20,custom_size.y*340-20)
	self.size = Vector2(custom_size.x*475-20,custom_size.y*340-20)
	self.position = Vector2(custom_position.x*475+20,custom_position.y*340+20)
	$contents.custom_minimum_size = Vector2(custom_size.x*475-40,custom_size.y*340-40)
	$contents.size = Vector2(custom_size.x*475-40,custom_size.y*340-40)
	$contents/title.text = title
	$contents/info.text = info
	$contents/info.size = Vector2(custom_size.x*475-40,custom_size.y*340-80)
	
