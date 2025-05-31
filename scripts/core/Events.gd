# scripts/core/Events.gd - Signal Bus Global
class_name Events
extends Node

# === INVENTAIRE ===
signal slot_clicked(context: ClickContext)
signal item_moved(from_slot: int, to_slot: int, container_id: String)
signal inventory_opened(container_id: String)
signal inventory_closed(container_id: String)

# === PLAYER ===
signal player_state_changed(old_state: String, new_state: String)
signal player_item_pickup(item: Item, quantity: int)

# === AUDIO ===
signal play_ui_sound(sound_name: String)
signal play_player_sound(sound_name: String, category: String)

static var instance: Events

func _init():
	if instance == null:
		instance = self

# === MÉTHODES STATIQUES ===
static func emit_slot_clicked(context: ClickContext):
	if instance:
		instance.slot_clicked.emit(context)

static func emit_item_moved(from_slot: int, to_slot: int, container_id: String):
	if instance:
		instance.item_moved.emit(from_slot, to_slot, container_id)
