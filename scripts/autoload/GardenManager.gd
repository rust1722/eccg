extends Node
## GardenManager (Autoload) — состояние сада: горшки и таймеры роста.
##
## Состояние живёт здесь, а не в сцене сада: сцена выгружается при
## переходе в другую комнату, а растения должны продолжать расти.
## Таймер хранится как момент готовности (deadline по системному
## времени), поэтому рост честно идёт, пока игрок в других комнатах.

signal garden_changed

enum PotState {
	EMPTY, ## Пустой горшок
	NEEDS_WATER, ## Росток посажен, ждёт полива
	GROWING, ## Полито, идёт таймер созревания
	READY, ## Созрело, можно собирать
}

const POT_COUNT: int = 8

## Каждый горшок: {state: PotState, seed_card: SeedCardData, ready_unix: float}
var pots: Array[Dictionary] = []


func _ready() -> void:
	for i in POT_COUNT:
		pots.append({
			"state": PotState.EMPTY,
			"seed_card": null,
			"ready_unix": 0.0,
		})
	print("[GardenManager] ready: %d pots" % POT_COUNT)


func _process(_delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	var changed := false
	for pot in pots:
		if int(pot["state"]) == PotState.GROWING and now >= float(pot["ready_unix"]):
			pot["state"] = PotState.READY
			changed = true
			var seed := pot["seed_card"] as SeedCardData
			print("[Garden] ready: %s" % (seed.title if seed != null else "?"))
	if changed:
		garden_changed.emit()


func get_pot(pot_index: int) -> Dictionary:
	return pots[pot_index]


func get_pot_state(pot_index: int) -> int:
	return int(pots[pot_index]["state"])


## Посадить семя из веера в пустой горшок. Карта списывается из веера.
func plant_seed(pot_index: int, card: CardData) -> bool:
	if get_pot_state(pot_index) != PotState.EMPTY:
		return false
	if not (card is SeedCardData):
		return false
	if not InventoryManager.remove_card_from_hand(card):
		return false
	pots[pot_index]["state"] = PotState.NEEDS_WATER
	pots[pot_index]["seed_card"] = card
	pots[pot_index]["ready_unix"] = 0.0
	garden_changed.emit()
	print("[Garden] pot %d: planted %s" % [pot_index, card.title])
	return true


## Полить посаженный росток картой воды из веера: стартует таймер.
func water_pot(pot_index: int, card: CardData) -> bool:
	if get_pot_state(pot_index) != PotState.NEEDS_WATER:
		return false
	if card == null or card.id != "water":
		return false
	if not InventoryManager.remove_card_from_hand(card):
		return false
	var seed := pots[pot_index]["seed_card"] as SeedCardData
	var grow_seconds := 180.0
	if seed != null and seed.grow_time_seconds > 0.0:
		grow_seconds = seed.grow_time_seconds
	pots[pot_index]["state"] = PotState.GROWING
	pots[pot_index]["ready_unix"] = Time.get_unix_time_from_system() + grow_seconds
	garden_changed.emit()
	print("[Garden] pot %d: watered, %.0f sec to grow" % [pot_index, grow_seconds])
	return true


## Сколько секунд осталось расти (0, если не растёт).
func get_time_left(pot_index: int) -> int:
	if get_pot_state(pot_index) != PotState.GROWING:
		return 0
	var left := float(pots[pot_index]["ready_unix"]) - Time.get_unix_time_from_system()
	return maxi(0, int(ceil(left)))


## Собрать созревший урожай. Возвращает словарь
## {card: CardData, destination: "hand"/"archive"} или пустой словарь.
func harvest(pot_index: int) -> Dictionary:
	if get_pot_state(pot_index) != PotState.READY:
		return {}
	var seed := pots[pot_index]["seed_card"] as SeedCardData
	var result_card: CardData = null
	if seed != null:
		result_card = seed.harvest_result_card
	pots[pot_index]["state"] = PotState.EMPTY
	pots[pot_index]["seed_card"] = null
	pots[pot_index]["ready_unix"] = 0.0
	garden_changed.emit()
	if result_card == null:
		push_warning("[Garden] seed has no harvest_result_card")
		return {}
	var destination := InventoryManager.add_loot_card(result_card)
	print("[Garden] pot %d: harvested %s -> %s" % [pot_index, result_card.title, destination])
	return {"card": result_card, "destination": destination}


func has_ready_plants() -> bool:
	for pot in pots:
		if int(pot["state"]) == PotState.READY:
			return true
	return false


func get_ready_count() -> int:
	var count := 0
	for pot in pots:
		if int(pot["state"]) == PotState.READY:
			count += 1
	return count
