import math
import glm
import chronicles
import ./types
import c4/entities

const MAX_ITEMS = 100
type
  SpatialGrid*[T] = ref object
    bounds*: ref AABB
    nodeSize*: float32
    cells*: seq[Cell[T]]
    width*: uint
    height*: uint
  Cell*[T] = ref object
    position: Vec2f
    items: seq[T]

proc newCell[T](pos: Vec2f): Cell[T] = 
  result = (Cell[T])(
    position: pos,
    items: @[]
  )

proc newSpatialGrid*[T](bounds: ref AABB, size: float32): SpatialGrid[T] =
  new(result)
  result.bounds = bounds
  result.nodeSize = size
  result.cells = @[]
  var dimm = (bounds.max - bounds.min) / size
  result.width = ceil(dimm.x).uint
  result.height = ceil(dimm.y).uint
  var numNodes = result.width * result.height
  for i in 1.uint..numNodes.uint:
    result.cells.add(newCell[T](result.posFromIndex(i)))
  info "Initialize spatial grid", bMin=bounds.min, bMax=bounds.max, size=size, numNodes=numNodes

method posFromIndex*[T](self: SpatialGrid[T], index: uint): Vec2f =
  var x = (index mod self.width).float32 * self.nodeSize
  var y = floor(index.float32 / self.width.float32).float32 * self.nodeSize
  return vec2f(x, y)

method indexAt*[T](self: SpatialGrid[T], pos: Vec2f): uint =
  var u: uint = floor(pos.x / self.nodeSize).uint
  var j: uint = floor(pos.y / self.nodeSize).uint
  return j * self.width + u

method cellAt*[T](self: SpatialGrid[T], pos: Vec2f): Cell[T] = 
  return self.cells[self.indexAt(pos)]

method add*[T](self: SpatialGrid[T], item: T, pos: Vec2f) =
  var cell = self.cellAt(pos)
  cell.add(item)

method add*[T](self: Cell[T], item: T) =
  self.items.add(item)