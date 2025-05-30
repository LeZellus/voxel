# WalkingState.gd - VERSION REFACTORISÉE (80% de code en moins!)
extends MovementStateBase
class_name WalkingState

# Plus besoin de toutes les variables répétitives ! 
# Elles sont dans MovementStateBase

func configure_state():
	"""Configuration spécifique à la marche"""
	configure_for_walking()  # Utilise la config par défaut

func handle_specific_logic(delta: float):
	"""Seule la logique spécifique à la marche"""
	
	# IMPORTANT: Vérifier d'abord si on doit s'arrêter
	if not InputHelper.is_moving():
		state_machine.change_state("idle")
		return
	
	apply_common_movement(delta)

# Plus besoin de enter(), exit(), physics_update() !
# Tout est géré par MovementStateBase

# Si vous voulez ajouter de la logique spécifique :
func on_enter():
	print("Mode marche activé")

func on_exit():
	print("Fin du mode marche")
