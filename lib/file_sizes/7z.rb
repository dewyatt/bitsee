require 'digest'

SVNZ_SIGNATURE = [0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c].pack('C*')
SVNZ_MAJOR_VERSION = 0x00
SVNZ_ID_HEADER = 0x01
SVNZ_ID_ENCODED_HEADER = 0x17

def file_size_7z(bytes)
  return 0 if bytes.length < 20

  io = StringIO.new(bytes)
  
  # Check for signature
  sig = io.read(6)
  return 0 if SVNZ_SIGNATURE != sig

  # Check major version
  ver_maj = read8(io)
  ver_min = read8(io)
  return 0 if SVNZ_MAJOR_VERSION != ver_maj

  # Checksum
  crc = read32le(io)
  crc_calc = Digest::CRC32.digest(bytes.byteslice(12, 20))
  return 0 if [crc].pack('L>') != crc_calc
  
  nh_offset = read64le(io)
  nh_size = read64le(io)
  nh_crc = read32le(io)

  # Success
  return 0x20 + nh_offset + nh_size
end

