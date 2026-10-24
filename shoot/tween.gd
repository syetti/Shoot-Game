extends Sprite2D

var tween:Tween = create_tween()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween.set_trans(Tween.TRANS_QUART) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"modulate:a",0.0,0.8)
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
