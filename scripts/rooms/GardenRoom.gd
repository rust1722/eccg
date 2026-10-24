extends Control
## Комната «Сад» — первая настоящая механика игры (этап 4).
##
## Как играть (карты ТАСКАЮТ мышью — тактильно, рукой на объект):
##   1) перетащить карту СЕМЕНИ из веера на пустой горшок — посажено;
##   2) перетащить карту ВОДЫ на росток — пошёл таймер;
##   3) когда горшок золотой («Созрело») — обычный клик по нему
##      собирает урожай в веер, а при полном веере — в Архив.
## Горшок сам подсвечивается, когда над ним держат подходящую карту.
## Состояние горшков и таймеры живут в GardenManager, поэтому
## растения растут, пока игрок ходит по другим комнатам.

var _status_label: Label
var _info_label: Label
var _pots: Array[PotView] = []
var _refresh_accumulator: float = 0.0


func _ready() -> void:
	_build_ui()

	GardenManager.garden_changed.connect(_on_garden_changed)
	_refresh_all()
	print("[Garden] room opened")


func _process(delta: float) -> void:
	# Раз в четверть секунды обновляем обратный отсчёт на горшках.
	_refresh_accumulator += delta
	if _refresh_accumulator >= 0.25:
		_refresh_accumulator = 0.0
		for pot in _pots:
			pot.refresh_display()
		_update_info()


func _on_garden_changed() -> void:
	_refresh_all()


func _refresh_all() -> void:
	for pot in _pots:
		pot.refresh_display()
	_update_info()


func _update_info() -> void:
	var ready_count := GardenManager.get_ready_count()
	_info_label.text = "Горшков: %d\nСозрело: %d\n\n" % [GardenManager.POT_COUNT, ready_count] \
		+ "Семя — тащить на горшок\nВода — тащить на росток\nКлик по зрелому -> урожай"


func _on_pot_clicked(pot_index: int) -> void:
	var state := GardenManager.get_pot_state(pot_index)

	if state == GardenManager.PotState.READY:
		var result := GardenManager.harvest(pot_index)
		if not result.is_empty():
			var card := result["card"] as CardData
			if String(result["destination"]) == "hand":
				_status_label.text = "Собрано: %s — карта упала в веер." % card.title
			else:
				_status_label.text = "Собрано: %s — веер полон, карта ушла в Архив." % card.title
		_refresh_all()
		return

	# Клик по незрелому горшку теперь только подсказка: карты сюда таскают.
	match state:
		GardenManager.PotState.EMPTY:
			_status_label.text = "Перетащите сюда семя из веера внизу."
		GardenManager.PotState.NEEDS_WATER:
			_status_label.text = "Перетащите сюда воду из веера внизу."
		GardenManager.PotState.GROWING:
			_status_label.text = "Ещё растёт: осталось %d сек." % GardenManager.get_time_left(pot_index)


func _on_pot_card_dropped(pot_index: int, card: CardData) -> void:
	var state := GardenManager.get_pot_state(pot_index)
	if state == GardenManager.PotState.EMPTY and GardenManager.plant_seed(pot_index, card):
		_status_label.text = "Посажено: %s. Теперь перетащите сюда воду." % card.title
	elif state == GardenManager.PotState.NEEDS_WATER and GardenManager.water_pot(pot_index, card):
		_status_label.text = "Полито! Таймер пошёл — можно заниматься другими комнатами."
	_refresh_all()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.04, 0.09, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	for candle_position in [Vector2(60, 120), Vector2(1064, 92)]:
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
	title_label.text = "Сад"
	title_label.position = Vector2(36, 26)
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "Перетащите семя или воду из веера на горшок. " \
		+ "Растения растут сами, пока вы в других комнатах."
	subtitle_label.position = Vector2(38, 80)
	subtitle_label.custom_minimum_size = Vector2(760, 40)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	add_child(subtitle_label)

	_status_label = Label.new()
	_status_label.text = "Перетащите семя из веера на пустой горшок."
	_status_label.position = Vector2(38, 124)
	_status_label.custom_minimum_size = Vector2(760, 30)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	add_child(_status_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(46, 168)
	grid.custom_minimum_size = Vector2(748, 292)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)

	for i in GardenManager.POT_COUNT:
		var pot := PotView.new()
		pot.setup(i)
		pot.pot_clicked.connect(_on_pot_clicked)
		pot.pot_card_dropped.connect(_on_pot_card_dropped)
		grid.add_child(pot)
		_pots.append(pot)

	var info_panel := PanelContainer.new()
	info_panel.position = Vector2(824, 168)
	info_panel.size = Vector2(232, 190)
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.10, 0.13, 0.10, 0.92)
	info_style.set_border_width_all(1)
	info_style.border_color = Color(0.6, 0.7, 0.45, 0.6)
	info_style.set_corner_radius_all(8)
	info_style.content_margin_left = 12
	info_style.content_margin_right = 12
	info_style.content_margin_top = 10
	info_panel.add_theme_stylebox_override("panel", info_style)
	add_child(info_panel)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.75))
	info_panel.add_child(_info_label)
