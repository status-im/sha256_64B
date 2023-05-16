# Copyright (c) 2023 Status Research & Development GmbH
# Licensed under either of
#   Apache License, version 2.0,
#   MIT license
# at your option.  This file may not be copied, modified, or distributed except
# according to those terms.

import std/[os, strutils]

# Binary lib distribution is rare, but since github.com/prysmaticlabs/hashtree
# is in gas-specific .S files & Apple defaults development kits to LLVM-based
# tools which do not include gas, it seems unavoidable on OSX.  Distributing
# all 3 chooses internal consistency (vs. external doing only OSX).
const
  topPath = currentSourcePath.parentDir.replace('\\', '/')
  libPath = topPath & "/install/usr/lib"

when defined linux:   (const ops  = "Lin"; const ext = ".a")
elif defined osx:     (const ops  = "Osx"; const ext = ".a")
elif defined windows: (const ops  = "W64"; const ext = ".lib") #Q: Win32 Needed?

when defined amd64:   (const cpu = "X64")
elif defined arm64:   (const cpu = "A64")

{.passl: libPath & "/libhashtree" & ops & "_" & cpu & ext.}
{.passl: "-lcrypto".}           #XXX or BearSSL?
type
  Digest*  = array[32, byte] ## Outputs
  Block64* = array[64, byte] ## Inputs; OR array[2, Digest], but input is really more general
  Algo     = enum sse, a4, a28, a5, ni, ssl

# These are defined as pure .S.  So, a C .h header adds nothing.  Library paths
# per platform above are already complex enough deployment.  These are the very
# UNSAFE, unexported `pointer` variants.
proc hashtree_sha256_sse_x1(    o, i: pointer; n: uint64) {.importc.}
proc hashtree_sha256_avx_x4(    o, i: pointer; n: uint64) {.importc.}
proc hashtree_sha256_avx2_x8(   o, i: pointer; n: uint64) {.importc.}
proc hashtree_sha256_avx512_x16(o, i: pointer; n: uint64) {.importc.}
proc hashtree_sha256_shani_x2(  o, i: pointer; n: uint64) {.importc.}
proc SHA256(i: pointer, n: uint64, o: pointer) {.importc.}

template pua(T: typedesc): untyped = ptr UncheckedArray[T] ## pua T ~ C's T[]

proc sha256_64Bs(algo: Algo, o: pua Digest, i: pua Block64, bN: int) =
  ## A batch interface to SHA256 hashing of `bN` 64 Byte blocks.  Here callers
  ## must allocate space for the output, `o`.
  case algo
  of sse: hashtree_sha256_sse_x1(    o[0].addr, i[0].addr, bN.uint64)
  of a4 : hashtree_sha256_avx_x4(    o[0].addr, i[0].addr, bN.uint64)
  of a28: hashtree_sha256_avx2_x8(   o[0].addr, i[0].addr, bN.uint64)
  of a5 : hashtree_sha256_avx512_x16(o[0].addr, i[0].addr, bN.uint64)
  of ni : hashtree_sha256_shani_x2(  o[0].addr, i[0].addr, bN.uint64)
  of ssl: (for b in 0 ..< bN: SHA256(i[b].addr, 64, o[b].addr))

## This will soon instead become a call to hashtree_init
proc cpuID(eaxi=0i32, ecxi=0i32): tuple[eax, ebx, ecx, edx: int32] =
  when defined(vcc):
    proc cpuidVcc(cpuInfo: ptr int32; functionID: int32)
      {.importc: "__cpuidex", header: "intrin.h".}
    cpuidVcc(addr result.eax, eaxi, ecxi)
  else:
    var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
    asm """cpuid
           :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
           :"a"(`eaxi`), "c"(`ecxi`)"""
    (eaxr, ebxr, ecxr, edxr)

when defined amd64:
  let
    leaf1 = cpuID(1)
    leaf7 = cpuID(7) # leaf8 = cpuID(0x80000001'i32)
  proc test(input, bit: int): bool = ((1 shl bit) and input) != 0

  proc cpuHasSSE42:    bool = leaf1.ecx.test(20)
  proc cpuHasAVX:      bool = leaf1.edx.test(28)
  proc cpuHasAVX2:     bool = leaf7.ebx.test(5)
  proc cpuHasBMI2:     bool = leaf7.ebx.test(8)
  proc cpuHasSHA:      bool = leaf7.ebx.test(29)
  proc cpuHasAVX512F:  bool = leaf7.ebx.test(16)
  proc cpuHasAVX512VL: bool = leaf7.ebx.test(31)


proc sha256_64Bs(o: pua Digest, i: pua Block64, bN: int) =
  ## A runtime-CPU dispatching batch interface to SHA256 hashing of `bN` 64 Byte
  ## blocks into half as many output bytes. Here callers must allocate space for
  ## the output, `o`.
  let algo =
    when defined amd64:
      if   cpuHasAVX512F() and cpuHasAVX512VL(): a5  # Have not tested myself
      elif cpuHasSHA()     and cpuHasAVX()     : ni
      elif cpuHasAVX2()    and cpuHasBMI2()    : a28 #AESNI PCLMULQDQ?
      elif cpuHasAVX()                         : a4
      elif cpuHasSSE42()                       : sse #AESNI PCLMULQDQ CMOV BSWAP
      else                                     : ssl # SSL fall back
#   elif defined arm64: XXX Feature testing on ARM is reportedly more subtle.
    else: ssl
# echo "algo: ", algo # Just for testing cpu-based algo selection
  sha256_64Bs(algo, o, i, bN)

proc sha256_64Bs*(o: var seq[Digest], i: openArray[Block64]) =
  ## A high level batch interface to SHA256 hashing of `bN` 64 Byte blocks.
  o.setLen i.len
  sha256_64Bs cast[pua Digest](o[0].addr), cast[pua Block64](i[0].addr), i.len
