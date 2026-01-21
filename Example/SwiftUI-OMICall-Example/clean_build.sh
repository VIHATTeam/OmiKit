#!/bin/bash

# Clean build script for Swift 6 project

echo "🧹 Cleaning Xcode build artifacts..."

# Navigate to project directory
cd "$(dirname "$0")"

# Remove DerivedData
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SwiftUI-OMICall-Example-*

# Remove build folder
echo "Removing build folder..."
rm -rf build/

# Remove Pods
echo "Removing Pods..."
rm -rf Pods/
rm -rf Podfile.lock

# Clean module cache
echo "Cleaning module cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/

# Reinstall pods
echo "📦 Installing Pods with Swift 6 configuration..."
pod install

echo "✅ Clean build completed!"
echo ""
echo "Next steps:"
echo "1. Open SwiftUI-OMICall-Example.xcworkspace in Xcode"
echo "2. Product > Clean Build Folder (Shift+Cmd+K)"
echo "3. Product > Build (Cmd+B)"
