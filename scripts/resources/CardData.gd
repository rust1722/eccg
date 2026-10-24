class_name CardData
extends Resource
## Базовая карта игры (DESIGN.md §2.1).
##
## Это данные, а не картинка на экране: одна карта как .tres файл в
## resources/cards/. Экранная карта (веер, перетаскивание) появится позже
## и будет только показывать эти данные.

enum CardType {
	CREATURE, ## Существо (постоянная)
	SPELL, ## Заклинание (расходная)
	ITEM, ## Предмет (расходная)
	INGREDIENT, ## Ингредиент (крафт)
	FOOD, ## Еда (расходная / для клиентов)
	DRINK, ## Напиток (расходная / для клиентов)
	SEED, ## Семена (для сада)
	POTION, ## Зелье (расходная)
	RECIPE, ## Рецепт (для изучения в книгах)
	QUEST, ## Задание (для активации в кабинете)
}

## Уникальный id карты латиницей, например "potion_health". По нему карта
## находится в Архиве и в сохранениях, поэтому id не меняем после релиза.
@export var id: String = ""
## Название, которое видит игрок.
@export var title: String = ""
## Описание для игрока.
@export_multiline var description: String = ""
## Картинка карты (пока может быть пустой).
@export var icon: Texture2D
@export var card_type: CardType = CardType.INGREDIENT
## true = карта сгорает после использования (еда, зелья, заклинания...).
## false = постоянная карта (существа): не сгорает никогда (DESIGN.md §5).
@export var is_consumable: bool = false
@export var buy_price: int = 0
@export var sell_price: int = 0


func _to_string() -> String:
	return "%s [%s]" % [title if title != "" else id, CardType.keys()[card_type]]
