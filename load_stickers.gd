extends ContentInfo

var sif_loaded:bool = false

var sif_stickers = {
	"sif_weedkiller": preload("res://mods/synergy_is_fun/battle_moves/weedkiller.tres"),
	"sif_shear_force": preload("res://mods/synergy_is_fun/battle_moves/shear_force.tres"),
	"sif_vine_whip": preload("res://mods/synergy_is_fun/battle_moves/vine_whip.tres"),
}

func _init():
	Console.register("sif_stickers", {
		"description":"Give stickers from Synergy is Fun", 
		"args":[], 
		"target":[self, "_console_sif_stickers"]
	})
	SceneManager.preloader.connect("singleton_setup_completed", self, "_init_stickers")

func _init_stickers():
	if sif_loaded:
		return

	for sticker_id in sif_stickers:
			_add_sticker(sif_stickers[sticker_id], sticker_id)

	sif_loaded = true
	print("[SIF] Loaded " + str(sif_stickers.size()) + " stickers.")

func _add_sticker(sticker, sticker_id):
	# Add to global move list. Used in dev console, custom battle scene, etc.
	BattleMoves.moves.append(sticker)
	BattleMoves.by_id[sticker_id] = sticker

	# Add to primary sticker bucket. Used for "certain loot tables, Be Random, and AlephNull".
	BattleMoves.all_stickers.append(sticker)

	for tag in sticker.tags:

		# Initializes tag "since at this point there hasnt been any other stickers loaded yet".
		if not BattleMoves.by_tag.has(tag):
			BattleMoves.by_tag[tag] = []
		BattleMoves.by_tag[tag].push_back(sticker)

		# Add move to the pool
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
