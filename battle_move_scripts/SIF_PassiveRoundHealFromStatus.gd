extends BattleMove

export (Array, Resource) var required_status_effects:Array

export (int, 0, 100) var chance:int = 100

export (int) var duration_removed:int = 1
export (int, 0, 100) var percent_hp_heal:int = 0
export (int) var absolute_hp_heal:int = 0

func notify(fighter, id:String, args):
	if id == "round_ending" and fighter.status.hp < fighter.status.max_hp:
		if required_status_effects.size() > 0 and effect_chance_succeeds(fighter, chance):
			for effect_node in fighter.status.get_effects():
				if required_status_effects.has(effect_node.effect):
					var order = BattleOrder.new(fighter, BattleOrder.OrderType.FIGHT, self, {})
					fighter.battle.queue_turn_action(order)
					break

	return .notify(fighter, id, args)

func _execute(_battle, user, _argument, _attack_params):
	var stack = 0
	if duration_removed > 0:
		for effect_node in user.status.get_effects():
			if required_status_effects.has(effect_node.effect):
				stack += min(effect_node.get_duration(), duration_removed)
				effect_node.drain(duration_removed)
	else:
		stack = 1

	var hp = int(max(1, stack * (user.status.max_hp * percent_hp_heal / 100 + absolute_hp_heal)))
	user.get_controller().heal(hp)
