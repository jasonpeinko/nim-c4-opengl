import glm
import chronicles
import ./types

proc newCollision(a, b: ref Physics2DBody): ref Collision =
  result = (ref Collision)(
    a: a,
    b: b,
    contacts: @[],
    relativeVelocity: a.velocity - b.velocity
  )

proc AABBAABB*(a, b: ref AABB): bool =
  if a.max.x < b.min.x or a.min.x > b.max.x:
    return false
  if a.max.y < b.min.y or a.min.y > b.max.y:
    return false
  return true

proc CircleCircle*(a, b: ref Circle, bodya, bodyb: ref Physics2DBody): ref Collision =
  result = newCollision(bodya, bodyb)
  var r = a.radius + b.radius
  let deltaP = bodyb.position - bodya.position
  # No collision
  if (r*r) < deltaP.length2():
    return
  let d = deltaP.length()
  if d <= 0.0:
    # Circles on exact same point
    result.penetration = a.radius
    result.normal = vec2f(1, 0)
    result.contacts.add(bodya.position)
  else:
    result.penetration = r - d
    result.normal = deltaP / d
    result.contacts.add(result.normal * a.radius + bodya.position)

proc resolve(a, b: ref Physics2DBody) =
  let dv = b.velocity - a.velocity

method applyImpulse*(self: ref Collision) =
  if self.contacts.len <= 0:
    return
  
  for contact in self.contacts:
    var ra = contact - self.a.position
    var rb = contact - self.b.position

    var contactVel = dot(self.relativeVelocity, self.normal)
    var sep = (self.normal * self.penetration) / 2
    var impulse = contactVel
    # info "vel", va=self.a.velocity, vb=self.b.velocity, vel=contactVel, impulse=impulse, normal=self.normal, velocity=self.relativeVelocity, pen=self.penetration, ra=ra, rb=rb
    self.a.velocity += self.normal * -impulse
    self.b.velocity += self.normal * impulse
    # self.a.velocity = vec2f(0,0) 
    # self.b.velocity = vec2f(0,0)
    self.a.position -= self.normal * (self.penetration/2+0.01)
    self.b.position += self.normal * (self.penetration/2-0.01)
    # info "vel", va=self.a.velocity, vb=self.b.velocity