#!/bin/bash
# Capture screenshots of every screen in the Chronos app via the screenshot tour.
set -e

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
DEVICE="iPhone 17 Pro"
BUNDLE="codernsingh.chronos"
SCREENSHOT_DIR="/Users/Narendra/Developer/iOS Development ( Swift )/chronos/screenshot"

# Helper: launch the app with a tour screen, wait for render, capture.
capture() {
    local screen="$1"
    local filename="$2"
    local wait="${3:-3.5}"

    echo "→ $filename (screen=$screen, wait=${wait}s)"
    xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
    sleep 0.4
    xcrun simctl launch booted "$BUNDLE" -chronos-screen "$screen" >/dev/null
    sleep "$wait"
    xcrun simctl io booted screenshot "$SCREENSHOT_DIR/$filename"
    echo "   saved $filename"
}

# Onboarding & sheets
capture "model_picker_onboarding" "02_model_picker.png" 4.0
capture "home" "03_home.png" 4.0
capture "home_empty" "04_home_empty.png" 4.0
capture "roadmap" "05_roadmap.png" 4.5
capture "roadmap_in_progress" "06_roadmap_in_progress.png" 4.5
capture "roadmap_completed" "07_roadmap_completed.png" 4.5
capture "node_detail" "08_node_detail.png" 4.5
capture "node_detail_completed" "09_node_detail_completed.png" 4.5
capture "quiz_generation" "10_quiz_generation.png" 4.0
capture "quiz_play" "11_quiz_play.png" 4.0
capture "quiz_play_answered" "12_quiz_play_answered.png" 4.0
capture "quiz_results" "13_quiz_results_perfect.png" 4.0
capture "quiz_results_partial" "14_quiz_results_partial.png" 4.0
capture "level_up" "15_level_up_modal.png" 4.0
capture "profile" "16_profile.png" 4.0
capture "avatar_picker" "17_avatar_picker.png" 4.0
capture "settings" "18_settings.png" 4.0
capture "model_picker_settings" "19_model_picker_settings.png" 4.0

echo ""
echo "✅ All screenshots captured."
ls -la "$SCREENSHOT_DIR" | tail -25
