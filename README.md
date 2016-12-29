# Bitsee

## What is it?
![Screenshot](/../screenshots/screenshots/bitsee.png?raw=true "Screenshot")

Bitsee is a bitcoin (and other compatible) blockchain embedded data viewer and extractor.

It crawls the blockchain and extracts embedded text and files.

## Package Requirements
Some of the packages required on an Ubuntu Xenial host would include:
* git
* ruby
* bundler
* nodejs
* zlib1g-dev
* libmagic-dev
* libsqlite3-dev

## Getting Started
1. Install required packages as noted above
2. Install and run a [Bitcore](https://bitcore.io/guides/full-node/) bitcoin daemon with added indexes (txindex, addressindex, spentindex). Allow time to download the blockchain (this will take up ~200GiB of space).
3. `git clone https://github.com/dewyatt/bitsee.git`
4. `cd bitsee`
5. `bundle install`
6. `bundle exec rails db:migrate`
7. `bundle exec rails server`

Now that the development web server is running, you can proceed to scan the blockchain.

## Scanning the blockchain
If you just want some immediate results, you can run:

`bundle exec rails utils:load_test_data`

This will use test/lib/txs.yml which contains a list of transactions that are known to contain embedded data.
It will use the transaction hashes only and will query the local bitcoin daemon for the actual transaction data.

Now view http://localhost:3000/ for the results.

### Scan a specific transaction
You can quickly scan a specific transaction using something like this:

`bundle exec rails utils:scan_tx BTC_USERNAME=bitcoin BTC_PASSWORD=local321 FILES_PATH=~/bitsee/public/files/ FILES_URL=/files TX=4b0cd7e191ef0a14a9b6ab1c5900be534118c20a332ff26407648168d2722a2e`

Note that we're passing a number of environment variables here:
* BTC_USERNAME and BTC_PASSWORD are the credentials for the local bitcoin daemon's RPC interface. The defaults for bitcore are used here.
* FILES_PATH is the path to save any files that are found and should be bitsee/public/files when running the development server.
* FILES_URL is the URL where FILES_PATH can be reached.
* TX is the transaction to scan.

Note that you can of couse export some of these in your shell rather than pass all of them every time. For example:
```sh
export BTC_USERNAME=bitcoin
export BTC_PASSWORD=local321
export FILES_PATH=~/bitsee/public/files/
export FILES_URL=/files
bundle exec rails utils:scan_tx TX=ca933de16b6466e40b37c7ee0ec0dcd9a56bc365a567a5fff81ba4927dd61e23
bundle exec rails utils:scan_tx TX=c0bb963cb3ceffc49059f09db94e3fd73caa3b7a8e005160d49e99020ff6b51a:
```

### Scan a range of blocks

Similar to the above, you can run:

`bundle exec rails utils:scan_blocks BTC_USERNAME=bitcoin BTC_PASSWORD=local321 FILES_PATH=~/bitsee/public/files/ FILES_URL=/files BLOCK_BEGIN=230037 BLOCK_END=230100`

BLOCK_END can also be 0, in which case it will use the current block count. (`bitcoin-cli getblockcount`).

## Donations

If you want to support this software, please consider sending some bitcoins my way.

![Donate](https://chart.googleapis.com/chart?chs=250x250&cht=qr&chl=bitcoin:1KHcEwfZbMmZqkpsbv2YGBzvkqZFYUjnZW)

1KHcEwfZbMmZqkpsbv2YGBzvkqZFYUjnZW
