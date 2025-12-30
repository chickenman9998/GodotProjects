extends RayCast2D

func _physics_process(_delta):
	rotation = 0
	global_rotation = 0
	force_raycast_update()
