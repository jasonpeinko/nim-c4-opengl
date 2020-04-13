import stb_image/read as stbi

type 
  ImageResource* = ref object
    data*: seq[byte]
    width*, height*, channels*: int

proc load_image*(path: string): ImageResource =
  result = ImageResource()
  # stbi.setFlipVerticallyOnLoad(true)               
  result.data = stbi.load(path, result.width, result.height, result.channels, stbi.Default)
  echo result.channels
