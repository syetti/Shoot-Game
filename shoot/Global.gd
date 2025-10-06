extends Node

func _ready() -> void:
	#Global.match_countdown()
	pass

func match_countdown():
	$"/root/Main/UI/MatchBeginTime".show()
	var i: int = 3
	while(i > 0):
		$"/root/Main/UI/MatchBeginTime".set_text(str(i))
		await get_tree().create_timer(1).timeout 
		i-=1
	$"/root/Main/UI/MatchBeginTime".set_text("SHOOT!")
	await get_tree().create_timer(1).timeout 
	$"/root/Main/UI/MatchBeginTime".hide()
	
	
