shader_type canvas_item;

uniform float dist : hint_range(0.0, 64.0) = 4.0;
uniform float softness : hint_range(0.0, 16.0) = 2.0;
uniform float angle : hint_range(0.0, 360.0) = 45.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform bool global_direction = true;

varying vec2 main_uv;
varying vec2 shadow_uv;
varying vec4 modulate_color;

// Returns 1.0 inside [0, 1] UV bounds, 0.0 outside (prevents texture repeat/clamping)
float in_bounds(vec2 uv) {
	vec2 s = step(vec2(0.0), uv) - step(vec2(1.0), uv);
	return s.x * s.y;
}

// Samples texture alpha safely within UV bounds
float sample_alpha(sampler2D tex, vec2 uv) {
	return texture(tex, uv).a * in_bounds(uv);
}

void vertex() {
	// Capture node modulate / self_modulate color
	modulate_color = COLOR;
	
	// Calculate total pixel padding needed for both offset and blur radius
	float total_pad = dist + softness * 2.0;
	vec2 pad_uv = TEXTURE_PIXEL_SIZE * total_pad;
	
	// Expand vertex outward from center regardless of Sprite2D pivot/centered setting
	VERTEX += sign(UV - 0.5) * total_pad;
	
	// Remap UV so the original sprite remains stationary in the center
	vec2 scale = 1.0 + pad_uv * 2.0;
	main_uv = (UV - 0.5) * scale + 0.5;
	
	// Calculate shadow offset direction
	float rad = radians(angle);
	vec2 dir = vec2(cos(rad), sin(rad));
	
	if (global_direction) {
		// Keep shadow angle consistent in world space even when the sprite rotates
		dir = normalize((vec4(dir, 0.0, 0.0) * MODEL_MATRIX).xy);
	}
	
	shadow_uv = main_uv - dir * TEXTURE_PIXEL_SIZE * dist;
}

void fragment() {
	// 1. Sample shadow alpha (with optional 9-tap Gaussian-like blur)
	float shadow_alpha = 0.0;
	
	if (softness <= 0.01) {
		shadow_alpha = sample_alpha(TEXTURE, shadow_uv);
	} else {
		vec2 blur_step = TEXTURE_PIXEL_SIZE * softness;
		
		// Center sample (weight 4)
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv) * 4.0;
		
		// Axis samples (weight 2 each)
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(blur_step.x, 0.0)) * 2.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv - vec2(blur_step.x, 0.0)) * 2.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(0.0, blur_step.y)) * 2.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv - vec2(0.0, blur_step.y)) * 2.0;
		
		// Diagonal samples (weight 1 each)
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(blur_step.x, blur_step.y));
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(-blur_step.x, blur_step.y));
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(blur_step.x, -blur_step.y));
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(-blur_step.x, -blur_step.y));
		
		shadow_alpha /= 16.0;
	}
	
	vec4 sh_col = vec4(shadow_color.rgb, shadow_color.a * shadow_alpha);
	
	// 2. Sample main sprite color safely within [0, 1] bounds
	vec4 main_col = texture(TEXTURE, main_uv) * in_bounds(main_uv) * modulate_color;
	
	// 3. Proper Porter-Duff "Source Over" alpha compositing (prevents dark fringes)
	float out_a = main_col.a + sh_col.a * (1.0 - main_col.a);
	vec3 out_rgb = mix(sh_col.rgb * sh_col.a, main_col.rgb, main_col.a) / max(out_a, 0.0001);
	
	COLOR = vec4(out_rgb, out_a);
}