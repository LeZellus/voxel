extends State
class_name IdleState

func enter():
	print("Joueur: En attente")

func physics_update(delta):
	player.apply_gravity(delta)
	
	# FORCER l'arrêt immédiat
	player.velocity.x = 0  # AJOUTER
	player.velocity.z = 0  # AJOUTER
	
	# Vérifier transitions
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() > 0:
		state_machine.change_state("walking")
	
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		state_machine.change_state("jumping")
	
	# Arrêter le mouvement
	player.apply_movement(Vector3.ZERO, 0)
	player.move_and_slide()

func handle_input(event):
	# Les inputs caméra sont gérés par PlayerController
	# Ici on gère seulement les inputs spécifiques à cet état
	pass
