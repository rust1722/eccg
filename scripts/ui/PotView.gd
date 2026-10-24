class_name PotView
extends PanelContainer
## Один горшок в саду. Только показывает состояние горшка из
## GardenManager и сообщает о клике сигналом pot_clicked.
## Логика (посадить/полить/собрать) — в GardenRoom и GardenManager.

signal pot_clicked(pot_index: int)
signal pot_card_dropped(pot_index: int, card: CardData)

var pot_index: int = 0
var _drop_highlight: bool = false

var _style: StyleBoxFlat
var _title_label: Label
var _state_label: Label
var _timer_label: Label
var _built: bool = false


func setup(index: int) -> void:
	pot_index = index
	if is_node_ready():
		refresh_display()


func _ready() -> void:
	_build()
	gui_input.connect(_on_gui_input)
	refresh_display()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			pot_clicked.emit(pot_index)
			accept_event()


func _process(_delta: float) -> void:
	# Перетаскивание закончилось где-то в другом месте: снять подсветку.
	if _drop_highlight and get_viewport() != null and not get_viewport().gui_is_dragging():
		_drop_highlight = false
		refresh_display()


## Сюда ли можно сбросить перетаскиваемую карту прямо сейчас?
## Пустой горшок берёт только семена, росток — только воду.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var card := _card_from_drag_data(data)
	var can_drop := false
	if card != null:
		var state := GardenManager.get_pot_state(pot_index)
		if state == GardenManager.PotState.EMPTY and card is SeedCardData:
			can_drop = true
		elif state == GardenManager.PotState.NEEDS_WATER and card.id == "water":
			can_drop = true
	if can_drop != _drop_highlight:
		_drop_highlight = can_drop
		refresh_display()
	return can_drop


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_drop_highlight = false
	var card := _card_from_drag_data(data)
	if card != null:
		pot_card_dropped.emit(pot_index, card)
	refresh_display()


func _card_from_drag_data(data: Variant) -> CardData:
	if data is Dictionary:
		var dict := data as Dictionary
		if String(dict.get("kind", "")) == "hand_card":
			return dict.get("card") as CardData
	return null


func refresh_display() -> void:
	if not _built:
		return
	var pot := GardenManager.get_pot(pot_index)
	var state := int(pot["state"])
	var seed := pot["seed_card"] as SeedCardData

	custom_minimum_size = Vector2(178, 138)
	if _drop_highlight:
		_style.border_color = Color(1.0, 0.85, 0.35)
		_style.set_border_width_all(4)
	else:
		_style.set_border_width_all(2)
	_title_label.text = "Горшок %d" % (pot_index + 1)

	match state:
		GardenManager.PotState.EMPTY:
			_style.bg_color = Color(0.16, 0.12, 0.09)
			_style.border_color = Color(0.5, 0.38, 0.22, 0.7)
			_state_label.text = "Пустой"
			_timer_label.text = "Перетащите сюда семя"
		GardenManager.PotState.NEEDS_WATER:
			_style.bg_color = Color(0.13, 0.17, 0.10)
			_style.border_color = Color(0.55, 0.62, 0.35, 0.8)
			_state_label.text = "Росток: %s" % (seed.title if seed != null else "?")
			_timer_label.text = "Перетащите сюда воду"
		GardenManager.PotState.GROWING:
			_style.bg_color = Color(0.10, 0.20, 0.12)
			_style.border_color = Color(0.4, 0.7, 0.4, 0.9)
			_state_label.text = "Растёт: %s" % (seed.title if seed != null else "?")
			_timer_label.text = "Осталось: %s" % _format_time(GardenManager.get_time_left(pot_index))
		GardenManager.PotState.READY:
			_style.bg_color = Color(0.20, 0.24, 0.10)
			_style.border_color = Color(1.0, 0.85, 0.35)
			_state_label.text = "Созрело: %s" % (seed.title if seed != null else "?")
			_timer_label.text = "Клик — собрать урожай"


func _format_time(total_seconds: int) -> String:
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]


func _build() -> void:
	if _built:
		return
	_built = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	_style = StyleBoxFlat.new()
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(10)
	_style.content_margin_left = 10
	_style.content_margin_right = 10
	_style.content_margin_top = 10
	_style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", _style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	_title_label = Label.new()
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 15)
	_title_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	vbox.add_child(_title_label)

	_state_label = Label.new()
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_state_label.add_theme_font_size_override("font_size", 14)
	_state_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.75))
	vbox.add_child(_state_label)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_timer_label = Label.new()
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_timer_label.add_theme_font_size_override("font_size", 13)
	_timer_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.95))
	vbox.add_child(_timer_label)
