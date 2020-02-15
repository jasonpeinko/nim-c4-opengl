import nimgl/[opengl]
import sequtils
import glm

type
  Geometry* = tuple[vao, vbo, ebo: uint32, count: uint32]

proc triangleStrip*(n: int): seq[uint32] = 
  return toSeq(0.uint32..(n-1).uint32)
proc lineIndex*(n: int): seq[uint32] = 
  return toSeq(0.uint32..(n-1).uint32)

proc createGeometry*(verts: openArray[Vec2f], makeIndicies: proc) : Geometry =
  result = (0.uint32, 0.uint32, 0.uint32, 0.uint32)
  var indicies = makeIndicies(verts.len)
  glGenBuffers(1, result.vbo.addr)
  glGenBuffers(1, result.ebo.addr)
  glGenVertexArrays(1, result.vao.addr)
  result.count = indicies.len.uint32
  glBindVertexArray(result.vao)
  glBindBuffer(GL_ARRAY_BUFFER, result.vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.ebo)

  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * verts.len*2), verts[0].unsafeAddr, GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, cint(cuint.sizeof * indicies.len), indicies[0].addr, GL_STATIC_DRAW)

  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0'u32, 2, EGL_FLOAT, false, cfloat.sizeof * 2, nil)

proc renderTriangleStrip*(self: Geometry) =
  glBindVertexArray(self.vao)
  glDrawElements(GL_TRIANGLE_STRIP, self.count.cint, GL_UNSIGNED_INT, nil)

proc renderLines*(self: Geometry) =
  glBindVertexArray(self.vao)
  glDrawElements(GL_LINES, self.count.cint, GL_UNSIGNED_INT, nil)

proc renderLineLoop*(self: Geometry) =
  glBindVertexArray(self.vao)
  glDrawElements(GL_LINE_LOOP, self.count.cint, GL_UNSIGNED_INT, nil)