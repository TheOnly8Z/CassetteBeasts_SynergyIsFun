extends "res://data/battle_move_scripts/GenericAttack.gd"

export (String) var empower_toast:String = ""
export (Array, Resource) var empower_status_effects:Array
export (int) var power_empowered:int = 0
export (int) var recoil_empowered:int = 0
export (int) var power_per_effect_stack:int = 0
export (int) var recoil_per_effect_stack:int = 0

export (Array, Resource) var follow_up_damage_types:Array = []
export (Array, Resource) var follow_up_hit_vfx:Array = []
export (float) var follow_up_hit_delay:float = 0.0

func contact(battle, user, target, damage, attack_params):
	.contact(battle, user, target, damage, attack_params)

	if empower_status_effects.size() > 0:
		var stacks = 0
		for effect in empower_status_effects:
			if target.status.has_effect(effect):
				if effect.has_duration:
					stacks += target.status.get_effect_node(effect).amount
				else:
					stacks += 1
		if stacks > 0:
			var follow_up_params = {
				"types":follow_up_damage_types, 
				"power":power_empowered + power_per_effect_stack * stacks, 
				"hit_vfx":follow_up_hit_vfx, 
				"hit_delay":follow_up_hit_delay,
				"toast_message":empower_toast,
			}
			var follow_up_damage = create_damage(battle, user, target, follow_up_params)
			target.get_controller().take_damage_with_chemistry(follow_up_damage)
			if recoil_empowered + recoil_per_effect_stack > 0:
				var recoil_params = {
					"types":follow_up_damage_types, 
					"power":recoil_empowered + recoil_per_effect_stack * stacks, 
					"hit_vfx":follow_up_hit_vfx, 
					"hit_delay":follow_up_hit_delay,
					"toast_message":empower_toast,
				}
				var recoil_damage = create_damage(battle, user, user, recoil_params)
				user.get_controller().take_damage_with_chemistry(recoil_damage)
