extends StatusEffect

export (String) var toast_before_heal:String = "STATUS_MIRACLE_SEED_TOAST_BEFORE_HEAL"
export (int, 0, 100) var percent_hp_heal:int = 0
export (int) var absolute_hp_heal:int = 0

func get_stackability(_other):
	return Stackability.NONE

func notify(node, id:String, args):
	if id == "turn_ending" and args.fighter == node.fighter and node.had_round_end:
		seed_heal(node)
	elif id == "attack_contact_ending" and args.target == node.fighter and args.damage.physicality == BattleMove.Physicality.MELEE and args.damage.damage > 0:
		pass_seed(node, args.fighter)

func seed_heal(node):
	var toast = node.battle.create_toast()
	toast.setup_text(toast_before_heal)
	node.battle.queue_play_toast(toast, node.fighter.slot)
	
	var hp = int(max(1, node.fighter.status.max_hp * percent_hp_heal / 100 + absolute_hp_heal))
	node.fighter.get_controller().heal(hp)
	node.battle.queue_status_update(node.fighter, false)
	
	node.remove()

func pass_seed(node, target):
	node.transfer(target)
	node.had_round_end = false 
