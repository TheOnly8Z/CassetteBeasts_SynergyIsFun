extends Node

export (Resource) var move:Resource
export (bool) var only_if_target_is_self:bool = false
export (bool) var only_if_target_is_ally:bool = false
export (bool) var only_if_target_is_self_or_ally:bool = false
export (bool) var only_if_target_is_enemy:bool = false

export (Array, Resource) var only_if_target_has_status_effect:Array
export (Array, Resource) var only_if_target_lacks_status_effect:Array
export (Array, Resource) var only_if_user_has_status_effect:Array
export (Array, Resource) var only_if_user_lacks_status_effect:Array

export (int) var only_if_user_wall_duration_below:int = -1
export (bool) var only_if_user_has_no_wall:bool = false
export (Resource) var only_if_user_has_wall_of_type:Resource

export (int) var only_if_stack_greater_than:int = 0

export (float) var stack_weight_buff:float = 1
export (float) var stack_weight_debuff:float = 1

export (float) var score:float = 1.0
export (float) var score_per_stack:float = 0
export (float, 0, 1) var score_health_factor:float = 0.5
export (int, "Absolute", "Add", "Multiply") var score_mode:int = 0

func get_order_score(order:BattleOrder, current_score:float)->float:
	var stacks = matches_conditions(order)
	if stacks > 0.0:
		var factor = (1 - score_health_factor) + score_health_factor * calc_health_factor(stacks)
		print(stacks, factor, current_score)
		return calc_score(stacks * factor, current_score)
	return current_score

func calc_health_factor(stacks:float)->float:
	var fighter = get_parent().fighter
	var hp = int(max(1, fighter.status.max_hp * move.percent_hp_heal_per_stack / 100 + move.absolute_hp_heal_per_stack) * stacks)
	return min(fighter.status.max_hp - fighter.status.hp, hp) / fighter.status.max_hp

func matches_conditions(order:BattleOrder)->float:
	var battle = get_parent().battle
	var fighter = get_parent().fighter
	
	var targets = []
	if order.argument.has("target_slots"):
		for slot in order.argument.target_slots:
			var target = slot.get_fighter()
			if target != null:
				targets.push_back(target)
	if targets.size() == 0:
		targets.push_back(fighter)
		
	var stacks = 0.0
	
	if move and not move.is_move(order.order):
		return 0.0
	if only_if_target_is_self and not (fighter in targets):
		return 0.0
	if only_if_target_is_ally and (targets[0].team != fighter.team or targets == [fighter]):
		return 0.0
	if only_if_target_is_self_or_ally and targets[0].team != fighter.team:
		return 0.0
	if only_if_target_is_enemy and targets[0].team == fighter.team:
		return 0.0
		
	# Custom
	if only_if_target_has_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_target_has_status_effect:
			if targets[0].status.has_effect(effect):
				has_effect = true
				break
		if not has_effect:
			return 0.0
	if only_if_target_lacks_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_target_lacks_status_effect:
			if targets[0].status.has_effect(effect):
				has_effect = true
				break
		if has_effect:
			return 0.0
	if only_if_user_has_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_user_has_status_effect:
			if fighter.status.has_effect(effect):
				has_effect = true
				break
		if not has_effect:
			return 0.0
	if only_if_user_lacks_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_user_lacks_status_effect:
			if fighter.status.has_effect(effect):
				has_effect = true
				break
		if has_effect:
			return 0.0
	
	var wall = fighter.status.get_current_decoy_effect()
	if only_if_user_has_no_wall and wall != null:
		return 0.0
	if only_if_user_has_wall_of_type and (wall == null or wall.elemental_type != only_if_user_has_wall_of_type):
		return 0.0
	if only_if_user_wall_duration_below >= 0 and wall != null and wall.amount >= only_if_user_wall_duration_below:
		return 0.0

	var stacks_unweighted = 0
	for target in targets:
		for effect_node in target.status.get_effects():
			if _should_purge_effect(effect_node.effect, move):
				var dur = 1
				if effect_node.has_duration():
					dur = effect_node.get_duration()
					stacks_unweighted += dur
				else:
					stacks_unweighted += 1
				if effect_node.effect.is_buff:
					dur *= stack_weight_buff
					if target.team == fighter.team:
						dur *= -1
				elif effect_node.effect.is_debuff:
					dur *= stack_weight_debuff
					if target.team != fighter.team:
						dur *= -1
				stacks += dur
	
	if only_if_stack_greater_than > 0 and only_if_stack_greater_than >= stacks_unweighted:
		return 0.0
	
	return stacks

func _should_purge_effect(effect, move):
	return move.purge_status_effects.has(effect) or (effect.is_decoy and move.purge_walls_of_type.has(effect.elemental_type))


func targets_have_type(targets:Array, type:ElementalType)->bool:
	for target in targets:
		if target.status.get_types().has(type):
			return true
	return false

func calc_score(stacks:float, value:float)->float:
	if score_mode == 0:
		return score + score_per_stack * stacks
	elif score_mode == 1:
		return (score + score_per_stack * stacks) + value
	else :
		assert (score_mode == 2)
		return (score + score_per_stack * stacks) * value
