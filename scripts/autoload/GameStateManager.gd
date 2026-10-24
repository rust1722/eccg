extends Node
## GameStateManager (Autoload) — в каком режиме сейчас игра.
##
## Режимы из DESIGN.md §3. Комнаты внутри таверны здесь не различаются:
## какая именно комната открыта — забота RoomManager.

signal mode_changed(previous_mode: Mode, new_mode: Mode)

enum Mode {
	TAVERN, ## Таверна: бар, сад, мастерские, лавка, архив, кабинет
	WORLD_MAP, ## Карта мира в кабинете: выбор точки
	BATTLE, ## Бой: отдельный полноэкранный экран (DESIGN.md §5, §6.2D)
}

var current_mode: Mode = Mode.TAVERN


func _ready() -> void:
	print("[GameStateManager] ready, mode = %s" % Mode.keys()[current_mode])


func set_mode(new_mode: Mode) -> void:
	if new_mode == current_mode:
		return
	var previous_mode := current_mode
	current_mode = new_mode
	print("[GameStateManager] mode: %s -> %s" % [
		Mode.keys()[previous_mode], Mode.keys()[new_mode]
	])
	mode_changed.emit(previous_mode, new_mode)


func get_mode_name() -> String:
	return Mode.keys()[current_mode]


func is_in_tavern() -> bool:
	return current_mode == Mode.TAVERN


func is_in_battle() -> bool:
	return current_mode == Mode.BATTLE
