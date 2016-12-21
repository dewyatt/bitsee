require 'filemagic'

def mime_type(bytes)
  fm = FileMagic.open(:mime_type, :mime_encoding)
  mime = fm.buffer(bytes)
  # For our purposes octet-stream means unknown garbage data.
  return nil if mime.start_with?('application/octet-stream')
  return mime
end

# MIME to file extension mapping.
# These take precedence over EXTENSION_OVERRIDES.
MIME_EXTENSIONS = {
  'application/pdf; charset=binary' => 'pdf',

  # TODO: This should probably just be .gz
  'application/x-gzip; charset=binary' => 'tar.gz',

  'image/gif; charset=binary' => 'gif',
  'image/png; charset=binary' => 'png',
}

# Override some extensions that we don't like.
EXTENSION_OVERRIDES = {
  'jpeg' => 'jpg',
  '???' => 'txt',
}

def file_extension(bytes, mime)
  # FileMagic seems to crash on empty data.
  return nil if bytes == nil or bytes.empty?
  # If we have a mime->extension mapping, use it.
  if MIME_EXTENSIONS.include?(mime)
    return MIME_EXTENSIONS[mime]
  end
  # See if FileMagic can come up with a file extension.
  fm = FileMagic.open(:extension)
  extensions = fm.buffer(bytes)
  # The extensions are separated by '/', use the first one.
  ext = extensions.split('/')[0]
  if EXTENSION_OVERRIDES.include?(ext)
    ext = EXTENSION_OVERRIDES[ext]
  end
  ext
end

# These mimes are OK to save and likely not false positives.
MIME_WHITELIST = [
  'application/x-7z-compressed; charset=binary',
  'application/x-gzip; charset=binary',
  'application/pdf; charset=binary',

  'image/jpeg; charset=binary',
  'image/gif; charset=binary',
  'image/png; charset=binary',
]

def text_mime?(mime)
  return (mime.start_with?('text/') and 
            (
              mime.end_with?('charset=utf-8') or
              mime.end_with?('charset=us-ascii')
            )
         )
end

def whitelisted_mime?(mime)
  return true if text_mime?(mime)
  return MIME_WHITELIST.include?(mime)
end

