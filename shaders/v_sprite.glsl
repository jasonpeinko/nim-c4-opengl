#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aTexCoord;

uniform mat4 uMVP;
out vec4 fColor;
out vec2 TexCoord;
void main() {
  gl_Position = uMVP * vec4(aPos, 0.0, 1.0);
  fColor = vec4(1,1,1,1);
  TexCoord = aTexCoord;
}