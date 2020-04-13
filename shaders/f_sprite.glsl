#version 330 core
out vec4 FragColor;
in vec4 fColor;
in vec2 TexCoord;

uniform sampler2D uTexture;
uniform vec4 uColor = vec4(1.0, 1.0, 1.0, 1.0);

void main() {
//   FragColor = uColor;
    vec4 sample = texture(uTexture, TexCoord);
    // FragColor = vec4(uColor.r, uColor.g, TexCoord.x, TexCoord.y);
    FragColor = sample;
    // FragColor = vec4(TexCoord, 0, 1);
}