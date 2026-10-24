extends PanelContainer
## Профиль игрока в левом нижнем углу нижней полосы (DESIGN.md §4.0):
## аватар, здоровье, уровень и золото рядом с аватаром.
## Цифры не выдумывает сам — берёт из PlayerManager и обновляется
## по его сигналу stats_changed.

var _gold_label: Label
var _hp_label: Label
var _level_label: Label


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.15, 0.92)
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.72, 0.45, 0.45)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(58, 72)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.32, 0.26, 0.45)
	avatar_style.set_border_width_all(2)
	avatar_style.border_color = Color(0.85, 0.72, 0.45)
	avatar_style.set_corner_radius_all(8)
	avatar.add_theme_stylebox_override("panel", avatar_style)
	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	avatar.add_child(_level_label)
	hbox.add_child(avatar)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "Ведьмочка"
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	vbox.add_child(name_label)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 13)
	_hp_label.add_theme_color_override("font_color", Color(1, 0.55, 0.5))
	vbox.add_child(_hp_label)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	vbox.add_child(_gold_label)

	PlayerManager.stats_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_level_label.text = "LV\n%d" % PlayerManager.level
	_hp_label.text = "HP %d / %d" % [PlayerManager.health, PlayerManager.max_health]
	_gold_label.text = "Золото: %d" % PlayerManager.gold
