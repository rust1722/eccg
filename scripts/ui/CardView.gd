class_name CardView
extends PanelContainer
## Одна видимая карта: в веере руки и в панели Архива размер одинаковый.
## Только показывает данные CardData: название, тип и цены.
## Клик по карте сообщает сигналом card_clicked — что делать с картой,
## решает владелец (веер или Архив).

signal card_clicked(card_data: CardData)

## Где этой карте можно показывать цену. Цены — информация Лавки,
## а не карты вообще (правка автора): в Архиве цен нет никогда,
## в веере ценник продажи появляется только в комнате Лавки,
## на полках Лавки позже будет ценник покупки.
enum PriceDisplay {
	NONE, ## Цены не показывать (обычный вид карты)
	BUY, ## «Куп. N» — полка Лавки
	SELL, ## «Прод. N» — веер игрока, пока он в Лавке
}

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
## Можно ли таскать эту карту мышью (drag-and-drop в комнатах).
## Ставит владелец: веер включает таскание, когда Архив закрыт;
## в панели Архива и в самом веере при открытом Архиве — клики.
var drag_enabled: bool = false

var _count_label: Label
var _price_label: Label
var _price_display: PriceDisplay = PriceDisplay.NONE
var _built: bool = false
var _pending_count: int = -1


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
			# Когда карту можно таскать, событие не глушим:
			# иначе Godot не начнёт перетаскивание.
			if not drag_enabled:
				accept_event()


## Начало перетаскивания (Godot вызывает сам, когда карту потянули).
## Возвращаем словарь с картой: его получат _can_drop_data/_drop_data
## у объекта-цели (горшок, стол крафта, гость...).
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not drag_enabled or card_data == null:
		return null
	var preview := CardView.new()
	preview.setup(card_data)
	preview.custom_minimum_size = Vector2(104, 136)
	preview.size = Vector2(104, 136)
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	modulate.a = 0.45
	return {"kind": "hand_card", "card": card_data}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Перетаскивание кончилось (сбросили или отменили) —
		# карта в веере снова непрозрачная.
		modulate.a = 1.0


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


## Владелец карты решает, показывать ли ей цену (см. PriceDisplay).
func set_price_display(mode: PriceDisplay) -> void:
	_price_display = mode
	_apply_price_display()


func _apply_price_display() -> void:
	if _price_label == null or card_data == null:
		return
	match _price_display:
		PriceDisplay.BUY:
			_price_label.text = "Куп. %d" % card_data.buy_price
			_price_label.visible = true
		PriceDisplay.SELL:
			_price_label.text = "Прод. %d" % card_data.sell_price
			_price_label.visible = true
		_:
			_price_label.visible = false


## Подсветка рамки (для наведения перетаскиваемой карты и т.п.).
func set_selected(value: bool) -> void:
	if not _built:
		return
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	if value:
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

	# Нижняя строка: ценник в правом нижнем углу (если владелец разрешил).
	var bottom_row := HBoxContainer.new()
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_row)

	var bottom_spacer := Control.new()
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(bottom_spacer)

	_price_label = Label.new()
	_price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_price_label.add_theme_font_size_override("font_size", 11)
	_price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	var price_style := StyleBoxFlat.new()
	price_style.bg_color = Color(0, 0, 0, 0.45)
	price_style.set_corner_radius_all(6)
	price_style.content_margin_left = 5
	price_style.content_margin_right = 5
	_price_label.add_theme_stylebox_override("normal", price_style)
	bottom_row.add_child(_price_label)
	_apply_price_display()
