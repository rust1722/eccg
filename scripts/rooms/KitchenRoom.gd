extends Control
## Комната «Кухня» — крафт еды по рецептам (этап 6).
##
## Как играть (карты ТАСКАЮТ из веера):
##   1) карту «Рецепт: Лесной суп» — на Книгу рецептов справа:
##      рецепт изучен и появился в панели рецептов;
##   2) ингредиенты (Мясо, Вода, Зелень) — на Разделочный стол;
##      лишнее можно вернуть кликом по фишке на столе;
##   3) кнопка «Варить» в панели рецепта — ингредиенты сгорели,
##      готовый суп упал в веер (или в Архив, если веер полон).
## Состояние (изученные рецепты, стол) живёт в CraftManager.

var _status_label: Label
var _table_zone: DropZone
var _book_zone: DropZone
var _recipes_box: VBoxContainer


func _ready() -> void:
	_build_ui()
	CraftManager.craft_changed.connect(_refresh_all)
	_refresh_all()
	print("[Kitchen] room opened")


func _accept_ingredient(card: CardData) -> bool:
	return card != null and card.card_type == CardData.CardType.INGREDIENT


func _accept_recipe(card: CardData) -> bool:
	return card != null and card.card_type == CardData.CardType.RECIPE


func _on_table_card_dropped(card: CardData) -> void:
	if CraftManager.place_on_table(card):
		_status_label.text = "На столе: %s. Клик по фишке вернёт карту обратно." % card.title
	_refresh_all()


func _on_book_card_dropped(card: CardData) -> void:
	var recipe_id := CraftManager.recipe_taught_by(card)
	if recipe_id == "":
		_status_label.text = "Эта книга такого рецепта не знает."
	elif CraftManager.is_learned(recipe_id):
		_status_label.text = "Рецепт уже изучен — карта не сгорела."
	elif CraftManager.learn_recipe(card):
		_status_label.text = "Изучено: %s! Теперь несите ингредиенты на стол." % \
			String(CraftManager.get_recipe(recipe_id)["title"])
	_refresh_all()


func _on_table_chip_pressed(card: CardData) -> void:
	var destination := CraftManager.return_from_table(card)
	if destination == "hand":
		_status_label.text = "%s — обратно в веер." % card.title
	elif destination == "archive":
		_status_label.text = "%s — веер полон, карта ушла в Архив." % card.title
	_refresh_all()


func _on_craft_pressed(recipe_id: String) -> void:
	var result := CraftManager.craft(recipe_id)
	if result != null:
		_status_label.text = "Готово: %s! Карта упала в веер или в Архив." % result.title
	_refresh_all()


func _refresh_all() -> void:
	# Стол: фишки лежащих ингредиентов.
	var content := _table_zone.get_content()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if CraftManager.kitchen_table.is_empty():
		var empty := Label.new()
		empty.text = "(пусто)"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.7, 0.73, 0.85))
		content.add_child(empty)
	else:
		for card in CraftManager.kitchen_table:
			var chip := Button.new()
			chip.text = card.title
			chip.tooltip_text = "Вернуть: " + card.title
			chip.pressed.connect(_on_table_chip_pressed.bind(card))
			content.add_child(chip)

	# Панель рецептов.
	for child in _recipes_box.get_children():
		_recipes_box.remove_child(child)
		child.queue_free()
	if CraftManager.learned_recipes.is_empty():
		var none_label := Label.new()
		none_label.text = "Рецепты не изучены.\nПеретащите карту рецепта на книгу."
		none_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
		_recipes_box.add_child(none_label)
	else:
		for recipe_id in CraftManager.learned_recipes:
			_recipes_box.add_child(_make_recipe_row(recipe_id))


func _make_recipe_row(recipe_id: String) -> VBoxContainer:
	var recipe := CraftManager.get_recipe(recipe_id)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var title_label := Label.new()
	title_label.text = String(recipe["title"])
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
	row.add_child(title_label)

	var on_table_ids: Array[String] = []
	for card in CraftManager.kitchen_table:
		on_table_ids.append(card.id)

	var needed: Array = recipe["ingredient_ids"]
	for ingredient_id in needed:
		var ingredient_card := InventoryManager.card_registry.get(
			String(ingredient_id)) as CardData
		var ingredient_title := ingredient_card.title if ingredient_card != null \
			else String(ingredient_id)
		var have := on_table_ids.has(String(ingredient_id))
		var line := Label.new()
		line.text = "%s %s" % ["✓" if have else "✗", ingredient_title]
		line.add_theme_color_override("font_color",
			Color(0.65, 0.95, 0.6) if have else Color(0.95, 0.6, 0.55))
		row.add_child(line)

	var craft_button := Button.new()
	craft_button.text = "Варить: %s" % String(recipe["title"])
	craft_button.disabled = not CraftManager.can_craft(recipe_id)
	craft_button.pressed.connect(_on_craft_pressed.bind(recipe_id))
	row.add_child(craft_button)
	return row


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.13, 0.09, 0.05)
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
	title_label.text = "Кухня"
	title_label.position = Vector2(36, 26)
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "Рецепт — на книгу, ингредиенты — на стол, дальше кнопка «Варить»."
	subtitle_label.position = Vector2(38, 80)
	subtitle_label.custom_minimum_size = Vector2(760, 30)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	add_child(subtitle_label)

	_status_label = Label.new()
	_status_label.text = "Перетащите сюда рецепт и ингредиенты из веера."
	_status_label.position = Vector2(38, 118)
	_status_label.custom_minimum_size = Vector2(800, 30)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	add_child(_status_label)

	_table_zone = DropZone.new()
	_table_zone.position = Vector2(46, 168)
	_table_zone.size = Vector2(470, 250)
	_table_zone.setup("Разделочный стол",
		"Сюда таскают ингредиенты из веера", Color(0.16, 0.12, 0.09, 0.95))
	_table_zone.accept_filter = Callable(self, "_accept_ingredient")
	_table_zone.card_dropped.connect(_on_table_card_dropped)
	add_child(_table_zone)

	_book_zone = DropZone.new()
	_book_zone.position = Vector2(536, 168)
	_book_zone.size = Vector2(200, 250)
	_book_zone.setup("Книга рецептов",
		"Сюда таскают карты рецептов", Color(0.12, 0.10, 0.16, 0.95))
	_book_zone.accept_filter = Callable(self, "_accept_recipe")
	_book_zone.card_dropped.connect(_on_book_card_dropped)
	add_child(_book_zone)

	var recipes_panel := PanelContainer.new()
	recipes_panel.position = Vector2(756, 168)
	recipes_panel.size = Vector2(330, 250)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.11, 0.15, 0.92)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.85, 0.72, 0.45, 0.5)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	recipes_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(recipes_panel)

	_recipes_box = VBoxContainer.new()
	_recipes_box.add_theme_constant_override("separation", 8)
	recipes_panel.add_child(_recipes_box)
