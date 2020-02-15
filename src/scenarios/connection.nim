{.used.}
import chronicles
import net
import strformat
import glm

import sdl2/sdl as sdllib

import c4/sugar
import c4/entities
import c4/threads
import c4/systems/network/enet
import c4/systems/physics/simple
import c4/systems/video/sdl

import ../lib/video/debug
import ../lib/physics/types
import ../systems/network
import ../systems/physics
import ../systems/video
import ../messages


# New client connection handling

method process*(self: ref ServerNetworkSystem, message: ref ConnectionOpenedMessage) =
  # client just connected - send this info to physics system
  info "Client connected, send physics"
  message.send("physics")
method processLocal*(self: ref ServerNetworkSystem, message: ref ConnectionOpenedMessage) =
  # client just connected - send this info to physics system
  info "Client connected, send physics"
  message.send("physics")


proc aabbCreated(self: Entity): seq[ref EntityMessage] =
  info "Networking - create aabb"
  result.add((ref AABBCreatedMessage)(
    entity: self,
    min: self[ref AABB].min,
    max: self[ref AABB].max,
  ))

proc boundsCreated(self: Entity): seq[ref EntityMessage] =
  info "Networking - create aabb"
  result.add createdMsg(self, self[ref Physics2DBody])
  result.add createdMsg(self, self[ref DebugDrawRect])

proc circleCreated(self: Entity): seq[ref EntityMessage] =
  info "Networking - create aabb"
  result.add (ref CreateEntityMessage)(entity: self)
  result.add createdMsg(self, self[ref Physics2DBody])
  result.add createdMsg(self, self[ref DebugDrawCircle])

proc getEntityDescribingMessages(self: Entity, kind: EntityKind): seq[ref EntityMessage] =
  # helper to send all entity info over network
  result.add((ref CreateTypedEntityMessage)(
    entity: self,
    kind: kind,
  ))


method process*(self: ref Physics2DSystem, message: ref ConnectionOpenedMessage) =
  # send world info to newly connected client
  info "Physics {message}"
  for msg in self.bounds.aabbCreated():
    msg.peer = message.peer
    msg.send("network")
  for msg in self.bounds.boundsCreated():
    msg.peer = message.peer
    msg.send("network")
  for circle in self.circles:
    for msg in circle.circleCreated():
      msg.peer = message.peer
      msg.send("network")
  self.connected = true



# then all local messages are by default sent to corresponding peers


method processRemote*(self: ref ClientNetworkSystem, message: ref AABBCreatedMessage) =
  # when entity is created, draw it on screen
  info "Process Remote", message=message
  procCall self.as(ref EnetClientNetworkSystem).processRemote(message)  # create entity, generate mapping

  message.entity[ref Physics2DBody] = (ref Physics2DBody)(
    position: vec2f(0.5, 0.5),
    velocity: vec2f(0.0, 0.0),
    force: vec2f(0.0, 0.0),
    angularVelocity: 0.0,
    rotation: 0.0
  )
  message.entity[ref AABB] = (ref AABB)(min: message.min, max: message.max)

method processRemote*(self: ref ClientNetworkSystem, message: ref Physics2DBodyCreateMsg) =
  # when entity is created, draw it on screen
  info "Process Remote", message=message
  procCall self.as(ref EnetClientNetworkSystem).processRemote(message)  # create entity, generate mapping

  message.entity[ref Physics2DBody] = (ref Physics2DBody)(
    velocity: message.component.velocity,
    force: message.component.force,
    angularVelocity: message.component.angularVelocity,
    position: message.component.position,
    rotation: message.component.rotation,
    scale: message.component.scale
  )

method processRemote*(self: ref ClientNetworkSystem, message: ref DebugCircleCreateMsg) =
  # when entity is created, draw it on screen
  info "Process Remote", message=message
  procCall self.as(ref EnetClientNetworkSystem).processRemote(message)  # create entity, generate mapping

  message.entity[ref DebugDrawCircle] = (ref DebugDrawCircle)(
    radius: message.component.radius,
    color: message.component.color,
    fill: message.component.fill,
  )

method processRemote*(self: ref ClientNetworkSystem, message: ref DebugRectCreateMsg) =
  # when entity is created, draw it on screen
  info "Process Remote", message=message
  procCall self.as(ref EnetClientNetworkSystem).processRemote(message)  # create entity, generate mapping

  message.entity[ref DebugDrawRect] = (ref DebugDrawRect)(
    min: message.component.min,
    max: message.component.max,
    color: message.component.color,
    fill: message.component.fill,
  )

method processRemote*(self: ref ClientNetworkSystem, message: ref Physics2DBodyUpdateMsg) =
  try:
    procCall self.as(ref EnetClientNetworkSystem).processRemote(message)
  except KeyError:
    return
  let body = message.entity[ref Physics2DBody]
  body.position = message.component.position
  # let video = message.entity[ref Video]
  # video.width = message.width
  # video.height = message.height

method processRemote*(self: ref ClientNetworkSystem, message: ref SetDimensionMessage) =
  try:
    procCall self.as(ref EnetClientNetworkSystem).processRemote(message)
  except KeyError:
    return

  # let video = message.entity[ref Video]
  # video.width = message.width
  # video.height = message.height


method processRemote*(self: ref ClientNetworkSystem, message: ref SetPositionMessage) =
  try:
    procCall self.as(ref EnetClientNetworkSystem).processRemote(message)
  except KeyError:
    return

  # let video = message.entity[ref Video]
  # video.x = message.x
  # video.y = message.y
