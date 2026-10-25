extends Node
## CraftManager (Autoload) — рецепты и состояние крафта.
##
## Рецепты пока заданы прямо здесь (тестовый набор этапа 6):
## карта-рецепт учит рецепт через книгу в мастерской, ингредиенты
## лежат на столе (kitchen_table), результат уходит в веер/Архив.
## Состояние живёт в менеджере, а не в сцене кухни: ушёл в другую
## комнату — стол и изученные рецепты не пропали.

signal craft_changed

## recipe_id -> {title, result_id, ingredient_ids, teacher_card_id}
const RECIPES: Dictionary = {
	"soup": {
		"title": "Лесной суп",
		"result_id": "soup",
		"ingredient_ids": ["meat", "water", "herbs"],
		"teacher_card_id": "soup_recipe",
	},
}

## Изученные рецепты (id из RECIPES).
var learned_recipes: Array[String] = []
## Что сейчас лежит на разделочном столе кухни.
var kitchen_table: Array[CardData] = []


func _ready() -> void:
	print("[CraftManager] ready: %d recipes known to the game" % RECIPES.size())


func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})


func get_recipe_ids() -> Array:
	return RECIPES.keys()


func is_learned(recipe_id: String) -> bool:
	return learned_recipes.has(recipe_id)


## Какую рецептуру учит эта карта ("" — никакую).
func recipe_taught_by(card: CardData) -> String:
	if card == null:
		return ""
	for recipe_id in RECIPES.keys():
		if String(RECIPES[recipe_id]["teacher_card_id"]) == card.id:
			return String(recipe_id)
	return ""


## Изучить рецепт картой-рецептом: карта сгорает в книге.
## false = карта не рецепт, рецепт не найден или уже изучен
## (уже изученный рецепт карту не съедает).
func learn_recipe(card: CardData) -> bool:
	var recipe_id := recipe_taught_by(card)
	if recipe_id == "" or is_learned(recipe_id):
		return false
	if not InventoryManager.remove_card_from_hand(card):
		return false
	learned_recipes.append(recipe_id)
	craft_changed.emit()
	print("[Craft] learned recipe: %s" % recipe_id)
	return true


## Положить ингредиент из веера на стол.
func place_on_table(card: CardData) -> bool:
	if card == null or card.card_type != CardData.CardType.INGREDIENT:
		return false
	if not InventoryManager.remove_card_from_hand(card):
		return false
	kitchen_table.append(card)
	craft_changed.emit()
	print("[Craft] on table: %s (now %d)" % [card.title, kitchen_table.size()])
	return true


## Забрать ингредиент со стола обратно: в веер, а при полном — в Архив.
## Возвращает "hand"/"archive".
func return_from_table(card: CardData) -> String:
	var index := kitchen_table.find(card)
	if index == -1:
		return ""
	kitchen_table.remove_at(index)
	var destination := InventoryManager.add_loot_card(card)
	craft_changed.emit()
	return destination


## Хватает ли на столе ингредиентов на этот рецепт.
func can_craft(recipe_id: String) -> bool:
	if not is_learned(recipe_id):
		return false
	var needed: Array = RECIPES[recipe_id]["ingredient_ids"]
	var on_table: Array[String] = []
	for card in kitchen_table:
		on_table.append(card.id)
	for ingredient_id in needed:
		if not on_table.has(String(ingredient_id)):
			return false
	return true


## Сварить: ингредиенты сгорают со стола, результат — в веер/Архив.
## Возвращает карту результата или null, если нельзя.
func craft(recipe_id: String) -> CardData:
	if not can_craft(recipe_id):
		return null
	var needed: Array = RECIPES[recipe_id]["ingredient_ids"]
	for ingredient_id in needed:
		for card in kitchen_table:
			if card.id == String(ingredient_id):
				kitchen_table.erase(card)
				break
	var result_id := String(RECIPES[recipe_id]["result_id"])
	var result_card := InventoryManager.card_registry.get(result_id) as CardData
	if result_card != null:
		InventoryManager.add_loot_card(result_card)
	craft_changed.emit()
	print("[Craft] crafted: %s" % (result_card.title if result_card != null else result_id))
	return result_card
