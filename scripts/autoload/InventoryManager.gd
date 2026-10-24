extends Node
## InventoryManager (Autoload) — Архив и руки комнат таверны.
##
## Архив — главное хранилище: archive_inventory хранит, СКОЛЬКО карт
## каждого вида свободно лежит в Архиве (id карты -> количество).
## У каждой комнаты таверны своя запоминаемая рука до HAND_LIMIT карт
## (система A+, DESIGN.md §6.5): room_hands, room_id -> веер карт.
## Карта, лежащая в руке комнаты, в Архиве не числится — она
## "зарезервирована" за этой комнатой, дублей не возникает.

signal archive_changed
signal room_hand_changed(room_id: String)

const HAND_LIMIT: int = 10

## Комнаты таверны в порядке указателя с вороной (DESIGN.md §6.3).
const ROOM_IDS: Array[String] = [
	"bar",
	"garden",
	"kitchen",
	"forge",
	"alchemy",
	"library",
	"shop",
	"cabinet",
	"archive",
]

## id карты -> количество свободных карт в Архиве.
var archive_inventory: Dictionary = {}
## id карты -> сама карта (чтобы находить данные по id).
var card_registry: Dictionary = {}
## room_id -> Array[CardData], веер этой комнаты.
var room_hands: Dictionary = {}


func _ready() -> void:
	for room_id in ROOM_IDS:
		var empty_hand: Array[CardData] = []
		room_hands[room_id] = empty_hand
	print("[InventoryManager] ready: archive + %d room hands" % ROOM_IDS.size())


## Запомнить карту в реестре, чтобы потом находить её по id.
func register_card(card: CardData) -> void:
	if card == null or card.id == "":
		push_warning("[InventoryManager] register_card: card without id")
		return
	card_registry[card.id] = card


## Положить карту в Архив (например: добыча, переполнение руки).
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


## Веер комнаты. Возвращается именно хранимый массив, а не копия:
## поменял его — поменялась рука комнаты.
func get_room_hand(room_id: String) -> Array[CardData]:
	if not room_hands.has(room_id):
		var new_hand: Array[CardData] = []
		room_hands[room_id] = new_hand
	return room_hands[room_id]


## Положить карту в руку комнаты. По умолчанию карта забирается из Архива.
## false = рука полна или карты не хватило в Архиве.
func add_card_to_room_hand(room_id: String, card: CardData, take_from_archive: bool = true) -> bool:
	var hand := get_room_hand(room_id)
	if card == null or hand.size() >= HAND_LIMIT:
		return false
	if take_from_archive and not take_from_archive(card):
		return false
	hand.append(card)
	room_hand_changed.emit(room_id)
	return true


## Новая добыча (урожай, крафт, покупка): сначала в руку этой комнаты,
## при полной руке — автоматически в Архив (DESIGN.md §6.5).
## Возвращает "hand" или "archive" — куда карта реально попала.
func add_loot_card(card: CardData, room_id: String) -> String:
	if add_card_to_room_hand(room_id, card, false):
		return "hand"
	add_to_archive(card)
	return "archive"


## Вернуть одну карту из руки комнаты обратно в Архив.
func move_hand_card_to_archive(room_id: String, card: CardData) -> bool:
	var hand := get_room_hand(room_id)
	var index := hand.find(card)
	if index == -1:
		return false
	hand.remove_at(index)
	add_to_archive(card)
	room_hand_changed.emit(room_id)
	return true


## "Собрать всё в Архив" для одной комнаты.
func clear_room_hand_to_archive(room_id: String) -> void:
	var hand := get_room_hand(room_id)
	for card in hand:
		archive_inventory[card.id] = get_archive_count(card.id) + 1
	hand.clear()
	archive_changed.emit()
	room_hand_changed.emit(room_id)


## "Собрать всё в Архив" вообще из всех комнат.
func collect_all_hands_to_archive() -> void:
	for room_key in room_hands.keys():
		clear_room_hand_to_archive(String(room_key))


## Данные для сохранения (SaveManager, DESIGN.md §6.6): только id и
## количества, сами карты восстановим по реестру при загрузке.
func get_save_data() -> Dictionary:
	var hand_ids: Dictionary = {}
	for room_key in room_hands.keys():
		var room_id := String(room_key)
		var ids: Array[String] = []
		for card in get_room_hand(room_id):
			ids.append(card.id)
		hand_ids[room_id] = ids
	return {
		"archive_inventory": archive_inventory.duplicate(),
		"room_hand_ids": hand_ids,
	}


func load_save_data(data: Dictionary) -> void:
	archive_inventory = data.get("archive_inventory", {}).duplicate()
	var hand_ids: Dictionary = data.get("room_hand_ids", {})
	for room_key in hand_ids.keys():
		var hand := get_room_hand(String(room_key))
		hand.clear()
		for card_key in hand_ids[room_key]:
			var card_id := String(card_key)
			if card_registry.has(card_id):
				hand.append(card_registry[card_id] as CardData)
	archive_changed.emit()
