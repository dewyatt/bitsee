MARKER_SOI = 0xffd8
MARKER_EOI = 0xffd9
MARKER_TEM = 0xff01
MARKER_SOS = 0xffda
MARKER_RST_0 = 0xffd0
MARKER_RST_7 = 0xffd7

def file_size_jpeg(bytes)
  # Rough estimate of smallest jpeg
  return 0 if bytes.length < 100

  io = StringIO.new(bytes)
  
  # Start of Image
  marker = read16be(io)
  return 0 if marker != MARKER_SOI

  marker = read16be(io)
  while marker != MARKER_EOI and not io.eof?
    case
    when marker < 0xff00
      # Invalid marker
      return 0
    when marker == MARKER_TEM
    when marker == MARKER_SOS
      length = read16be(io)
      io.seek(length - 2, IO::SEEK_CUR)

      while not io.eof?
        byte1 = read8(io)
        while byte1 != 0xff and not io.eof?
          byte1 = read8(io)
        end

        byte2 = read8(io)
        break if byte2 != 0x00 and
          not (byte2 >= (MARKER_RST_0 & 0xff) and byte2 <= (MARKER_RST_7 & 0xff))
      end
      io.seek(-2, IO::SEEK_CUR)
    else
      # All other markers have a length field.
      length = read16be(io)
      io.seek(length - 2, IO::SEEK_CUR)
    end
    marker = read16be(io)
  end
  io.tell
end

