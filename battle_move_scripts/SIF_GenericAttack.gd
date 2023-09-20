extends "res://data/battle_move_scripts/GenericAttack.gd"

export (Array, Resource) var destroys_walls_of_type:Array
export (Array, Resource) var purge_status_effects:Array
export (String) var purge_status_effects_toast:String
export (Array, Resource) var always_critical_against_types:Array
export (Array, Resource) var no_chemistry_against_types:Array

export (Array, Resource) var user_wall_type:Array
export (int) var user_wall_amount:int = 0
export (int) var user_wall_chance:int = 100

export (Array, Resource) var target_wall_type:Array
export (int) var target_wall_amount:int = 0
export (int) var target_wall_chance:int = 100

func contact(battle, user, target, damage, attack_params):
	var type_match = _has_type_match(target, status_effect_only_for_target_types)
	
	# Purge status effects
	var purge_status_effects = attack_params.get("purge_status_effects", self.purge_status_effects)
	if purge_status_effects.size() > 0:
		var num_removed:int = 0
		for effect_node in target.status.get_effects():
			if purge_status_effects.has(effect_node.effect) and effect_node.remove():
				num_removed += 1

		if purge_status_effects_toast != null and num_removed > 0:
			var toast = battle.create_toast()
			toast.setup_text(purge_status_effects_toast)
			battle.queue_play_toast(toast, target.slot)

	# Apply status effects
	var target_status_effects = attack_params.get("target_status_effects", self.target_status_effects)
	if type_match and target_status_effects.size() > 0 and battle.rand.rand_int(100) < status_effect_chance:
		inflict_statuses(battle, user, target, attack_params)
	elif not damage.reacted:
		default_contact_effects(battle, user, target, damage)

	# Apply wall to target. Type is based on specified type, move type, user type, in that order
	if target_wall_amount > 0 and battle.rand.rand_int(100) < target_wall_chance:
		var types = get_types(user)
		var type = preload("res://data/elemental_types/beast.tres")
		if user_wall_type.size() > 0:
			type = user_wall_type[0]
		elif types.size() > 0:
			type = types[0]
		var shield = WallStatus.new()
		shield.set_decoy(load("res://data/decoys/wall_" + type.id + ".tres"))
		apply_status_effect(target, shield, target_wall_amount)

func _pre_contact(battle, user, target, damage):
	# Apply wall to user. Not contact dependent, triggers as long as move doesn't miss
	if user_wall_amount > 0 and battle.rand.rand_int(100) < user_wall_chance:
		var types = get_types(user)
		var type = preload("res://data/elemental_types/beast.tres")
		if user_wall_type.size() > 0:
			type = user_wall_type[0]
		elif types.size() > 0:
			type = types[0]
		var shield = WallStatus.new()
		shield.set_decoy(load("res://data/decoys/wall_" + type.id + ".tres"))
		apply_status_effect(user, shield, user_wall_amount)

func _is_critical(battle, user, target, damage:Damage)->bool:
	if ._is_critical(battle, user, target, damage):
		return true
	# Crit against type
	if always_critical_against_types.size() > 0 and _has_type_match(target, always_critical_against_types):
		return true
	return false

func launch_attack(battle, user, targets:Array, attack_params = {}, on_contact = null):
	var launch_notify_args = {
		"fighter":user, 
		"move":self, 
		"attack_params":attack_params, 
		"targets":targets
	}
	if battle.events.notify("launch_attack_starting", launch_notify_args):
		return 
	
	affect_weather(battle)
	
	for target in targets:
		var damage = create_damage(battle, user, target, attack_params)
		var notify_args = {
			"fighter":user, 
			"move":self, 
			"damage":damage, 
			"target":target
		}

		if not battle.events.notify("attack_starting", notify_args):
			if _is_unavoidable(user, target) or battle.rand.rand_bool(BattleFormulas.get_hit_chance(damage.accuracy, user, target)):
				_pre_contact(battle, user, target, damage)
				
				# Type-dependent wall break
				if damage.destroys_walls != true:
					var destroys_walls_of_type = self.destroys_walls_of_type
					var decoy_status = target.status.get_current_decoy_effect()
					if decoy_status != null and destroys_walls_of_type.has(decoy_status.effect.elemental_type):
						# Ugly hack: Multi hit moves with destroys_walls doesn't kill the wall on first hit.
						# Create a separate instance of contact to kill the wall, and let the remaining hits go through.
						if damage.hits > 1 and not damage.ignores_walls \
						and not (target.status.has_tag("window") and damage.physicality == BattleMove.Physicality.RANGED):
							damage.hits -= 1
							var temp_damage = create_damage(battle, user, target, attack_params)
							temp_damage.hits = 1
							temp_damage.destroys_walls = true
							var temp_args = {
								"fighter":user, 
								"move":self, 
								"damage":temp_damage, 
								"target":target
							}
							battle.events.notify("attack_contact_starting", temp_args)
						else:
							damage.destroys_walls = true
				
				# Make contact and do damage stuff normally.
				if not battle.events.notify("attack_contact_starting", notify_args):
					if damage.damage > 0:
						if not battle.events.notify("attack_damage_starting", notify_args):
							# No reaction against type
							if _has_type_match(target, self.no_chemistry_against_types):
								target.get_controller().take_damage(damage)
								damage.reacted = false
							else:
								damage.reacted = target.get_controller().take_damage_with_chemistry(damage)
							battle.events.notify("attack_damage_ending", notify_args)
					if on_contact != null:
						on_contact.call_func([battle, user, target, damage, attack_params])
					call_attributes("on_contact", [self, user, target, damage])
					battle.events.notify("attack_contact_ending", notify_args)
			else :
				battle.queue_animation(Bind.new(target, "animate_miss", [target.slot]))
				battle.events.notify("attack_missed", notify_args)
			battle.events.notify("attack_ending", notify_args)
	
	battle.events.notify("launch_attack_ending", launch_notify_args)


func _has_type_match(target, types:Array)->bool:
	if types.size() > 0:
		for type in types:
			if target.status.get_types().has(type):
				return true
		return false
	return true
