extends WeightedAIMovePreference

export (Array, Resource) var only_if_target_has_status_effect:Array
export (Array, Resource) var only_if_target_lacks_status_effect:Array
export (Array, Resource) var only_if_user_has_status_effect:Array
export (Array, Resource) var only_if_user_lacks_status_effect:Array

export (int) var only_if_user_wall_duration_below:int = -1
export (bool) var only_if_user_has_no_wall:bool = false
export (bool) var only_if_user_team_has_no_wall:bool = false
export (Resource) var only_if_user_has_wall_of_type:Resource

export (Array, Resource) var only_if_target_has_wall_of_type:Array

func get_order_score(order:BattleOrder, current_score:float)->float:
	if matches_conditions(order):
		return modify_score(current_score)
	return current_score

func matches_conditions(order:BattleOrder)->bool:
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
	
	if move and not move.is_move(order.order):
		return false
	if only_if_target_is_self and not (fighter in targets):
		return false
	if only_if_target_is_ally and (targets[0].team != fighter.team or targets == [fighter]):
		return false
	if only_if_target_is_self_or_ally and targets[0].team != fighter.team:
		return false
	if only_if_target_is_enemy and targets[0].team == fighter.team:
		return false
	if only_if_user_has_type:
		if not fighter.status.get_types().has(only_if_user_has_type):
			return false
	if only_if_target_has_status_tag.size() != 0:
		var has_tag = false
		for tag in only_if_target_has_status_tag:
			if targets[0].status.has_tag(tag):
				has_tag = true
				break
		if not has_tag:
			return false
	if only_if_target_lacks_status_tag.size() != 0:
		var has_tag = false
		for tag in only_if_target_lacks_status_tag:
			if targets[0].status.has_tag(tag):
				has_tag = true
				break
		if has_tag:
			return false
	if only_if_user_has_status_tag.size() != 0:
		var has_tag = false
		for tag in only_if_user_has_status_tag:
			if fighter.status.has_tag(tag):
				has_tag = true
				break
		if not has_tag:
			return false
	if only_if_enemy_has_status_tag != "":
		var has_tag = false
		for enemy in battle.get_fighters():
			if enemy.team == fighter.team:
				continue
			if enemy.status.has_tag(only_if_enemy_has_status_tag):
				has_tag = true
				break
		if not has_tag:
			return false
	if only_if_target_has_type.size() != 0:
		var has_type = false
		for type in only_if_target_has_type:
			if targets_have_type(targets, type):
				has_type = true
				break
		if not has_type:
			return false
	if only_if_target_lacks_type.size() != 0:
		var has_type = false
		for type in only_if_target_has_type:
			if targets_have_type(targets, type):
				has_type = true
				break
		if has_type:
			return false
	if only_if_status_due_to_run_out:
		var applicable = false
		for target in targets:
			var node = target.status.get_effect_node(only_if_status_due_to_run_out)
			if node and not node.everlasting and node.amount == 1:
				applicable = true
				break
		if not applicable:
			return false
		
	if only_if_target_hp_percent_below < 101:
		var any_below = false
		for target in targets:
			if target.status.hp * 100 / target.status.max_hp < only_if_target_hp_percent_below:
				any_below = true
				break
		if not any_below:
			return false
	
	# Custom
	if only_if_target_has_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_target_has_status_tag:
			if targets[0].status.has_effect(effect):
				has_effect = true
				break
		if not has_effect:
			return false
	if only_if_target_lacks_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_target_lacks_status_effect:
			if targets[0].status.has_effect(effect):
				has_effect = true
				break
		if has_effect:
			return false
	if only_if_user_has_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_user_has_status_effect:
			if fighter.status.has_effect(effect):
				has_effect = true
				break
		if not has_effect:
			return false
	if only_if_user_lacks_status_effect.size() != 0:
		var has_effect = false
		for effect in only_if_user_lacks_status_effect:
			if fighter.status.has_effect(effect):
				has_effect = true
				break
		if has_effect:
			return false
	
	var wall = fighter.status.get_current_decoy_effect()
	
	if only_if_user_has_no_wall and wall != null:
		return false
	if only_if_user_has_wall_of_type and (wall == null or wall.effect.elemental_type != only_if_user_has_wall_of_type):
		return false
	if only_if_user_wall_duration_below >= 0 and (wall == null or wall.amount >= only_if_user_wall_duration_below):
		return false
	
	if only_if_user_team_has_no_wall or only_if_target_has_wall_of_type.size() > 0:
		var has_wall = false
		var ally_has_wall = false
		for target in targets:
			var target_wall = target.status.get_current_decoy_effect()
			if target_wall != null and only_if_target_has_wall_of_type.has(target_wall.effect.elemental_type):
				has_wall = true
			if target.team == fighter.team and target_wall != null:
				ally_has_wall = true
		if only_if_target_has_wall_of_type.size() > 0 and not has_wall:
			return false
		if only_if_user_team_has_no_wall and ally_has_wall:
			return false

	return true

func targets_have_type(targets:Array, type:ElementalType)->bool:
	for target in targets:
		if target.status.get_types().has(type):
			return true
	return false

func modify_score(value:float)->float:
	if score_mode == 0:
		return score
	elif score_mode == 1:
		return score + value
	else :
		assert (score_mode == 2)
		return score * value
