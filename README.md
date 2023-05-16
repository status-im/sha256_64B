This is a Nim wrapper for https://github.com/prysmaticlabs/hashtree which is
about SHA256 hashing batches of 64B blocks in parallel which can be useful to
hash a [Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree).

## Building & Testing

It should just work to:

    nimble install sha256_64B

You could then do an out-of-tree test by
```
    cp -pr tests /tmp
    cd /tmp/tests
    nim c bench
    ./bench a28
```
(On Windows you may need to use a very large `-b=` to get a long enough test
for meaningful times.)

## Supported platforms

The optimization so far is only done on amd64/x86\_64 and some ARM. Object files
for libhashtree.a are only provided for Linux, Windows, & OSX.  (This should be
made more specific in a few ways.)

## License

Licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. These files may not be copied, modified, or distributed except according to those terms.
