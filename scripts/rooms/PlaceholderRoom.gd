extends Control
## Комната-заглушка: цветной фон, название, описание и центральный
## "главный объект" комнаты. Настоящий арт и механики придут позже,
## а навигация, веер и указатель работают уже на этих заглушках.
##
## Одна и та же сцена-скрипт на все комнаты: отличия задаются
## экспортируемыми полями прямо в .tscn каждой комнаты.

@export var room_id: String = ""
@export var room_title: String = "Комната"
@export_multiline var room_subtitle: String = ""
@export_multiline var center_object_text: String = "Главный объект"
@export var background_color: Color = Color(0.09, 0.10, 0.14)


func _ready() -> void:
	var background := ColorRect.new()
	background.color = background_color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Пара "свечей" для ночной атмосферы: тёплые пятна по углам.
	for candle_position in [Vector2(60, 120), Vector2(1064, 92), Vector2(120, 360)]:
		var candle := ColorRect.new()
		candle.color = Color(1.0, 0.62, 0.22, 0.75)
		candle.position = candle_position
		candle.size = Vector2(10, 18)
		add_child(candle)

	var moon_label := Label.new()
	moon_label.text = "Ночь. Таверна освещена свечами."
	moon_label.position = Vector2(824, 30)
	moon_label.add_theme_font_size_override("font_size", 14)
	moon_label.add_theme_color_override("font_color", Color(0.65, 0.72, 0.95, 0.8))
	add_child(moon_label)

	var title_label := Label.new()
	title_label.text = room_title
	title_label.position = Vector2(36, 26)
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = room_subtitle
	subtitle_label.position = Vector2(38, 82)
	subtitle_label.custom_minimum_size = Vector2(760, 70)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	add_child(subtitle_label)

	var center_panel := PanelContainer.new()
	center_panel.position = Vector2(316, 178)
	center_panel.size = Vector2(520, 210)
	var center_style := StyleBoxFlat.new()
	center_style.bg_color = Color(0.14, 0.12, 0.10, 0.9)
	center_style.set_border_width_all(2)
	center_style.border_color = Color(0.85, 0.72, 0.45, 0.55)
	center_style.set_corner_radius_all(10)
	center_panel.add_theme_stylebox_override("panel", center_style)
	add_child(center_panel)

	var center_label := Label.new()
	center_label.text = center_object_text
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_label.add_theme_font_size_override("font_size", 20)
	center_label.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	center_panel.add_child(center_label)

	var note_label := Label.new()
	note_label.text = "Заглушка комнаты: здесь будут фон, объекты и механики комнаты."
	note_label.position = Vector2(38, 462)
	note_label.add_theme_font_size_override("font_size", 13)
	note_label.add_theme_color_override("font_color", Color(0.6, 0.63, 0.75, 0.8))
	add_child(note_label)

	print("[Room] opened: %s (%s)" % [room_title, room_id])
