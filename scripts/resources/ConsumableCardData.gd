class_name ConsumableCardData
extends CardData
## Расходная карта (DESIGN.md §2.3): еда, напитки, зелья, ингредиенты...
## После использования сгорает навсегда (DESIGN.md §5).

@export var mana_cost: int = 0
## Сколько одинаковых карт помещается в один стак Архива.
@export var stack_limit: int = 99
## Что делает карта при использовании. Исполняет боевой движок (позже).
@export var effects: Array[CardEffect] = []
## Рецепт, по которому эта карта создаётся в мастерской (если есть).
## Например у "Лесного супа" здесь будет ссылка на карту-рецепт супа.
@export var craft_recipe: CardData


func _init() -> void:
	is_consumable = true
