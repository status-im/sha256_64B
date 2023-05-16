import sha256_64B {.all.}

proc cpuName(): string =          # This is just to test cpuID
  var leaves {.global.} = cast[array[48, char]]([cpuID(0x80000002'i32),
                                                 cpuID(0x80000003'i32),
                                                 cpuID(0x80000004'i32)])
  $cast[cstring](leaves[0].addr)

echo cpuName() # Output should match `uname -p` on Unix
