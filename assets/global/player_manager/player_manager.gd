extends Node

signal upgrade_changed(upgrade_type: Upgrade.UpgradeType, new_level: int)
signal money_changed(new_amount: int)

const SAVE_PATH := "user://player_data.tres" #i think this is right? we'll have to figure this out but seems simple enough

var data: PlayerData

#base funct

func _ready() -> void:
	data = load_from_disk()
	if data == null:
		data = PlayerData.new()
		
func add_money(amount: int) -> void:
	data.money += amount
	money_changed.emit(data.money)

	# TODO: re-enable once AudioManager + sfx streams are ported
	#if amount < 200:
		#AudioManager.play_sfx(money_small_sfx)
	#else:
		#AudioManager.play_sfx(money_big_sfx)

func spend_money(amount: int) -> bool:
	if data.money < amount:
		return false
	data.money -= amount
	money_changed.emit(data.money)
	return true
	
func get_upgrade_level(type: Upgrade.UpgradeType) -> int:
	return data.upgrades.get(type, 0) #i mean, do we need this? or can we just do data.upgrades.get from the consumer. maybe we keep this just in case for calcs later, safest option

func set_upgrade_level(type: Upgrade.UpgradeType, level: int) -> void:
	data.upgrades[type] = level
	upgrade_changed.emit(type, level)
	#AudioManager.play_sfx(item_pickup_sfx)
	
func trigger_event(event: PlayerData.GameEvent):
	data.events_triggered[event] = null # value is meaningless. we will just be checking that key exists

func has_event_triggered(event: PlayerData.GameEvent) -> bool:
	return data.events_triggered.has(event)

# like has_event_triggered but clears the flag so it can re-arm
func consume_event(event: PlayerData.GameEvent) -> bool:
	if data.events_triggered.has(event):
		data.events_triggered.erase(event)
		return true
	return false
	
#save functionality

func save_to_disk() -> void:
	ResourceSaver.save(data, SAVE_PATH)

func load_from_disk() -> PlayerData:
	if ResourceLoader.exists(SAVE_PATH):
		#need to force a reload without cached data, otherwise we can save fish in the same day, quit, then return and still have the fish.
		return ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PlayerData
	return null

func has_save() -> bool:
	return ResourceLoader.exists(SAVE_PATH)

func new_game() -> void:
	data = PlayerData.new()
	
	#PauseMenu._refresh()
	money_changed.emit(data.money)
