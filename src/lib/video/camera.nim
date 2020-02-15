import glm


type
    Camera* = object
        position, target, up: Vec3f
        fov, near, far: float32
        ortho: bool

proc createCamera*(): Camera =
    result = Camera(
        position: vec3f(0, 0, -4.0),
        target: vec3f(0, 0, 0.0),
        up: vec3f(0.0, 1.0, 0.0),
        fov: 60.0,
        near: -10.0,
        far: 10.0,
        ortho: true
    )

method getViewMatrix*(self: Camera): Mat4f {.base.} =
    return lookAt(self.position, self.target, self.up)

method getProjMatrix*(self: Camera, width, height: int): Mat4f {.base.} =
  if self.ortho:
    var halfW:float32 = width.toFloat()/2
    var halfH:float32 = width.toFloat()/2
    var t:float32 = width.toFloat() / height.toFloat()
    return ortho(0.0f, width.float, height.float, 0.0f, self.near, self.far)
  return perspective(self.fov, width.float / height.float, self.near, self.far)
