attribute float size;
attribute float effectStrength;
varying   vec3  vColor;
varying   float vEffectStrength;
uniform   float morphSizeFactor;

void main(){
  vColor = color;
  vEffectStrength = effectStrength;
  vec4 mv = modelViewMatrix * vec4(position,1.0);
  float scale = 1.0 - vEffectStrength * morphSizeFactor;
  gl_PointSize = size * scale * (400.0 / -mv.z);
  gl_Position  = projectionMatrix * mv;
} 