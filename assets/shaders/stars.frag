varying vec3 vColor;

void main(){
  vec2 cxy = 2.0 * gl_PointCoord - 1.0;
  float r  = length(cxy);
  if(r>1.0) discard;

  float a = pow(1.0 - r,3.0);
  a *= 0.8 + 0.2 * sin(r * 10.0);
  gl_FragColor = vec4(vColor, a * 0.9);
} 