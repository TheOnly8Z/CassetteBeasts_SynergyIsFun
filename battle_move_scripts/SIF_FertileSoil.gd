extends BattleMove

export (Array, Resource) var weaknesses:Array
export (int) var heal_amp:int = 30

export (Array, Resource) var status_effects_to_extend:Array

func notify(fighter, id:String, args):
	
	if id == "turn_ending" and status_effects_to_extend.size() > 0 and args.fighter == fighter:
		var update = false
		for effect_node in fighter.status.get_effects():
			if effect_node.has_duration() and status_effects_to_extend.has(effect_node.effect) and effect_node.had_round_end:
				effect_node.amount += 1
				update = true
		if update:
			fighter.battle.queue_status_update(fighter)

	if id == "heal_starting" and heal_amp > 0 and args.fighter == fighter:
		args.heal_amount *= 1 + (heal_amp / 100)

	if id == "create_damage" and args.target == fighter:
		if _types_match(args.damage.types):
			args.damage.is_critical = true

	return .notify(fighter, id, args)

func _types_match(types:Array)->bool:
	for type in types:
		if weaknesses.has(type):
			return true
	return false
