#!/usr/bin/env bash
# Compila Primer para macOS y lo firma de forma local.
# Uso: ./build.sh            compila y firma
#      ./build.sh --open     además abre la aplicación
set -euo pipefail

cd "$(dirname "$0")"

# La carpeta del ejecutable está ignorada por git, así que no existe en un clon nuevo
mkdir -p Primer.app/Contents/MacOS

swiftc -O Primer.swift -o Primer.app/Contents/MacOS/Primer

codesign --force --sign - Primer.app

echo "Listo: $(pwd)/Primer.app"

if [[ "${1:-}" == "--open" ]]; then
    open -n Primer.app
fi
