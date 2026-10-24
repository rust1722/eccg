class_name SeedCardData
extends ConsumableCardData
## Семя для сада (DESIGN.md §2.3, §4.5): сажается в горшок, после полива
## созревает по реальному таймеру и даёт карту урожая.

## Что вырастет. Пока может быть пустым, если карты урожая ещё нет.
@export var harvest_result_card: CardData
## Сколько секунд растёт после полива (сад — на коротких минутных
## таймерах, DESIGN.md §4.5). Позже значение переедет в баланс по растениям.
@export var grow_time_seconds: float = 180.0


func _init() -> void:
	super._init()
	card_type = CardType.SEED
