# Copyright (c) 2019-2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0,
#  * MIT license
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

mode = ScriptMode.Verbose

packageName   = "sha256_64B"
version       = "0.0.1"
author        = "Status Research & Development GmbH"
description   = "sha256 hash of batches of 64B blocks in parallel via pure asm lib hashtree"
license       = "MIT or Apache License 2.0"
installDirs   = @["install"]
installFiles  = @["sha256_64B.nim"]

requires "nim >= 1.0"
