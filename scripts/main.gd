extends Node2D
## Временный самотест ПЕРВОГО ЭТАПА (DESIGN.md, Приложение A).
##
## По F5 загружает 8 тестовых карт, кладёт их в Архив и раскладывает
## по рукам комнат (система A+), а результат печатает в панель Output
## внизу Godot. Когда появится настоящий интерфейс, этот тест уберём.

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


func _ready() -> void:
	print("=== eccg: STAGE 1 SELF-TEST ===")
	print("Game mode: ", GameStateManager.get_mode_name())

	var loaded_ok := 0
	for card in test_cards:
		if card == null or card.id == "":
			push_error("[Stage1] Broken test card in test set!")
			continue
		loaded_ok += 1
		InventoryManager.add_to_archive(card, 3)
		print("- ", card.title, " [", CardData.CardType.keys()[card.card_type],
				"] consumable=", card.is_consumable,
				" buy=", card.buy_price, " sell=", card.sell_price)
	print("Test cards loaded: ", loaded_ok, "/", test_cards.size())

	# Демонстрация системы A+: у каждой комнаты своя рука (DESIGN.md §6.5).
	var seed := test_cards[0]
	var meat := test_cards[2]
	InventoryManager.add_card_to_room_hand("garden", seed)
	InventoryManager.add_card_to_room_hand("kitchen", meat)
	print("Garden hand: ", _card_titles(InventoryManager.get_room_hand("garden")))
	print("Kitchen hand: ", _card_titles(InventoryManager.get_room_hand("kitchen")))
	print("Archive left: seed=", InventoryManager.get_archive_count(seed.id),
			" meat=", InventoryManager.get_archive_count(meat.id))
	print("=== STAGE 1 OK: if you see this, foundation works ===")


func _card_titles(cards: Array[CardData]) -> String:
	var titles: PackedStringArray = []
	for card in cards:
		titles.append(card.title)
	return ", ".join(titles)
