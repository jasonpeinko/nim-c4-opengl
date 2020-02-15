import strformat
import sequtils
import tables
import glm
import chronicles
import times

import nimgl/[glfw, opengl, imgui]
import nimgl/imgui/[impl_opengl, impl_glfw]

import c4/entities
import c4/threads
import c4/loop
import c4/messages
import ./physics

import ../lib/physics/types
import ../lib/video/[graphics, camera, rect]
import ../lib/video/debug as debug

const WIDTH = 960
const HEIGHT = 540
type
  VideoSystem* = object
    graphics*: Graphics
    camera*: Camera
    debug*: ref DebugDraw
    rect*: GLRect

method init*(self: ref VideoSystem){.base.} =
  info "Initializing Video System"
  self.graphics = createAndInitGraphcis(WIDTH.int32, HEIGHT.int32, "test")


  self.camera = createCamera()
  self.rect = GLRect()
  self.rect.init()
  self.debug = newDebugDraw()

# method render*(self: ref VideoSystem, body: ref Physics2DBody){.base.} =
#   echo "render body"
#   discard

method renderUI*(self: ref VideoSystem){.base.} =
  var now = cpuTime()
  var last {.global.} = cpuTime()
  let frameTime: float32 = now - last
  let time = getTime()
  last = now
  var toMs = 10000.0'f32
  igOpenGL3NewFrame()
  igGlfwNewFrame()
  igNewFrame()

  igBegin("Stats")
  igText("Frame Time: %2.2fms", frameTime*toMs)
  igText("FPS: %3.0f", (1000/frameTime)/toMs)
  igEnd()

  igRender()
  igOpenGL3RenderDrawData(igGetDrawData())
method renderDebugDrawRect*(self: ref VideoSystem, entity: Entity, proj: Mat4f) =
  var dd = entity[ref DebugDrawRect]
  var body = entity[ref Physics2DBody]
  var model = mat4f()
  var proj = self.camera.getProjMatrix(WIDTH, HEIGHT)
  model = model.translate(vec3f(body.position, 0.0))
  # self.debug.rect(proj, body.position, (dd.max-dd.min))
  # debug.setup(proj * model)
  # debug.start(dd.color)
  # debug.rect(dd.min, dd.max, dd.fill)
  self.debug.addRect(dd.min + body.position, dd.max + body.position)

proc renderDebugDrawCircle*(self: ref VideoSystem, entity: Entity, proj: Mat4f) =
  var dd = entity[ref DebugDrawCircle]
  if not entity.has(ref Physics2DBody):
    return
  var body = entity[ref Physics2DBody]
  var proj = self.camera.getProjMatrix(WIDTH, HEIGHT)
  var model = mat4f()
  model = model.translate(vec3f(body.position, 0.0))
  # self.debug.circle(proj, body.position, dd.radius)
  # self.debug.addRect(dd.radius - body.position, dd.radius + body.position)
  self.debug.addCircle(body.position, dd.radius)

method render*(self: ref VideoSystem){.base.} =
  self.debug.clear()
  var view = self.camera.getViewMatrix()
  var proj = self.camera.getProjMatrix(WIDTH, HEIGHT)

  glClearColor(0.3, 0.3, 0.34, 1.0)
  glClear(GL_COLOR_BUFFER_BIT)
  for entity, ddRect in getComponents(ref DebugDrawRect):
    self.renderDebugDrawRect(entity, proj)
  for entity, ddRect in getComponents(ref DebugDrawCircle):
    self.renderDebugDrawCircle(entity, proj)
  self.debug.render(proj)
  self.renderUI()

method update*(self: ref VideoSystem, dt: float){.base.} =
  glfwPollEvents()
  self.render()
  self.graphics.window.swapBuffers()

method process*(self: ref VideoSystem, message: ref Message) {.base.} =
  warn "No rule for processing {message}"

method dispose*(self: ref VideoSystem) {.base.} =
  self.graphics.dispose()

method run*(self: ref VideoSystem) {.base.} =
  loop(frequency=60) do:
    self.update(dt)
    if self.graphics.window.windowShouldClose:
      break
    while true:
      let message = tryRecv()
      if message.isNil:
        break
      self.process(message)
