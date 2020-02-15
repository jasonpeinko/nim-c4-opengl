import glm
import nimgl/[opengl, glfw]
import os
import chronicles as log
import ./program
import ./geometry

type 
  Mesh* = tuple[vbo, vao, ebo: uint32]
  GLRect* = ref object
    min*: Vec2f
    max*: Vec2f
    mesh*: Geometry
    vertex, fragment, program: uint32
    uColor, uMVP: int32
    # program*: ShaderProgram

type PositionColorVertex {.packed, pure.} = object
  x*, y*, z*: float32
  color*: uint32

method render*(self: GLRect, mvp: Mat4f) =
  var mvp = ortho(-2f, 2f, -1.5f, 1.5f, -1f, 1f)
  var color = vec3(0.50f, 0.205f, 0.50f)
  glUseProgram(self.program)
  glUniform3fv(self.uColor, 1, color.caddr)
  glUniformMatrix4fv(self.uMVP, 1, false, mvp.caddr)

  self.mesh.renderTriangleStrip()

method init*(self: GLRect) =
  var vertexData = [
    vec2f(-0.3f, 0.3f),
    vec2f(0.3f, 0.3f),
    vec2f(-0.3f, -0.3f),
    vec2f(0.3f, -0.3f),
  ]
  self.mesh = createGeometry(vertexData, triangleStrip)
  self.program = load_program("flat")
  var
    log_length: int32
    message = newSeq[char](1024)
    pLinked: int32
  glGetProgramiv(self.program, GL_LINK_STATUS, pLinked.addr);
  if pLinked != GL_TRUE.ord:
    glGetProgramInfoLog(self.program, 1024, log_length.addr, message[0].addr);
    info "shader compiled", message=message
  # self.program = load_program("cubes")
  self.uColor = glGetUniformLocation(self.program.uint32, "uColor")
  self.uMVP   = glGetUniformLocation(self.program.uint32, "uMVP")