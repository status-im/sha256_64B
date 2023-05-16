import std/[random, stats, times, math], sha256_64B{.all.}, cligen/strUt, cligen

proc benchK(a: Algo, x: seq[uint64], bN=256, mN=5, aN=10, cold=false) =
  var o = newSeq[Digest](bN)    # Output hash/digests
  var s = 0u64
  var ra: RunningStat
  for aj in 0 ..< aN:           # Average loop
    var rm: RunningStat
    for m in 0 ..< mN:          # Minimum loop
      let t0 = epochTime()
      sha256_64Bs a, cast[pua Digest](o[0].addr),
                  cast[pua Block64](x[8*(mN*(m + aN*aj))].unsafeAddr), bN
      rm.push epochTime() - t0  # Note time & below accum chksum
      for b in 0 ..< bN: s += cast[ptr uint64](o[b][0].addr)[]
    ra.push (if cold: rm.max else: rm.min) # Avg(Most(Times))
  let scale = 1e9/bN.float      # Want amortized nanosec per hash
  let sigDt = ra.standardDeviation*scale/ra.n.float.sqrt
  echo a, " ", fmtUncertain(ra.mean*scale, sigDt), " ", s

proc bench*(algos: seq[Algo], bN=256, mN=5, aN=10, cold=false) =
  ## Small bench CLI for Potuz' asm hashtree lib largely to get at auto (but
  ## likely static unless we go ATLAS route) method choice on various CPUs.
  var x: seq[uint64]            # Pre-generated rand data
  for j in 1 .. 8*bN*mN*aN: x.add randState.next
  for a in algos: benchK(a, x, bN, mN, aN)

when defined(release): randomize()
when defined(linux): import cligen/osUt; setAffinity() # lessen CPU migration
dispatch bench, help={"bN":"block count", "mN":"most loop", "aN":"avg loop",
                      "cold": "average max times not min"}
