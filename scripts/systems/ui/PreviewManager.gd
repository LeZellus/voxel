# scripts/systems/ui/PreviewManager.gd - GESTIONNAIRE CENTRALISÉ
class_name PreviewManager
extends Node

# === SINGLETON ===
static var instance: PreviewManager

# === COMPOSANTS ===
var preview_layer: CanvasLayer
var item_preview: ItemPreview

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	print("🔧 PreviewManager: Initialisation...")
	_create_preview_system()
	print("✅ PreviewManager: Prêt")

# === INITIALISATION ===

func _create_preview_system():
	"""Crée le système de preview de manière propre"""
	# Créer le layer dédié
	preview_layer = CanvasLayer.new()
	preview_layer.name = "UIPreviewLayer"
	preview_layer.layer = 100
	
	# Ajouter au root pour éviter les problèmes de hiérarchie
	get_tree().root.add_child.call_deferred(preview_layer)
	
	# Créer la preview
	_create_item_preview()

func _create_item_preview():
	"""Crée l'ItemPreview"""
	var preview_scene = load("res://scenes/click_system/ui/ItemPreview.tscn")
	if not preview_scene:
		print("❌ ItemPreview.tscn introuvable")
		return
	
	item_preview = preview_scene.instantiate() as ItemPreview
	if not item_preview:
		print("❌ Impossible d'instancier ItemPreview")
		return
	
	preview_layer.add_child(item_preview)
	item_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("✅ ItemPreview créé et configuré")

# === API PUBLIQUE ===

static func show_item_preview(item_data: Dictionary):
	"""API statique pour afficher une preview"""
	if not instance:
		print("❌ PreviewManager instance introuvable")
		return
		
	if not instance.item_preview:
		print("❌ ItemPreview introuvable dans PreviewManager")
		return
		
	if not is_instance_valid(instance.item_preview):
		print("❌ ItemPreview invalide")
		return
	
	print("📦 PreviewManager: Affichage item '%s'" % item_data.get("item_name", "Inconnu"))
	instance.item_preview.show_item(item_data)

static func hide_item_preview():
	"""API statique pour cacher la preview"""
	if not instance:
		print("❌ PreviewManager instance introuvable")
		return
		
	if not instance.item_preview:
		print("❌ ItemPreview introuvable")
		return
		
	print("📦 PreviewManager: Masquage preview")
	instance.item_preview.hide_item()

static func is_preview_active() -> bool:
	"""Vérifie si la preview est active"""
	if instance and instance.item_preview:
		return instance.item_preview.is_active
	return false

# === NETTOYAGE ===

func _exit_tree():
	"""Nettoyage à la sortie"""
	if preview_layer and is_instance_valid(preview_layer):
		preview_layer.queue_free()
	
	if instance == self:
		instance = null
