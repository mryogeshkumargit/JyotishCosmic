#!/usr/bin/env bash
# Builds the Swiss Ephemeris shared library for the host so that `flutter test`
# can run the ephemeris tests (Flutter plugins are not loaded in unit tests).
#
# Usage: tool/build_sweph_test_lib.sh   (after `flutter pub get`)
set -euo pipefail
cd "$(dirname "$0")/.."

# Resolve the sweph package location from the package config written by pub get.
SWEPH_DIR=$(python3 -c "import json,urllib.parse as u;c=json.load(open('.dart_tool/package_config.json'));print([u.urlparse(p['rootUri']).path for p in c['packages'] if p['name']=='sweph'][0])" 2>/dev/null || true)
if [[ -z "${SWEPH_DIR}" || ! -d "${SWEPH_DIR}" ]]; then
  echo "sweph package not found; run 'flutter pub get' first" >&2
  exit 1
fi

OUT=build/test_native
mkdir -p "$OUT"
case "$(uname -s)" in
  Darwin) LIB="$OUT/libsweph.dylib"; SHARED="-dynamiclib" ;;
  *)      LIB="$OUT/libsweph.so";    SHARED="-shared" ;;
esac

SRC="$SWEPH_DIR/native/sweph/src"
cc -O2 -fPIC $SHARED -DDART_SHARED_LIB -I"$SRC" \
  "$SRC"/swecl.c "$SRC"/swedate.c "$SRC"/swehel.c "$SRC"/swehouse.c "$SRC"/swejpl.c \
  "$SRC"/swemmoon.c "$SRC"/swemplan.c "$SRC"/sweph.c "$SRC"/swephlib.c -lm -o "$LIB"

# Ephemeris data files used by the tests.
mkdir -p "$OUT/ephe_src"
cp "$SWEPH_DIR"/assets/ephe/sepl_18.se1 "$SWEPH_DIR"/assets/ephe/semo_18.se1 "$SWEPH_DIR"/assets/ephe/seleapsec.txt "$OUT/ephe_src/"
echo "Built $LIB"
