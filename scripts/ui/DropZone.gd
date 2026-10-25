class_name DropZone
extends PanelContainer
## Универсальная цель для перетаскивания карт из веера:
## разделочный стол, книга рецептов, позже — торговец и гости.
##
## Сама зона решает только одно: подходит ли ей эта карта
## (через accept_filter, который ставит владелец). Подходящую
## карту подсвечивает золотой рамкой, пока её держат над зоной.
## Что делать со сброшенной картой — дело владельца (сигнал).

signal card_dropped(card: CardData)

## func(card: CardData) -> bool: подходит ли карта этой зоне.
var accept_filter: Callable

var _style: StyleBoxFlat
var _content: VBoxContainer
var _drop_highlight: bool = false
var _base_border_color := Color(0.85, 0.72, 0.45, 0.55)


func setup(title: String, hint: String, bg_color: Color) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_style = StyleBoxFlat.new()
	_style.bg_color = bg_color
	_style.set_border_width_all(2)
	_style.border_color = _base_border_color
	_style.set_corner_radius_all(10)
	_style.content_margin_left = 12
	_style.content_margin_right = 12
	_style.content_margin_top = 10
	_style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", _style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	vbox.add_child(title_label)

	var hint_label := Label.new()
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.text = hint
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	vbox.add_child(hint_label)

	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", 6)
	vbox.add_child(_content)


## Сюда владелец кладёт содержимое зоны (фишки ингредиентов и т.п.).
func get_content() -> VBoxContainer:
	return _content


func _process(_delta: float) -> void:
	if _drop_highlight and get_viewport() != null and not get_viewport().gui_is_dragging():
		_set_highlight(false)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var card := _card_from_drag_data(data)
	var can_drop := false
	if card != null and accept_filter.is_valid():
		can_drop = bool(accept_filter.call(card))
	if can_drop != _drop_highlight:
		_set_highlight(can_drop)
	return can_drop


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	var card := _card_from_drag_data(data)
	if card != null:
		card_dropped.emit(card)


func _set_highlight(active: bool) -> void:
	_drop_highlight = active
	if _style == null:
		return
	if active:
		_style.border_color = Color(1.0, 0.85, 0.35)
		_style.set_border_width_all(4)
	else:
		_style.border_color = _base_border_color
		_style.set_border_width_all(2)


func _card_from_drag_data(data: Variant) -> CardData:
	if data is Dictionary:
		var dict := data as Dictionary
		if String(dict.get("kind", "")) == "hand_card":
			return dict.get("card") as CardData
	return null
