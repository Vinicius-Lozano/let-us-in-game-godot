shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color;
uniform float outline_width = 1.0;
uniform float pulse_speed = 1.0; // Speed of the pulse
uniform float min_alpha = 0.0;   // Minimum alpha in pulse
uniform float max_alpha = 1.0;   // Maximum alpha in pulse

void vertex() {
    // THE FIX: Instead of complex screen-space normal math, we simply 
    // grab the vertex and push it slightly outward from the object's center.
    // This entirely bypasses the "split normal" gap on sharp corners.
    // Note: We multiply by 0.05 so an outline_width of '1.0' in the 
    // inspector feels natural and doesn't explode the size of the mesh.
    
    VERTEX = VERTEX * (1.0 + (outline_width * 0.05));
}

void fragment() {
    // Pulse alpha with sine wave over time
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5; // range: 0 to 1
    float alpha = mix(min_alpha, max_alpha, pulse);

    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a * alpha;
}