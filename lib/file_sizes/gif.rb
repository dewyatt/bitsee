GIF_EXT_BLOCK = 0x21
GIF_EXT_PLAIN_TEXT = 0x01
GIF_EXT_APPLICATION = 0xff
GIF_EXT_COMMENT = 0xfe

GIF_IMAGE_DATA = 0x2c
GIF_TRAILER = 0x3b

def read_subblocks(io)
  b = read8(io)
  while b != 0x00 and not io.eof?
    io.seek(b, IO::SEEK_CUR)
    b = read8(io)
  end
end

def file_size_gif(bytes)
  # Roughly 20 bytes minimum
  return 0 if bytes.length < 20

  io = StringIO.new(bytes)

  # Check signature
  sig = io.read(3)
  return 0 if sig != 'GIF'
  
  # Check version
  version = io.read(3)
  return 0 if (version != '87a' and version != '89a')

  # Logical Screen Descriptor
  screen_width = read16le(io)
  screen_height = read16le(io)
  packed = read8(io)
  # We don't use most of these, but keep them
  # around for debugging later.
  gct_size =    packed & 0b00000111
  gct_sort =    packed & 0b00001000
  color_res =   packed & 0b01110000
  gct_present = packed & 0b10000000

  gct_size = 1 << (gct_size + 1)
  gct_sort = (gct_sort != 0)
  gct_present = (gct_present != 0)

  bg_color = read8(io)
  aspect_ratio = read8(io)

  # Skip the Global Color Table, if present
  io.seek(3 * gct_size, IO::SEEK_CUR) if gct_present

  while not io.eof?
    b = read8(io)
    case b
    when GIF_EXT_BLOCK
      label = read8(io)
      case label
      when GIF_EXT_PLAIN_TEXT
        read_subblocks(io)
      when GIF_EXT_APPLICATION
        read_subblocks(io)
      when GIF_EXT_COMMENT
        read_subblocks(io)
      else
        # All other blocks
        blocksize = read8(io)
        io.seek(blocksize + 1, IO::SEEK_CUR)
      end
    when GIF_IMAGE_DATA
      left, top = read16le(io), read16le(io)
      width, height = read16le(io), read16le(io)
      packed = read8(io)

      lct_present =    packed & 0b10000000
      lct_interlace =  packed & 0b01000000
      lct_sort =       packed & 0b00100000
      lct_size =       packed & 0b00000111

      lct_size = 1 << (lct_size + 1)
      lct_sort = (lct_sort != 0)
      lct_present = (lct_present != 0)
      
      # Skip the Local Color Table, if present.
      io.seek(3 * lct_size, IO::SEEK_CUR) if lct_present
      
      lzw_mcs = read8(io)
      read_subblocks(io)
    when GIF_TRAILER
      # Success
      return io.tell
    else
      # Unrecognized data
      return 0
    end
  end
  return 0
end

