extends DecoratorAction

signal defeated

export (String) var met_flag:String = ""
export (Array, String) var dialogue:Array = []
export (AudioStream) var dialogue_audio:AudioStream
export (Array, String) var defeat_dialogue:Array = []
export (AudioStream) var defeat_dialogue_audio:AudioStream
export (PackedScene) var defeat_extra:PackedScene

func _ready():
	if Engine.editor_hint:
		return 

	var pawn = get_pawn()
	var encounter = pawn.get_node("EncounterConfig") if pawn.has_node("EncounterConfig") else null

	if encounter and encounter.is_defeated():
		emit_signal("defeated")
	elif encounter:
		encounter.connect("defeated", self, "_on_defeated")
		if pawn.has_node(NodePath("Interaction")):
			pawn.get_node(NodePath("Interaction")).icon_override = preload("res://ui/icons/position_markers/battle_icon.png")

	if met_flag != "":
		$Cutscene.set_flags = [met_flag]
	
	var action = $Cutscene / Selector / Sequence / MainDialogue
	action.messages = dialogue
	action.audio = dialogue_audio
	
	action = $Cutscene / Selector / Sequence / BattleAction
	if not encounter:
		action.queue_free()
	
	action = $Cutscene / Selector / Sequence2 / DefeatDialogue
	action.messages = defeat_dialogue
	action.audio = defeat_dialogue_audio

	if defeat_extra:
		var extra = defeat_extra.instance()
		action.get_parent().add_child_below_node(action, extra)

func _on_defeated():
	emit_signal("defeated")
