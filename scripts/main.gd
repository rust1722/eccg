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


func _ready() -> void:
	print("=== eccg: STAGE 2 - tavern shell ===")
	_seed_test_cards()
	RoomManager.register_shell(_room_slot, _hand_ui)


## Стартовый набор: карты в Архив, а из него — по рукам комнат (A+).
## Запускается один раз на старте игры; сохранения появятся позже.
func _seed_test_cards() -> void:
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
	InventoryManager.add_card_to_room_hand("garden", by_id["seed_sunflower"])
	InventoryManager.add_card_to_room_hand("garden", by_id["water"])
	InventoryManager.add_card_to_room_hand("garden", by_id["herbs"])
	# Кухня: мясо, вода, зелень и рецепт супа (комнаты пока нет, рука уже ждёт).
	InventoryManager.add_card_to_room_hand("kitchen", by_id["meat"])
	InventoryManager.add_card_to_room_hand("kitchen", by_id["water"])
	InventoryManager.add_card_to_room_hand("kitchen", by_id["herbs"])
	InventoryManager.add_card_to_room_hand("kitchen", by_id["soup_recipe"])
	# Бар: суп и зелье гостям.
	InventoryManager.add_card_to_room_hand("bar", by_id["soup"])
	InventoryManager.add_card_to_room_hand("bar", by_id["potion_health"])
	# Кабинет: задание для карты мира.
	InventoryManager.add_card_to_room_hand("cabinet", by_id["quest_tower"])

	print("[Stage2] seeded: bar=", _titles("bar"),
			" garden=", _titles("garden"),
			" kitchen=", _titles("kitchen"))


func _titles(room_id: String) -> String:
	var titles: PackedStringArray = []
	for card in InventoryManager.get_room_hand(room_id):
		titles.append(card.title)
	return ", ".join(titles)
