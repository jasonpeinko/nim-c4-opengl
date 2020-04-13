import glm
import nimPNG
import nimgl/[opengl, glfw]
import os
import chronicles as log
import ../video/program
import ../video/geometry
import ../resources

type 
  Mesh* = tuple[vao, vbo: GLuint]

  Sprite* = ref object
    min*: Vec2f
    max*: Vec2f
    mesh*: Mesh
    vertex, fragment, program: uint32
    uColor, uMVP: int32
    texture*: GLuint
    image*: ImageResource
    # program*: ShaderProgram

type PositionColorVertex {.packed, pure.} = object
  x*, y*, z*: float32
  color*: uint32

method render*(self: Sprite, mvp: Mat4f) =
  # var mvp = ortho(-2f, 2f, -1.5f, 1.5f, -1f, 1f)
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, self.texture)
  glBindVertexArray(self.mesh.vao)
  var color = vec4(0.50f, 0.205f, 0.50f, 1)
  glUseProgram(self.program)
  glUniform4fv(self.uColor, 1, cast[ptr GLFloat](color.unsafeAddr))
  glUniformMatrix4fv(self.uMVP, 1, false, cast[ptr GLFloat](mvp.unsafeAddr))
  var loc = glGetUniformLocation(self.program.uint32, "uTexture")
  glUniform1i(loc, 0)

  glDrawArrays(GL_TRIANGLES, 0, 6)
  glBindVertexArray(0)

method init*(self: Sprite) =
  # var vertexData = [
  #   vec2f(0, 0),
  #   vec2f(0, 0),
  #   vec2f(128, 0),
  #   vec2f(1, 0),
  #   vec2f(0, 128),
  #   vec2f(0, 1),

  #   vec2f(128, 0),
  #   vec2f(1, 0),
  #   vec2f(128, 128),
  #   vec2f(1, 1),
  #   vec2f(0, 128),
  #   vec2f(0, 1)
  # ]
  var vertexData = [
    vec2f(0, 128),
    vec2f(0, 1/16),
    vec2f(128, 0),
    vec2f(1/16, 0),
    vec2f(0, 0),
    vec2f(0, 0),

    vec2f(0, 128),
    vec2f(0, 1/16),
    vec2f(128, 128),
    vec2f(1/16, 1/16),
    vec2f(128, 0),
    vec2f(1/16, 0)
  ]
  info "init sprite"
  self.mesh = (vao: 0.GLuint, vbo: 0.GLuint)

  self.image = load_image("sprites/terrain/forrest.png")
  info "img", width=self.image.width, height=self.image.height, format=GL_RGBA.ord, channels=self.image.channels, data=self.image.data.len

  # var width, height, channels: int
  # var data = stbi.load("sprites/terrain/forrest.png", width, height, channels, stbi.Default)
  # info "data", data=data

  glGenTextures(1, self.texture.addr)
  glBindTexture(GL_TEXTURE_2D, self.texture)
  # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint)
  # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)
  # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
  # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)

  glTexImage2D(GL_TEXTURE_2D, 0.GLint, GL_RGBA.ord, self.image.width.GLsizei, self.image.height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, self.image.data[0].addr)
  glGenerateMipmap(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, 0)

  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, self.texture)
  
  glGenBuffers(1, self.mesh.vbo.addr)
  glGenVertexArrays(1, self.mesh.vao.addr)

  glBindVertexArray(self.mesh.vao)
  glBindBuffer(GL_ARRAY_BUFFER, self.mesh.vbo)

  glEnableVertexAttribArray(0)
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(0'u32, 2, EGL_FLOAT, false, cfloat.sizeof * 4, nil)
  glVertexAttribPointer(1'u32, 2, EGL_FLOAT, false, cfloat.sizeof * 4, cast[ptr GLfloat](cfloat.sizeof * 2))

  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * vertexData.len*4), vertexData[0].unsafeAddr, GL_STATIC_DRAW)

  self.program = load_program("sprite")
  var
    log_length: int32
    message = newSeq[char](1024)
    pLinked: int32
  glGetProgramiv(self.program, GL_LINK_STATUS, pLinked.addr);
  if pLinked != GL_TRUE.ord:
    glGetProgramInfoLog(self.program, 1024, log_length.addr, message[0].addr);
    info "shader compiled", message=cast[string](message)
  # self.program = load_program("cubes")
  self.uColor = glGetUniformLocation(self.program.uint32, "uColor")
  self.uMVP   = glGetUniformLocation(self.program.uint32, "uMVP")