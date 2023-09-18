extends "res://data/battle_move_scripts/GenericAttack.gd"

const PlantType = preload("res://data/elemental_types/plant.tres")
const AirType = preload("res://data/elemental_types/air.tres")

func get_types(user)->Array:
	var user_types = user.status.get_types()
	if user_types.size() > 0 and user_types[0] == AirType:
		return [PlantType]
	return .get_types(user)
