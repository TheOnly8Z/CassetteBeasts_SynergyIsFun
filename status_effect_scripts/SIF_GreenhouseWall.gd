extends WallStatus

export (int) var heal_amp:int = 30

func notify(node, id:String, args):
	print(node)
	if id == "heal_starting" and heal_amp > 0 and args.fighter == node.fighter:
		args.heal_amount = round(args.heal_amount * (1.0 + (heal_amp / 100.0)))

	return .notify(node, id, args)
