import nimgl/[opengl]
import glm
import sequtils
import easygl
import chronicles
import ./geometry
import ./program

type
  DebugVertex* {.packed.} = object
    pos: Vec2f
    color: Vec4f
    
  PrimitiveRenderer* = object
    vao*, vbo*, ebo*: GLuint
    vertices*: seq[Vec2f]
    indices*: seq[GLint]
    sizes*: seq[GLsizei]
    buffered*: bool
    program*: ShaderProgram
  DebugDraw* = object
    renderer*: ref PrimitiveRenderer
    program*: ShaderProgram
    unitRect*: Geometry
    unitCircle*: Geometry
    
  # Components
  DebugDrawable* {.inheritable.} = object
    color*: Vec4f
  DebugDrawRect* = object of DebugDrawable
    min*: Vec2f
    max*: Vec2f
    fill*: bool
  DebugDrawCircle* = object of DebugDrawable
    radius*: float32
    fill*: bool

method addPolygon*(self: ref PrimitiveRenderer, vertices: openArray[Vec2f], color: Vec4f) =
  self.indices.add(self.vertices.len.GLint)
  self.sizes.add(vertices.len.GLsizei)
  self.vertices = self.vertices & @vertices
method buffer*(self: ref PrimitiveRenderer): bool {.base.} =
  self.buffered = true
  if self.vertices.len == 0:
    return false
  glBindVertexArray(self.vao)
  glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
  glBufferData(GL_ARRAY_BUFFER, self.vertices.len*Vec2f.sizeof().GLsizeiptr, self.vertices[0].unsafeAddr, GL_DYNAMIC_DRAW)
  return true
method render*(self: ref PrimitiveRenderer, mode: GLenum, proj: Mat4f) {.base.} =
  if not self.buffer():
    return
  glUseProgram(self.program)
  var color = vec4f(1.0, 0.0, 1.0, 1.0)
  glUniformMatrix4fv(1, 1, false, cast[ptr GLFloat](proj.unsafeAddr))
  glUniform4fv(0, 1, cast[ptr GLfloat](color.unsafeAddr))
  # for i in 0..self.indices.len-1:
  #   let offset = self.indices[i]
  #   let size = self.sizes[i]
  #   glDrawArrays(GL_LINE_LOOP, offset.GLint, size.GLsizei)
  # Not working for whatever reason, should be the same as above?
  glMultiDrawArrays(
    GL_LINE_LOOP,
    cast[ptr GLint](self.indices[0].addr),
    cast[ptr GLsizei](self.sizes[0].addr),
    self.indices.len.GLsizei
  )
method clear*(self: ref PrimitiveRenderer) =
  self.vertices = @[]
  self.sizes = @[]
  self.indices = @[]

method addRect*(self: ref DebugDraw, min, max: Vec2f) =
  self.renderer.addPolygon([
    vec2f(min.x, min.y),
    vec2f(max.x, min.y),
    vec2f(max.x, max.y),
    vec2f(min.x, max.y),
  ], vec4f(1.0f, 0, 1.0, 1.0))
method addCircle*(self: ref DebugDraw, center: Vec2f, radius: float32, resolution: int = 10) = 
  var verts: seq[Vec2f] = @[]
  for i in 0..resolution-1:
    var theta = 2 * PI * (i/resolution)
    verts.add(center + vec2f(cos(theta), sin(theta)) * radius)
  self.renderer.addPolygon(verts, vec4f(1.0, 1.0, 0.0, 1.0))
method clear*(self: ref DebugDraw) {.base.} =
  self.renderer.clear()
  var color = vec4f(1.0, 0.0, 1.0, 1.0)
  glUseProgram(self.program)
  glUniform4fv(0, 1, cast[ptr GLfloat](color.unsafeAddr))
method render*(self: ref DebugDraw, proj: Mat4f){.base.} =
  self.renderer.render(GL_LINE_LOOP, proj)
  # self.renderer.render(GL_TRIANGLE_FAN, proj)
method rect*(self: ref DebugDraw, proj: Mat4f, pos: Vec2f, size: Vec2f) {.base.}= 
  var trans = mat4f().translate(vec3f(pos, 0)).scale(vec3f(size, 1.0))
  var p = proj*trans
  var color = vec4f(1.0, 0.0, 1.0, 1.0)
  glUniformMatrix4fv(1, 1, false, cast[ptr GLFloat](p.unsafeAddr))
  self.unitRect.renderLineLoop()
  
var color = vec4f(1.0, 0.0, 1.0, 1.0)
method circle*(self: ref DebugDraw, proj: Mat4f, center: Vec2f, radius: float32) = 
  var trans = mat4f().translate(vec3f(center, 0)).scale(vec3f(radius, radius, 1.0))
  var p = proj*trans
  glUniformMatrix4fv(1, 1, false, cast[ptr GLFloat](p.unsafeAddr))
  # glUniform4fv(1, 1, cast[ptr GLfloat](color.unsafeAddr))
  self.unitCircle.renderLineLoop()

proc newPrimitiveRenderer*: auto =
  result = (ref PrimitiveRenderer)()
  result.program = load_program("flat")
  glGenVertexArrays(1, result.vao.addr)
  glGenBuffers(1, result.vbo.addr)
  glBindVertexArray(result.vao)
  glBindBuffer(GL_ARRAY_BUFFER, result.vbo)

  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0'u32, 2, EGL_FLOAT, false, cfloat.sizeof * 2, nil)
proc newDebugDraw*: auto =
  result = (ref DebugDraw)()
  result.program = load_program("flat")
  result.renderer = newPrimitiveRenderer()
  result.unitRect = createGeometry([
      vec2f(0, 0),
      vec2f(1, 0),
      vec2f(1, 1),
      vec2f(0, 1),
    ], lineIndex)

  var verts: seq[Vec2f] = @[]
  for i in 0..14:
    var theta = 2 * PI * (i/15)
    verts.add(vec2f(cos(theta), sin(theta)) * 1.0)
  result.unitCircle = createGeometry(verts, lineIndex)

proc start*(color: Vec4f) =
  glUniform4fv(1, 1, cast[ptr GLfloat](color.unsafeAddr))

proc setup*(proj: Mat4f) =
  var program = load_program("flat")
  glUseProgram(program)
  glUniformMatrix4fv(0, 1, false, cast[ptr GLFloat](proj.unsafeAddr))

proc rect*(min, max: Vec2f, fill: bool = true) =
  if fill:
    var ts = createGeometry([
      vec2f(min.x, min.y),
      vec2f(max.x, min.y),
      vec2f(min.x, max.y),
      vec2f(max.x, max.y)
    ], triangleStrip)
    ts.renderTriangleStrip()
  else:
    var ts = createGeometry([
      vec2f(min.x, min.y),
      vec2f(max.x, min.y),
      vec2f(max.x, max.y),
      vec2f(min.x, max.y),
    ], lineIndex)
    ts.renderLineLoop()

proc lines*(verts: openArray[Vec2f]) =
  var ts = createGeometry(verts, lineIndex)
  ts.renderLines()

proc circle*(radius: float32, resolution: int = 20, fill: bool = true) = 
  var verts: seq[Vec2f] = @[]
  for i in 0..resolution:
    var theta = 2 * PI * (i/resolution)
    verts.add(vec2f(cos(theta), sin(theta)) * radius)
  var ts = createGeometry(verts, lineIndex)
  ts.renderLineLoop()