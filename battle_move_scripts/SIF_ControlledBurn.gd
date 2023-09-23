extends "res://data/battle_move_scripts/GenericAttack.gd"

const HealingLeaf = preload("res://data/status_effects/healing_leaf.tres")

func _create_damage(battle, user, target, damage_params:Dictionary)->Damage:
	var damage = ._create_damage(battle, user, target, damage_params)
	
	var effect_status = user.status.get_effect_node(HealingLeaf)
	var effect_amount = effect_status.amount if effect_status else 1
	damage.damage *= effect_amount
	
	return damage

func notify(fighter, id:String, args):
	#if id == "launch_attack_ending" and args.move == self and args.fighter == fighter:
	#	var effect_status = fighter.status.get_effect_node(HealingLeaf)
	#	if effect_status:
	#		fighter.battle.queue_animation(Bind.new(fighter, "animate_vfx_sequence", [hit_vfx, elemental_types]))
	#		effect_status.remove()

	return .notify(fighter, id, args)

func launch_attack(battle, user, targets:Array, attack_params = {}, on_contact = null):
	
	.launch_attack(battle, user, targets, attack_params, on_contact)
	
	var effect_status = user.status.get_effect_node(HealingLeaf)
	if effect_status:
		battle.queue_animation(Bind.new(user, "animate_vfx_sequence", [hit_vfx, elemental_types]))
		effect_status.remove()
