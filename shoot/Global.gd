extends Node

var player_can_move = false
@onready var announcer = $"/root/Main/UI/Announcer"
@onready var match_time = $"/root/Main/UI/MatchBeginTime"

func _ready() -> void:
	#Global.match_countdown()
	pass
	
func matchStart() -> void:
	#Create Server
	@warning_ignore("standalone_expression")
	multiplayer
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9999, 1)
	multiplayer.multiplayer_peer = peer
	
	#Create Client
	peer = ENetMultiplayerPeer.new()
	peer.create_client("129.32.224.72", 9999)
	
	multiplayer.multiplayer_peer = peer
func match_countdown():
	match_time.show()
	var i: int = 3
	while(i > 0):
		match_time.set_text(str(i))
		await get_tree().create_timer(1).timeout 
		i-=1
	match_time.set_text("SHOOT!")
	await get_tree().create_timer(1).timeout 
	player_can_move = true
	match_time.hide()
	
func takedown(player):
	announcer.show()
	announcer.set_text("TAKEDOWN %s! " % player)
	await get_tree().create_timer(0.3).timeout 

func match_over(winner):
	announcer.show()
	announcer.set_text("MATCH OVER! \n %s HAS WON!", winner)
	
	
