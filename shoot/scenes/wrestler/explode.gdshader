shader_type particles;

uniform float thrust_speed_x = 500.0;     // Fast forward push
uniform float nozzle_spread_y = 5.0;      // Tighter vertical spawning area
uniform float focus_strength = 4.0;       // Pulls stray particles back to the center line
uniform float noise_shake = 30.0;         // Small high-frequency vibration

// ADDED: repeat_enable so the TIME scroll doesn't run off the edge of the texture
uniform sampler2D noise_texture : repeat_enable; 

// Helper function for 2D random variation
float rand_from_seed(inout uint seed) {
    seed = seed * 747796405u + 289133645u;
    uint result = ((seed >> ((seed >> 28u) + 4u)) ^ seed) * 277803737u;
    return float((result >> 22u) & 0x00ffffffu) / float(0x01000000u);
}

void start() {
    uint seed_x = NUMBER + uint(INDEX);
    uint seed_y = NUMBER * uint(INDEX);
    
    CUSTOM.y = 0.0; 
    
    // ADDED: Move the particle to the node's exact world position when it spawns
    TRANSFORM = EMISSION_TRANSFORM;
    
    // Tight initial speed with minimal variation
    VELOCITY.x = -thrust_speed_x * (0.9 + rand_from_seed(seed_x) * 0.2);
    
    // Razor thin nozzle spawning distribution
    VELOCITY.y = (rand_from_seed(seed_y) * 2.0 - 1.0) * nozzle_spread_y;
    VELOCITY.z = 0.0;
}

void process() {
    CUSTOM.y += DELTA / LIFETIME;
    float life_ratio = CUSTOM.y;
    
    vec2 particle_pos = TRANSFORM[3].xy;
    
    // Sample high-speed scrolling noise for engine vibrations
    vec2 noise_uv = particle_pos * 0.1 - vec2(TIME * 2.0, 0.0);
    vec2 noise = texture(noise_texture, noise_uv).rg;
    
    // FIXED PINCH EFFECT: 
    // Pull towards the node's current Y position, not the world's Y=0
    float relative_y = particle_pos.y - EMISSION_TRANSFORM[3].y;
    VELOCITY.y -= relative_y * focus_strength;
    
    // 2. HIGH FREQUENCY MICRO-TURBULENCE
    VELOCITY.y += (noise.y - 0.5) * noise_shake * DELTA;
    
    // 3. MINIMAL DRAG
    VELOCITY.x -= thrust_speed_x * 0.1 * life_ratio * DELTA;
    
    // 4. SAFE SCALE MANIPULATION
    float scale_factor = max(1.0 - life_ratio, 0.001); 
    
    TRANSFORM[0].xyz = normalize(TRANSFORM[0].xyz + vec3(0.0001, 0.0, 0.0)) * scale_factor;
    TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz + vec3(0.0, 0.0001, 0.0)) * scale_factor;
    TRANSFORM[2].xyz = normalize(TRANSFORM[2].xyz + vec3(0.0, 0.0, 0.0001)) * scale_factor;
}