#Script for TESTING DUMMY

extends CharacterBody2D


const SPEED: float = 5.0
const SHOTSPEED: float = 7.0
const STUFFEDSPEED: float = 1.0
var is_blocking: bool = false
var is_shooting: bool = false
var can_shoot: bool = true

var shotbar = 3


func _ready() -> void:
	is_blocking = true
	
	
	
func _physics_process(delta: float) -> void:
	pass
