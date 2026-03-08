#Read game data on startup
class_name GameData extends Node

var stats: Dictionary = {}

var speed_walk_speed: int
var speed_shoot_speed: int
var speed_stuffed_speed : int

var moves_shoot_distance: int
var moves_shoot_prep_time: int
var moves_shoot_active_time: int
var moves_shoot_recovery_time: int
var moves_shoot_root_time: int
var moves_shoot_total_frames: int

var moves_block_prep_time: int
var moves_block_active_time: int

var moves_feint_prep_time: int
var moves_feint_active_time: int
var moves_feint_recovery_time: int
var moves_feint_cooldown_time: int

var combat_stunned_time: int
var combat_stuffed_stunned_time : int
var combat_hitstop_frames: int
var combat_knockback_distance: int
var combat_knockback_time: int
var combat_reaction_window_time: int
var combat_hit_anim_time: int

var fatigue_fatigue_bar_max: int
var fatigue_fatigue_charge_time: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var stat_file = FileAccess.open("res://resources/data/character_stats.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(stat_file.get_as_text())
	stats = json.data
	stat_file.close()
	_scan_into_vars()

	pass # Replace with function body.

func _scan_into_vars() -> void:
	speed_walk_speed = stats["speed"]["walk_speed"]
	speed_shoot_speed = stats["speed"]["shoot_speed"]
	speed_stuffed_speed = stats["speed"]["stuffed_speed"]

	moves_shoot_distance = stats["moves"]["shoot"]["distance"]
	moves_shoot_prep_time = stats["moves"]["shoot"]["prep_time"]
	moves_shoot_active_time = stats["moves"]["shoot"]["active_time"]
	moves_shoot_recovery_time = stats["moves"]["shoot"]["recovery_time"]
	moves_shoot_root_time = stats["moves"]["shoot"]["root_time"]
	moves_shoot_total_frames = moves_shoot_prep_time + moves_shoot_active_time + moves_shoot_recovery_time + moves_shoot_root_time

	moves_block_prep_time = stats["moves"]["block"]["prep_time"]
	moves_block_active_time = stats["moves"]["block"]["active_time"]

	moves_feint_prep_time = stats["moves"]["feint"]["prep_time"]
	moves_feint_active_time = stats["moves"]["feint"]["active_time"]
	moves_feint_recovery_time = stats["moves"]["feint"]["recovery_time"]
	moves_feint_cooldown_time = stats["moves"]["feint"]["cooldown_time"]

	combat_stunned_time = stats["combat"]["stunned_time"]
	combat_stuffed_stunned_time = stats["combat"]["stuffed_stunned_time"]
	combat_hitstop_frames = stats["combat"]["hitstop_frames"]
	combat_knockback_distance = stats["combat"]["knockback_distance"]
	combat_knockback_time = stats["combat"]["knockback_time"]
	combat_reaction_window_time = stats["combat"]["reaction_window_time"]
	combat_hit_anim_time = stats["combat"]["hit_anim_time"]

	fatigue_fatigue_bar_max = stats["fatigue"]["fatigue_bar_max"]
	fatigue_fatigue_charge_time = stats["fatigue"]["fatigue__fatigue_charge_time"]
