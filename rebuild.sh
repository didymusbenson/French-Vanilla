#!/bin/bash
echo "Stopping any running Flutter apps..."
killall -9 flutter 2>/dev/null || true

echo "Uninstalling app from connected devices..."
flutter install --uninstall-only 2>/dev/null || true

echo "Cleaning build..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building and running app..."
flutter run

