# scripts/systems/inventory/ClickSystemIntegrator.gd - VERSION DEBUG
class_name ClickSystemIntegrator
extends Node

# === COMPOSANTS ===
var click_system: ClickSystemManager
var registered_uis: Dictionary = {}
var selected_slot_info: Dictionary = {}
var currently_selected_slot_ui: ClickableSlotUI

# === NOUVEAU: ITEM PREVIEW ===
var item_preview: ItemPreview
var preview_layer: CanvasLayer

func _ready():
	print("🔧 ClickSystemIntegrator _ready() appelé")
	_initialize_system()
	# CORRECTION: Attendre un frame avant de créer la preview
	call_deferred("_create_item_preview")

func _initialize_system():
	"""Initialise le système de clic"""
	print("🔧 Initialisation du système de clic...")
	click_system = ClickSystemManager.new()
	add_child(click_system)
	
	ServiceLocator.register("click_system", click_system)
	
	if Events.instance:
		Events.instance.slot_clicked.connect(_handle_slot_click_via_events)
		print("✅ Connecté aux événements de slots")
	else:
		print("❌ Events.instance introuvable")

func _create_item_preview():
	"""NOUVEAU: Crée le système de preview avec debug complet"""
	print("🔧 Création de l'ItemPreview...")
	
	# ÉTAPE 1: Vérifier l'existence du fichier
	var preview_scene_path = "res://scenes/ui/components/ItemPreview.tscn"
	
	if not ResourceLoader.exists(preview_scene_path):
		print("❌ Fichier ItemPreview.tscn introuvable à: %s" % preview_scene_path)
		print("💡 Créer la preview manuellement...")
		_create_preview_manually()
		return
	
	# ÉTAPE 2: Charger la scène
	var preview_scene = load(preview_scene_path)
	if not preview_scene:
		print("❌ Impossible de charger ItemPreview.tscn")
		_create_preview_manually()
		return
	
	print("✅ Scène ItemPreview chargée")
	
	# ÉTAPE 3: Instancier
	item_preview = preview_scene.instantiate() as ItemPreview
	if not item_preview:
		print("❌ Impossible d'instancier ItemPreview")
		_create_preview_manually()
		return
	
	print("✅ ItemPreview instancié: %s" % item_preview.name)
	
	# ÉTAPE 4: Créer le CanvasLayer
	_create_preview_layer()

func _create_preview_manually():
	"""FALLBACK: Crée la preview manuellement si la scène n'existe pas"""
	print("🔧 Création manuelle de l'ItemPreview...")
	
	# Créer l'instance directement depuis le script
	var ItemPreviewScript = load("res://scripts/ui/components/ItemPreview.gd")
	if not ItemPreviewScript:
		print("❌ Script ItemPreview.gd introuvable")
		return
	
	item_preview = ItemPreviewScript.new()
	item_preview.name = "ItemPreview"
	
	print("✅ ItemPreview créé manuellement")
	_create_preview_layer()
	
	# CORRECTION CRUCIALE: Forcer l'initialisation immédiate
	call_deferred("_ensure_preview_ready")

func _ensure_preview_ready():
	"""NOUVEAU: S'assure que la preview est complètement prête"""
	if not item_preview:
		return
	
	print("🔧 Vérification état preview...")
	
	# Si la preview n'est pas encore prête, forcer la création
	if item_preview.has_method("debug_state"):
		item_preview.debug_state()
	
	# Forcer la création de l'UI si pas encore faite
	if item_preview.has_method("_create_simple_ui") and not item_preview.is_setup_complete:
		print("🔧 Forçage création UI de la preview...")
		item_preview._create_simple_ui()
		await get_tree().process_frame
		print("✅ UI preview forcée")
	
	print("✅ Preview garantie prête")

func _create_preview_layer():
	"""VERSION ULTRA-SIMPLE: Pas de CanvasLayer, ajout direct"""
	if not item_preview:
		print("❌ Impossible de créer le layer - pas d'ItemPreview")
		return
	
	# Ajouter DIRECTEMENT à la scène principale
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("❌ Scène actuelle introuvable")
		return
	
	print("🔧 Ajout direct à la scène: %s" % current_scene.name)
	
	# Ajouter sans CanvasLayer
	current_scene.add_child(item_preview)
	
	# Configurer pour être visible
	item_preview.z_index = 9999
	item_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	print("✅ ItemPreview ajouté directement")
	print("   - Parent: %s" % item_preview.get_parent().name)
	print("   - Z-index: %d" % item_preview.z_index)
	print("   - Position: %s" % item_preview.position)
	print("   - Taille: %s" % item_preview.size)

# === GESTION DES CLICS (inchangée) ===

func _handle_slot_click_via_events(context: ClickContext):
	"""Point d'entrée principal pour les clics"""
	if not selected_slot_info.is_empty():
		_handle_transfer_attempt(context)
	else:
		_handle_initial_click(context)

func _handle_transfer_attempt(context: ClickContext):
	"""Gère une tentative de transfert"""
	print("🔄 Tentative de transfert...")
	
	var target_context = _create_slot_to_slot_context(context)
	var success = click_system.action_registry.execute(target_context)
	
	_clear_selection()
	
	if success:
		_refresh_all_uis()

func _handle_initial_click(context: ClickContext):
	"""Gère le premier clic sur un slot"""
	match context.click_type:
		ClickContext.ClickType.SIMPLE_LEFT_CLICK:
			_handle_selection(context)
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			_handle_usage(context)

func _handle_selection(context: ClickContext):
	"""Gère la sélection d'un slot (MODIFIÉ pour preview)"""
	if context.source_slot_data.get("is_empty", true):
		_show_error_feedback(context)
		return
	
	_clear_visual_selection()
	_apply_visual_selection(context)
	_save_selection_data(context)
	
	# NOUVEAU: Afficher la preview avec debug
	_show_item_preview(context.source_slot_data)

