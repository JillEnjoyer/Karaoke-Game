extends Control

@onready var subviewport = $SubViewport
@onready var label_copy = $SubViewport/Label

func label_to_texture(label: Label) -> Texture2D:
	subviewport.size = label.size
	subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	subviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	label_copy.text = label.text
	label_copy.theme = label.theme
	label_copy.size = label.size
	label_copy.scale = label.scale
	label_copy.modulate = label.modulate
	label_copy.horizontal_alignment = label.horizontal_alignment
	label_copy.vertical_alignment = label.vertical_alignment
	label_copy.autowrap_mode = label.autowrap_mode
	label_copy.clip_text = label.clip_text
	label_copy.custom_minimum_size = label.custom_minimum_size

	subviewport.add_child(label_copy)

	await get_tree().process_frame

	var texture: Texture2D = subviewport.get_texture()

	call_deferred("queue_free")

	return texture
