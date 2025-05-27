varying vec3  vColor;
varying float vEffectStrength;
uniform float morphBrightnessFactor;

void main(){
  vec2 cxy = 2.0 * gl_PointCoord - 1.0;
  float r  = length(cxy);
  if(r>1.0) discard;

  float alpha = smoothstep(1.0,0.0,r);
  alpha += smoothstep(1.0,0.5,r)*0.5;

  vec3 color = vColor * (1.0 + vEffectStrength * morphBrightnessFactor);
  gl_FragColor = vec4(clamp(color,0.0,1.0), alpha);
} 