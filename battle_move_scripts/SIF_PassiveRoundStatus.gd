extends BattleMove

export (int, "One At Random", "All") var passive_effect_target_type:int = 0
export (int, "Any", "User", "Enemy") var passive_effect_target_team:int = 0
export (bool) var passive_effect_target_self:bool = true

export (Array, Resource) var passive_effects:Array
export (int, "All", "One At Random") var passive_effects_to_apply:int = 0
export (int) var passive_effect_amount:int = 3
export (int, 0, 100) var passive_effect_chance:int = 100

func notify(fighter, id:String, args):
	if id == "round_ending":
		if effect_chance_succeeds(fighter, passive_effect_chance):
			var order = BattleOrder.new(fighter, BattleOrder.OrderType.FIGHT, self, {})
			fighter.battle.queue_turn_action(order)
	return .notify(fighter, id, args)

# This doesn't actually use the standard target selection system.
# Looks goofy, and may have unintended interaction issues.
# TODO: Switch over to default target system
func _execute(battle, user, _argument, attack_params):

	# You better not forget to put in a status effect, OR ELSE
	assert (passive_effects.size() > 0)

	var targets:Array = []

	if passive_effect_target_team == 0: # All fighters
		targets = battle.get_fighters()
	elif passive_effect_target_team == 1: # Same team as user
		for fighter in battle.get_fighters():
			if user.team == fighter.team:
				targets.push_back(fighter)
	else: # Different team from user
		assert (passive_effect_target_team == 2)
		for fighter in battle.get_fighters():
			if user.team != fighter.team:
				targets.push_back(fighter)

	# Don't target self if disabled
	if !passive_effect_target_self and targets.has(user):
		targets.erase(user)

	# May happen if move is random ally and we have no living allies;
	# Or if targets random enemies and no enemies are left
	if targets.size() == 0:
		battle.queue_animate_turn_failed()
		return 

	# Select one target from list of targets
	if passive_effect_target_type == 0:
		var target = battle.rand.choice(targets)
		targets = [target]
	
	# Apply effects
	for fighter in targets:
		if passive_effects_to_apply == 0:
			for effect in passive_effects:
				apply_status_effect(fighter, effect, passive_effect_amount)
		else :
			assert (passive_effects_to_apply == 1)
			var effect = battle.rand.choice(passive_effects)
			apply_status_effect(fighter, effect, passive_effect_amount)
