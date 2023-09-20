extends BattleMove

export (Array, Resource) var purge_status_effects:Array
export (Array, Resource) var purge_walls_of_type:Array
export (String) var purge_status_effects_toast:String = ""

export (bool) var toast_on_no_effect:bool = true

export (int, 0, 100) var percent_hp_heal_per_stack:int = 0
export (int) var absolute_hp_heal_per_stack:int = 0
export (int) var stack_to_ap:int = 0
export (String) var ap_change_toast:String = ""

export (int, "User", "Target") var effect_recipient:int = 0

func _should_purge_effect(effect, purge_status_effects, purge_walls_of_type):
	return purge_status_effects.has(effect) or (effect.is_decoy and purge_walls_of_type.has(effect.elemental_type))

func _execute(battle, user, _argument, attack_params):
	var targets = attack_params.targets
	if targets.size() == 0:
		if target_type != TargetType.TARGET_NONE:
			battle.queue_animate_turn_failed()
			return 
		else :
			targets = [user]
	
	launch_attack(battle, user, targets, attack_params, Bind.new(self, "contact"))

func contact(battle, user, target, _damage, attack_params):
	
	var purge_status_effects = attack_params.get("purge_status_effects", self.purge_status_effects)
	var purge_walls_of_type = attack_params.get("purge_walls_of_type", self.purge_walls_of_type) 
	if purge_status_effects.size() + purge_walls_of_type.size() > 0:
		var num_removed:int = 0
		var stacks:int = 0
		for effect_node in target.status.get_effects():
			var dur = 1
			if effect_node.has_duration():
				dur = effect_node.get_duration()
			if _should_purge_effect(effect_node.effect, purge_status_effects, purge_walls_of_type) and effect_node.remove():
				stacks += dur
				num_removed += 1

		var recipient = user
		if effect_recipient == 1:
			recipient = target

		if num_removed > 0:
			if percent_hp_heal_per_stack + absolute_hp_heal_per_stack > 0:
				var hp = int(max(1, recipient.status.max_hp * percent_hp_heal_per_stack / 100 + absolute_hp_heal_per_stack) * stacks)
				recipient.get_controller().heal(hp)
			
			if stack_to_ap != 0:
				var ap_change = round(stacks / stack_to_ap)
				if ap_change > 0:
					ap_change = min(ap_change, recipient.status.max_ap - recipient.status.ap)
				else:
					ap_change = min(ap_change, recipient.status.ap)
				recipient.status.change_ap(ap_change, ap_change_toast)

				battle.queue_status_update(recipient, false)

			if purge_status_effects_toast != "":
				var toast = battle.create_toast()
				toast.setup_text(purge_status_effects_toast)
				battle.queue_play_toast(toast, target.slot)
		elif toast_on_no_effect:
			var toast = battle.create_toast()
			toast.setup_text("BATTLE_TOAST_NO_EFFECT")
			battle.queue_play_toast(toast, target.slot)

func get_effect_hint(_user, target):
	var total = Vector3()
	for effect in target.status.get_effects():
		if effect.effect.is_removable and _should_purge_effect(effect.effect, self.purge_status_effects, self.purge_walls_of_type):
			if effect.effect.is_buff:
				total.y += 1
			if effect.effect.is_debuff:
				total.z += 1
	return total
