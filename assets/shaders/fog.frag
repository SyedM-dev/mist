#version 120

uniform vec2 resolution; // 720x480
uniform vec2 offset;     // padding in pixels
uniform float scale;     // scale factor
uniform vec2 torch_lights[32];
uniform int num_torches;
uniform float time_sec;
uniform float lorentz_field;

// External snippet 
// Simplex 2D noise
// Source: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}
// End of external snippet.

void main() {
  vec2 virtual_coord = (gl_FragCoord.xy - offset) / scale;

  if (virtual_coord.x < 0.0 || virtual_coord.x > resolution.x ||
      virtual_coord.y < 0.0 || virtual_coord.y > resolution.y) {
    return;
  }

  // tint
  vec3 lf_color = vec3(3.0/255.0, 9.0/255.0, 42.0/255.0);
  vec3 tint = mix(vec3(0.0), lf_color, lorentz_field);

  // radii
  float p_i_radius = mix(100.0, 120.0, lorentz_field);
  float p_o_radius = mix(340.0, 235.0, lorentz_field);

  float t_i_radius = 10.0;
  float t_o_radius = 160.0;

  // player is always at screen center in virtual coords
  vec2 player_screen = vec2(resolution.x / 2.0, resolution.y / 2.0);

  float light_strength = 0.0;

  // Player light
  float d = distance(virtual_coord, player_screen);
  if (d < p_i_radius) {
    light_strength = 1.0;
  } else if (d < p_o_radius) {
    float t = (d - p_i_radius) / (p_o_radius - p_i_radius);
    light_strength = 1.0 - t;
  }

  // Torch lights
  for (int i = 0; i < num_torches; i++) {
    float td = distance(virtual_coord, torch_lights[i]);
    float strength = 0.0;
    if (td < t_i_radius) {
      strength = 1.0;
    } else if (td < t_o_radius) {
      float t = (td - t_i_radius) / (t_o_radius - t_i_radius);
      strength = 1.0 - t;
    }
    light_strength += strength;
  }

  light_strength = clamp(light_strength, 0.0, 1.0);

  // Noise
  float noise = (snoise(virtual_coord / resolution * 3.0 + vec2(time_sec * 0.25, 0)) + 1.0) / 2.0;

  float t = 1.0 - light_strength;
  float alpha = clamp(t * (1.0 + noise), 0.0, 1.0);

  gl_FragColor = vec4(tint, alpha);
}