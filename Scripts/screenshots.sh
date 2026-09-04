#!/bin/bash
#
# Captures App Store screenshots. A thin wrapper: the runner is shared across every app, and this
# app's part is `.screenshots.conf` plus "Sprite CutterUITests/ScreenshotTests.swift".
#
#   Scripts/screenshots.sh              # every platform
#   Scripts/screenshots.sh mac iphone   # only the named ones
#   Scripts/screenshots.sh --upload     # capture, then send the results to App Store Connect

set -euo pipefail
cd "$(dirname "$0")/.."

ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# The runner lives in iCloud next to the repos. Both defaults are places it has lived, so a checkout
# on a machine that has not caught up still finds it; APP_SCRIPTS_DIR wins over either.
for candidate in "${APP_SCRIPTS_DIR:-}" "$ICLOUD/Repos/Scripts" "$ICLOUD/Apps/Scripts"; do
    if [ -n "$candidate" ] && [ -x "$candidate/screenshots" ]; then
        exec "$candidate/screenshots" "$@"
    fi
done

echo "shared runner not found in ${APP_SCRIPTS_DIR:+$APP_SCRIPTS_DIR, }$ICLOUD/Repos/Scripts, $ICLOUD/Apps/Scripts" >&2
echo "(it lives in iCloud; set APP_SCRIPTS_DIR if yours is elsewhere)" >&2
exit 2
