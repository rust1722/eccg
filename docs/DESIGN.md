Markdown

````
# Game Design Document & Technical Architecture Spec (GDScript / Godot 4)

## 1. Общая концепция и Core Game Loop
* **Жанр:** Story-driven Card RPG / Tavern Management.
* **Визуальный стиль:** Static 2D с эффектом параллакса (слои фонов, персонажей и объектов).
* **Игровой цикл (Core Loop):**
  1. **Кабинет (Карта мира):** Выбор боевой или сюжетной точки.
  2. **Бой:** Пошаговый бой (30 карт в колоде, +1 маны за ход до 10, лимит руки 10 карт).
  3. **Смена дня:** Победа в бою вызывает `DayManager.advance_day()`. Поражение возвращает в таверну без смены дня.
  4. **Фаза Таверны:**
     * **Сад:** Созревание растений с таймером или по смене дня.
     * **Мастерские (Кухня, Кузня, Алхимия, Библиотека):** Крафт карт по рецептам.
     * **Барная стойка:** Обслуживание клиентов, выполнение заказов.
     * **Лавка:** Торговля с торговцем.
     * **Архив:** Редактирование колод и менеджмент коллекции.

---

## 2. Модуль 1: Архитектура данных (Godot Custom Resources)

Все скрипты ресурсов находятся в `res://scripts/resources/`.

### 2.1. Базовый класс: `CardData.gd`
```gdscript
class_name CardData
extends Resource

enum CardType {
	CREATURE,    # Существо (постоянная)
	SPELL,       # Заклинание (расходная)
	ITEM,        # Предмет (расходная)
	INGREDIENT,  # Ингредиент (крафт)
	FOOD,        # Еда (расходная / для клиентов)
	DRINK,       # Напиток (расходная / для клиентов)
	SEED,        # Семена (для сада)
	POTION,      # Зелье (расходная)
	RECIPE,      # Рецепт (для изучения в книгах)
	QUEST        # Задание (для активации в кабинете)
}

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var card_type: CardType
@export var is_consumable: bool = false
@export var buy_price: int = 0
@export var sell_price: int = 0
````

### 2.2. Система эффектов: `CardEffect.gd`

GDScript

```
class_name CardEffect
extends Resource

enum EffectType {
	DAMAGE, HEAL, ARMOR, DRAW_CARD, DISCARD,
	BUFF_ATTACK, BUFF_HEALTH, SUMMON, FREEZE, DESTROY_TARGET
}

enum TargetType {
	SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF_HERO, ENEMY_HERO, ANY_TARGET
}

