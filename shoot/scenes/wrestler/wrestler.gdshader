shader_type canvas_item;

// Pass these variables in from your player script
uniform vec2 velocity = vec2(0.0, 0.0);
uniform float smear_strength : hint_range(0.0, 5.0) = 0.5;
uniform float smear_fade : hint_range(0.0, 2.0) = 1.0;

void vertex() {
	// Only smear trailing vertices (moving away from velocity direction)
	float dot_product = dot(normalize(VERTEX), normalize(velocity));
	
	if (dot_product < 0.0) {
		// Stretch the vertex backward based on speed
		VERTEX -= velocity * smear_strength;
	}
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Determine trailing edge using UV alignment
	float trail_fade = dot(normalize(UV - vec2(0.5)), normalize(velocity));
	
	// Smoothly fade out the stretched pixels
	if (trail_fade < 0.0) {
		tex_color.a *= 1.0 - (abs(trail_fade) * smear_fade);
	}
	
	COLOR = tex_color;
}
