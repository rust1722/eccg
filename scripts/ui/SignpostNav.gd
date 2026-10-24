extends Control
## Дорожный указатель с вороной — навигация по комнатам (DESIGN.md §6.3).
##
## В обычном состоянии в правом нижнем углу виден только указатель
## с вороной. По клику он раскрывается: по одной дощечке на комнату.
## Мастерские идут отдельными дощечками подряд. Комнаты без сцены
## пока выключены с пометкой "скоро".
## Сами переходы выполняет RoomManager.go_to_room().

var _planks_panel: PanelContainer
var _crow_label: Label
var _post_button: Button
var _buttons: Dictionary = {}
var _expanded: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_planks_panel = PanelContainer.new()
	_planks_panel.position = Vector2(0, 0)
	_planks_panel.size = Vector2(158, 326)
	_planks_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.13, 0.10, 0.07, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.55, 0.40, 0.22)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 6
	panel_style.content_margin_right = 6
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 6
	_planks_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_planks_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_planks_panel.add_child(vbox)

	for room_id in RoomManager.get_room_ids():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_plank_pressed.bind(String(room_id)))
		vbox.add_child(button)
		_buttons[String(room_id)] = button

	var crow_panel := PanelContainer.new()
	crow_panel.position = Vector2(19, 332)
	crow_panel.size = Vector2(120, 32)
	var crow_style := StyleBoxFlat.new()
	crow_style.bg_color = Color(0.08, 0.09, 0.14, 0.95)
	crow_style.set_border_width_all(1)
	crow_style.border_color = Color(0.85, 0.72, 0.45, 0.6)
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

	_post_button = Button.new()
	_post_button.position = Vector2(9, 368)
	_post_button.size = Vector2(140, 82)
	_post_button.text = "УКАЗАТЕЛЬ\nкомнаты"
	_post_button.add_theme_font_size_override("font_size", 13)
	_post_button.pressed.connect(_on_post_pressed)
	add_child(_post_button)

	RoomManager.room_changed.connect(_on_room_changed)
	_refresh()


func _on_post_pressed() -> void:
	_expanded = not _expanded
	_planks_panel.visible = _expanded
	if _expanded:
		_refresh()


func _on_plank_pressed(room_id: String) -> void:
	_expanded = false
	_planks_panel.visible = false
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
		var prefix := "> " if is_current else ""
		var suffix := "" if implemented else " (скоро)"
		button.text = prefix + RoomManager.get_room_title(room_id) + suffix
	if RoomManager.current_room_id == "":
		_crow_label.text = "ВОРОНА"
