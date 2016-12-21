require 'test_helper'
require 'yaml'
require 'btcrpcclient'
require 'btcscan'

class ScanTxTest < ActiveSupport::TestCase
  def setup
    @client = BTCRPCClient.new('http://localhost:8332', 'bitcoin', 'local321')
  end

  def check_result(values, result)
    if values.include?('file_md5')
      expected = values['file_md5']
      actual = Digest::MD5.hexdigest(result[:file_data])
      assert_equal expected, actual
    end
    if values.include?('file_mime')
      expected = values['file_mime']
      actual = result[:file_mime]
      assert_equal expected, actual
    end
    if values.include?('file_ext')
      expected = values['file_mime']
      actual = result[:file_mime]
      assert_equal expected, actual
    end
    if values.include?('text_md5')
      expected = values['text_md5']
      actual = Digest::MD5.hexdigest(result[:text])
      assert_equal expected, actual
    end
  end

  test 'scan known transactions' do
    txs = YAML.load(File.read('test/lib/txs.yml'))
    txs.each {|txhash, values|
      puts txhash
      result = BTCScan.scan_one_tx(@client, txhash)
      assert_equal 1, result.length
      check_result(values, result[0])
    }
  end
end

