extends Node2D

@onready var despawn_timer = $DespawnTimer

func _network_spawn(data: Dictionary) -> void:
	global_position = data['position']
	despawn_timer.start()


func _on_despawn_timer_timeout() -> void:
	SyncManager.despawn(self)
