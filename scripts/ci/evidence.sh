#!/usr/bin/env bash
# Produces the lab's evidence on macOS: screenshots (light, dark, largest text, iPad),
# a GIF of the main flow, the accessibility audit and package coverage.
# Runs in the "Evidence" GitHub Actions workflow (or on any Mac).
#   scripts/ci/evidence.sh [all|shots|record|audit|coverage]
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
ROOT="$PWD"
OUT="$ROOT/evidence"
DD="$ROOT/.dd"
SHOTS="$HOME/lab-shots"   # UI tests write here through SIMULATOR_HOST_HOME
WHAT="${1:-all}"
PROJECT=PocketBudget.xcodeproj
SCHEME=PocketBudget
UITESTS=PocketBudgetUITests
mkdir -p "$OUT/images" "$SHOTS"

log() { printf '\n==> %s\n' "$*"; }

# pick <regex>: UDID of the first available simulator whose name matches (newest iOS first)
pick() {
  xcrun simctl list devices available -j | python3 -c '
import json, re, sys
pattern = re.compile(sys.argv[1])
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if ".iOS-" not in runtime:
        continue
    for device in devices[runtime]:
        if pattern.search(device["name"]):
            print(device["udid"])
            sys.exit(0)
' "$1"
}

IPHONE="$(pick '^iPhone [0-9]+$')"; [ -n "$IPHONE" ] || IPHONE="$(pick '^iPhone')"
SMALL="$(pick '^iPhone SE')"; [ -n "$SMALL" ] || SMALL="$(pick '^iPhone [0-9]+e$')"; [ -n "$SMALL" ] || SMALL="$IPHONE"
IPAD="$(pick '^iPad Pro')"; [ -n "$IPAD" ] || IPAD="$(pick '^iPad')"
log "Simulators: iPhone=$IPHONE small=$SMALL iPad=$IPAD"

boot() {
  xcrun simctl boot "$1" 2>/dev/null || true
  xcrun simctl bootstatus "$1" -b >/dev/null 2>&1 || true
  xcrun simctl status_bar "$1" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 2>/dev/null || true
}

build() {
  [ -d "$DD/Build/Products" ] && return 0
  log "Building the app and UI tests"
  [ -d "$PROJECT" ] || xcodegen generate
  xcodebuild build-for-testing -project "$PROJECT" -scheme "$SCHEME" \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" \
    CODE_SIGNING_ALLOWED=NO -quiet > "$OUT/build.log" 2>&1 \
    || { echo "Build failed: see evidence/build.log"; tail -40 "$OUT/build.log"; exit 1; }
}

# run_test <udid> <TestClass[/testMethod]> [VAR=value ...]
# GitHub's Mac simulators sometimes fail to launch an app ("Timed out while launching
# application"). Each test gets at most 5 minutes, and a failure is retried once on a
# freshly rebooted simulator.
run_once() {
  local udid="$1" test="$2"; shift 2
  env "$@" xcodebuild test-without-building -project "$PROJECT" -scheme "$SCHEME" \
    -destination "id=$udid" -derivedDataPath "$DD" -only-testing:"$UITESTS/$test" \
    -test-timeouts-enabled YES -default-test-execution-time-allowance 300 -maximum-test-execution-time-allowance 300 \
    CODE_SIGNING_ALLOWED=NO >> "$OUT/ui-tests.log" 2>&1
}

run_test() {
  local udid="$1" test="$2"; shift 2
  run_once "$udid" "$test" "$@" && return 0
  echo "  $test failed; rebooting the simulator and trying once more"
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  boot "$udid"
  run_once "$udid" "$test" "$@"
}

shots() {
  build
  # shot_set <udid> <tag> <appearance> <content size> [VAR=value ...]
  shot_set() {
    local udid="$1" tag="$2" look="$3" size="$4"; shift 4
    log "Screenshots: $tag"
    boot "$udid"
    xcrun simctl ui "$udid" appearance "$look"
    xcrun simctl ui "$udid" content_size "$size"
    run_test "$udid" ScreenshotTests TEST_RUNNER_SHOTS_TAG="$tag" "$@" || echo "Screenshot set $tag had failures"
    xcrun simctl ui "$udid" content_size large
    xcrun simctl ui "$udid" appearance light
  }
  shot_set "$IPHONE" light light large
  shot_set "$IPHONE" dark dark large
  shot_set "$SMALL" ax5 light accessibility-extra-extra-extra-large
  [ -n "$IPAD" ] && shot_set "$IPAD" ipad light large
  cp "$SHOTS"/*.png "$OUT/images/" 2>/dev/null || echo "No screenshots were produced"
}

record() {
  build
  log "Recording: demo"
  boot "$IPHONE"
  local mov="$OUT/demo.mov"
  xcrun simctl io "$IPHONE" recordVideo --codec=h264 --force "$mov" > /dev/null 2>&1 &
  local recorder=$!
  sleep 3
  run_test "$IPHONE" BudgetFlowUITests/testAddAnExpense TEST_RUNNER_DEMO_PACE=1 || echo "Recording test had failures"
  sleep 1
  kill -INT "$recorder" 2>/dev/null
  wait "$recorder" 2>/dev/null
  if [ -s "$mov" ] && command -v ffmpeg > /dev/null; then
    ffmpeg -y -loglevel error -i "$mov" \
      -vf "fps=8,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse" \
      -loop 0 "$OUT/images/demo.gif" || echo "GIF conversion failed"
  fi
}

audit() {
  build
  log "Accessibility audit"
  boot "$IPHONE"
  run_test "$IPHONE" AccessibilityAuditTests || echo "Audit test had failures"
  cp "$SHOTS/a11y-audit.md" "$OUT/" 2>/dev/null || echo "No audit report was produced"
}

coverage() {
  log "Package tests and coverage"
  COVERAGE_MD="$OUT/coverage.md" bash scripts/run_package_tests.sh > "$OUT/package-tests.log" 2>&1 \
    || echo "Package tests or the coverage gate failed: see evidence/package-tests.log"
}

case "$WHAT" in
  all) coverage; shots; audit; record ;;
  shots|record|audit|coverage) "$WHAT" ;;
  *) echo "Usage: $0 [all|shots|record|audit|coverage]"; exit 2 ;;
esac
log "Done. Evidence is in $OUT"
ls -la "$OUT" "$OUT/images" 2>/dev/null
exit 0
