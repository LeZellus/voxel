# scripts/inventory/actions/ActionManager.gd
class_name ActionManager
extends RefCounted

# === GESTIONNAIRE MODULAIRE DES ACTIONS ===

var registered_handlers: Array[ActionHandler] = []
var debug_enabled: bool = true

func _init():
	_register_default_handlers()

# === ENREGISTREMENT DES HANDLERS ===

func register_handler(handler: ActionHandler):
	"""Enregistre un nouveau handler d'action"""
	if not handler:
		print("❌ Handler invalide")
		return
	
	registered_handlers.append(handler)
	# Trier par priorité (plus élevé en premier)
	registered_handlers.sort_custom(func(a, b): return a.priority > b.priority)
	
	if debug_enabled:
		print("✅ Handler enregistré: %s (priorité: %d)" % [handler.action_name, handler.priority])

func _register_default_handlers():
	"""Enregistre les handlers par défaut"""
	
	# Pour l'instant, on va créer des handlers simples qui wrappent tes actions existantes
	register_handler(LegacyUseHandler.new())
	register_handler(LegacyMoveHandler.new())
	
	if debug_enabled:
		print("🎮 ActionManager initialisé avec %d handlers" % registered_handlers.size())

# === EXÉCUTION DES ACTIONS ===

func handle_click(context: ClickContext) -> bool:
	"""Point d'entrée principal - trouve et exécute l'action appropriée"""
	
	if debug_enabled:
		print("🎯 ActionManager: traitement clic %s" % ClickContext.ClickType.keys()[context.click_type])
	
	# Parcourir les handlers par ordre de priorité
	for handler in registered_handlers:
		if handler.can_handle(context):
			if debug_enabled:
				print("🎮 Handler sélectionné: %s" % handler.action_name)
			
			var success = handler.execute(context)
			
			if debug_enabled:
				var status = "✅ Succès" if success else "❌ Échec"
				print("🎮 %s: %s" % [handler.action_name, status])
			
			return success
	
	if debug_enabled:
		print("⚠️ Aucun handler trouvé pour ce contexte")
	
	return false

# === UTILITAIRES ===

func get_available_actions(context: ClickContext) -> Array[String]:
	"""Retourne la liste des actions possibles pour ce contexte (debug/UI)"""
	var actions: Array[String] = []
	
	for handler in registered_handlers:
		if handler.can_handle(context):
			actions.append(handler.get_description(context))
	
	return actions

func debug_handlers():
	"""Affiche tous les handlers enregistrés"""
	print("\n🎮 === HANDLERS ENREGISTRÉS ===")
	for i in range(registered_handlers.size()):
		var handler = registered_handlers[i]
		print("   %d. %s (priorité: %d)" % [i+1, handler.action_name, handler.priority])

# === CLASSES DE TRANSITION (LEGACY WRAPPERS) ===

# Ces classes permettent d'utiliser tes actions existantes avec le nouveau système
# Tu pourras les supprimer une fois que tu auras migré complètement

class LegacyUseHandler extends ActionHandler:
	
	func _init():
		super("legacy_use", 10)
	
	func can_handle(context: ClickContext) -> bool:
		return (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK 
				and has_source_item(context)
				and context.target_slot_index == -1)  # Pas de slot-to-slot
	
	func execute(context: ClickContext) -> bool:
		print("🎮 [%s] Utilisation legacy de: %s" % [action_name, get_source_item(context).get("item_name", "")])
		
		# Pour l'instant, juste simuler l'action
		var item_type = get_source_item(context).get("item_type", -1)
		
		match item_type:
			Item.ItemType.CONSUMABLE:
				print("🎮 [%s] Item consommé!" % action_name)
				return true
			Item.ItemType.TOOL:
				print("🎮 [%s] Outil équipé!" % action_name)
				return true
			_:
				print("🎮 [%s] Type d'item non supporté" % action_name)
				return false

class LegacyMoveHandler extends ActionHandler:
	
	func _init():
		super("legacy_move", 5)
	
	func can_handle(context: ClickContext) -> bool:
		return (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK 
				and has_source_item(context))
	
	func execute(context: ClickContext) -> bool:
		# Si pas de cible, démarrer l'attente
		if context.target_slot_index == -1:
			print("🎮 [%s] Sélection pour déplacement: %s" % [action_name, get_source_item(context).get("item_name", "")])
			return true
		
		# Sinon, effectuer le déplacement
		print("🎮 [%s] Déplacement de %s vers slot %d" % [action_name, get_source_item(context).get("item_name", ""), context.target_slot_index])
		return true
