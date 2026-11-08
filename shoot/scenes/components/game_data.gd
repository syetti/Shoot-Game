#Read game data on startup
class_name GameData extends Node

var stats: Dictionary = {}

var match_timer_normal_match :int

var speed_walk_speed: int
var speed_shoot_speed: int
var speed_stuffed_speed : int

var moves_buffer_window: int
var moves_shoot_distance: int
var moves_shoot_prep_time: int
var moves_shoot_active_time: int
var moves_shoot_recovery_time: int
var moves_shoot_root_time: int
var moves_shoot_total_frames: int

var moves_block_prep_time: int
var moves_block_active_time: int

var moves_feint_prep_frames: int
var moves_feint_active_frames: int
var moves_feint_recovery_frames: int
var moves_feint_cooldown_frames: int

var combat_stunned_time: int
var combat_stuffed_stunned_time : int
var combat_hitstop_frames: int
var combat_knockback_distance: int
var combat_knockback_time: int
var combat_reaction_window_time: int
var combat_hit_anim_time: int

var fatigue_fatigue_bar_max: int
var fatigue_fatigue_charge_time: int
var fatigue_fatigue_bar_decay_time: int

func _ready() -> void:
	_scan_into_vars()
	pass

func _scan_into_vars() -> void:
	var stat_file = FileAccess.open("res://resources/data/character_stats.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(stat_file.get_as_text())
	stats = json.data["character_stats"]
	stat_file.close()
	
	match_timer_normal_match = stats["match_timer"]["normal_match"]
	
	speed_walk_speed = stats["speed"]["walk_speed"]
	speed_shoot_speed = stats["speed"]["shoot_speed"]
	speed_stuffed_speed = stats["speed"]["stuffed_speed"]
	
	moves_buffer_window = stats["moves"]["buffer_window"]
	moves_shoot_distance = stats["moves"]["shoot"]["shoot_distance"]
	moves_shoot_prep_time = stats["moves"]["shoot"]["prep_time"]
	moves_shoot_active_time = stats["moves"]["shoot"]["active_time"]
	moves_shoot_recovery_time = stats["moves"]["shoot"]["recovery_time"]


	moves_block_prep_time = stats["moves"]["block"]["prep_time"]
	moves_block_active_time = stats["moves"]["block"]["active_time"]

	moves_feint_prep_frames = stats["moves"]["feint"]["prep_frames"]
	moves_feint_active_frames = stats["moves"]["feint"]["active_frames"]
	moves_feint_recovery_frames = stats["moves"]["feint"]["recovery_frames"]
	moves_feint_cooldown_frames = stats["moves"]["feint"]["cooldown_frames"]
	

	combat_stunned_time = stats["combat"]["stunned_time"]
	combat_stuffed_stunned_time = stats["combat"]["stuffed_stun_time"]
	combat_hitstop_frames = stats["combat"]["hitstop_frames"]
	combat_knockback_distance = stats["combat"]["knockback_distance"]
	combat_knockback_time = stats["combat"]["knockback_time"]
	combat_reaction_window_time = stats["combat"]["reaction_window_time"]
	combat_hit_anim_time = stats["combat"]["hit_anim_time"]

	fatigue_fatigue_bar_max = stats["fatigue"]["fatigue_bar_max"]
	fatigue_fatigue_charge_time = stats["fatigue"]["fatigue_charge_time"]
	fatigue_fatigue_bar_decay_time = stats["fatigue"]["fatigue_bar_decay_time"]
