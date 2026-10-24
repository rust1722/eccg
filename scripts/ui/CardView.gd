class_name CardView
extends PanelContainer
## Одна видимая карта: в веере руки и в панели Архива размер одинаковый.
## Только показывает данные CardData: название, тип и цены.
## Клик по карте сообщает сигналом card_clicked — что делать с картой,
## решает владелец (веер или Архив).

signal card_clicked(card_data: CardData)

const TYPE_COLORS: Dictionary = {
	0: Color(0.45, 0.52, 0.38), # CREATURE
	1: Color(0.45, 0.35, 0.62), # SPELL
	2: Color(0.52, 0.45, 0.33), # ITEM
	3: Color(0.33, 0.50, 0.42), # INGREDIENT
	4: Color(0.58, 0.40, 0.26), # FOOD
	5: Color(0.62, 0.36, 0.30), # DRINK
	6: Color(0.36, 0.55, 0.30), # SEED
	7: Color(0.60, 0.30, 0.38), # POTION
	8: Color(0.55, 0.47, 0.28), # RECIPE
	9: Color(0.40, 0.44, 0.58), # QUEST
}

var card_data: CardData

var _count_label: Label
var _built: bool = false
var _pending_count: int = -1
var _selected: bool = false


func setup(card: CardData) -> void:
	card_data = card
	if is_node_ready():
		_build()


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_build()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_clicked.emit(card_data)
			accept_event()


## Количество "×N" в ПРАВОМ ВЕРХНЕМ УГЛУ карты (для панели Архива).
## Метка живёт в верхней строке карты рядом с типом, поэтому угол
## гарантирован раскладкой, а не наложением поверх PanelContainer.
func set_count_badge(count: int) -> void:
	_pending_count = count
	_apply_count_badge()


func _apply_count_badge() -> void:
	if _count_label == null:
		return
	if _pending_count < 0:
		_count_label.visible = false
		return
	_count_label.visible = true
	_count_label.text = "×%d" % _pending_count


## Подсветка выбранной карты (клик в веере вне Архива, этап Сада):
## золотая толстая рамка вместо обычной.
func set_selected(value: bool) -> void:
	_selected = value
	if not _built:
		return
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	if _selected:
		style.set_border_width_all(4)
		style.border_color = Color(1.0, 0.85, 0.35)
	else:
		style.set_border_width_all(2)
		style.border_color = Color(0.85, 0.72, 0.45)


func _build() -> void:
	# НЕ проверяем get_child_count(): бейдж ×N добавляется до сборки
	# и не должен отменять постройку самой карты (баг пустого Архива).
	if card_data == null or _built:
		return
	_built = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	custom_minimum_size = Vector2(104, 136)
	size = custom_minimum_size
	tooltip_text = card_data.description

	var style := StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(card_data.card_type, Color(0.35, 0.35, 0.4))
	style.set_border_width_all(2)
	style.border_color = Color(0.85, 0.72, 0.45)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Верхняя строка: тип слева, количество ×N — в правом углу.
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 4)
	vbox.add_child(top_row)

	var type_label := Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.text = CardData.CardType.keys()[card_data.card_type]
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_label.add_theme_font_size_override("font_size", 9)
	type_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	top_row.add_child(type_label)

	_count_label = Label.new()
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.add_theme_font_size_override("font_size", 15)
	_count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0, 0, 0, 0.45)
	badge_style.set_corner_radius_all(6)
	badge_style.content_margin_left = 5
	badge_style.content_margin_right = 5
	_count_label.add_theme_stylebox_override("normal", badge_style)
	top_row.add_child(_count_label)
	_apply_count_badge()

	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = card_data.title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	vbox.add_child(title_label)

	var spacer := Control.new()
	# Разделитель НЕ должен перехватывать клики: иначе нижняя
	# половина карты мертва для мыши (баг, найденный автором).
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var price_label := Label.new()
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_label.text = "Куп. %d · Прод. %d" % [card_data.buy_price, card_data.sell_price]
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 9)
	price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	vbox.add_child(price_label)