func _show_error_feedback(context: ClickContext):
	"""Affiche le feedback d'erreur sur un slot vide"""
	var slot_ui = SlotFinder.find_slot_ui_for_context(context, registered_uis)
	if slot_ui and slot_ui.has_method("show_error_feedback"):
		slot_ui.show_error_feedback()
		print("❌ Clic sur slot vide - feedback d'erreur affiché")

func _handle_usage(context: ClickContext):
	"""Gère l'utilisation directe d'un item"""
	var success = click_system.action_registry.execute(context)
	if success:
		call_deferred("_refresh_all_uis")

# === GESTION VISUELLE ===

func _clear_visual_selection():
	"""Nettoie la sélection visuelle précédente"""
	if currently_selected_slot_ui and is_instance_valid(currently_selected_slot_ui):
		currently_selected_slot_ui.remove_selection_highlight()

func _apply_visual_selection(context: ClickContext):
	"""Applique la sélection visuelle"""
	var slot_ui = SlotFinder.find_slot_ui_for_context(context, registered_uis)
	if slot_ui:
		slot_ui.highlight_as_selected()
		currently_selected_slot_ui = slot_ui
		print("✨ Sélection visuelle activée sur slot %d" % context.source_slot_index)

func _save_selection_data(context: ClickContext):
	"""Sauvegarde les données de sélection"""
	selected_slot_info = {
		"slot_index": context.source_slot_index,
		"container_id": context.source_container_id,
		"slot_data": context.source_slot_data
	}
	print("✅ Slot %d sélectionné (%s)" % [context.source_slot_index, context.source_slot_data.get("item_name", "Inconnu")])

func _clear_selection():
	"""Efface complètement la sélection (MODIFIÉ)"""
	if selected_slot_info.is_empty():
		return
	
	print("🔹 Sélection effacée slot %d" % selected_slot_info.slot_index)
	
	_clear_visual_selection()
	currently_selected_slot_ui = null
	selected_slot_info.clear()
	
	# NOUVEAU: Cacher la preview
	_hide_item_preview()

# === MÉTHODES PREVIEW AVEC DEBUG ===

func _show_item_preview(item_data: Dictionary):
	"""Affiche la preview de l'item sélectionné avec debug"""
	print("🖼️ Tentative d'affichage preview...")
	
	if not item_preview:
		print("❌ ItemPreview introuvable pour affichage")
		return
	
	if not is_instance_valid(item_preview):
		print("❌ ItemPreview invalide")
		return
	
	print("✅ ItemPreview valide, affichage item: %s" % item_data.get("item_name", "Inconnu"))
	
	item_preview.show_item(item_data)
	
	# Positionner immédiatement à la souris
	var mouse_pos = get_viewport().get_mouse_position()
	item_preview.update_position(mouse_pos)
	
	print("✅ Preview affichée à la position: %s" % mouse_pos)

func _hide_item_preview():
	"""Cache la preview avec debug"""
	print("🖼️ Tentative de cache preview...")
	
	if not item_preview:
		print("❌ ItemPreview introuvable pour cache")
		return
	
	if not is_instance_valid(item_preview):
		print("❌ ItemPreview invalide pour cache")
		return
	
	item_preview.hide_item()
	print("✅ Preview cachée")

# === UTILITAIRES ===

func _create_slot_to_slot_context(target_context: ClickContext) -> ClickContext:
	"""Crée un contexte de transfert slot-to-slot"""
	return ClickContext.create_slot_to_slot_interaction(
		ClickContext.ClickType.SIMPLE_LEFT_CLICK,
		selected_slot_info.slot_index,
		selected_slot_info.container_id, 
		selected_slot_info.slot_data,
		target_context.source_slot_index,
		target_context.source_container_id,
		target_context.source_slot_data
	)

func _refresh_all_uis():
	"""Rafraîchit toutes les UIs enregistrées"""
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()

# === API PUBLIQUE ===

func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	click_system.register_container(container_id, controller)
	
	if ui:
		registered_uis[container_id] = ui

func print_debug_info():
	"""Affiche l'état du système pour debug AMÉLIORÉ"""
	print("\n🔍 ÉTAT CLICK SYSTEM:")
	print("   - Sélection active: %s" % (not selected_slot_info.is_empty()))
	if not selected_slot_info.is_empty():
		print("   - Slot sélectionné: %d dans %s" % [selected_slot_info.slot_index, selected_slot_info.container_id])
	print("   - UIs enregistrées: %d" % registered_uis.size())
	
	# DEBUG PREVIEW DÉTAILLÉ
	print("   - Preview existe: %s" % (item_preview != null))
	if item_preview:
		print("   - Preview valide: %s" % is_instance_valid(item_preview))
		print("   - Preview nom: %s" % item_preview.name)
		print("   - Preview active: %s" % item_preview.is_active)
		print("   - Preview visible: %s" % item_preview.visible)
		print("   - Preview layer: %s" % (preview_layer.name if preview_layer else "null"))
	else:
		print("   - ❌ Preview complètement manquante")

# === MÉTHODE DE FORCE CRÉATION ===

func force_create_preview():
	"""NOUVEAU: Force la création de la preview pour debug"""
	print("🔧 FORCE création de la preview...")
	if item_preview:
		print("⚠️ Preview existe déjà, suppression...")
		if is_instance_valid(item_preview):
			item_preview.queue_free()
		item_preview = null
	
	_create_item_preview()
	
	# Vérification
	await get_tree().process_frame
	print_debug_info()
