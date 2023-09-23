extends "res://data/battle_move_scripts/GenericAttack.gd"

export (Resource) var match_move:Resource = null
export (Array, Resource) var match_status_effects:Array

func _is_critical(battle, user, target, damage:Damage)->bool:
	if ._is_critical(battle, user, target, damage):
		return true
	if user.last_used_move and user.last_used_move.is_move(match_move):
		for effect in match_status_effects:
			if target.has_effect(effect):
				return true
	return false
