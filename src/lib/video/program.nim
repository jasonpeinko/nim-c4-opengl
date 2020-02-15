import chronicles
import tables
import nimgl/[opengl]

# proc LoadMemory*(path: string): ptr bgfx_memory_t =
#     var file: File
#     if open(file, path):
#         var size = getFileSize(file)
#         var mem = bgfx_alloc(cast[uint32](size+1))
#         assert size == readBuffer(file, mem.data, size)
#         close(file)
#         let memoryEnd: ptr uint8 = cast[ptr uint8](cast[int](mem.data) + cast[int](size))
#         memoryEnd[] = cast[uint8]('\0')
#         return mem
#     error "failed to read shader file", file=path
#     return nil

# proc ToMemory*(data: var seq[uint8]): ptr bgfx_memory_t = 
#     var size = data.len()
#     var mem = bgfx_alloc(cast[uint32](size+1))
#     copyMem(mem.data, addr(data[0]), size)
#     cast[ptr uint8](cast[int](mem.data) + cast[int](size))[] = cast[uint8]('\0')
#     return mem 

# proc load_shader*(name: string): bgfx_shader_handle_t =
#     info "loading shader",
#         name=name,
#         renderer=bgfx_get_renderer_type()
#     var path = "./src/"
#     case bgfx_get_renderer_type()
#         of BGFX_RENDERER_TYPE_VULKAN:
#             path &= "shaders/glsl/"
#             # path &= "shaders/spirv/"
#         of BGFX_RENDERER_TYPE_OPENGL:
#             path &= "shaders/glsl/"
#         else:
#             raise newException(CatchableError, "Invalid bgfx renderer type")
#     path &= name & ".bin"
#     var mem = LoadMemory(path)
#     echo cast[int](mem)
#     return bgfx_create_shader(mem)
proc statusShader(shader: uint32) =
  var status: int32
  glGetShaderiv(shader, GL_COMPILE_STATUS, status.addr);
  if status != GL_TRUE.ord:
    var
      log_length: int32
      message = newSeq[char](1024)
    glGetShaderInfoLog(shader, 1024, log_length.addr, message[0].addr);
    echo message

type
  ShaderProgram* = uint32
  ShaderManager* = Table[string, uint32]

var shaderManager: ShaderManager = initTable[string, uint32]()

proc load_program*(name: string): ShaderProgram =
  if shaderManager.hasKey(name):
    return shaderManager[name]
  var vertex = glCreateShader(GL_VERTEX_SHADER)
  var vsrc: cstring = """
#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec4 aColor;
uniform mat4 uMVP;
out vec4 fColor;
void main() {
  gl_Position = uMVP * vec4(aPos, 0.0, 1.0);
  fColor = aColor;
}
  """
  glShaderSource(vertex, 1'i32, vsrc.addr, nil)
  glCompileShader(vertex)
  statusShader(vertex)

  var fragment = glCreateShader(GL_FRAGMENT_SHADER)
  var fsrc: cstring = """
#version 330 core
out vec4 FragColor;
uniform vec4 uColor = vec4(1.0, 1.0, 1.0, 1.0);
in vec4 fColor;
void main() {
  FragColor = uColor;
}
  """
  glShaderSource(fragment, 1, fsrc.addr, nil)
  glCompileShader(fragment)
  statusShader(fragment)

  var program = glCreateProgram()
  glAttachShader(program, vertex)
  glAttachShader(program, fragment)
  glLinkProgram(program)

  var count: GLint
  var buff: array[16, GLchar]
  var length: GLsizei
  var size : GLint
  var argType: GLenum
  glGetProgramiv(program, GL_ACTIVE_UNIFORMS, count.addr)
  info "uniforms", count=count
  for i in 0..count:
    var loc = glGetUniformLocation(program, "uColor")
    var loc2 = glGetUniformLocation(program, "uMVP")
    glGetActiveUniform(program, i.GLuint, 16, length.addr, size.addr, argType.addr, buff[0].addr)
    info "uniform", length=length, size=size, name=buff, loc=loc, loc2=loc2
  shaderManager[name] = program
  return program



# proc LoadProgram*(vertData, fragData: var seq[uint8]): bgfx_program_handle_t =
#     return bgfx_create_program(
#         bgfx_create_shader(ToMemory(vertData)),
#         bgfx_create_shader(ToMemory(fragData)),
#         true
#     )

# proc LoadProgram*(vertName: string, fragName: string): bgfx_program_handle_t =
#     return bgfx_create_program(
#         LoadShader(vertName),
#         LoadShader(fragName), 
#         true)
