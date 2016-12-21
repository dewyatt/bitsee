#!/usr/bin/env ruby
require 'digest'

require_relative 'btcrpcclient.rb'
require_relative 'mime.rb'
require_relative 'file_sizes.rb'

##
# Convert a single transaction output to a byte string.
#
def vout_to_data(vout)
  asm = vout['scriptPubKey']['asm']
  data = ''
  asm.split(' ').each { |chunk|
    # TODO: Why do we test for even lengths here?
    # Block 435078 tx e133cb4d8df4626d80d8494bf5aa72a084368a61ce5fe2aa2a88580859c441dc
    # OP_RETURN 7171437 (Why is this not hex?)
    # This is not the only instance IIRC.
    if not chunk.start_with? 'OP_' and chunk.length % 2 == 0
      data += [chunk].pack('H*')
    end
  }
  data
end

##
# Convert all transaction outputs to byte strings
#
def vouts_to_data(vouts)
  vouts.inject('') { |data,vout| data += vout_to_data(vout) }
end

def get_length_and_cksum(data)
  # We need at least 8 bytes here.
  return nil if data.length <= 8
  length = data.byteslice(0, 4).unpack('L<')[0]
  cksum = data.byteslice(4, 4).unpack('L<')[0]
  crc = Digest::CRC32.checksum data.byteslice(8, length)
  if cksum == crc
    [length, cksum]
  else
    # Checksum did not match.
    nil
  end
end

##
# Tries to find the next transaction when dealing with a multi-tx 
# file embed.
#
# For now this just picks the last address in the outputs and
# then locates the next transaction that address was involved in.
#
# This works for cablegate which is the only instance I am currently aware of.
def find_next_tx(client, tx)
  outputs = tx['vout']
  addresses = outputs.select {|output| output['scriptPubKey'].include?('addresses')}.
                      map{ |output| output['scriptPubKey']['addresses'][0]}
  lastaddr = addresses[-1]
  txids = client.getaddresstxids(lastaddr)
  idx = txids.index(tx['txid'])
  if idx == nil or idx == (txids.length - 1)
    $stderr.puts 'Failed to find next tx'
    return nil
  end
  nexttx = txids[idx + 1]
  tx = client.getrawtransaction(nexttx, 1)
end

def scan_output_group(client, outputs)
  data = vouts_to_data(outputs)
  return nil if data.empty?

  # Find out if we have a [len][cksum] prefix on the data.
  length, cksum = get_length_and_cksum(data)
  have_length_and_cksum = (length != nil and length != 0)
  filedata = have_length_and_cksum ? data.byteslice(8, length) : data.byteslice(0..-1)
  
  mime = mime_type(filedata)
  if not mime
    # Not able to identify data.
    # Try again with first few bytes.
    # Useful when we have valid text data followed by garbage.
    mime = mime_type(filedata.byteslice(0, 10))
  end
  # No luck, time to bail.
  return nil if not mime
  file_size_func = $file_size_functions[mime]
  filesize = 0
  if file_size_func
    filesize = send(file_size_func, filedata)
    $stderr.puts 'WARNING: filesize == 0' if filesize == 0
    return nil if filesize == 0
  end
  return [have_length_and_cksum, mime, filedata, filesize]
end

##
# These are prefixes on text data that are application-specific
# and not generally interesting enough for us to store.
#
IGNORED_TEXT_PREFIXES = [
  'ASCRIBE',
  'id:',
  '@COPYROBO@'
]

##
# Checks if the supplied text has a prefix that we are not
# interested in storing.
#
def has_ignored_prefix?(text)
  IGNORED_TEXT_PREFIXES.each {|prefix|
    return true if text.start_with?(prefix)
  }
  return false
end

