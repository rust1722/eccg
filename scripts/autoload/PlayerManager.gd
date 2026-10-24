extends Node
## PlayerManager (Autoload) — состояние игрока для нижней полосы.
##
## Золото живёт здесь и показывается в левом нижнем углу рядом
## с аватаром (решение автора, DESIGN.md §8). Остальные счётчики
## ресурсов со скетчей добавим, когда решим, что это за ресурсы (§7).

signal stats_changed

var gold: int = 142
var health: int = 28
var max_health: int = 30
var level: int = 4
## Прогресс до следующего уровня, 0.0-1.0 (полоска опыта на скетчах).
var experience_ratio: float = 0.6


func _ready() -> void:
	print("[PlayerManager] ready: gold=%d hp=%d/%d lv=%d" % [
		gold, health, max_health, level
	])


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	stats_changed.emit()


## false = золота не хватило.
func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	stats_changed.emit()
	return true
