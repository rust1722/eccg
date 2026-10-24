class_name ArchiveOverlay
extends Control
## Панель Архива на фоне комнаты, НАД веером карт (не на весь экран).
##
## Веер у игрока один на все комнаты, поэтому панель одинаковая везде.
##   - Клик по карте в Архиве -> карта "улетает" вниз, в общий веер
##     (анимацию делает HandUI, панель только сообщает о клике
##     сигналом archive_card_chosen и показывает, откуда лететь).
##   - Клик по карте в веере -> карта улетает сюда, в Архив
##     (это делает сам веер, когда включён его archive_mode).
## Панель не двигает данные сама, кроме подписей и счётчиков:
## количества берёт из InventoryManager и перестраивается по сигналам.

signal closed
signal archive_card_chosen(card: CardData, source_global_position: Vector2)

var _panel: PanelContainer
var _title_label: Label
var _counts_label: Label
var _status_label: Label
var _archive_grid: GridContainer


func _ready() -> void:
	# Корень прозрачен для кликов: ловит их только сама панель,
	# комната, веер и указатель вокруг продолжают жить.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	InventoryManager.archive_changed.connect(_on_inventory_changed)
	InventoryManager.hand_changed.connect(_on_hand_changed)


func open_archive() -> void:
	visible = true
	_status_label.text = "Клик по карте здесь — она улетит в веер. " \
		+ "Клик по карте в веере — улетит сюда."
	_refresh()
	print("[Archive] opened")


func close_overlay() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
	print("[Archive] closed")


## Куда вееру отправлять карту, чтобы она "прилетела в Архив":
## верхняя середина панели (глобальные координаты экрана).
func get_fly_destination_global_position() -> Vector2:
	return _panel.global_position + Vector2((_panel.size.x - 104.0) * 0.5, 16.0)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_overlay()
		get_viewport().set_input_as_handled()


func _on_inventory_changed() -> void:
	if visible:
		_refresh.call_deferred()


func _on_hand_changed() -> void:
	if visible:
		_refresh.call_deferred()


func _on_archive_card_clicked(card: CardData, view: CardView) -> void:
	var hand := InventoryManager.get_hand()
	if hand.size() >= InventoryManager.HAND_LIMIT:
		_status_label.text = (
			"Веер полон (%d/%d). Кликните лишнюю карту в веере — она улетит в Архив."
			% [hand.size(), InventoryManager.HAND_LIMIT]
		)
		return
	_status_label.text = "В веер: %s" % card.title
	archive_card_chosen.emit(card, view.global_position)


func _refresh() -> void:
	if not visible:
		return

	_title_label.text = "Архив"
	var hand := InventoryManager.get_hand()
	var kinds_in_archive := 0
	var total_in_archive := 0
	for card in InventoryManager.get_known_cards():
		var count := InventoryManager.get_archive_count(card.id)
		if count > 0:
			kinds_in_archive += 1
			total_in_archive += count
	_counts_label.text = "Веер: %d/%d · В Архиве: %d карт (%d видов)" % [
		hand.size(), InventoryManager.HAND_LIMIT, total_in_archive, kinds_in_archive
	]

	_clear_children(_archive_grid)
	var known_cards := InventoryManager.get_known_cards()
	if known_cards.is_empty():
		var empty := Label.new()
		empty.text = "В Архиве пока пусто."
		_archive_grid.add_child(empty)
		return
	for card in known_cards:
		_archive_grid.add_child(_make_archive_card(card))


func _make_archive_card(card: CardData) -> CardView:
	var count := InventoryManager.get_archive_count(card.id)
	var view := CardView.new()
	view.setup(card)
	# В Архиве цен у карт нет и быть не должно: цены — только Лавка.
	view.set_price_display(CardView.PriceDisplay.NONE)
	view.set_count_badge(count)
	if count <= 0:
		view.modulate = Color(1, 1, 1, 0.4)
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.tooltip_text = card.title + " — в Архиве не осталось"
	else:
		view.card_clicked.connect(_on_archive_card_clicked.bind(view))
	return view


func _clear_children(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 12
	_panel.offset_top = 108
	_panel.offset_right = -266
	_panel.offset_bottom = 492
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.10, 0.15, 0.97)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.85, 0.72, 0.45)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	header.add_child(_title_label)

	_counts_label = Label.new()
	_counts_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_counts_label.add_theme_font_size_override("font_size", 13)
	_counts_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	header.add_child(_counts_label)

	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(104, 36)
	close_button.pressed.connect(close_overlay)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_archive_grid = GridContainer.new()
	_archive_grid.columns = 6
	_archive_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_archive_grid.add_theme_constant_override("h_separation", 8)
	_archive_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_archive_grid)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1))
	root_vbox.add_child(_status_label)
