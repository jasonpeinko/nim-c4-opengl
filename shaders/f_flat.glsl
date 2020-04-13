#version 330 core
out vec4 FragColor;
uniform vec4 uColor = vec4(1.0, 1.0, 1.0, 1.0);
in vec4 fColor;
void main() {
  FragColor = uColor;
}