import glm

type
  # Collision Result
  Collision* = object
    a*: ref Physics2DBody
    b*: ref Physics2DBody
    penetration*: float32
    normal*: Vec2f
    contacts*: seq[Vec2f]
    relativeVelocity*: Vec2f
  # Physics Component
  AABB* {.inheritable.} = object
    min*: Vec2f
    max*: Vec2f

  Transform* {.inheritable.} = object
    position*: Vec2f
    rotation*: float
    scale*: Vec2f

  Point* {.inheritable.} = object
    position*: Vec2f
  
  Circle* {.inheritable.} = object
    radius*: float

  Physics2DBody* {.inheritable.} = object of Transform
    velocity*: Vec2f
    force*: Vec2f
    angularVelocity*: float