##
# Scan a single transaction for embedded files/data.
# This may scan multiple transactions behind the scenes.
#
def scan_tx(client, tx)
  findings = []

  # Ignore miner data (less interesting).
  return [] if tx['vin'][0]['coinbase']

  outputs = tx['vout']
  # multisig, pubkeyhash, nulldata, nil
  outputs_by_type = outputs.group_by { |output| output['scriptPubKey']['type'] }
  outputs_by_type.keys.each {|type|
    # TODO: If vout.spentTxId, probably not data
    have_length_and_cksum, mime, filedata, filesize = scan_output_group(client, outputs_by_type[type])
    if mime
      if not whitelisted_mime?(mime) and not mime.start_with?('text/') and filedata.length > 40
        total = outputs_by_type[type].length
        spent = outputs_by_type[type].select{ |output| output.include?('spentTxId') }.length
        unspent = total - spent
        if unspent > spent
          puts ''
          puts "#{tx['txid']} ******* Potentially interesting ******* #{mime}"
          puts ''
        end
      end
      if filedata.length < filesize
        nexttx = tx
        while filedata.length < filesize
          nexttx = find_next_tx(client, nexttx)
          outputs = nexttx['vout']
          outputs_by_type = outputs.group_by { |output| output['scriptPubKey']['type'] }

          data = vouts_to_data(outputs_by_type[type])
          length, cksum = get_length_and_cksum(data)
          next_have_length_and_cksum = (length != nil)
          if next_have_length_and_cksum != have_length_and_cksum
            $stderr.puts '******* Length and cksum mismatch on multi-tx file ********'
            next
          end
          next_filedata = have_length_and_cksum ? data.byteslice(8, length) : data.byteslice(0..-1)
          filedata += next_filedata
        end
      end
      if filesize > 0
        skipto = 20 * (filesize / 20 + 1)
        if skipto < filedata.length
          leftoverdata = filedata.byteslice(skipto..-1)
          if Digest::RMD160.digest(filedata.byteslice(0, filesize)) == leftoverdata.byteslice(0, 160/8)
            # cryptograffiti
            skipto = 20 * (filesize / 20 + 2)
            if (skipto + 40) < filedata.length
              leftoverdata = leftoverdata.byteslice(20..-1)
              endidx = leftoverdata.index("\x00")
              endidx = (endidx - 1) if endidx != nil
              endidx = (leftoverdata.length - 40 - 1) if endidx == nil
              text = leftoverdata.byteslice(0..endidx).force_encoding('utf-8')
              if not text.valid_encoding?
                puts "#{tx['txid']} Invalid encoding, skipping"
                next
              end
            end
          end
        end
        filedata = filedata.byteslice(0, filesize)
      end
      if whitelisted_mime?(mime)
        if not text and text_mime?(mime)
          mime = nil
          endidx = filedata.index("\x00")
          endidx = (endidx - 1) if endidx != nil
          endidx = -1 if endidx == nil
          text = filedata.byteslice(0..endidx).force_encoding('utf-8')
          if not text.valid_encoding?
            puts "#{tx['txid']} Invalid encoding, skipping"
            next
          end
          next if has_ignored_prefix?(text)
          filedata = nil
        end
        findings += [
         {
           tx: tx['txid'],
           file_mime: mime,
           file_data: filedata,
           file_ext: file_extension(filedata, mime),
           text: text,
           time: tx['time']
         }
        ]
        # We found what we wanted in this tx
        return findings
      end
    end
  }
  findings
end

##
# Scan all transactions in a block for embedded files/data.
#
def scan_block(client, blocknum)
  bhash = client.getblockhash(blocknum)
  block = client.getblock(bhash)
  txhashes = block['tx']

  # Many blocks contain > 2k transactions, so batching this
  # can cause read timeouts on slower hardware.
  # The timeout can be adjusted in btcrpcclient if needed.
  calls = txhashes.map { |txhash| ['getrawtransaction', txhash, 1] }
  txs = client.batch(calls)
  return txs.inject([]) {|findings, tx| findings += scan_tx(client, tx) }
end

module BTCScan

  def BTCScan.scan_blocks(client, blockbeg, blockend, &block)
    blockend = client.getblockcount() if blockend == 0
    findings = []
    (blockbeg..blockend).each do |blocknum|
      puts "[Block #{blocknum}]"
      findings += scan_block(client, blocknum)
      if block_given?
        findings.each {|finding| yield finding }
        findings = []
      end
    end
    findings
  end

  def BTCScan.scan_one_tx(client, txhash, &block)
    tx = client.getrawtransaction(txhash, 1)
    findings = scan_tx(client, tx)
    if block_given?
      findings.each {|finding| yield finding }
    else
      findings
    end
  end

end

