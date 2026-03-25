#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_FILE="$REPO_ROOT/Packages"

echo "==> Updating TouchAutomation repository..."

# Clear old Packages file
> "$PACKAGES_FILE"

PACKAGE_COUNT=0

# Process each pool directory
for TYPE in rootless roothide; do
    POOL_DIR="$REPO_ROOT/pool/$TYPE"

    for DEB in "$POOL_DIR"/*.deb; do
        [ -f "$DEB" ] || continue

        echo "  Processing: $(basename "$DEB") ($TYPE)"

        # Extract control info from .deb
        CONTROL=$(dpkg-deb -f "$DEB")

        # Get file metadata (handle both GNU and BSD stat)
        SIZE=$(stat -c%s "$DEB" 2>/dev/null || stat -f%z "$DEB" 2>/dev/null)
        MD5=$(md5sum "$DEB" | cut -d' ' -f1)
        SHA256=$(sha256sum "$DEB" | cut -d' ' -f1)
        FILENAME="pool/$TYPE/$(basename "$DEB")"

        # Write entry to Packages
        echo "$CONTROL" >> "$PACKAGES_FILE"
        echo "Filename: $FILENAME" >> "$PACKAGES_FILE"
        echo "Size: $SIZE" >> "$PACKAGES_FILE"
        echo "MD5sum: $MD5" >> "$PACKAGES_FILE"
        echo "SHA256: $SHA256" >> "$PACKAGES_FILE"
        echo "" >> "$PACKAGES_FILE"

        PACKAGE_COUNT=$((PACKAGE_COUNT + 1))
    done
done

echo "  Found $PACKAGE_COUNT package(s)"

# Generate compressed variants
echo "==> Compressing Packages..."
if [ -s "$PACKAGES_FILE" ]; then
    bzip2 -c9 "$PACKAGES_FILE" > "$PACKAGES_FILE.bz2"
    xz -c9 "$PACKAGES_FILE" > "$PACKAGES_FILE.xz"
else
    # Create empty compressed files if no packages
    > "$PACKAGES_FILE.bz2"
    > "$PACKAGES_FILE.xz"
fi

# Generate Release file with checksums
echo "==> Generating Release..."

generate_hash_entry() {
    local FILE="$1"
    local BASENAME="$2"
    local HASH_CMD="$3"
    if [ -s "$FILE" ]; then
        local HASH=$($HASH_CMD "$FILE" | cut -d' ' -f1)
        local FSIZE=$(stat -c%s "$FILE" 2>/dev/null || stat -f%z "$FILE" 2>/dev/null)
        echo " $HASH $FSIZE $BASENAME"
    fi
}

cat > "$REPO_ROOT/Release" << RELEASE_EOF
Origin: TouchAutomation
Label: TouchAutomation
Suite: stable
Version: 1.0
Codename: ios
Architectures: iphoneos-arm64
Components: main
Description: TouchAutomation - APT Repository for rootless and roothide jailbreaks
MD5Sum:
$(generate_hash_entry "$PACKAGES_FILE" "Packages" "md5sum")
$(generate_hash_entry "$PACKAGES_FILE.bz2" "Packages.bz2" "md5sum")
$(generate_hash_entry "$PACKAGES_FILE.xz" "Packages.xz" "md5sum")
SHA256:
$(generate_hash_entry "$PACKAGES_FILE" "Packages" "sha256sum")
$(generate_hash_entry "$PACKAGES_FILE.bz2" "Packages.bz2" "sha256sum")
$(generate_hash_entry "$PACKAGES_FILE.xz" "Packages.xz" "sha256sum")
RELEASE_EOF

echo "==> Done! Repository updated with $PACKAGE_COUNT package(s)."
