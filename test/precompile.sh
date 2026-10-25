#!/bin/sh
# The precompile gate (slice S2, kickoff 1.5). Deploy examples/precompile.lang,
# then do one `evm run --prestate` step for each view and compare the result
# word with a constant. Each constant was confirmed at build (2026-10-15, evm
# 1.14.12) with a direct `evm run --input HEX --receiver 0x..0N` to the
# precompile address N (1 ecrecover, 6 ecAdd, 7 ecMul, 8 ecPairing) before it
# entered this file. The evaluator computes a closed ecAdd or ecMul (S8 B1):
# examples/bn254.lang gives k G in the host for each k of the mulX and mulY rows,
# with the same words. ecPairing and ecrecover stay stuck (R17). This gate
# compares the chain result only. It needs evm (go-ethereum), bc, od and
# build/slottool. Run it from the kit root.
set -u
fail=0
steps=0
tmp=${TMPDIR:-/tmp}/langc-precompile.$$
mkdir -p "$tmp"
. test/evmchain.sh

prog=examples/precompile.lang
caller=0x00000000000000000000000000000000000000aa

# call WANT NAME ARGS...: one step of the view or entry NAME with ARGS at
# TIMESTAMP 1. The result must equal WANT: `out HEX` (HEX as hexnorm), `ok`,
# `revert` or `trap`. An entry changes the storage of the next step.
call() {
  _want=$1 _name=$2
  shift 2
  steps=$((steps + 1))
  _input=$(input "$prog" "$_name" "$@")
  if ! step 1 "$caller" "$_input"; then
    echo "FAIL precompile $_name: evm: $(head -n 1 "$tmp/dump")"
    fail=$((fail + 1))
    return
  fi
  case $result in
    "out "*) _hex=${result#out }
      [ ${#_hex} -eq 64 ] && result="out $(hexnorm "$_hex")" ;;
  esac
  if [ "$result" != "$_want" ]; then
    echo "FAIL precompile $_name: want $_want, got $result"
    fail=$((fail + 1))
  fi
}

if ! deploy "$prog"; then
  echo "FAIL precompile deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  # 2G on BN254 (EIP-196): ecAdd (1,2) (1,2) and ecMul (1,2) 2.
  twoGx=30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3
  twoGy=15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4
  call "out $twoGx" addX 1u 2u 1u 2u
  call "out $twoGy" addY 1u 2u 1u 2u
  call "out $twoGx" mulX 1u 2u 2u
  call "out $twoGy" mulY 1u 2u 2u
  # ecMul (1,2) 0 is the point at infinity, (0, 0).
  call "out 0" mulX 1u 2u 0u
  call "out 0" mulY 1u 2u 0u
  # 3G, (r minus 1) G = (1, p minus 2) and r G = (0, 0), r the order of G1 (S8 B1;
  # confirmed 2026-10-18 with a direct `evm run` to 0x..07, evm 1.14.12).
  threeGx=769bf9ac56bea3ff40232bcb1b6bd159315d84715b8e679f2d355961915abf0
  threeGy=2ab799bee0489429554fdb7c8d086475319e63b40b9c5b57cdf1ff3dd9fe2261
  pMinusTwo=30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd45
  rMinusOne=0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000u
  rOrder=0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001u
  call "out $threeGx" mulX 1u 2u 3u
  call "out $threeGy" mulY 1u 2u 3u
  call "out 1" mulX 1u 2u "$rMinusOne"
  call "out $pMinusTwo" mulY 1u 2u "$rMinusOne"
  call "out 0" mulX 1u 2u "$rOrder"
  call "out 0" mulY 1u 2u "$rOrder"
  # (1, 1) is not on the curve: the precompile fails and the call reverts (R18).
  call revert addBad 2u
  # e(G1, G2) e(-G1, G2) = 1 (EIP-197), and the empty product is 1.
  call "out 1" pairOk
  call "out 1" pairNil
  # The go-ethereum ecrecover vector (core/vm/testdata/precompiles/ecRecover.json, CallEcrecover0).
  h=0x38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873eu
  sgood=0x789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02u
  addr=ceaccac640adf55b2028469bd36ba501f28b699d
  call "out $addr" recover "$h" 27 "$h" "$sgood"
  # s = 0 gives an empty output: the address is 0 (R18).
  call "out 0" recover "$h" 27 "$h" 0u
  # The same ecrecover statement twice (a fold over the pushed words, the end of
  # the list first): the valid s, then s = 0. The sum is the one address (M8).
  call ok sign "$sgood"
  call ok sign 0u
  call "out $addr" recoverSum
  # keccak256 of 64 zero bytes; `langc eval examples/precompile.lang hashZero` gives the same word.
  call "out ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5" hashv 0u 0u
  # leafStep i = natDiv i 2 + natMod i 2 (the parent index plus the side bit).
  call "out 4" leafStep 7
  call "out 3" leafStep 6
  call "out aa" addrWord 0x00000000000000000000000000000000000000aa
  # u256Mul and u256Div (S10 s2, Q-S10-9 (a)): MUL with the overflow trap, DIV with the 0 trap.
  call "out f" mulv 3u 5u
  call "out fffffffffffffffffffffffffffffffe00000000000000000000000000000001" mulv 0xffffffffffffffffffffffffffffffffu 0xffffffffffffffffffffffffffffffffu
  call trap mulv 0x8000000000000000000000000000000000000000000000000000000000000000u 2u
  call "out 3" divv 7u 2u
  call "out ffffffffffffffffffffffffffffffff" divv 0xfffffffffffffffffffffffffffffffe00000000000000000000000000000001u 0xffffffffffffffffffffffffffffffffu
  call trap divv 7u 0u
fi

# The private cast of examples/zkcast.lang (S8 B3a): the ring (p0, p1) at poll 0.
# The six words are the `dao b0` row of test/prove/expect.txt (choice, c_1, s_1,
# s_2, I.x, I.y): six refusals revert (S8 B3b), the valid cast enters, count 1
# reads 1, the same key image reverts.
prog=examples/zkcast.lang
c1=39381386088514315497347125331661662002366806678711758872472619958305300356361u
s1=10556691046619535408078082753355190806958972782948105030448836431921968396625u
s2=5075046572376896310100317466143363171635445558286582457308097647558945948934u
ix=10761449505403964036076757638925780734653286855769319211451479689235022075489u
iy=7813043007448227325775284969956458831967279497483528366357925175793623591926u
# The refusal words: bad1 to bad5 = c_1, s_1, s_2, I.x, I.y of a signature by
# zkKey 2 over the ring (p0, p2) at poll 0 (the host refuses it on the cast
# ring); p71 to p75 = the b0 member signed at poll 7u; s1r = s_1 + r.
bad1=114233635948204567937611136005807964635379552110520686947477480399687734882175u
bad2=4606903119986625213584159387736508097390161799663041052171944740195199651320u
bad3=19405452480297225842144819244991036144939704859909575586366782468791467929709u
bad4=12143800741274053729678695342025405071161578280145823471976847353119162962133u
bad5=5478805016161928785310155891281398518466491099139863695584469452713860577342u
p71=115326832689243201939208783265390243471483834046477764896127408546428269123821u
p72=6848704374829197146497408100537308754776627187049601801861139456475064325019u
p73=5324371756747053231067432293918824366492735010707968715625973090356803969703u
p74=10761449505403964036076757638925780734653286855769319211451479689235022075489u
p75=7813043007448227325775284969956458831967279497483528366357925175793623591926u
s1r=32444933918458810630324488498612465895507337183364139374147040618497776892242u
if ! deploy "$prog"; then
  echo "FAIL zkcast deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  # Six refusals before the valid cast: the entry checks the used key first, so
  # a vector with the b0 key image placed after the cast would revert for the key.
  # A signer outside the ring (p0, p1): the hash chain does not close.
  call revert cast 1u "$bad1" "$bad2" "$bad3" "$bad4" "$bad5"
  # The b0 words with the choice flipped to 0: the choice is in the hash.
  call revert cast 0u "$c1" "$s1" "$s2" "$ix" "$iy"
  # The b0 member signed at poll 7u: the poll id is in the hash.
  call revert cast 1u "$p71" "$p72" "$p73" "$p74" "$p75"
  # I = (1, 1) is not on bn254: the ecMul precompile returns 0, the code reverts.
  call revert cast 1u "$c1" "$s1" "$s2" 1u 1u
  # I = (0, 0): the precompile takes infinity, the chain fails, the last flag refuses.
  call revert cast 1u "$c1" "$s1" "$s2" 0u 0u
  # s_1 + r: the precompile reduces mod r and the chain closes; u256Le s_1 rmax refuses.
  call revert cast 1u "$c1" "$s1r" "$s2" "$ix" "$iy"
  call ok cast 1u "$c1" "$s1" "$s2" "$ix" "$iy"
  call "out 1" count 1u
  call revert cast 1u "$c1" "$s1" "$s2" "$ix" "$iy"
fi

# The one-hot ballot proofs of examples/onehot.lang (S10 s1, Q-S10-1 (a)):
# the words of `build/sigmatool words` (pk from blsag_key(5), ctx
# blsag_key(23), k 2, choice 1). The intent-lang S7 port: each ecMul, ecAdd
# and hash chain was confirmed there (2026-10-23, evm 1.14.12) with a direct
# `evm run` to 0x..06, 0x..07 or a keccak code. z + 1 fails randOk, the
# forged split of slot 0 (an encryption of 2) fails slotOk, and the split
# maxWord + 2 = 1 (modulo 2^256) passes without the trap of u256Add.
prog=examples/onehot.lang
wctx=0x165d47d57adae4a13e25107baeb75afb447248ec79152ef9fad26eac97ba177eu
wpkx=0x0968d432a7834f16726268caca7e1a398153743ee91bff7afa02f0ca6fdd1cefu
wpky=0x1b03a01c8bb70557c6ae6cc0e854ca3f1ff99bf86a8c867437e1d654b8238854u
s0c1x=0x0b32ee9502fbea21ed59bf4e9198cef815d87a58c9f30e87c950dc5faa0f5df8u
s0c1y=0x1eab782fcf92ebbc712c3d3a89fcbb8859038df33c8c792ce2c240c9a14364edu
s0c2x=0x1dc1189d0143f3bbf1196014d6ccb0d04189c26a0241d6338266428060556131u
s0c2y=0x171be7a10d9c991e95d1a22d9d1d0917a9ff0590a872d7614179eb22bf20817fu
s0a0x=0x25135c67b0307427422c6fe242eeeed17eb7945f8412c9277282da0125cdfeecu
s0a0y=0x07b5b92c527d5fd666715fb20a6da4e625e4f150ab71549cec8146e291f0149au
s0b0x=0x0606985761b99eaf9f2e80d64a21dcf2d89c1310e411395cdaf535e9d095eda3u
s0b0y=0x035e3eacb3f7097011e82df135aff72cb88fdbc173ceadd77c897332419a27e9u
s0a1x=0x1e88846757fb3f8b971ccab757f29a23f861358fc7425f889230ea4755764cb8u
s0a1y=0x2f20e36c608268bfec51d1814b66c82acbd45c268e755a1f91472cbc1e65ccb9u
s0b1x=0x2e8bda41bd08f2562e22cd58a9b90732a542662f331269ba72addfd02f983ee5u
s0b1y=0x0d49abdac41195fb6b248647c9ad9010d9c25e1ea9146fdbdcb5b7f378cbb148u
s0e0=0x6faeac6b62fe2c187afe5c4bb48022021fe4108eaa20c48090fdfebe2c7edf78u
s0e1=0x0ef7d8fc7ba5b5aada617108f8009a0d400d74938749e744a5e44e08bee0c1f1u
s0z0=0x134b833a9077298f8b4c871292751dbb6b6b5eb263ac0ca0bddad910930600adu
s0z1=0x0964a8f24a8737cca4409c4ff3ad3307e27101709b88508d59061c42c22c50d7u
s1c1x=0x1872c00f9a13d4ef35dedbbae4050f22038c055feaa32963d2923976b5d55e69u
s1c1y=0x1db9f31831e6861aad480f5c7ebf778deda29d7bba582730418ee98499867e0fu
sumc1x=0x2f87c2138b9a349174c49a78c8bf1b12ab7b639b953135c0063e1d3db5ed4294u
sumc1y=0x12bb1fff7bfbf6d742d74adb8e0f9b9ca9e86c1cb64551cb59bd21303ef262f1u
sumc2x=0x1f64eaba25542c7dee1b41bbe25b36b20713de4cdbaf1817883c7da1ba7290b5u
sumc2y=0x2a88156a2bd65b8241108574ad3335797ffd995d8201836741ab5d53c593d25cu
sumax=0x1357fdbc12f002c9350a6850f66d0f53a50eb71a0352ce19ce594259b19c32e5u
sumay=0x0d9e5cad710ea83bd84be8c626488de680ed285cba48866813a8d3ee1fc4cbbdu
sumbx=0x2c4716f2bfcfca295be12849d64d8d442780f1d27e452459825b85de8da52f28u
sumby=0x1bee6e8a256611724dc7e3966b75945b4722c180e0de3d738d0d37ae803cf3ddu
sumz=0x2943f4819ae982763e3016a5d6f4a54ba7ec3ed2939186bf6f51baa02ac06d30u
sumzbad=0x2943f4819ae982763e3016a5d6f4a54ba7ec3ed2939186bf6f51baa02ac06d31u
fc1x=0x13595f66a0a2e2d61015668c55f8bcd0288e619830ca19aa601f4f024821c75bu
fc1y=0x2be3b092f87a4bb4f2d8a5246c14541f1ad0d730bf1591cf158b5772a13b4eb9u
fc2x=0x02c60b6cb0a59f5546a6371be9833002bd69c38253e67ea53e294686e07bb00eu
fc2y=0x052185f10c8b7838fdb0abf4279629523ece4f08bfd236765ef369beeb5f459cu
fa0x=0x092033173cacce9202703314152285ae3a6d3c10c49438a7a2af8a8fd072f95eu
fa0y=0x0b52cbce26803a3889d1c18d83c88d57c26d70b45d81abf3970b305b782d0946u
fb0x=0x253c919fd3bb2ba6d2d2724f53ca60e350b4ae9d51639d825e25b34609c39649u
fb0y=0x295f9276881af8976fb39112281cee6ce1a54f74989034850cdfc9ea375459c0u
fa1x=0x136c7c5f4608b42851699653b678a174294b83051c934f5e47ccc177f769832eu
fa1y=0x16cee4a2fc0b36f54460f7da5f06b6a96ff1762f2fe7d0f629f394551977891fu
fb1x=0x221a789806ab05b0de16b97cb797dc21f13811a8bb43ff88fda988faa06730deu
fb1y=0x129e7d4979010c9897e787f976e5a9633949b2816ec1ba2030cb7eba31612a7eu
fe0=0x1f9db1de5bdcdf7689acd41f1944259d1709531bd6c420081a60b695e9a87738u
fe1=0x0ecd2e5cb928db41d562959a119b5e280aae61e7b3e45ed566a6579bf4aed0d0u
fz0=0x1155cee05885e4b13c009fc8a8a0493b2823c1febfc3daf50b33e1e0a6eb4841u
fz1=0x20f0a7e0737ce8053f5d12c4b64a2251b04b38e2aad9cb1cc8f2f286d7904d06u
if ! deploy "$prog"; then
  echo "FAIL onehot deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  call "out 1" randOk "$wctx" "$wpkx" "$wpky" "$sumc1x" "$sumc1y" "$sumc2x" "$sumc2y" 1u "$sumax" "$sumay" "$sumbx" "$sumby" "$sumz"
  call "out 0" randOk "$wctx" "$wpkx" "$wpky" "$sumc1x" "$sumc1y" "$sumc2x" "$sumc2y" 1u "$sumax" "$sumay" "$sumbx" "$sumby" "$sumzbad"
  call "out 1" slotOk "$wctx" 0u "$wpkx" "$wpky" "$s0c1x" "$s0c1y" "$s0c2x" "$s0c2y" "$s0a0x" "$s0a0y" "$s0b0x" "$s0b0y" "$s0a1x" "$s0a1y" "$s0b1x" "$s0b1y" "$s0e0" "$s0e1" "$s0z0" "$s0z1"
  call "out 0" slotOk "$wctx" 0u "$wpkx" "$wpky" "$fc1x" "$fc1y" "$fc2x" "$fc2y" "$fa0x" "$fa0y" "$fb0x" "$fb0y" "$fa1x" "$fa1y" "$fb1x" "$fb1y" "$fe0" "$fe1" "$fz0" "$fz1"
  call "out 1" splitView 1u 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffu 2u
  call "out 2f87c2138b9a349174c49a78c8bf1b12ab7b639b953135c0063e1d3db5ed4294" sumX "$s0c1x" "$s0c1y" "$s1c1x" "$s1c1y"
  call "out 12bb1fff7bfbf6d742d74adb8e0f9b9ca9e86c1cb64551cb59bd21303ef262f1" sumY "$s0c1x" "$s0c1y" "$s1c1x" "$s1c1y"
fi

# The written DAO contract (S9 B1): the text of `langc contract examples/dao.lang`.
# The cast words come from `langc prove test/contract/ballots.lang NAME POLL`
# (choice, c_1, s_1, s_2, I.x, I.y): the prove ring depends only on the Member
# cardinality, 2 as in examples/dao.lang. Before 2 casts the outcome is 2 (no
# outcome). m0 votes 0 and m1 votes 1, so agree0 gives outcome 1; enact adopts
# constitution 1 and opens poll 1, where the poll 0 words of m0 revert.
build/langc contract examples/dao.lang >"$tmp/dao.lang"
prog="$tmp/dao.lang"
ballot() {
  build/langc prove test/contract/ballots.lang "$1" "$2" | tr '\n' ' '
}
if ! deploy "$prog"; then
  echo "FAIL contract deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  m0p0=$(ballot m0c0 0u)
  m0p1=$(ballot m0c0 1u)
  m1p0=$(ballot m1c1 0u)
  m1c2=$(ballot m1c2 0u)
  call "out 2" outcome
  call revert enact
  call "out 0" selfConstituting
  call ok cast $m0p0
  call revert cast $m0p0
  # A valid signature over choice 2: the contract has 2 choices.
  call revert cast $m1c2
  call ok cast $m1p0
  call "out 1" count 0u
  call "out 1" count 1u
  call "out 1" outcome
  call ok enact
  call "out 1" poll
  call "out 1" constitution
  call "out 0" selfConstituting
  call revert cast $m0p0
  call ok cast $m0p1
  call "out 1" count 0u
fi

# The differential (S9 B2) on the EVM: for each row of test/contract/diff.txt,
# the calls of test/run.sh on a new deploy of the written contract `langc
# contract examples/PROG.lang --start START`. The SELF word is 1 for flagYes and
# 0 for flagNo. The rows are read on fd 3, so evm and langc cannot read them.
diffs=0
while read -r line <&3; do
  case $line in --*|'') continue ;; esac
  set -- ${line%% => *}
  want=${line#* => }
  diffs=$((diffs + 1))
  if ! build/langc contract "examples/$1.lang" --start "$2" >"$prog" || ! deploy "$prog"; then
    echo "FAIL differential deploy $line: $(head -n 1 "$tmp/dump")"
    fail=$((fail + 1))
    continue
  fi
  ballots=$5
  before=$fail
  shift 5
  for name in "$@"; do
    call ok cast $(build/langc prove "test/contract/$ballots.lang" "$name" 0u | tr '\n' ' ')
  done
  call "out ${want%% *}" outcome
  call ok enact
  call "out ${want#* }" selfConstituting
  [ "$fail" -eq "$before" ] || echo "FAIL differential row: $line"
done 3<test/contract/diff.txt
echo "differential: $diffs EVM rows checked"

# The side value (S10 s2, Q-S10-5 (a)): deploy examples/side.lang with the
# 32-byte word 7 after the creation code. init : U256 -> State writes the word
# to field 0 (slot 0), and the view sideOf gives it. The guest evaluator does
# not see the appended word, thus only this row tests it (test/run/side.script
# gives the word on the init line).
prog=examples/side.lang
if ! deploy "$prog" 0000000000000000000000000000000000000000000000000000000000000007; then
  echo "FAIL side deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  steps=$((steps + 1))
  side=$(hexnorm "$(awk '$1 ~ /^0+$/ { print $2 }' "$tmp/raw")")
  [ "$side" = 7 ] || { echo "FAIL side slot 0: want 7, got $side"; fail=$((fail + 1)); }
  call "out 7" sideOf
fi

# A constructor argument is one complete ABI word. Missing, partial and
# extra words must revert instead of reading runtime bytes or the final word.
for bad in '' 07 00000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000008; do
  steps=$((steps + 1))
  if deploy "$prog" "$bad" && [ -n "$(cat "$tmp/code")" ]; then
    echo "FAIL side malformed constructor: deployed with $((${#bad} / 2)) argument bytes"
    fail=$((fail + 1))
  elif ! awk '/execution reverted/ { found = 1 } END { exit !found }' "$tmp/dump"; then
    echo "FAIL side malformed constructor: expected a revert"
    fail=$((fail + 1))
  fi
done

rm -rf "$tmp"
echo "precompile: $steps steps checked"
echo "precompile gate: $fail failures"
[ "$fail" -eq 0 ]
