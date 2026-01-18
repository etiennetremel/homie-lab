#!/usr/bin/env bash
# Encrypt secrets using age

set -euo pipefail

path="clusters/**/*.secret"
key="$HOME/.config/age/homie-key.txt"

for input in $path
do
  [ ! -f "$input" ] && continue
  output="$input.age"
  echo "Encrypting $input into $output";
  age -e -i "$key" -o "$output" "$input"
  rm "$input"
done
