extends Control
## Дорожный указатель с вороной — навигация по комнатам (DESIGN.md §6.3).
##
## Все дощечки видны ВСЕГДА, без раскрывающегося списка: игрок ходит
## между комнатами постоянно, поэтому переход — в один клик.
## Слева столбец обычных комнат, справа отдельным столбцом четыре
## мастерские (каждая своей дощечкой, но рядом). Комнаты без сцены
## пока выключены с пометкой "скоро".
## Указатель — часть постоянной нижней полосы оболочки и накладывается
## на любую комнату; сами переходы выполняет RoomManager.go_to_room().

const LEFT_COLUMN: Array[String] = ["bar", "garden", "shop", "cabinet", "barracks"]
const RIGHT_COLUMN: Array[String] = ["kitchen", "forge", "alchemy", "library"]
const PLANK_SIZE := Vector2(112, 36)

var _crow_label: Label
var _buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Столб указателя по центру между столбцами дощечек.
	var pole := ColorRect.new()
	pole.color = Color(0.16, 0.11, 0.07)
	pole.position = Vector2(118, 42)
	pole.size = Vector2(10, 288)
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pole)

	_make_plank_column(LEFT_COLUMN, Vector2(4, 58))
	_make_plank_column(RIGHT_COLUMN, Vector2(124, 82))

	# Ворона сидит сверху на указателе.
	var crow_panel := PanelContainer.new()
	crow_panel.position = Vector2(71, 8)
	crow_panel.size = Vector2(104, 36)
	var crow_style := StyleBoxFlat.new()
	crow_style.bg_color = Color(0.08, 0.09, 0.14, 0.95)
	crow_style.set_border_width_all(1)
	crow_style.border_color = Color(0.85, 0.72, 0.45, 0.7)
	crow_style.set_corner_radius_all(6)
	crow_panel.add_theme_stylebox_override("panel", crow_style)
	add_child(crow_panel)

	_crow_label = Label.new()
	_crow_label.text = "ВОРОНА"
	_crow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crow_label.add_theme_font_size_override("font_size", 12)
	_crow_label.add_theme_color_override("font_color", Color(0.85, 0.88, 1))
	crow_panel.add_child(_crow_label)

	RoomManager.room_changed.connect(_on_room_changed)
	GardenManager.garden_changed.connect(_refresh)
	_refresh()


func _make_plank_column(room_ids: Array[String], start_position: Vector2) -> void:
	for i in room_ids.size():
		var room_id := room_ids[i]
		var button := Button.new()
		button.position = start_position + Vector2(0, i * 41)
		button.size = PLANK_SIZE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_stylebox_override("normal", _plank_style(Color(0.23, 0.16, 0.10)))
		button.add_theme_stylebox_override("hover", _plank_style(Color(0.32, 0.22, 0.13)))
		button.add_theme_stylebox_override("pressed", _plank_style(Color(0.42, 0.30, 0.14)))
		button.add_theme_stylebox_override("disabled", _plank_style(Color(0.14, 0.11, 0.08, 0.85)))
		button.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
		button.add_theme_color_override("font_hover_color", Color(1, 0.98, 0.9))
		button.add_theme_color_override("font_disabled_color", Color(0.75, 0.72, 0.68))
		button.pressed.connect(_on_plank_pressed.bind(room_id))
		add_child(button)
		_buttons[room_id] = button


func _plank_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(1)
	style.border_color = Color(0.65, 0.48, 0.25)
	style.set_corner_radius_all(6)
	style.content_margin_left = 9
	style.content_margin_right = 6
	return style


func _on_plank_pressed(room_id: String) -> void:
	RoomManager.go_to_room(room_id)


func _on_room_changed(_from_room_id: String, room_id: String) -> void:
	_crow_label.text = "Кар! " + RoomManager.get_room_title(room_id)
	_refresh()


func _refresh() -> void:
	for key in _buttons.keys():
		var room_id := String(key)
		var button: Button = _buttons[room_id]
		var implemented: bool = RoomManager.is_room_implemented(room_id)
		var is_current: bool = room_id == RoomManager.current_room_id
		button.disabled = not implemented or is_current or RoomManager.is_transitioning()
		button.modulate = Color(1.2, 1.08, 0.72) if is_current else Color.WHITE
		var prefix := "> " if is_current else ""
		var suffix := "" if implemented else " · скоро"
		# Восклицательный знак: в саду что-то созрело, из любой комнаты видно.
		if room_id == "garden" and GardenManager.has_ready_plants():
			suffix += " !"
		button.text = prefix + RoomManager.get_room_title(room_id) + suffix
	if RoomManager.current_room_id == "":
		_crow_label.text = "ВОРОНА"
