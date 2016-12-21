require_relative 'read_utils'
require_relative 'file_sizes/7z'
require_relative 'file_sizes/jpeg'
require_relative 'file_sizes/gif'
require_relative 'file_sizes/png'
require_relative 'file_sizes/gzip'
require 'digest'

$file_size_functions = {}
$file_size_functions['application/x-7z-compressed; charset=binary'] = :file_size_7z
$file_size_functions['image/jpeg; charset=binary']                  = :file_size_jpeg
$file_size_functions['image/gif; charset=binary']                   = :file_size_gif
$file_size_functions['image/png; charset=binary']                   = :file_size_png
$file_size_functions['application/x-gzip; charset=binary']          = :file_size_gzip

