extends ContentInfo

var sif_loaded:bool = false

const MOD_STRINGS:Array = [
	preload("sif_localization.en.translation"),
]

const MODUTILS: Dictionary = {
}

func _init():
	
	# Add translation strings
	for translation in MOD_STRINGS:
		TranslationServer.add_translation(translation)

	Console.register("sif_stickers", {
		"description":"Give stickers from Synergy is Fun", 
		"args":[], 
		"target":[self, "_console_sif_stickers"]
	})

	SceneManager.preloader.connect("singleton_setup_completed", self, "_init_stickers")

func init_content():
	DLC.mods_by_id.cat_modutils.callbacks.connect_scene_ready("res://cutscenes/merchants/TownHall_VendingMachine_InteractionBehavior.tscn", self, "_on_VendingMachine1_ready")

func _on_VendingMachine1_ready(scene: Node) -> void:
	var exchange_menu = scene.get_child(0).get_child(0)
	var sticker_packs = Datatables.load("res://mods/synergy_is_fun/exchanges/booster_packs/").table
	for pack in sticker_packs:
			exchange_menu.exchanges.push_back(sticker_packs[pack])
			print("[SIF] Added Sticker Pack: " + pack)

func _init_stickers():
	if sif_loaded:
		return
		
	var battle_moves = Datatables.load("res://mods/synergy_is_fun/battle_moves/").table

	for move_name in battle_moves:
		_add_sticker(battle_moves[move_name], "sif_" + move_name)

	sif_loaded = true
	print("[SIF] Loaded " + str(battle_moves.size()) + " stickers.")

func _add_sticker(sticker, sticker_id):
	# Add to global move list. Used in dev console, custom battle scene, etc.
	BattleMoves.moves.append(sticker)
	BattleMoves.by_id[sticker_id] = sticker

	# Add to primary sticker bucket. Used for "certain loot tables, Be Random, and AlephNull".
	BattleMoves.all_stickers.append(sticker)

	for tag in sticker.tags:

		# Initializes tag if it's new.
		if not BattleMoves.by_tag.has(tag):
			BattleMoves.by_tag[tag] = []
		BattleMoves.by_tag[tag].push_back(sticker)

		# Add move to the tag pool
		if not BattleMoves.stickers_by_tag.has(tag):
			BattleMoves.stickers_by_tag[tag] = []
		BattleMoves.stickers_by_tag[tag].push_back(sticker)

		# Add move to shop pool, unless tagged unsellable
		if not sticker.tags.has("unsellable"):
			BattleMoves.sellable_stickers.push_back(sticker)
			if not BattleMoves.sellable_stickers_by_tag.has(tag):
				BattleMoves.sellable_stickers_by_tag[tag] = []
			BattleMoves.sellable_stickers_by_tag[tag].push_back(sticker)

	print("[SIF] Added sticker: " + sticker_id)

func _console_sif_stickers(force_rares:bool = false):
	var rand = Random.new()
	for move in BattleMoves.by_tag["sif"]:
		for _i in range(5):
			var rarity = null
			if force_rares:
				var dist = [
					{weight = 0.1, value = BaseItem.Rarity.RARITY_UNCOMMON}, 
					{weight = 0.025, value = BaseItem.Rarity.RARITY_RARE}
				]
				rarity = ItemFactory.rand_rarity(rand, dist)
			var sticker = ItemFactory.create_sticker(move, rand, rarity)
			SaveState.inventory.add_new_item(sticker, 1)
