class_name CardView
extends PanelContainer
## Одна видимая карта в веере. Только показывает данные CardData:
## название, тип и цены. Перетаскивание добавим на следующих этапах.

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


func setup(card: CardData) -> void:
	card_data = card
	if is_node_ready():
		_build()


func _ready() -> void:
	_build()


func _build() -> void:
	if card_data == null or get_child_count() > 0:
		return

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
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var title_label := Label.new()
	title_label.text = card_data.title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	vbox.add_child(title_label)

	var type_label := Label.new()
	type_label.text = CardData.CardType.keys()[card_data.card_type]
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 9)
	type_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	vbox.add_child(type_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var price_label := Label.new()
	price_label.text = "Куп. %d · Прод. %d" % [card_data.buy_price, card_data.sell_price]
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 9)
	price_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	vbox.add_child(price_label)
