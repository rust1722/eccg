class_name HandUI
extends Control
## Веер карт текущей комнаты в нижней полосе (система A+, DESIGN.md §6.5).
##
## Веер один на всю игру и живёт в оболочке. При смене комнаты RoomManager
## вызывает animate_hide() -> show_room_hand(): старый веер уезжает вниз
## за экран, новый вылезает снизу по картам (DESIGN.md §6.5.1).
## Какие карты показать, HandUI не придумывает сам: берёт запоминаемую
## руку комнаты из InventoryManager.room_hands.

const CARD_SIZE := Vector2(104, 136)
const FAN_WIDTH: float = 620.0
const SETTLED_Y: float = 84.0
const HIDDEN_OFFSET_Y: float = 210.0

var current_room_id: String = ""

var _views: Array[Control] = []
var _animating: bool = false


func is_animating() -> bool:
	return _animating


## Показать руку комнаты с анимацией выхода снизу.
func show_room_hand(room_id: String) -> void:
	current_room_id = room_id
	_clear_views()

	var cards := InventoryManager.get_room_hand(room_id)
	if cards.is_empty():
		_views.append(_make_empty_placeholder())
	else:
		for card in cards:
			var view := CardView.new()
			view.setup(card)
			_views.append(view)

	var targets: Array[Vector2] = []
	var count := _views.size()
	for i in count:
		var view := _views[i]
		add_child(view)
		var view_size: Vector2 = view.get_meta("fan_size", CARD_SIZE)
		view.size = view_size
		view.pivot_offset = view_size * 0.5
		var offset_from_center := float(i) - float(count - 1) * 0.5
		var spacing := 62.0
		if count > 1:
			spacing = minf(spacing, (FAN_WIDTH - CARD_SIZE.x) / float(count - 1))
		var target := Vector2(
			(size.x - view_size.x) * 0.5 + offset_from_center * spacing,
			SETTLED_Y + absf(offset_from_center) * 7.0
		)
		targets.append(target)
		view.position = target + Vector2(0, HIDDEN_OFFSET_Y)
		view.rotation_degrees = offset_from_center * 5.0
		view.modulate.a = 0.0
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_animating = true
	var tween := create_tween().set_parallel(true)
	for i in _views.size():
		var view := _views[i]
		tween.tween_property(view, "position", targets[i], 0.32) \
			.set_delay(float(i) * 0.03) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "modulate:a", 1.0, 0.22) \
			.set_delay(float(i) * 0.03)
	await tween.finished

	for view in _views:
		view.mouse_filter = Control.MOUSE_FILTER_STOP
	_animating = false


## Убрать веер вниз за экран (перед сменой комнаты).
func animate_hide() -> void:
	if _views.is_empty():
		return
	_animating = true
	for view in _views:
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween := create_tween().set_parallel(true)
	for i in _views.size():
		var view := _views[i]
		var delay := float(_views.size() - 1 - i) * 0.02
		tween.tween_property(view, "position", view.position + Vector2(0, HIDDEN_OFFSET_Y), 0.24) \
			.set_delay(delay) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(view, "modulate:a", 0.0, 0.18).set_delay(delay)
	await tween.finished

	_clear_views()
	_animating = false


func _clear_views() -> void:
	for view in _views:
		if is_instance_valid(view):
			remove_child(view)
			view.queue_free()
	_views.clear()


func _make_empty_placeholder() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 90)
	panel.size = panel.custom_minimum_size
	panel.set_meta("fan_size", panel.custom_minimum_size)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.18, 0.9)
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.72, 0.45, 0.5)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "В этой комнате рука пуста.\nОткройте Архив кнопкой «Колода»."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88))
	panel.add_child(label)
	return panel
