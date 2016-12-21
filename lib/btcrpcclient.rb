#!/usr/bin/env ruby
require 'faraday'
require 'net/http/persistent'
require 'multi_json'

class BTCRPCClient
  def initialize(url=nil, username=nil, password=nil)
    url ||= 'http://localhost:8332'
    username ||= ENV['BTC_USERNAME']
    password ||= ENV['BTC_PASSWORD']
    fail 'Missing credentials' if not username or not password
    @conn = Faraday.new(:url => url) do |faraday|
      faraday.headers = {'content-type': 'application/json'}
      faraday.adapter :net_http_persistent
      # Sometimes I do large batch requests that are slow on my old hardware.
      faraday.options[:timeout] = 300
    end
    @conn.basic_auth(username, password)
    @url = url
  end

  def method_missing(method, *args, &block)
    self.batch([[method.to_s, *args]])[0]
  end

  def batch(calls)
    payload = []
    callid = 0
    calls.each do |call|
      payload += [{
        'method': call[0],
        'params': call[1..-1],
        'jsonrpc': '2.0',
        'id': callid
      }]
      callid += 1
    end
    resp = @conn.post do |req|
      req.url @url
      req.body = ::MultiJson.encode(payload)
    end
    fail 'Unexpected HTTP response' if resp.status != 200
    data = ::MultiJson.decode(resp.body)
    fail 'Missing responses' if calls.length != data.length
    data.sort_by! { |obj| obj['id'] }
    fail 'Errors in response' if data.any? { |x| x['error'] != nil }
    data.map!{ |x| x['result'] }
  end

end

