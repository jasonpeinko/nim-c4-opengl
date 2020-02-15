import nimgl/[opengl]
import glm
import ./geometry
import ./program

type
  DebugVertex* {.packed.} = object
    pos: Vec2f
    color: Vec4f
    
  DebugDraw* = object
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

method begin*(self: ref DebugDraw) {.base.} =
  var color = vec4f(1.0, 0.0, 1.0, 1.0)
  glUseProgram(self.program)
  glUniform4fv(0, 1, cast[ptr GLfloat](color.unsafeAddr))

const defaultColor = vec4f(1.0, 1.0, 0.0, 1.0)
method rect*(self: ref DebugDraw, proj: Mat4f, pos: Vec2f, size: Vec2f, color = defaultColor) {.base.}= 
  var trans = mat4f().translate(vec3f(pos, 0)).scale(vec3f(size, 1.0))
  var p = proj*trans
  glUniformMatrix4fv(1, 1, false, cast[ptr GLFloat](p.unsafeAddr))
  self.unitRect.renderLineLoop()
  
method circle*(self: ref DebugDraw, proj: Mat4f, center: Vec2f, radius: float32) = 
  var trans = mat4f().translate(vec3f(center, 0)).scale(vec3f(radius, radius, 1.0))
  var p = proj*trans
  glUniformMatrix4fv(1, 1, false, cast[ptr GLFloat](p.unsafeAddr))
  self.unitCircle.renderLineLoop()

proc newDebugDraw*: auto =
  result = (ref DebugDraw)()
  result.program = load_program("flat")
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