@export var effect_type: EffectType
@export var target_type: TargetType
@export var value: int = 0
```

### 2.3. Дочерние классы карт

- **`CreatureCardData.gd`**: `mana_cost`, `attack`, `health`, `max_health`, `keywords`.
    
- **`ConsumableCardData.gd`**: `mana_cost`, `stack_limit`, `effects`, `craft_recipe`.
    
- **`SeedCardData.gd`**: наследник `ConsumableCardData`, содержит `harvest_result_card: CardData`.
    

## 3. Модуль 2: Глобальные Менеджеры (Autoloads)

1. **`InventoryManager.gd`**: Хранит `archive_inventory: Dictionary` (со стаками расходников) и `current_hand: Array[CardData]` (лимит 10).
    
2. **`DayManager.gd`**: `current_day: int`, управление состоянием грядок в саду при `advance_day()`.
    
3. **`GameStateManager.gd`**: Режимы игры (`TAVERN`, `WORLD_MAP`, `BATTLE`).
    

## 4. Модуль 3: Визуальный дизайн и механика Локаций Таверны

### 4.1. Система книг (Активация Рецептов и Заданий)

Во всех мастерских и кабинете книги выступают в роли `DropZone`:

- Перетаскивание карты типа `RECIPE` на Книгу Рецептов сжигает карту и добавляет рецепт в список изученных.
    
- Перетаскивание карты типа `QUEST` на Книгу Заданий сжигает карту и активирует новую точку/миссию на Карте Мира.
    

### 4.2. Барная стойка (`BarScene.tscn`)

- **Визуал:** Стойка бара, камин, стеллажи с бутылками.
    
- **Механики:**
    
    - Индикатор-колокольчик внизу экрана уведомляет о новом госте.
        
    - Диалоговое окно слева и интерактивные опции диалога справа.
        
    - При нажатии «Завершить» проигрывается покадровая комикс-анимация ухода гостя.
        
    - Предупреждающее окно при попытке завершить диалог с необслуженным клиентом.
        

### 4.3. Шаблон ремесленных комнат (`CraftRoomTemplate.tscn`)

- **Кухня:** Разделочный стол (`DropZone`), книга кулинарных рецептов, висящий на стене виджет текущего заказа. Крафт еды/напитков.
    
- **Кузня:** Стол ремесленника (`DropZone`), чертежная книга, виджет заказа. Крафт снаряжения и предметов (`ITEM`).
    
- **Алхимия:** Бурлящий котёл (`DropZone`), гримуар зелий, виджет заказа. Крафт эликсиров и зелий (`POTION`).
    
- **Библиотека:** Магический круг с кристаллами (`DropZone`), фолиант заклинаний, виджет заказа. Крафт свитков и магии (`SPELL`).
    

### 4.4. Лавка торговца (`ShopScene.tscn`)

- **Покупки:** Витринные полки с картами и ценниками. Клик по карте перемещает ее в Руку, отправляя золото торговцу.
    
- **Продажа:** Перетаскивание карты из Руки на торговца (`DropZone`). Все карты в веере имеют бирки цен.
    
- **Фильтр:** Архив открывает инвентарь с ценами для выборки карт в Руку перед продажей.
    

### 4.5. Сад (`GardenScene.tscn`)

- **Посадка и полив:** Стеллаж с горшками (`DropZone`). Перетаскивание карты `SeedCardData` сажает росток, перетаскивание `Воды`/`Лейки` запускает таймер созревания.
    
- **Сбор урожая:** Клик по созревшему растению отправляет карту урожая в Руку.
    

### 4.6. Кабинет (`CabinetScene.tscn`)

- **Карта мира:** Фэнтезийная карта во весь экран с точками интереса, замками и ресурсами.
    
- **Интерфейс:** Вкладки фильтров сверху, виджет активных заданий справа и книга квестов (для сброса карт `QUEST`). Окно точки содержит сложность, награды, выбор колоды и кнопку «В БОЙ».
    

### 4.7. Архив (`ArchiveScene.tscn`)

- **Сборка колод:** Сетка карт с пагинацией (страницы `1/2`), фильтры по мане (`0-6+`) и вкладки типов карт (`Существа`, `Заклинания`, `Предметы`, `Зелья`, `Еда`).
    
- **Панель колод:** Блок справа со списком сохраненных 30-карточных колод для боевых миссий.
    

## 5. Модуль 4: Боевой Движок (`BattleManager.gd`)

- Формат Hearthstone: 2 героя, 30 карт в колоде, +1 маны за ход до 10.
    
- Разыгранные одноразовые карты (`is_consumable = true`) сгорают из Архива независимо от исхода.
    
- Постоянные карты (`is_consumable = false`) полностью восстанавливаются после боя.
    
- Смена дня происходит после любого боя.

Промт 
Текст для ИИ-кодинг-агента:
Задача: Инициализация Godot 4 проекта и создание тестового набора ресурсов (Test Suite)

Внимательно ознакомься с архитектурой и структурой в DESIGN_DOC.md.

Создай базовую структуру папок проекта Godot 4 (GDScript):

res://scripts/resources/

res://scripts/autoload/

res://resources/cards/test_set/

res://scenes/

Реализуй классы кастомных ресурсов в res://scripts/resources/:

CardData.gd (с enum CardType, включая RECIPE и QUEST)

CreatureCardData.gd

ConsumableCardData.gd

SeedCardData.gd

Реализуй базовые Autoload-скрипты в res://scripts/autoload/:

InventoryManager.gd

DayManager.gd

GameStateManager.gd

Создай стартовый тестовый набор карт (в виде .tres файлов) в res://resources/cards/test_set/:

card_seed_sunflower.tres (Тип: SEED)

card_water.tres (Тип: INGREDIENT)

card_meat.tres (Тип: INGREDIENT)

card_herbs.tres (Тип: INGREDIENT)

card_soup_recipe.tres (Тип: RECIPE)

card_soup.tres (Тип: FOOD)

card_potion_health.tres (Тип: POTION)

card_quest_tower.tres (Тип: QUEST)

Как только агент выполнит эту команду, у тебя в проекте появится всё необходимое фундаментом: скрипты данных, менеджеры и готовые карты для тестов.
    

