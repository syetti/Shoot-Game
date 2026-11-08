extends Timer

signal match_timeout
var mins: int
var secs : int
func _ready() -> void:
	var Data : GameData  = GameData.new()
	Data._scan_into_vars()
	wait_time = Data.match_timer_normal_match
	mins = int(wait_time)/60
	secs = int(wait_time) % 60
	start()
	pass 
	
	
func _process(delta: float) -> void:
	mins = int(time_left)/60
	secs = int(time_left) % 60
	%Label.text = str(mins)+":"+ "%02d" % secs
	
func _on_timeout() -> void:
	emit_signal("match_timeout")
