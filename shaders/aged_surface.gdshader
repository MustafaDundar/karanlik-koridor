shader_type spatial;
// Lightweight world-space wear; authored shader, not an AI-generated PBR map.
uniform vec4 base_color : source_color = vec4(0.25, 0.32, 0.28, 1.0);
uniform bool floor_surface = false;
varying vec3 world_pos;
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898,78.233,43.71))) * 43758.5453); }
float noise(vec3 p) {
    vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    float wear = noise(world_pos*3.5)*0.6 + noise(world_pos*23.0)*0.25 + noise(world_pos*90.0)*0.15;
    vec3 color = base_color.rgb * (0.68 + wear*0.5);
    if (floor_surface) {
        vec2 grid = abs(fract(world_pos.xz*1.25)-0.5);
        float grout = smoothstep(0.475,0.49,max(grid.x,grid.y));
        color *= 1.0-grout*0.65;
    } else {
        color *= mix(0.62,1.0,smoothstep(0.0,1.3,world_pos.y));
        color = mix(color,vec3(0.15,0.14,0.10),smoothstep(0.70,0.82,wear)*0.45);
    }
    ALBEDO = color;
    ROUGHNESS = floor_surface ? 0.68 : 0.94;
}
