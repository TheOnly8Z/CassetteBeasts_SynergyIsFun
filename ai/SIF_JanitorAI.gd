extends "res://battle/ai/WeightedAI.gd"

const Burnace = preload("res://data/monster_forms/burnace.tres")
const Draculeaf = preload("res://data/monster_forms/draculeaf.tres")

const AP_Boost = preload("res://data/status_effects/ap_boost.tres")
const Burned = preload("res://data/status_effects/burned.tres")
const Multitarget = preload("res://data/status_effects/multitarget.tres")

const Type_Plant = preload("res://data/elemental_types/plant.tres")

func request_orders():
	has_fair_fight = battle.has_status_tag("fair_fight")
	
	if not fighter.is_transformed():
		return []
	
	if is_fusion_appropriate():
		fighter.will_fuse = true
		return [BattleOrder.new(fighter, BattleOrder.OrderType.FUSE)]
	
	battle.rand.push("AI")
	
	var character = fighter.get_characters()[0]
	var status = fighter.status
	var wall = status.get_current_decoy_effect()
	var reserve_tapes = fighter.get_controller().get_available_tapes(true)
	
	var plant_wall_enemy = 0
	var enemy_count = 0
	var burned_enemy = 0
	var ally_healthy = false
	var ally_walled = false
	for enemy in battle.get_fighters(false):
		var enemy_wall = enemy.status.get_current_decoy_effect()
		if enemy.team != fighter.team:
			enemy_count += 1
			if enemy.status.has_effect(Burned):
				burned_enemy += 1
			if enemy_wall != null and enemy_wall.effect.elemental_type == Type_Plant:
				plant_wall_enemy += 1
		elif enemy != fighter:
			ally_healthy = ally_healthy or (enemy.status.hp >= enemy.status.max_hp * 0.6)
			ally_walled = ally_walled or enemy_wall != null

	# Don't you love hardcoded AI logic? I sure do!
	# Burnace -> Draculeaf: Multitarget up, either teammate is hurt or we've done all we can
	# Draculeaf -> Burnace: Ally healthy, self not walled, either no Multitarget or enemies have plant walls
	if reserve_tapes.size() > 0 and not fighter.status.has_tag("tape_jam"):
		var swap_target = null
		if character.current_tape.form == Burnace and ( \
				(enemy_count == 1 or status.has_effect(Multitarget)) and \
				not ally_healthy or (status.has_effect(AP_Boost) and \
				plant_wall_enemy == 0 and burned_enemy > 0)):
			swap_target = Draculeaf
		elif character.current_tape.form == Draculeaf and ( \
				ally_healthy and wall == null and \
				(enemy_count > 1 and not status.has_effect(Multitarget)) \
				or plant_wall_enemy > 1):
			swap_target = Burnace

		if swap_target != null:
			for tape in reserve_tapes:
				if tape.form == swap_target:
					battle.rand.pop()
					return [BattleOrder.new(fighter, BattleOrder.OrderType.SWITCH, tape)]

	var valid_moves = get_valid_moves()
	
	var ap:int = fighter.status.ap
	var orders = []
	for _i in range(get_max_move_orders()):
		if valid_moves.size() == 0:
			break
		
		var best = choose_best_order(valid_moves, orders if order_repeat_mode == 1 else [])
		if best is GDScriptFunctionState:
			best = yield (best, "completed")
		
		if best == null:
			break
		if order_repeat_mode == 0:
			assert (valid_moves.has(best.order))
			valid_moves.erase(best.order)
		if not allow_multiple_attacks and categorize(best.order) == Category.CATEGORY_ATTACK:
			_remove_attacks(valid_moves)
		
		orders.push_back(best)
		
		ap -= best.order.get_expected_cost(fighter)
		valid_moves = _filter_moves_cost_limit(valid_moves, ap)
	
	if orders.size() == 0:
		orders.push_back(BattleOrder.new(fighter, BattleOrder.OrderType.NOOP))
	
	battle.rand.pop()
	
	return orders

func get_status_score(effect:StatusEffect, target)->float:
	if has_fair_fight and effect.is_removable:
		return 0.0
	var multiplier = 1.0
	if target.status.has_effect(effect):
		multiplier = multiplier_duplicate_status
	if effect is TypeModifier:
		return multiplier * get_coating_score(effect, target)
	elif effect is WallStatus:
		return multiplier * get_wall_score(effect, target)
	elif effect is Healing:
		if target.team != fighter.team:
			return multiplier * weight_heal
		return multiplier * (target.status.max_hp - target.status.hp) / target.status.max_hp * weight_heal
	else :
		if effect is StatModifier:
			multiplier *= effect.stats_affected.size()
		return multiplier * get_vector_score(effect.get_effect_hint(target))
