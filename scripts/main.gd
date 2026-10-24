extends Control
## Main — постоянная оболочка таверны (вариант D, DESIGN.md §6.2).
##
## Внутри: RoomSlot, куда RoomManager ставит текущую комнату, и
## PersistentUI (нижняя полоса): профиль, веер карт, колода, указатель.
## Веер один на всю таверну и не меняется при смене комнат.
## На старте один раз кладёт тестовые карты в Архив и в общий веер.

var test_cards: Array[CardData] = [
	preload("res://resources/cards/test_set/card_seed_sunflower.tres"),
	preload("res://resources/cards/test_set/card_water.tres"),
	preload("res://resources/cards/test_set/card_meat.tres"),
	preload("res://resources/cards/test_set/card_herbs.tres"),
	preload("res://resources/cards/test_set/card_soup_recipe.tres"),
	preload("res://resources/cards/test_set/card_soup.tres"),
	preload("res://resources/cards/test_set/card_potion_health.tres"),
	preload("res://resources/cards/test_set/card_quest_tower.tres"),
	preload("res://resources/cards/test_set/card_sunflower.tres"),
]

@onready var _room_slot: Control = $RoomSlot
@onready var _hand_ui: HandUI = $PersistentUI/HandUI
@onready var _deck_button: Button = $PersistentUI/DeckButton
@onready var _archive_overlay: ArchiveOverlay = $PersistentUI/ArchiveOverlay


func _ready() -> void:
	print("=== eccg: STAGE 3.2 - one shared fan for all rooms ===")
	_seed_test_cards()
	_deck_button.pressed.connect(_on_deck_button_pressed)
	_archive_overlay.closed.connect(_on_archive_closed)
	_archive_overlay.archive_card_chosen.connect(_on_archive_card_chosen)
	RoomManager.register_shell(_room_slot, _hand_ui)


func _on_deck_button_pressed() -> void:
	if RoomManager.is_transitioning() or RoomManager.current_room_id == "":
		return
	if _archive_overlay.visible:
		_archive_overlay.close_overlay()
		return
	_archive_overlay.open_archive()
	_hand_ui.archive_target_global_position = _archive_overlay.get_fly_destination_global_position()
	_hand_ui.set_archive_mode(true)


func _on_archive_closed() -> void:
	_hand_ui.set_archive_mode(false)


func _on_archive_card_chosen(card: CardData, source_global_position: Vector2) -> void:
	await _hand_ui.animate_add_card_from(card, source_global_position)


## Стартовый набор: карты в Архив, а часть — сразу в общий веер.
## Запускается один раз на старте игры; сохранения появятся позже.
func _seed_test_cards() -> void:
	# Защита от повторного посева, если оболочку перезапустят в том же
	# процессе: иначе в веер лягут дубли карт.
	if InventoryManager.get_archive_count("seed_sunflower") > 0:
		print("[Seed] skipped: archive already has cards")
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
		"sunflower": 0,
	}
	var by_id: Dictionary = {}
	for card in test_cards:
		by_id[card.id] = card
		# Реестр знает и карты с нулём на старте (Подсолнух: его ещё
		# предстоит вырастить, в Архиве он будет виден как ×0).
		InventoryManager.register_card(card)
		InventoryManager.add_to_archive(card, int(start_counts.get(card.id, 1)))

	# Один общий стартовый веер на всю таверну: семена и вода пригодятся
	# в саду, суп и зелье — в баре. Игрок унесёт их в любую комнату,
	# а лишнее сбросит в Архив и возьмёт нужное (для того Архив и есть).
	InventoryManager.add_card_to_hand(by_id["seed_sunflower"] as CardData)
	InventoryManager.add_card_to_hand(by_id["water"] as CardData)
	InventoryManager.add_card_to_hand(by_id["soup"] as CardData)
	InventoryManager.add_card_to_hand(by_id["potion_health"] as CardData)

	print("[Seed] shared hand: ", _hand_titles())


func _hand_titles() -> String:
	var titles: PackedStringArray = []
	for card in InventoryManager.get_hand():
		titles.append(card.title)
	return ", ".join(titles)
