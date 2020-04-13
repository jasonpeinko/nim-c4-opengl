import tables
import strformat
import math
import sequtils
import os
import glm/vec
import chronicles
import random
import ../lib/video/debug
import ../messages as msg
when isMainModule:
  import unittest

import c4/sugar
import c4/threads
import c4/messages
import c4/systems/physics/simple
import c4/entities
import c4/loop
import logging
import ../lib/physics/[types, collision, grid]

randomize()


type
  Physics2DSystem* {.inheritable.} = object
    connected*: bool
    grid*: SpatialGrid[Entity]
    bounds*: Entity
    circles*: seq[Entity]

# method getComponents*(self: ref Physics2DSystem): Table[Entity, ref AABB] {.base.} =
#   getComponents(ref AABB)
proc createCircle(p: Vec2f, v: Vec2f, r: float32): Entity =
  result = newEntity()
  result[ref Physics2DBody] = (ref Physics2DBody)(
    position: p,
    velocity: v,
    force: vec2f(0.0, 0.0),
    angularVelocity: 0.0,
    rotation: 0.0
  )
  result[ref Circle] = (ref Circle)(
    radius: r
  )
  result[ref DebugDrawCircle] = (ref DebugDrawCircle)(
    radius: r,
    color: vec4f(0.0, 1.0, 0.8, 1.0),
    fill: false
  )


method init*(self: ref Physics2DSystem) {.base.} =
  self.connected = false
  self.bounds = newEntity()
  self.bounds[ref Physics2DBody] = (ref Physics2DBody)(
    position: vec2f(10, 10),
    velocity: vec2f(0.0, 0.0),
    force: vec2f(0.0, 0.0),
    angularVelocity: 0.0,
    rotation: 0.0
  )
  self.bounds[ref AABB] = (ref AABB)(
    min: vec2f(10, 10),
    max: vec2f(950, 530)
  )
  self.bounds[ref DebugDrawRect] = (ref DebugDrawRect)(
    min: vec2f(0, 0),
    max: vec2f(940, 520),
    color: vec4f(1.0, 0.0, 1.0, 1.0),
    fill: false
  )
  self.grid = newSpatialGrid[Entity](self.bounds[ref AABB], 200)

  for i in 0..2:
    var position = vec2f(rand(50.0..900.0), rand(50.0..490.0))
    var velocity = vec2f(rand(-1.0..1.0), rand(-1.0..1.0))
    var r = rand(10.0..30.0)
    var e = createCircle(position, velocity, r)
    self.circles.add(e)
  # self.circles.add createCircle(vec2f(100, 100), vec2f(1, 0), 50)
  # self.circles.add createCircle(vec2f(220, 100), vec2f(-0.5, 0), 30)
  # self.circles.add createCircle(vec2f(220, 400), vec2f(-1, 0), 50)
  # self.circles.add createCircle(vec2f(100, 400), vec2f(0.5, 0), 30)
  info "Init Physics"

method update*(self: ref Physics2DSystem, dt: float) {.base.} =
  if self.connected:
    for entity, circle in getComponents(ref Circle):
      let body = entity[ref Physics2DBody]
      let bounds = self.bounds[ref AABB]
      body.position = body.position + body.velocity
      if body.position.x - circle.radius < bounds.min.x:
        body.position.x = bounds.min.x + circle.radius
        body.velocity.x *= -1
      if body.position.y - circle.radius < bounds.min.y:
        body.position.y = bounds.min.y + circle.radius
        body.velocity.y *= -1
      if body.position.x + circle.radius > bounds.max.x:
        body.position.x = bounds.max.x - circle.radius
        body.velocity.x *= -1
      if body.position.y + circle.radius > bounds.max.y:
        body.position.y = bounds.max.y - circle.radius
        body.velocity.y *= -1
      msg.updatedMsg(entity, body).send("network")
    for i in 0..<self.circles.len:
      for j in (i+1)..<self.circles.len:
        var a = self.circles[i]
        var b = self.circles[j]
        var ac = a[ref Circle]
        var bc = b[ref Circle]
        var bodya = a[ref Physics2DBody]
        var bodyb = b[ref Physics2DBody]
        var collision = CircleCircle(ac, bc, bodya, bodyb)
        collision.applyImpulse()
        # info "test", a=a, b=b, collision=collision.contacts

method dispose*(self: ref Physics2DSystem) {.base.} =
  discard

method process*(self: ref Physics2DSystem, message: ref Message) {.base.} =
  logging.warn &"Physics `Don't know how to process {message}"

method run*(self: ref Physics2DSystem) {.base.} =
  loop(frequency=30) do:
    self.update(dt)
    while true:
      let message = tryRecv()
      if message.isNil:
        break
      self.process(message)


when isMainModule:
  suite "Physics2DSystem tests":
    test "Running inside thread":
      spawn("thread") do:
        let system = new(Physics2DSystem)
        system.init()
        system.run()
        system.dispose()

      sleep 1000
