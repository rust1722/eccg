class_name ArchiveOverlay
extends Control
## Окно Архива поверх текущей комнаты (DESIGN.md §6.5, система A+).
##
## Слева сетка всех карт Архива с количествами, справа — рука текущей
## комнаты. Клик по карте слева кладёт её в руку комнаты, клик по
## карте справа возвращает её в Архив. Перетаскивание будет позже,
## сначала надёжные клики.
##
## Окно не меняет данные само: всё делает InventoryManager, а окно
## только показывает результат и перестраивается по его сигналам.

signal closed

const ARCHIVE_CARD_SIZE := Vector2(146, 98)
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

var current_room_id: String = ""

var _room_label: Label
var _counts_label: Label
var _status_label: Label
var _archive_grid: GridContainer
var _hand_list: VBoxContainer
var _hand_title_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	InventoryManager.archive_changed.connect(_on_inventory_changed)
	InventoryManager.room_hand_changed.connect(_on_room_hand_changed)


func open_for_room(room_id: String) -> void:
	current_room_id = room_id
	visible = true
	_status_label.text = "Клик слева — взять в руку. Клик справа — вернуть в Архив."
	_refresh()
	print("[Archive] opened over room: %s" % RoomManager.get_room_title(room_id))


func close_overlay() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
	print("[Archive] closed")


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_overlay()
		get_viewport().set_input_as_handled()


func _on_inventory_changed() -> void:
	if visible:
		_refresh.call_deferred()


func _on_room_hand_changed(_room_id: String) -> void:
	if visible:
		_refresh.call_deferred()


func _on_archive_card_pressed(card: CardData) -> void:
	var hand := InventoryManager.get_room_hand(current_room_id)
	if hand.size() >= InventoryManager.HAND_LIMIT:
		_status_label.text = "Рука комнаты полна (%d/%d). Сначала верните что-нибудь в Архив." % [
			hand.size(), InventoryManager.HAND_LIMIT
		]
		return
	if InventoryManager.add_card_to_room_hand(current_room_id, card):
		_status_label.text = "В руку (%s): %s" % [RoomManager.get_room_title(current_room_id), card.title]
	else:
		_status_label.text = "Не получилось взять: %s" % card.title


func _on_hand_card_pressed(card: CardData) -> void:
	if InventoryManager.move_hand_card_to_archive(current_room_id, card):
		_status_label.text = "В Архив: %s" % card.title


func _on_collect_all_pressed() -> void:
	InventoryManager.clear_room_hand_to_archive(current_room_id)
	_status_label.text = "Вся рука комнаты возвращена в Архив."


func _refresh() -> void:
	if not visible:
		return

	_room_label.text = "Архив"
	var hand := InventoryManager.get_room_hand(current_room_id)
	_hand_title_label.text = "Рука: %s (%d/%d)" % [
		RoomManager.get_room_title(current_room_id), hand.size(), InventoryManager.HAND_LIMIT
	]

	_clear_children(_archive_grid)
	var shown := 0
	for card in InventoryManager.get_known_cards():
		_archive_grid.add_child(_make_archive_button(card))
		shown += 1
	if shown == 0:
		var empty := Label.new()
		empty.text = "В Архиве пока пусто."
		_archive_grid.add_child(empty)

	_clear_children(_hand_list)
	if hand.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Рука этой комнаты пуста."
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.73, 0.85))
		_hand_list.add_child(empty_label)
	else:
		for card in hand:
			_hand_list.add_child(_make_hand_button(card))

	var kinds_in_archive := 0
	for card in InventoryManager.get_known_cards():
		if InventoryManager.get_archive_count(card.id) > 0:
			kinds_in_archive += 1
	_counts_label.text = "Видов в Архиве: %d · Рука %s: %d/%d" % [
		kinds_in_archive, RoomManager.get_room_title(current_room_id),
		hand.size(), InventoryManager.HAND_LIMIT
	]


func _make_archive_button(card: CardData) -> Button:
	var count := InventoryManager.get_archive_count(card.id)
	var button := Button.new()
	button.custom_minimum_size = ARCHIVE_CARD_SIZE
	button.text = "%s\n%s\n× %d" % [
		card.title, CardData.CardType.keys()[card.card_type], count
	]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 12)
	var base_color: Color = TYPE_COLORS.get(card.card_type, Color(0.35, 0.35, 0.4))
	button.add_theme_stylebox_override("normal", _card_style(base_color))
	button.add_theme_stylebox_override("hover", _card_style(base_color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _card_style(base_color.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", _card_style(Color(0.16, 0.16, 0.2)))
	button.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.57, 0.65))
	button.disabled = count <= 0
	button.tooltip_text = card.description
	button.pressed.connect(_on_archive_card_pressed.bind(card))
	return button


func _make_hand_button(card: CardData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(286, 42)
	button.text = "%s · %s" % [card.title, CardData.CardType.keys()[card.card_type]]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 13)
	var base_color: Color = TYPE_COLORS.get(card.card_type, Color(0.35, 0.35, 0.4))
	button.add_theme_stylebox_override("normal", _card_style(base_color.darkened(0.25)))
	button.add_theme_stylebox_override("hover", _card_style(base_color.darkened(0.1)))
	button.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	button.tooltip_text = "Вернуть в Архив: " + card.title
	button.pressed.connect(_on_hand_card_pressed.bind(card))
	return button


func _card_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(1)
	style.border_color = Color(0.85, 0.72, 0.45, 0.6)
	style.set_corner_radius_all(7)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _clear_children(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 56
	panel.offset_top = 34
	panel.offset_right = -56
	panel.offset_bottom = -34
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.10, 0.15, 0.98)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.85, 0.72, 0.45)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	_room_label = Label.new()
	_room_label.add_theme_font_size_override("font_size", 26)
	_room_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	header.add_child(_room_label)

	_counts_label = Label.new()
	_counts_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_counts_label.add_theme_font_size_override("font_size", 13)
	_counts_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	header.add_child(_counts_label)

	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(110, 38)
	close_button.pressed.connect(close_overlay)
	header.add_child(close_button)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	root_vbox.add_child(content)

	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(left_vbox)

	var archive_title := Label.new()
	archive_title.text = "Архив (клик — взять в руку комнаты)"
	archive_title.add_theme_font_size_override("font_size", 15)
	archive_title.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	left_vbox.add_child(archive_title)

	var archive_scroll := ScrollContainer.new()
	archive_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(archive_scroll)

	_archive_grid = GridContainer.new()
	_archive_grid.columns = 4
	_archive_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_archive_grid.add_theme_constant_override("h_separation", 8)
	_archive_grid.add_theme_constant_override("v_separation", 8)
	archive_scroll.add_child(_archive_grid)

	var right_vbox := VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(302, 0)
	content.add_child(right_vbox)

	_hand_title_label = Label.new()
	_hand_title_label.add_theme_font_size_override("font_size", 15)
	_hand_title_label.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	right_vbox.add_child(_hand_title_label)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(hand_scroll)

	_hand_list = VBoxContainer.new()
	_hand_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hand_list.add_theme_constant_override("separation", 6)
	hand_scroll.add_child(_hand_list)

	var collect_button := Button.new()
	collect_button.text = "Собрать всё в Архив"
	collect_button.custom_minimum_size = Vector2(286, 40)
	collect_button.pressed.connect(_on_collect_all_pressed)
	right_vbox.add_child(collect_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1))
	root_vbox.add_child(_status_label)
