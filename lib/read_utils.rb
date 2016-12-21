def read8(io)
  io.read(1).unpack('C')[0]
end

def read16le(io)
  io.read(2).unpack('S<')[0]
end

def read16be(io)
  io.read(2).unpack('S>')[0]
end

def read32le(io)
  io.read(4).unpack('L<')[0]
end

def read32be(io)
  io.read(4).unpack('L>')[0]
end

def read64le(io)
  io.read(8).unpack('Q<')[0]
end

def read64be(io)
  io.read(8).unpack('Q>')[0]
end

