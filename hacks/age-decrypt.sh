#!/usr/bin/env bash
# Decrypt secrets using age

set -euo pipefail

path="clusters/**/*.secret.age"
key="$HOME/.config/age/homie-key.txt"

for input in $path
do
  [ ! -f "$input" ] && continue
  output="${input%.age}"
  echo "Decrypting $input into $output";
  age -d -i "$key" -o "$output" "$input"
done
