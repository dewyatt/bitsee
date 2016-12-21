require 'time'

require 'btcrpcclient'
require 'btcscan'

def save_result(result)
  return false if Secret.find_by({tx: result[:tx]})
  path = nil
  url = nil
  file_mime = nil
  file_size = 0
  if result[:file_data] and result[:file_data].length > 0
    file_mime = result[:file_mime]
    filename = result[:tx] + '.' + result[:file_ext]
    path = File.join(ENV['FILES_PATH'], filename)
    File.binwrite(path, result[:file_data])
    file_size = result[:file_data].length
    url = ENV['FILES_URL'] + '/' + filename
  end
  secret = Secret.new({
    tx: result[:tx],
    file_mime: file_mime, 
    file_path: url,
    file_size: file_size,
    text: result[:text],
    time: Time.at(result[:time]).utc,
  })
  if secret.save()
    puts "Added #{secret.tx} #{secret.time} #{secret.file_mime} #{secret.text}"
    return true
  else
    $stderr.puts "Failed to save secret:"
    $stderr.puts secret.inspect
    return false
  end

end

namespace :utils do
  desc "Scan bitcoin blocks for stored data. Starting block should be set in environment variable BLOCK_BEGIN."
  task scan_blocks: :environment do
    fail 'Missing environment variables' if not ENV['BLOCK_BEGIN'] or not ENV['FILES_PATH'] or not ENV['FILES_URL']
    blockbeg = ENV['BLOCK_BEGIN'].to_i
    blockend = ENV['BLOCK_END'] ? ENV['BLOCK_END'].to_i : 0
    client = BTCRPCClient.new
    BTCScan.scan_blocks(client, blockbeg, blockend) { |result|
      save_result(result)
    }
  end

  desc "Scan a specific transaction. Transaction ID should be set in environment variable TX."
  task scan_tx: :environment do
    fail 'Missing environment variables' if not ENV['TX'] or not ENV['FILES_PATH'] or not ENV['FILES_URL']
    tx = ENV['TX']
    client = BTCRPCClient.new
    BTCScan.scan_one_tx(client, tx) { |result|
      save_result(result)
    }
  end

  desc "Load transactions from the test data."
  task load_test_data: :environment do
    fail 'Missing environment variables' if not ENV['FILES_PATH'] or not ENV['FILES_URL']
    client = BTCRPCClient.new
    txs = YAML.load(File.read('test/lib/txs.yml'))
    txs.each {|txhash, values|
      BTCScan.scan_one_tx(client, txhash) { |result|
        save_result(result)
      }
    }
  end

end

