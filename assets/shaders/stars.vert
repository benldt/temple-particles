attribute float size;
varying   vec3  vColor;

void main(){
  vColor = color;
  vec4 mv = modelViewMatrix * vec4(position,1.0);
  gl_PointSize = size * (300.0 / -mv.z);
  gl_Position  = projectionMatrix * mv;
} 