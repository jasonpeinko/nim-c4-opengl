import math
import chronicles
import nimgl/[glfw]

import c4/sugar
import c4/threads
import c4/loop
import c4/messages
import os

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
             action: int32, mods: int32): void {.cdecl.} =
  echo "key"
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

type
  InputSystem* = object
  # event: Event

method init*(self: ref InputSystem) {.base.} =
  info "Initializing input system"


method update*(self: ref InputSystem, dt: float) {.base.} =
  discard
method process*(self: ref InputSystem, message: ref Message) {.base.} =
  warn "No rule for processing message", message=message

method dispose*(self: ref InputSystem) {.base.} =
  discard

method run*(self: ref InputSystem) {.base.} =
  loop(frequency=30) do:
    self.update(dt)
    while true:
      let message = tryRecv()
      if message.isNil:
        break
      self.process(message)


# method handle*(self: ref InputSystem, event: Event) =
#   ## Handling of basic event. These are pretty reasonable defaults.
#   procCall self.as(ref SdlInputSystem).handle(event)

#   if event.kind == KEYDOWN and event.key.keysym.sym == K_SPACE:
#     new(StartGameMessage).send("network")


# method handle*(self: ref InputSystem, keyboard: ptr array[NUM_SCANCODES.int, uint8]) =
#   var vector = (x: 0.0, y: 0.0)

#   if keyboard[SCANCODE_LEFT].bool:
#     vector = (x: vector.x - 1.0, y: vector.y + 0.0)

#   if keyboard[SCANCODE_RIGHT].bool:
#     vector = (x: vector. x + 1.0, y: vector.y + 0.0)

#   if keyboard[SCANCODE_UP].bool:
#     vector = (x: vector.x + 0.0, y: vector.y + 1.0)

#   if keyboard[SCANCODE_DOWN].bool:
#     vector = (x: vector.x + 0.0, y: vector.y - 1.0)

#   if vector == (x: 0.0, y: 0.0):
#     return

#   let angle = arctan2(vector.y, vector.x)
#   (ref MoveMessage)(direction: angle).send("network")
