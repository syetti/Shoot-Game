shader_type canvas_item;

uniform float dist : hint_range(0.0, 64.0) = 4.0;
uniform float softness : hint_range(0.0, 16.0) = 2.0;
uniform float angle : hint_range(0.0, 360.0) = 45.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform bool global_direction = true;

// Only needed if you use the Sprite2D's flip_h / flip_v checkboxes.
// (Using negative scale instead needs neither; see notes.)
uniform bool flip_h = false;
uniform bool flip_v = false;

varying vec2 main_uv;
varying vec2 shadow_uv;
varying vec4 modulate_color;
// Current frame's rect in sheet UV space, derived in vertex()
varying flat vec2 uv_min;
varying flat vec2 uv_max;

float in_bounds(vec2 uv) {
	vec2 s = step(uv_min, uv) - step(uv_max, uv);
	return s.x * s.y;
}

float sample_alpha(sampler2D tex, vec2 uv) {
	return texture(tex, uv).a * in_bounds(uv);
}

void vertex() {
	modulate_color = COLOR;

	// Before padding, VERTEX is the frame's corner in local pixels (centered Sprite2D),
	// so the frame size in UV space is just its pixel size * TEXTURE_PIXEL_SIZE.
	vec2 corner = sign(VERTEX);                       // geometric corner: -1 or +1
	vec2 fsize = 2.0 * abs(VERTEX) * TEXTURE_PIXEL_SIZE;

	// Which UV corner sits at this vertex (flipped axes swap it)
	vec2 flip = vec2(flip_h ? -1.0 : 1.0, flip_v ? -1.0 : 1.0);
	vec2 uv_corner = corner * flip;

	// Recover the frame rect from this vertex's own UV (identical for all 4 vertices)
	vec2 center = UV - uv_corner * fsize * 0.5;
	vec2 eps = TEXTURE_PIXEL_SIZE * 0.01;             // guards against float rounding at the edge
	uv_min = center - fsize * 0.5 - eps;
	uv_max = center + fsize * 0.5 + eps;

	// Expand quad and UV by the same number of texture pixels
	float total_pad = dist + softness * 2.0;
	VERTEX += corner * total_pad;
	main_uv = UV + uv_corner * total_pad * TEXTURE_PIXEL_SIZE;

	float rad = radians(angle);
	vec2 dir = vec2(cos(rad), sin(rad));
	if (global_direction) {
		dir = normalize((inverse(MODEL_MATRIX) * vec4(dir, 0.0, 0.0)).xy);
	}

	shadow_uv = main_uv - dir * flip * dist * TEXTURE_PIXEL_SIZE;
}

void fragment() {
	float shadow_alpha = 0.0;

	if (softness <= 0.01) {
		shadow_alpha = sample_alpha(TEXTURE, shadow_uv);
	} else {
		vec2 b = TEXTURE_PIXEL_SIZE * softness;

		shadow_alpha += sample_alpha(TEXTURE, shadow_uv) * 4.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(b.x, 0.0)) * 2.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv - vec2(b.x, 0.0)) * 2.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(0.0, b.y)) * 2.0;
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv - vec2(0.0, b.y)) * 2.0;

		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2( b.x,  b.y));
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(-b.x,  b.y));
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2( b.x, -b.y));
		shadow_alpha += sample_alpha(TEXTURE, shadow_uv + vec2(-b.x, -b.y));

		shadow_alpha /= 16.0;
	}

	float sh_a = shadow_color.a * shadow_alpha * modulate_color.a;
	vec4 main_col = texture(TEXTURE, main_uv) * in_bounds(main_uv) * modulate_color;

	float out_a = main_col.a + sh_a * (1.0 - main_col.a);
	vec3 out_rgb = (main_col.rgb * main_col.a + shadow_color.rgb * sh_a * (1.0 - main_col.a)) / max(out_a, 0.0001);

	COLOR = vec4(out_rgb, out_a);
}