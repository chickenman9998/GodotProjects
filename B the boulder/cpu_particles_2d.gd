extends CPUParticles2D # or whatever Node type your script is attached to

@onready var particles: CPUParticles2D = get_node_or_null("CPUParticles2D")  # replace with correct relative path

func _ready():
	particles.process_material.color = Color.RED
