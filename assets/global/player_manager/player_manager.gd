extends Node

signal upgrade_changed(upgrade_type: Upgrade.UpgradeType, new_level: int)
signal health_changed(new_health: int)
signal player_died
signal score_changed(new_score: int)

@export var death_sound: SfxEvent

const SAVE_PATH := "user://hiscore.dat" #i think this is right? we'll have to figure this out but seems simple enough

var data: PlayerData
var hiscore: int = 0

#base funct

func _ready() -> void:
	hiscore = load_from_disk()
	if data == null:
		data = PlayerData.new()
		
func lose_health(amount: int = 1) -> void:
	if data.health <= 0:
		return # already dead, don't emit player_died twice
	data.health = maxi(data.health - amount, 0)
	health_changed.emit(data.health)
	if data.health == 0:
		AudioManager.play_sfx(death_sound)
		player_died.emit()

func kill() -> void:
	lose_health(data.health)

func gain_health(amount: int = 1) -> void:
	data.health = mini(data.health + amount, data.max_health)
	health_changed.emit(data.health)

func add_score(amount: int) -> void:
	data.score += amount
	score_changed.emit(data.score)
	
func get_score() -> int:
	return data.score

func get_hiscore() -> int:
	return hiscore

func set_hiscore(score: int):
	hiscore = score
	save_hiscore()
	
func save_hiscore():
	save_to_disk()
	
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
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(hiscore)
		file.close() 

# Loads from the browser's IndexedDB storage
func load_from_disk() -> int:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var value = file.get_32()
			file.close()
			return value
			
	return 0 

func new_game() -> void:
	data = PlayerData.new()
	
	#PauseMenu._refresh()
	health_changed.emit(data.health)
	score_changed.emit(data.score)
