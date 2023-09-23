extends "res://data/battle_move_scripts/GenericAttack.gd"

export (Array, Resource) var destroys_walls_of_type:Array
export (Array, Resource) var always_critical_against_types:Array
export (Array, Resource) var no_chemistry_against_types:Array

export (bool) var no_damage_against_allies:bool = false

export (Array, Resource) var purge_status_effects:Array
export (int, "Remove", "Drain", "Do Nothing") var purge_mode:int = 0
export (int) var purge_amount:int = 1
export (String) var purge_status_effects_toast:String = ""
export (int, 0, 100) var purge_heal_percent:int = 0
export (int) var purge_heal_absolute:int = 0
export (int) var purge_heal_max_stacks:int = 0

export (Array, Resource) var user_wall_type:Array
export (int) var user_wall_amount:int = 0
export (int) var user_wall_chance:int = 100

export (Array, Resource) var target_wall_type:Array
export (int) var target_wall_amount:int = 0
export (int) var target_wall_chance:int = 100

export (int) var return_damage_power:int = 0
export (int) var absolute_return_damage:int = 0
export (int, 0, 100) var percent_return_damage:int = 0
export (String, "default", "max_hp", "melee_attack", "melee_defense", "ranged_attack", "ranged_defense", "speed") var attack_stat:String = "default"

func purge_effects(battle, user, target):
	if purge_status_effects.size() > 0:
		var num_removed:int = 0
		var stacks_removed:int = 0
		for effect_node in target.status.get_effects():
			if purge_status_effects.has(effect_node.effect):
				var dur = 1
				if effect_node.has_duration():
					dur = effect_node.get_duration()
				if purge_mode == 0 and effect_node.remove():
					num_removed += 1
					stacks_removed += dur
				elif purge_mode == 1:
					effect_node.drain(purge_amount)
					num_removed += 1
					stacks_removed += min(purge_amount, dur)
				else:
					assert (purge_mode == 2)
					stacks_removed += dur

		if purge_heal_percent + purge_heal_absolute > 0:
			if purge_heal_max_stacks > 0:
				stacks_removed = min(purge_heal_max_stacks, stacks_removed)
			var hp = int(max(1, user.status.max_hp * purge_heal_percent / 100 + purge_heal_absolute) * stacks_removed)
			user.get_controller().heal(hp)

		if purge_status_effects_toast != null and num_removed > 0:
			var toast = battle.create_toast()
			toast.setup_text(purge_status_effects_toast)
			battle.queue_play_toast(toast, target.slot)

func contact(battle, user, target, damage, attack_params):
	var type_match = _has_type_match(target, status_effect_only_for_target_types)
	print("contact")
	# Purge status effects
	purge_effects(battle, user, target)

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
	pass

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
	
	# Apply wall to user. Always triggers on a miss, but doesn't trigger per target
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
				
				# No damage against allies (also ignores walls)
				if no_damage_against_allies and user.team == target.team:
					damage.damage = 0
					damage.ignores_walls = true
				
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

func _get_user_attack_stat(user, physicality)->int:
	if attack_stat == "default":
		return ._get_user_attack_stat(user, physicality)
	return user.status.get(attack_stat)

func _get_damage_to_user(user)->int:
	var level = user.status.level
	var attack = user.status.get_attack_variant(physicality)
	var defense = user.status.get_defense_variant(physicality)
	return BattleFormulas.get_damage(user.battle.rand, return_damage_power, level, attack, defense, [], []) + absolute_return_damage + percent_return_damage * user.status.max_hp / 100

func get_effect_hint(user, target):
	var status_hints = []
	var attack_types = get_types(user)
	
	var decoy = target.status.get_current_decoy_effect()
	if decoy != null:
		status_hints += decoy.effect.get_decoy_hit_effect_hint(decoy, attack_types)
	else :
		var defense_types = []
		for type in target.status.get_types():
			if not no_chemistry_against_types.has(type):
				defense_types.push_back(type)
		var hint = ElementalReactions.get_reaction_hint(attack_types, defense_types)
		status_hints += hint

	status_hints += _get_effect_hint_extra_statuses(user, target)

	if status_hints.size() > 0:
		return status_hints
	return Vector3(0, 1, 0)
