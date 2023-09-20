extends BattleMove

export (Array, Resource) var traded_status_effects:Array
export (String) var traded_toast:String = ""
export (int, "After Status Effects", "Before Status Effects") var trade_order:int = 0

export (Array, Resource) var status_effects:Array
export (int, "All", "One At Random") var status_effects_to_apply:int = 0
export (int, "User", "Target", "User and Target") var status_effects_recipient:int = 0

export (int) var status_effect_amount:int = 3

func _execute(battle, user, _argument, attack_params):
	var targets = attack_params.targets
	if targets.size() == 0:
		battle.queue_animate_turn_failed()
		return

	launch_attack(battle, user, targets, attack_params, Bind.new(self, "contact"))

func _is_unavoidable(user, target)->bool:
	return ._is_unavoidable(user, target) or user.team == target.team

func _apply_effects(battle, user, target, attack_params):
	var recipients:Array
	if status_effects_recipient == 0:
		recipients = [user]
	elif status_effects_recipient == 1:
		recipients = [target]
	else:
		assert (status_effects_recipient == 2)
		recipients = [user, target]

	var status_effects = attack_params.get("status_effects", self.status_effects)
	for target in recipients:
		if status_effects_to_apply == 0:
			for effect in status_effects:
				apply_status_effect(target, effect, status_effect_amount)
		else :
			assert (status_effects_to_apply == 1)
			var effect = battle.rand.choice(status_effects)
			apply_status_effect(target, effect, status_effect_amount)
		battle.queue_status_update(target)

func contact(battle, user, target, _damage, attack_params):
	
	if trade_order == 0:
		_apply_effects(battle, user, target, attack_params)

	# trade
	var traded = false
	if user != target:
		for effect in traded_status_effects:
			var user_effect = user.status.get_effect_node(effect)
			var target_effect = target.status.get_effect_node(effect)
			if user_effect != null and target_effect != null:
				if effect.has_duration:
					var temp = user_effect.amount
					user_effect.amount = target_effect.amount
					target_effect.amount = temp
					traded = true
			elif user_effect != null:
				target.status.add_effect(effect, user_effect.amount)
				user_effect.remove()
				traded = true
			elif target_effect != null:
				user.status.add_effect(effect, target_effect.amount)
				target_effect.remove()
				traded = true

	if traded:
		battle.queue_status_update(user)
		battle.queue_status_update(target)
		if traded_toast != "":
			var toast = battle.create_toast()
			toast.setup_text(traded_toast)
			battle.queue_play_toast(toast, target.slot)

	if trade_order == 1:
		_apply_effects(battle, user, target, attack_params)

func get_effect_hint(user, target)->Array:
	var hint = []
	
	if status_effects_to_apply == 0 and status_effects_recipient != 1:
		hint.append_array(status_effects)

	for effect in traded_status_effects:
		if user.status.has_effect(effect):
			hint.push_back(effect)

	return hint
