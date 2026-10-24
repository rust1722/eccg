class_name CreatureCardData
extends CardData
## Карта существа (DESIGN.md §2.3). Постоянная карта: после боя
## полностью восстанавливается и не сгорает никогда (DESIGN.md §5).

@export var mana_cost: int = 1
@export var attack: int = 1
@export var health: int = 1
@export var max_health: int = 1
## Ключевые слова, например ["летает", "яд"]. Пока просто список строк.
@export var keywords: Array[String] = []


func _init() -> void:
	card_type = CardType.CREATURE
	is_consumable = false
