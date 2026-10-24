extends Control
## Main — постоянная оболочка таверны (вариант D, DESIGN.md §6.2).
##
## Внутри: RoomSlot, куда RoomManager ставит текущую комнату, и
## PersistentUI (нижняя полоса): профиль, веер карт, колода, указатель.
## На старте один раз раскладывает тестовые карты этапа 1 по Архиву и
## рукам комнат, чтобы веер было чем показать.

var test_cards: Array[CardData] = [
	preload("res://resources/cards/test_set/card_seed_sunflower.tres"),
	preload("res://resources/cards/test_set/card_water.tres"),
	preload("res://resources/cards/test_set/card_meat.tres"),
	preload("res://resources/cards/test_set/card_herbs.tres"),
	preload("res://resources/cards/test_set/card_soup_recipe.tres"),
	preload("res://resources/cards/test_set/card_soup.tres"),
	preload("res://resources/cards/test_set/card_potion_health.tres"),
	preload("res://resources/cards/test_set/card_quest_tower.tres"),
]

@onready var _room_slot: Control = $RoomSlot
@onready var _hand_ui: HandUI = $PersistentUI/HandUI
@onready var _deck_button: Button = $PersistentUI/DeckButton
@onready var _archive_overlay: ArchiveOverlay = $PersistentUI/ArchiveOverlay


func _ready() -> void:
	print("=== eccg: STAGE 3.1 - archive panel over the fan ===")
	_seed_test_cards()
	_deck_button.pressed.connect(_on_deck_button_pressed)
	_archive_overlay.closed.connect(_on_archive_closed)
	_archive_overlay.archive_card_chosen.connect(_on_archive_card_chosen)
	RoomManager.room_transition_started.connect(_on_room_transition_started)
	RoomManager.register_shell(_room_slot, _hand_ui)


func _on_deck_button_pressed() -> void:
	if RoomManager.is_transitioning() or RoomManager.current_room_id == "":
		return
	if _archive_overlay.visible:
		_archive_overlay.close_overlay()
		return
	_archive_overlay.open_for_room(RoomManager.current_room_id)
	_hand_ui.archive_target_global_position = _archive_overlay.get_fly_destination_global_position()
	_hand_ui.set_archive_mode(true)


func _on_archive_closed() -> void:
	_hand_ui.set_archive_mode(false)


func _on_archive_card_chosen(card: CardData, source_global_position: Vector2) -> void:
	await _hand_ui.animate_add_card_from(card, source_global_position)


func _on_room_transition_started(_from_room_id: String, _to_room_id: String) -> void:
	if _archive_overlay.visible:
		_archive_overlay.close_overlay()


## Стартовый набор: карты в Архив, а из него — по рукам комнат (A+).
## Запускается один раз на старте игры; сохранения появятся позже.
func _seed_test_cards() -> void:
	# Защита от повторного посева, если оболочку перезапустят в том же
	# процессе: иначе в руки комнат лягут дубли карт.
	if InventoryManager.get_archive_count("seed_sunflower") > 0:
		print("[Stage2] seed skipped: archive already has cards")
		return

	var start_counts: Dictionary = {
		"seed_sunflower": 3,
		"water": 5,
		"meat": 4,
		"herbs": 5,
		"soup_recipe": 1,
		"soup": 3,
		"potion_health": 3,
		"quest_tower": 1,
	}
	var by_id: Dictionary = {}
	for card in test_cards:
		by_id[card.id] = card
		InventoryManager.add_to_archive(card, int(start_counts.get(card.id, 1)))

	# Сад: семена, вода, зелень.
	InventoryManager.add_card_to_room_hand("garden", by_id["seed_sunflower"] as CardData)
	InventoryManager.add_card_to_room_hand("garden", by_id["water"] as CardData)
	InventoryManager.add_card_to_room_hand("garden", by_id["herbs"] as CardData)
	# Кухня: мясо, вода, зелень и рецепт супа (комнаты пока нет, рука уже ждёт).
	InventoryManager.add_card_to_room_hand("kitchen", by_id["meat"] as CardData)
	InventoryManager.add_card_to_room_hand("kitchen", by_id["water"] as CardData)
	InventoryManager.add_card_to_room_hand("kitchen", by_id["herbs"] as CardData)
	InventoryManager.add_card_to_room_hand("kitchen", by_id["soup_recipe"] as CardData)
	# Бар: суп и зелье гостям.
	InventoryManager.add_card_to_room_hand("bar", by_id["soup"] as CardData)
	InventoryManager.add_card_to_room_hand("bar", by_id["potion_health"] as CardData)
	# Кабинет: задание для карты мира.
	InventoryManager.add_card_to_room_hand("cabinet", by_id["quest_tower"] as CardData)

	print("[Stage2] seeded: bar=", _titles("bar"),
			" garden=", _titles("garden"),
			" kitchen=", _titles("kitchen"))


func _titles(room_id: String) -> String:
	var titles: PackedStringArray = []
	for card in InventoryManager.get_room_hand(room_id):
		titles.append(card.title)
	return ", ".join(titles)
