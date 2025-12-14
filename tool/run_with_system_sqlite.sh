#!/usr/bin/env bash
set -euo pipefail

# Use macOS system sqlite to avoid downloading native libs.
export SQLITE3_LIB_PATH="/usr/lib/libsqlite3.dylib"
export SQLITE3_LIB_DIR="/usr/lib"

flutter run -d macOS "$@"
