import c4/entities
import c4/messages
import c4/systems/network/enet
import c4/systems/physics/simple
import glm
import lib/physics/types
import lib/video/debug


type EntityKind* = enum
  wall, player, enemy, bounds

template componentMessages(name: untyped, componentType: typedesc, body: untyped) =
  type `name Msg`* {.inject.} = object of EntityMessage
    component*: ref componentType
  type `name CreateMsg`* {.inject.} = object of `name Msg`
  type `name UpdateMsg`* {.inject.} = object of `name Msg`
  type `name RemoveMsg`* {.inject.} = object of `name Msg`
  register `name CreateMsg`
  register `name UpdateMsg`
  register `name RemoveMsg`

  body

template genCreatedMsg(name: untyped, componentType: typedesc) =
  proc `createdMsg`*(self: Entity, component: ref componentType): ref EntityMessage {.inject.}  =
    echo "create msg"
    result = (ref `name CreateMsg`)(
      entity: self,
      component: component
    )

template genUpdatedMsg(name: untyped, componentType: typedesc) =
  proc `updatedMsg`*(self: Entity, component: ref componentType): ref EntityMessage {.inject.}  =
    result = (ref `name UpdateMsg`)(
      entity: self,
      component: component
    )


componentMessages(Physics2DBody, Physics2DBody):
  genCreatedMsg(Physics2DBody, Physics2DBody)
  genUpdatedMsg(Physics2DBody, Physics2DBody)

componentMessages(DebugRect, DebugDrawRect):
  genCreatedMsg(DebugRect, DebugDrawRect)
componentMessages(DebugCircle, DebugDrawCircle):
  genCreatedMsg(DebugCircle, DebugDrawCircle)


type AABBCreatedMessage* = object of CreateEntityMessage
  min*: Vec2f
  max*: Vec2f
register AABBCreatedMessage
type CreateTypedEntityMessage* = object of CreateEntityMessage
  kind*: EntityKind
register CreateTypedEntityMessage

type SetDimensionMessage* = object of EntityMessage
  ## Tells client size of object
  width*: float
  height*: float
register SetDimensionMessage

type SetPhysicsBodyMessage = object of EntityMessage

type SetPositionMessage* = object of EntityMessage
  ## Tells client where specific entity should be located
  x*: float
  y*: float
register SetPositionMessage

type MoveMessage* = object of NetworkMessage
  ## Client sends to server when arrow is pressed
  entity*: Entity
  direction*: float  # just angle in rad
register MoveMessage

type StartGameMessage* = object of NetworkMessage
register StartGameMessage
