import logging
import net
import strformat

import c4/processes
import c4/threads
import c4/systems/network/enet
import c4/utils/loglevel

import src/systems/[network, physics, input, video]
import src/scenarios/[connection, movement, collision]


when isMainModule:
  echo " start"
  run("server"):
    spawn("network"):
      logging.addHandler(logging.newConsoleLogger(
          levelThreshold = getCmdLogLevel(),
          fmtStr = "[$datetime] server $levelname: "))
      let network = new(ServerNetworkSystem)
      if not waitAvailable("physics"):
        raise newException(LibraryError, &"Physics system unavailable")
      network.init(port = Port(9000))
      network.run()
      network.dispose()

    spawn("physics"):
      logging.addHandler(logging.newConsoleLogger(
          levelThreshold = getCmdLogLevel(),
          fmtStr = "[$datetime] physics $levelname: "))
      let physics = new(Physics2DSystem)
      physics.init()
      physics.run()
      physics.dispose()

    joinAll()

  run("client"):
    spawn("network"):
      logging.addHandler(logging.newConsoleLogger(
          levelThreshold = getCmdLogLevel(),
          fmtStr = "[$datetime] client $levelname: "))
      let network = new(ClientNetworkSystem)
      network.init()
      if not waitAvailable("input"):
        raise newException(LibraryError, &"Input or Video system unavailable")
      network.connect(host = "localhost", port = Port(9000))
      network.run()
      network.dispose()

    spawn("input"):
      logging.addHandler(logging.newConsoleLogger(
          levelThreshold = getCmdLogLevel(),
          fmtStr = "[$datetime] input $levelname: "))
      let input = new(InputSystem)
      input.init()
      input.run()
      input.dispose()

    let video = new(VideoSystem)
    video.init()
    video.run()
    video.dispose()


    joinAll()

  dieTogether()
