# scripts/systems/inventory/actions/ActionRegistry.gd - PRIORITÉS CORRIGÉES
class_name ActionRegistry
extends RefCounted

var actions: Array[BaseInventoryAction] = []

func register(action: BaseInventoryAction):
	actions.append(action)
	# Trier par priorité (plus petit = plus prioritaire)
	actions.sort_custom(func(a, b): return a.priority < b.priority)

func execute(context: ClickContext) -> bool:
	print("\n🎯 === ACTION REGISTRY ===")
	print("   - Context: %s" % context._to_string())
	print("   - Actions disponibles: %d" % actions.size())
	
	for action in actions:
		print("   🔍 Test: %s (priorité %d)" % [action.name, action.priority])
		
		if action.can_execute(context):
			print("   ✅ Exécution: %s" % action.name)
			var result = action.execute(context)
			print("   📊 Résultat: %s" % ("✅ Succès" if result else "❌ Échec"))
			return result
		else:
			print("   ❌ Conditions non remplies")
	
	print("   ❌ Aucune action applicable")
	return false

func setup_defaults():
	"""Setup avec priorités claires"""
	register(HalfStackAction.new())       # Priorité 1 - Clic droit sans sélection
	register(HandPlacementAction.new())   # Priorité 2 - Placement depuis la main
	register(RestackAction.new())         # Priorité 3 - Restack entre slots
	register(SimpleMoveAction.new())      # Priorité 4 - Déplacement simple
	register(SimpleUseAction.new())       # Priorité 5 - Utilisation d'item
	
	print("✅ ActionRegistry configuré avec %d actions" % actions.size())

# Actions intégrées simplifiées

class SimpleUseAction extends BaseInventoryAction:
	func _init():
		super("use", 5)
	
	func can_execute(context: ClickContext) -> bool:
		# Seulement clic droit, slot non vide, pas de sélection, pas de half-stack
		var is_right_click = (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
		var source_not_empty = not context.source_slot_data.get("is_empty", true)
		var no_target = (context.target_slot_index == -1)
		var no_selection = not player_has_selection()
		
		# Cette action ne s'active que si HalfStackAction n'a pas pris le relais
		return is_right_click and source_not_empty and no_target and no_selection
	
	func execute(context: ClickContext) -> bool:
		var item_name = context.source_slot_data.get("item_name", "")
		print("🔨 [USE] Utilisation de: %s" % item_name)
		
		# Logique d'utilisation à implémenter selon tes besoins
		# Par exemple : consommer, équiper, etc.
		
		return true
