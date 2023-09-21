extends BattleMove

export (Array, Resource) var wall_elemental_type:Array
export (int) var amount:int = 3
export (int) var sacrifice_hp_percent:int = 20

export (Array, Resource) var status_effects:Array
export (int, "All", "One At Random") var status_effects_to_apply:int = 0
export (int, "User", "Target", "User and Target") var status_effects_recipient:int = 0
export (int) var status_effect_amount:int = 3
export (int, 0, 100) var status_effect_chance:int = 0

export (Array, Resource) var fail_if_status_effect:Array

func _execute(battle, user, _argument, attack_params):
	var targets = attack_params.targets
	if targets.size() == 0:
		battle.queue_animate_turn_failed()
		return 
	
	# If user has one of these status effects, the move fails.
	if fail_if_status_effect.size() > 0:
		for effect_node in user.status.get_effects():
			if fail_if_status_effect.has(effect_node.effect):
				battle.queue_animate_turn_failed()
				return 
	
	var status_effects = attack_params.get("status_effects", self.status_effects)

	if status_effects_recipient != 1:
		if status_effects_to_apply == 0:
			for effect in status_effects:
				apply_status_effect(user, effect, status_effect_amount)
		else :
			assert (status_effects_to_apply == 1)
			var effect = battle.rand.choice(status_effects)
			apply_status_effect(user, effect, status_effect_amount)

	launch_attack(battle, user, targets, attack_params, Bind.new(self, "contact"))

func _is_unavoidable(user, target)->bool:
	return ._is_unavoidable(user, target) or user.team == target.team

func _get_damage_to_user(user)->int:
	return user.status.max_hp * sacrifice_hp_percent / 100

func get_decoy(user)->Decoy:
	var types = get_types(user)
	var type = preload("res://data/elemental_types/beast.tres")
	if wall_elemental_type.size() > 0:
		type = wall_elemental_type[0]
	elif types.size() > 0:
		type = types[0]
	
	if type.id == "metal":
		var forms = user.get_species()
		for form in forms:
			if form is MonsterForm and form.move_tags.has("binvader"):
				return preload("res://data/decoys/wall_binvader.tres")
	
	return load("res://data/decoys/wall_" + type.id + ".tres") as Decoy

func contact(battle, user, target, _damage, attack_params):

	if status_effects_recipient != 0:
		if status_effects_to_apply == 0:
			for effect in status_effects:
				apply_status_effect(target, effect, status_effect_amount)
		else:
			assert (status_effects_to_apply == 1)
			var effect = battle.rand.choice(status_effects)
			apply_status_effect(target, effect, status_effect_amount)

	var shield = WallStatus.new()
	shield.set_decoy(get_decoy(user))
	apply_status_effect(target, shield, amount)

func get_effect_hint(user, target)->Array:
	var hint = []
	var wall = WallStatus.new()
	wall.set_decoy(get_decoy(user))
	hint.push_back(wall)
	
	if status_effects_to_apply == 0 and (target == user or status_effects_recipient != 0):
		hint.append_array(status_effects)
	
	return hint
