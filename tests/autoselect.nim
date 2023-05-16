import sha256_64B {.all.}

var dig: array[1, Digest]; var b64: array[1, Block64]
sha256_64Bs cast[pua Digest](dig[0].addr), cast[pua Block64](b64[0].addr), 1
echo "dig: ", dig
