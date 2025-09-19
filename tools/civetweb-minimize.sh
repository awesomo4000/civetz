#!/bin/bash
# Script to minimize CivetWeb vendor directory to essentials only
# Run this after updating CivetWeb via git subtree pull

set -e

# Check we're in the right place
if [ ! -d "vendor/civetweb" ]; then
    echo "Error: vendor/civetweb directory not found"
    echo "Run this script from the project root"
    exit 1
fi

echo "Minimizing CivetWeb vendor directory..."

# Get initial size
BEFORE_SIZE=$(du -sh vendor/civetweb | cut -f1)
echo "Size before: $BEFORE_SIZE"

# Remove unnecessary directories
REMOVE_DIRS=(
    "vendor/civetweb/.github"
    "vendor/civetweb/ci"
    "vendor/civetweb/cmake"
    "vendor/civetweb/contrib"
    "vendor/civetweb/distribution"
    "vendor/civetweb/docs"
    "vendor/civetweb/examples"
    "vendor/civetweb/fuzztest"
    "vendor/civetweb/Qt"
    "vendor/civetweb/resources"
    "vendor/civetweb/src/third_party"
    "vendor/civetweb/test"
    "vendor/civetweb/unittest"
    "vendor/civetweb/VisualStudio"
    "vendor/civetweb/zephyr"
)

for dir in "${REMOVE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Removing $dir"
        rm -rf "$dir"
    fi
done

# Remove unnecessary build files
REMOVE_FILES=(
    "vendor/civetweb/CMakeLists.txt"
    "vendor/civetweb/Makefile"
    "vendor/civetweb/Makefile.in"
    "vendor/civetweb/Makefile.osx"
    "vendor/civetweb/Makefile.deprecated"
    "vendor/civetweb/appveyor.yml"
    "vendor/civetweb/build"
    "vendor/civetweb/conanfile.py"
    "vendor/civetweb/mingw.py"
    "vendor/civetweb/winmake.bat"
    "vendor/civetweb/.clang-format"
    "vendor/civetweb/.gitignore"
    "vendor/civetweb/.travis.yml"
    "vendor/civetweb/format.sh"
    "vendor/civetweb/test.sh"
    "vendor/civetweb/civetweb.pc.in"
)

for file in "${REMOVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Removing $file"
        rm -f "$file"
    fi
done

# Remove any Lua/Duktape related files from src/
LUA_DUKTAPE_FILES=(
    "vendor/civetweb/src/mod_duktape.inl"
    "vendor/civetweb/src/mod_lua.inl"
    "vendor/civetweb/src/mod_lua_shared.inl"
)

for file in "${LUA_DUKTAPE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Removing $file"
        rm -f "$file"
    fi
done

# Get final size
AFTER_SIZE=$(du -sh vendor/civetweb | cut -f1)
echo ""
echo "Minimization complete!"
echo "Size before: $BEFORE_SIZE"
echo "Size after:  $AFTER_SIZE"
echo ""
echo "Kept:"
echo "  - src/civetweb.c (main source)"
echo "  - src/*.h and src/*.inl files"
echo "  - include/ directory (public headers)"
echo "  - Core documentation files"