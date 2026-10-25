#!/bin/sh
# The DSL regressions extend the real twin program, including its entry guards.
set -eu
tmp=${TMPDIR:-/tmp}/langc-twin.$$
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cat examples/twin.lang test/twin.lang >"$tmp/twin.lang"
fail=0
rows=0
while read -r name want; do
  status=0
  got=$(build/langc --kit eval "$tmp/twin.lang" "$name" 2>"$tmp/err") || status=$?
  rows=$((rows + 1))
  if [ "$status" -ne 0 ] || [ "$got" != "$want" ]; then
    echo "FAIL twin $name: want $want, got exit $status: $got $(head -n 1 "$tmp/err")"
    fail=$((fail + 1))
  fi
done <test/twin.txt
echo "twin: $rows rows, $fail failures"
[ "$fail" -eq 0 ]
