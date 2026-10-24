class_name HandUI
extends Control
## Веер карт игрока в нижней полосе. ОДИН на всю таверну
## (решение 2026-10-25, DESIGN.md §6.5): при смене комнаты веер
## не меняется и никуда не уезжает — меняется только сцена комнаты,
## а вся нижняя панель всегда одна и та же.
##
## Анимации остались только там, где состав веера реально меняется:
##   - первый показ при старте игры: веер вылезает снизу;
##   - Архив открыт: клик по карте веера — она улетает в Архив,
##     клик по карте в Архиве — карта прилетает в веер.
## Какие карты показать, HandUI не придумывает сам: это общий веер
## из InventoryManager.current_hand.
##
## В обычном режиме (Архив закрыт) карты из веера ТАСКАЮТ мышью
## на объекты комнат (горшок, стол крафта, гость): это даёт тактильное
## "положил рукой". Клики остаются только при открытом Архиве —
## там перекидать карты кликами быстрее, чем таскать.

const CARD_SIZE := Vector2(104, 136)
const FAN_WIDTH: float = 548.0
const SETTLED_Y: float = 84.0
const HIDDEN_OFFSET_Y: float = 210.0

## Включён, пока открыта панель Архива: клик по карте веера
## отправляет её в Архив с анимацией полёта вверх.
var archive_mode: bool = false
## Куда лететь карте в Архив (глобальные координаты): ставит Main
## при открытии панели, по умолчанию — просто вверх за край веера.
var archive_target_global_position: Vector2 = Vector2.ZERO

var _views: Array[Control] = []
var _animating: bool = false
var _refresh_queued: bool = false


func _ready() -> void:
	add_to_group("hand_ui")
	InventoryManager.hand_changed.connect(_on_hand_changed)
	RoomManager.room_changed.connect(_on_room_changed)


func is_animating() -> bool:
	return _animating


func set_archive_mode(enabled: bool) -> void:
	archive_mode = enabled
	# Архив открыт — таскать нельзя (там клики), закрыт — можно.
	for view in _views:
		if view is CardView:
			(view as CardView).drag_enabled = not enabled


func _on_room_changed(_from_room_id: String, _to_room_id: String) -> void:
	# Веер и панель при смене комнат не меняются, но ценники продажи
	# в углу карт должны появляться в Лавке и исчезать вне её.
	_update_fan_price_display()


## Веер поменялся снаружи (Сад забрал семя при сбросе карты, урожай
## упал в веер и т.д.). Обновляемся С ОТСРОЧКОЙ на кадр: прямо сейчас
## может ещё идти drag-and-drop, и освобождать перетаскиваемую карту
## в середине сброса нельзя.
## Во время собственных анимаций Архива не мешаем: там виды уже верные.
func _on_hand_changed() -> void:
	if _animating or _refresh_queued:
		return
	_refresh_queued = true
	_refresh_instant.call_deferred()


## Пересобрать веер на месте, без выезда снизу (для внешних изменений).
func _refresh_instant() -> void:
	_refresh_queued = false
	_clear_views()

	var cards := InventoryManager.get_hand()
	if cards.is_empty():
		_views.append(_make_empty_placeholder())
	else:
		for card in cards:
			_views.append(_make_card_view(card))

	var count := _views.size()
	for i in count:
		var view := _views[i]
		add_child(view)
		var view_size: Vector2 = view.get_meta("fan_size", CARD_SIZE)
		view.size = view_size
		view.pivot_offset = view_size * 0.5
		view.position = _layout_target(i, count, view_size)
		view.rotation_degrees = _layout_rotation(i, count)
		view.modulate.a = 1.0
		view.mouse_filter = Control.MOUSE_FILTER_STOP


func _make_card_view(card: CardData) -> CardView:
	var view := CardView.new()
	view.setup(card)
	view.drag_enabled = not archive_mode
	view.set_price_display(_fan_price_display())
	view.card_clicked.connect(_on_card_view_clicked.bind(view))
	return view


## Ценник «Прод. N» в углу карт веера виден только в Лавке:
## там игрок продаёт карты из веера торговцу (DESIGN.md §4.4).
func _fan_price_display() -> CardView.PriceDisplay:
	if RoomManager.current_room_id == "shop":
		return CardView.PriceDisplay.SELL
	return CardView.PriceDisplay.NONE


func _update_fan_price_display() -> void:
	var mode := _fan_price_display()
	for view in _views:
		if view is CardView:
			(view as CardView).set_price_display(mode)


func _on_card_view_clicked(_card: CardData, view: CardView) -> void:
	# Клики по вееру работают только при открытом Архиве (улететь в Архив).
	# В комнатах карты не кликают, а таскают на объекты.
	if not archive_mode or _animating:
		return
	animate_card_to_archive(view)


## Раскладка веера: чем больше карт, тем сильнее они сжимаются
## друг на друга, и веер целиком всегда помещается между профилем
## слева и колодой/указателем справа.
func _layout_target(index: int, total: int, view_size: Vector2) -> Vector2:
	var offset_from_center := float(index) - float(total - 1) * 0.5
	var spacing := 92.0
	if total > 1:
		var usable_width := minf(FAN_WIDTH, size.x - 16.0)
		spacing = minf(spacing, (usable_width - CARD_SIZE.x) / float(total - 1))
	return Vector2(
		(size.x - view_size.x) * 0.5 + offset_from_center * spacing,
		SETTLED_Y + absf(offset_from_center) * 7.0
	)


