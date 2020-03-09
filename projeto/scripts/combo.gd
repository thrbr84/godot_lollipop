extends Label

func _on_anim_animation_finished(anim_name):
	get_parent().queue_free()
