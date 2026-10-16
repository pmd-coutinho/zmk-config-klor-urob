#!/usr/bin/env bash
# Keymap simulation tests: builds config/klor.keymap for ZMK's native_sim board
# with a mock key matrix, replays the key presses in tests/<case>/native_sim.keymap
# and diffs the HID output against tests/<case>/expected.log.
# Runs inside the build container (see `make test`). ACCEPT=1 rewrites expected.log.
set -uo pipefail
cd /workspace/.zmk
west zephyr-export > /dev/null
mkdir -p build/tests
fail=0
for dir in /workspace/tests/*/; do
    name=$(basename "$dir")
    [[ -n "${1:-}" && "$name" != "$1" ]] && continue
    build=build/tests/$name
    if ! west build -p -s zmk/app -d "$build" -b native_sim//zmk_test_mock -- \
        -DCONFIG_ASSERT=y -DZMK_CONFIG="$dir" -DZMK_EXTRA_MODULES=/workspace \
        > "$build.log" 2>&1; then
        echo "FAIL $name (build error, see .zmk/$build.log)"; fail=1; continue
    fi
    "$build/zephyr/zmk.exe" | python3 /workspace/tests/decode.py > "$build/events.log"
    [[ "${ACCEPT:-0}" == 1 ]] && cp "$build/events.log" "$dir/expected.log"
    if diff -u "$dir/expected.log" "$build/events.log"; then
        echo "PASS $name"
    else
        echo "FAIL $name"; fail=1
    fi
done
exit $fail
