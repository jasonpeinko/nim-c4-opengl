import nimgl/[glfw, opengl, imgui]
import nimgl/imgui/[impl_opengl, impl_glfw]
import chronicles

type
  Graphics* = object
    window*: GLFWWindow


proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  info "key pressed", key=key, scancode=scancode, action=action, mods=mods
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    info "escape pressed, closing"
    window.setWindowShouldClose(true)  

proc createAndInitGraphcis*(width, height:int32, title: string): Graphics =
  info "Starting GLFW and creating window"
  assert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(width, height, title)
  if w == nil:
    error "Failed to initialize window"
    quit(-1)

  discard w.setKeyCallback(keyProc)
  w.makeContextCurrent()

  info "Initialize opengl"
  assert glInit()

  let context = igCreateContext()

  assert igGlfwInitForOpenGL(w, true)
  assert igOpenGL3Init()

  igStyleColorsDark()

  return Graphics(window:w)


method dispose*(self: Graphics){.base.} =
  self.window.destroyWindow()
  glfwTerminate()