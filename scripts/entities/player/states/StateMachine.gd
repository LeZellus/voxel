extends Node
class_name StateMachine

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready():
	# Récupérer référence au player (parent de cette StateMachine)
	var player_ref = get_parent()
	
	# Récupérer tous les états enfants
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.player = player_ref  # Assigner directement !
			
	# Démarrer avec l'état initial
	if initial_state:
		call_deferred("_start_initial_state")
		
	
	
	if initial_state:
		change_state(initial_state.name.to_lower())
	else:
		print("❌ Aucun état initial défini!")
		
func _start_initial_state():
	await get_tree().process_frame

	# Vérifier s'il faut démarrer en mouvement
	if InputHelper.is_moving():
		change_state("walking")
	else:
		change_state(initial_state.name.to_lower())

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)
		
	if current_state:
		current_state.physics_update(delta)
	else:
		print("Aucun état actuel!") 

func change_state(new_state_name: String):
	var new_state = states.get(new_state_name.to_lower())
	
	if not new_state:
		print("❌ État introuvable: ", new_state_name)
		print("📋 États disponibles: ", states.keys())
		return
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
	
func debug():
	print("🔍 États disponibles:", states.keys())
	print("🔍 État initial défini:", initial_state.name if initial_state else "AUCUN")