func _layout_rotation(index: int, total: int) -> float:
	var offset_from_center := float(index) - float(total - 1) * 0.5
	return offset_from_center * 5.0


func _global_to_local(global_point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * global_point


## Показать общий веер с анимацией выхода снизу.
## Вызывается один раз при старте таверны и когда веер опустел
## (показать плашку пустого веера тем же движением).
func show_hand() -> void:
	_clear_views()

	var cards := InventoryManager.get_hand()
	if cards.is_empty():
		_views.append(_make_empty_placeholder())
	else:
		for card in cards:
			_views.append(_make_card_view(card))

	var count := _views.size()
	for i in count:
		var view := _views[i]
		add_child(view)
		var view_size: Vector2 = view.get_meta("fan_size", CARD_SIZE)
		view.size = view_size
		view.pivot_offset = view_size * 0.5
		view.position = _layout_target(i, count, view_size) + Vector2(0, HIDDEN_OFFSET_Y)
		view.rotation_degrees = _layout_rotation(i, count)
		view.modulate.a = 0.0
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_animating = true
	var tween := create_tween().set_parallel(true)
	for i in count:
		var view := _views[i]
		var view_size: Vector2 = view.get_meta("fan_size", CARD_SIZE)
		tween.tween_property(view, "position", _layout_target(i, count, view_size), 0.32) \
			.set_delay(float(i) * 0.03) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "modulate:a", 1.0, 0.22) \
			.set_delay(float(i) * 0.03)
	await tween.finished

	for view in _views:
		view.mouse_filter = Control.MOUSE_FILTER_STOP
	_animating = false


## Карта из Архива "прилетает" в веер: появляется в точке панели
## Архива и летит на своё место в веере, остальные карты при этом
## плавно сдвигаются и сжимаются под новый размер веера.
## Данные в InventoryManager меняются в момент приземления.
func animate_add_card_from(card: CardData, source_global_position: Vector2) -> void:
	if _animating or card == null:
		return
	if InventoryManager.get_hand().size() >= InventoryManager.HAND_LIMIT:
		return

	# В пустом веере вместо плашки-подсказки теперь будет карта.
	if InventoryManager.get_hand().is_empty():
		_clear_views()

	_animating = true
	var new_view := _make_card_view(card)
	add_child(new_view)
	_views.append(new_view)
	new_view.size = CARD_SIZE
	new_view.pivot_offset = CARD_SIZE * 0.5
	new_view.position = _global_to_local(source_global_position)
	new_view.rotation_degrees = -6.0
	new_view.z_index = 20

	var total := _views.size()
	var tween := create_tween().set_parallel(true)
	for i in total:
		var view := _views[i]
		var view_size: Vector2 = view.get_meta("fan_size", CARD_SIZE)
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tween.tween_property(view, "position", _layout_target(i, total, view_size), 0.32) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "rotation_degrees", _layout_rotation(i, total), 0.32) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

	if InventoryManager.add_card_to_hand(card):
		for view in _views:
			view.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		# Не легла (например, веер успели заполнить): убираем картинку.
		_views.erase(new_view)
		remove_child(new_view)
		new_view.queue_free()
	new_view.z_index = 0
	_animating = false


## Кликнутая карта веера "улетает" в Архив (вверх, к панели),
## остальные карты плавно занимают освободившееся место.
## Данные в InventoryManager меняются после полёта.
func animate_card_to_archive(view: CardView) -> void:
	if _animating or view == null or not _views.has(view):
		return
	var card := view.card_data
	_animating = true
	view.z_index = 20

	var remaining: Array[Control] = []
	for other in _views:
		if other != view:
			remaining.append(other)

	var destination: Vector2
	if archive_target_global_position != Vector2.ZERO:
		destination = _global_to_local(archive_target_global_position)
	else:
		destination = Vector2((size.x - CARD_SIZE.x) * 0.5, -190.0)

	var tween := create_tween().set_parallel(true)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tween.tween_property(view, "position", destination, 0.32) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(view, "scale", Vector2(0.55, 0.55), 0.32)
	tween.tween_property(view, "modulate:a", 0.0, 0.3)
	for i in remaining.size():
		var other := remaining[i]
		var other_size: Vector2 = other.get_meta("fan_size", CARD_SIZE)
		other.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tween.tween_property(other, "position", _layout_target(i, remaining.size(), other_size), 0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(other, "rotation_degrees", _layout_rotation(i, remaining.size()), 0.3)
	await tween.finished

	InventoryManager.move_hand_card_to_archive(card)
	_views.erase(view)
	remove_child(view)
	view.queue_free()
	for other in remaining:
		other.mouse_filter = Control.MOUSE_FILTER_STOP
	_animating = false

	# Веер опустел: покажем плашку пустого веера как обычно.
	if remaining.is_empty():
		await show_hand()


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
	label.text = "Веер пуст.\nОткройте Архив кнопкой «Колода»."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88))
	panel.add_child(label)
	return panel
