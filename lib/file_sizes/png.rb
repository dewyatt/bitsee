require 'digest'

PNG_SIG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].pack('C*')
PNG_CHUNK_IEND = 'IEND'.unpack('L>')[0]

def read_chunk(io)
  length = read32be(io)
  type = read32be(io)
  data = io.read(length)
  crc = read32be(io)
  # Verify checksum for this chunk
  digest = Digest::CRC32.new
  digest << [type].pack('L>')
  digest << data
  # Fail if checksum does not match
  return nil if digest.checksum != crc
  # Success
  return type,data
end

def file_size_png(bytes)
  io = StringIO.new(bytes)

  # Check signature
  sig = io.read(8)
  return 0 if sig != PNG_SIG

  # Keep reading chunks until IEND
  type,data = read_chunk(io)
  while type != nil and type != PNG_CHUNK_IEND
    type, data = read_chunk(io)
  end
  # Fail
  return 0 if type == nil
  # Success
  io.tell
end

