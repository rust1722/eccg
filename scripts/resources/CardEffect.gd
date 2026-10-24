class_name CardEffect
extends Resource
## Один эффект карты (DESIGN.md §2.2): что делает карта и по кому.
##
## Карта может нести несколько эффектов списком
## (см. ConsumableCardData.effects). Сами эффекты ничего не выполняют —
## их будет исполнять боевой движок на следующих этапах.

enum EffectType {
	DAMAGE,
	HEAL,
	ARMOR,
	DRAW_CARD,
	DISCARD,
	BUFF_ATTACK,
	BUFF_HEALTH,
	SUMMON,
	FREEZE,
	DESTROY_TARGET,
}

enum TargetType {
	SINGLE_ENEMY,
	ALL_ENEMIES,
	SINGLE_ALLY,
	ALL_ALLIES,
	SELF_HERO,
	ENEMY_HERO,
	ANY_TARGET,
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
## Сила эффекта: урон, лечение, броня и т.д.
@export var value: int = 0


func _to_string() -> String:
	return "%s %d -> %s" % [
		EffectType.keys()[effect_type], value, TargetType.keys()[target_type]
	]
