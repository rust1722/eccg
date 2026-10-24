extends Node
## InventoryManager (Autoload) — Архив и ОДИН общий веер карт таверны.
##
## Решение автора от 2026-10-25 (DESIGN.md §6.5): отдельных рук по
## комнатам больше нет. Веер всегда один и тот же во всех комнатах:
## игрок может получить в саду карты для алхимии — и просто унести
## их в веере в алхимию. Ненужное сбрасывается в Архив, нужное берётся
## из Архива, поэтому Архив — главное хранилище, а веер — "карман"
## на HAND_LIMIT карт, который игрок носит с собой.
##
## archive_inventory хранит, СКОЛЬКО карт каждого вида свободно лежит
## в Архиве (id карты -> количество). Карта, лежащая в веере, в Архиве
## не числится — она "в кармане", дублей не возникает.

signal archive_changed
signal hand_changed

const HAND_LIMIT: int = 10

## id карты -> количество свободных карт в Архиве.
var archive_inventory: Dictionary = {}
## id карты -> сама карта (чтобы находить данные по id).
var card_registry: Dictionary = {}
## Единственный веер игрока на всю таверну.
var current_hand: Array[CardData] = []


func _ready() -> void:
	print("[InventoryManager] ready: archive + one shared hand")


## Запомнить карту в реестре, чтобы потом находить её по id.
func register_card(card: CardData) -> void:
	if card == null or card.id == "":
		push_warning("[InventoryManager] register_card: card without id")
		return
	card_registry[card.id] = card


## Положить карту в Архив (например: добыча при полном веере).
func add_to_archive(card: CardData, amount: int = 1) -> void:
	if card == null or amount <= 0:
		return
	register_card(card)
	archive_inventory[card.id] = get_archive_count(card.id) + amount
	archive_changed.emit()


## Забрать карту из Архива. false = такой карты в Архиве не хватило.
func take_from_archive(card: CardData, amount: int = 1) -> bool:
	if card == null or get_archive_count(card.id) < amount:
		return false
	archive_inventory[card.id] = get_archive_count(card.id) - amount
	if archive_inventory[card.id] <= 0:
		archive_inventory.erase(card.id)
	archive_changed.emit()
	return true


func get_archive_count(card_id: String) -> int:
	return int(archive_inventory.get(card_id, 0))


## Все карты, которые игра уже видела (для панели Архива):
## и те, что лежат в Архиве, и те, что сейчас в веере.
## Отсортировано по названию, чтобы сетка не прыгала.
func get_known_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for key in card_registry.keys():
		var card := card_registry[String(key)] as CardData
		if card != null:
			cards.append(card)
	cards.sort_custom(func(a: CardData, b: CardData) -> bool: return a.title < b.title)
	return cards


## Общий веер игрока. Возвращается именно хранимый массив, а не копия:
## поменял его — поменялся веер.
func get_hand() -> Array[CardData]:
	return current_hand


## Положить карту в веер. По умолчанию карта забирается из Архива.
## false = веер полон или карты не хватило в Архиве.
func add_card_to_hand(card: CardData, take_from_archive: bool = true) -> bool:
	if card == null or current_hand.size() >= HAND_LIMIT:
		return false
	if take_from_archive and not take_from_archive(card):
		return false
	current_hand.append(card)
	hand_changed.emit()
	return true


## Новая добыча (урожай, результат крафта, покупка): сначала в веер,
## при полном веере — автоматически в Архив (DESIGN.md §6.5).
## Возвращает "hand" или "archive" — куда карта реально попала.
func add_loot_card(card: CardData) -> String:
	if add_card_to_hand(card, false):
		return "hand"
	add_to_archive(card)
	return "archive"


## Вернуть одну карту из веера обратно в Архив.
func move_hand_card_to_archive(card: CardData) -> bool:
	var index := current_hand.find(card)
	if index == -1:
		return false
	current_hand.remove_at(index)
	add_to_archive(card)
	hand_changed.emit()
	return true


## Вернуть весь веер в Архив одним действием.
func clear_hand_to_archive() -> void:
	for card in current_hand:
		archive_inventory[card.id] = get_archive_count(card.id) + 1
	current_hand.clear()
	archive_changed.emit()
	hand_changed.emit()


## Данные для сохранения (SaveManager, DESIGN.md §6.6): только id и
## количества, сами карты восстановим по реестру при загрузке.
func get_save_data() -> Dictionary:
	var hand_ids: Array[String] = []
	for card in current_hand:
		hand_ids.append(card.id)
	return {
		"archive_inventory": archive_inventory.duplicate(),
		"hand_ids": hand_ids,
	}


func load_save_data(data: Dictionary) -> void:
	archive_inventory = data.get("archive_inventory", {}).duplicate()
	current_hand.clear()
	for card_key in data.get("hand_ids", []):
		var card_id := String(card_key)
		if card_registry.has(card_id):
			current_hand.append(card_registry[card_id] as CardData)
	archive_changed.emit()
	hand_changed.emit()
