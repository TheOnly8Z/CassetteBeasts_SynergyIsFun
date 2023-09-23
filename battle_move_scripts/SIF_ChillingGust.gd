extends "res://mods/synergy_is_fun/battle_move_scripts/SIF_GenericAttack.gd"

const IceType = preload("res://data/elemental_types/ice.tres")
const AirType = preload("res://data/elemental_types/air.tres")


func _create_attack_params(battle, user, targets:Array, argument)->Dictionary:
	var params = ._create_attack_params(battle, user, targets, argument)
	params.ignores_walls = true
	return params

func get_types(user)->Array:
	var user_types = user.status.get_types()
	if user_types.size() > 0 and user_types[0] == IceType:
		return [AirType]
	return .get_types(user)
