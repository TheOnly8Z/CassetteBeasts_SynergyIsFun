extends "res://data/battle_move_scripts/GenericAttack.gd"

export (Array, Resource) var follow_up_damage_types:Array = []
export (int) var follow_up_damage_power:int = 30
export (Array, Resource) var follow_up_hit_vfx:Array = []
export (float) var follow_up_hit_delay:float = 0.0

func contact(battle, user, target, damage, attack_params):
	.contact(battle, user, target, damage, attack_params)
	
	var follow_up_params = {
		"types":follow_up_damage_types, 
		"power":follow_up_damage_power, 
		"hit_vfx":follow_up_hit_vfx, 
		"hit_delay":follow_up_hit_delay
	}
	var follow_up_damage = create_damage(battle, user, target, follow_up_params)
	target.get_controller().take_damage_with_chemistry(follow_up_damage)
