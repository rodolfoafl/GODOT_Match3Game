extends TextureButton

var active = false

enum {add_to_counter, make_color_bomb, destroy_piece}
var state

export (Texture) var active_texture

func _ready():
	pass
	
func check_active(is_active):
	if(is_active):
		texture_normal = active_texture
	else:
		texture_normal = null
