extends Label

@onready var timer = $timer


func _process(delta: float) -> void:
	if visible:
		timer.wait_ticks = 10
		timer.start()
		
	
func _on_timer_timeout() -> void:
	hide()
