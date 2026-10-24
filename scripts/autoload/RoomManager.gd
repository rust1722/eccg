extends Node
## RoomManager (Autoload) — переходы между комнатами таверны.
##
## Утверждённая схема D (DESIGN.md §6.2): комнаты живут внутри постоянной
## оболочки Main.tscn, а бой позже будет отдельным экраном с загрузкой.
## При переходе меняется ТОЛЬКО сцена комнаты в слоте оболочки:
## вся нижняя панель (профиль, веер, колода, указатель) всегда одна
## и та же и никуда не уезжает — веер у игрока один на все комнаты
## (решение 2026-10-25, DESIGN.md §6.5).
## Веер показывается один раз при старте таверны (show_hand).
## Игрок ходит сюда через указатель с вороной (SignpostNav).

signal room_changed(previous_room_id: String, room_id: String)
signal room_transition_started(previous_room_id: String, room_id: String)

## Все комнаты в порядке дощечек указателя (DESIGN.md §6.3).
const ROOM_TITLES: Dictionary = {
	"bar": "Бар",
	"garden": "Сад",
	"kitchen": "Кухня",
	"forge": "Кузня",
	"alchemy": "Алхимия",
	"library": "Библиотека",
	"shop": "Лавка",
	"cabinet": "Кабинет",
	"archive": "Архив",
}

## Комнаты, у которых уже есть сцена. С этапа 3 сцены есть у всех
## комнат (пока это заглушки PlaceholderRoom), указатель полностью живой.
const ROOM_SCENES: Dictionary = {
	"bar": "res://scenes/rooms/BarScene.tscn",
	"garden": "res://scenes/rooms/GardenScene.tscn",
	"kitchen": "res://scenes/rooms/KitchenScene.tscn",
	"forge": "res://scenes/rooms/ForgeScene.tscn",
	"alchemy": "res://scenes/rooms/AlchemyScene.tscn",
	"library": "res://scenes/rooms/LibraryScene.tscn",
	"shop": "res://scenes/rooms/ShopScene.tscn",
	"cabinet": "res://scenes/rooms/CabinetScene.tscn",
	"archive": "res://scenes/rooms/ArchiveScene.tscn",
}

var current_room_id: String = ""
var previous_room_id: String = ""

var _room_slot: Control
var _hand_ui: HandUI
var _current_room_node: Node
var _transition_busy: bool = false


func _ready() -> void:
	print("[RoomManager] ready")


## Оболочка Main при старте отдаёт сюда свой слот для комнат и веер.
## Веер нужен только чтобы один раз показать его при старте и чтобы
## не менять сцену посреди полёта карты веер <-> Архив.
func register_shell(room_slot: Control, hand_ui: HandUI) -> void:
	_room_slot = room_slot
	_hand_ui = hand_ui
	if current_room_id == "":
		go_to_room.call_deferred("bar")


func get_room_ids() -> Array:
	return ROOM_TITLES.keys()


func get_room_title(room_id: String) -> String:
	return String(ROOM_TITLES.get(room_id, room_id))


func is_room_implemented(room_id: String) -> bool:
	return ROOM_SCENES.has(room_id)


func is_transitioning() -> bool:
	return _transition_busy


## Единственная точка перехода между комнатами. Её дёргает указатель,
## а позже будут дёргать двери в комнатах.
func go_to_room(room_id: String) -> void:
	if _transition_busy:
		return
	if room_id == current_room_id:
		return
	if not is_room_implemented(room_id):
		push_warning("[RoomManager] Room '%s' has no scene yet" % room_id)
		return
	if _room_slot == null:
		push_error("[RoomManager] register_shell() was not called")
		return

	_transition_busy = true
	var from_room_id := current_room_id
	room_transition_started.emit(from_room_id, room_id)
	print("[RoomManager] go_to_room: '%s' -> '%s'" % [from_room_id, room_id])

	# Не спорим с полётами карт веер<->Архив: дождёмся их конца.
	if _hand_ui != null:
		while _hand_ui.is_animating():
			await get_tree().process_frame

	# Меняем только сцену комнаты. Нижняя панель и веер не трогаем:
	# они одни и те же во всех комнатах (решение 2026-10-25).
	if _current_room_node != null:
		_room_slot.remove_child(_current_room_node)
		_current_room_node.queue_free()
		_current_room_node = null
	var packed := load(String(ROOM_SCENES[room_id])) as PackedScene
	if packed == null:
		push_error("[RoomManager] Cannot load room scene: %s" % ROOM_SCENES[room_id])
		_transition_busy = false
		return
	_current_room_node = packed.instantiate()
	_room_slot.add_child(_current_room_node)

	previous_room_id = from_room_id
	current_room_id = room_id

	# Один-единственный раз, при самом первом входе в таверну,
	# веер вылезает снизу. Дальше он просто всегда на месте.
	if _hand_ui != null and from_room_id == "":
		await _hand_ui.show_hand()

	_transition_busy = false
	room_changed.emit(from_room_id, room_id)
	print("[RoomManager] now in room: %s" % get_room_title(room_id))
