require 'zlib'

def file_size_gzip(bytes)
  begin
    io = StringIO.new(bytes)
    gz = Zlib::GzipReader.new(io)
    data = gz.read
    unused_length = gz.unused ? gz.unused.length : 0
    return bytes.length - unused_length
  rescue
    # Probably not gzip
    return 0
  end
end

