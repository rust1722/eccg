# Этап 1 — фундамент (готово, ждёт проверки в Godot)

Что сделано по задаче из `docs/DESIGN.md` (Приложение A). Игры здесь пока нет —
это «скелет»: данные карт, хранилище и режимы, на которых всё построится.

## Что появилось

```
scripts/resources/          классы карт (данные)
  CardData.gd               базовая карта: id, название, цена, тип
  CardEffect.gd             эффект карты: урон/лечение/цель/сила
  CreatureCardData.gd       существо: мана, атака, здоровье
  ConsumableCardData.gd     расходник: стак, эффекты, рецепт
  SeedCardData.gd           семя: карта урожая + время роста (сек)

scripts/autoload/           глобальные менеджеры (всегда в памяти)
  InventoryManager.gd       Архив (сколько каких карт) + рука каждой комнаты (A+)
  GameStateManager.gd       режим игры: TAVERN / WORLD_MAP / BATTLE

resources/cards/test_set/   8 тестовых карт (файлы .tres)
  Семена подсолнуха, Вода, Мясо, Зелень,
  Рецепт: Лесной суп, Лесной суп, Зелье лечения, Задание: башня
```

Оба менеджера подключены в `project.godot` как Autoload — Godot сам
запускает их при старте любой сцены.

## Как проверить (2 минуты)

1. В GitHub Desktop: **Fetch origin → Pull**.
2. Открой проект в Godot, подожди, пока он перечитает файлы
   (если спросит про сцену — **Reload**).
3. Нажми **F5**.
4. Внизу Godot открой панель **Output** (Вывод). Должно быть примерно так:

```
[InventoryManager] ready: archive + 9 room hands
[GameStateManager] ready, mode = TAVERN
=== eccg: STAGE 1 SELF-TEST ===
- Семена подсолнуха [SEED] consumable=true buy=2 sell=1
... (ещё 7 карт)
Test cards loaded: 8/8
Garden hand: Семена подсолнуха
Kitchen hand: Мясо
Archive left: seed=2 meat=2
=== STAGE 1 OK: if you see this, foundation works ===
```

5. На экране вместо старого "Hello" теперь "Stage 1: foundation ready".
6. Ещё можно щёлкнуть слева внизу по файлу
   `resources/cards/test_set/card_potion_health.tres` — справа в Inspector
   будут видны все поля карты: название, цены, эффект лечения 10.

Если вместо этого в Output красные ошибки — сделай скрин Output и пришли мне.

## Что осознанно пока НЕ сделано

- Картинок у карт нет (`icon` пустой) — арт позже.
- У семян подсолнуха не заполнено «что вырастет» (`harvest_result_card`):
  карты урожая подсолнуха в тестовом наборе нет.
- Рука, Архив и бой — пока только данные и менеджеры, без экрана и анимаций.
  Экран таверны с веером и указателем — следующий этап.
