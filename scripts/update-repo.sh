#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_FILE="$REPO_ROOT/Packages"

echo "==> Updating TouchAutomation repository..."

# Step 1: Repackage .deb files to remove Conflicts field
echo "==> Patching .deb files (removing Conflicts)..."
TMPDIR=$(mktemp -d)
for TYPE in rootless roothide; do
    POOL_DIR="$REPO_ROOT/pool/$TYPE"
    for DEB in "$POOL_DIR"/*.deb; do
        [ -f "$DEB" ] || continue

        # Check if this .deb has Conflicts field
        if dpkg-deb -f "$DEB" | grep -q "^Conflicts:"; then
            echo "  Patching: $(basename "$DEB") - removing Conflicts"
            WORK="$TMPDIR/$(basename "$DEB")"
            mkdir -p "$WORK"
            dpkg-deb -R "$DEB" "$WORK"
            sed -i '/^Conflicts:/d' "$WORK/DEBIAN/control"
            dpkg-deb -b "$WORK" "$DEB"
            rm -rf "$WORK"
        fi
    done
done
rm -rf "$TMPDIR"

# Clear old Packages file
> "$PACKAGES_FILE"

PACKAGE_COUNT=0

# Process each pool directory
for TYPE in rootless roothide; do
    POOL_DIR="$REPO_ROOT/pool/$TYPE"

    # Process .deb files (extract control from deb)
    for DEB in "$POOL_DIR"/*.deb; do
        [ -f "$DEB" ] || continue

        echo "  Processing: $(basename "$DEB") ($TYPE)"

        CONTROL=$(dpkg-deb -f "$DEB")

        # Append jailbreak type suffix to Name field
        SUFFIX=$(echo "$TYPE" | sed 's/rootless/(rootless)/;s/roothide/(roothide)/')
        CONTROL=$(echo "$CONTROL" | sed "s/^Name: \(.*\)/Name: \1 $SUFFIX/")

        SIZE=$(stat -c%s "$DEB" 2>/dev/null || stat -f%z "$DEB" 2>/dev/null)
        MD5=$(md5sum "$DEB" | cut -d' ' -f1)
        SHA256=$(sha256sum "$DEB" | cut -d' ' -f1)
        FILENAME="pool/$TYPE/$(basename "$DEB")"

        echo "$CONTROL" >> "$PACKAGES_FILE"
        echo "Filename: $FILENAME" >> "$PACKAGES_FILE"
        echo "Size: $SIZE" >> "$PACKAGES_FILE"
        echo "MD5sum: $MD5" >> "$PACKAGES_FILE"
        echo "SHA256: $SHA256" >> "$PACKAGES_FILE"
        echo "" >> "$PACKAGES_FILE"

        PACKAGE_COUNT=$((PACKAGE_COUNT + 1))
    done

    # Process non-.deb files (.tipa, .ipa, etc.) using sidecar control files
    # For each file like "package.tipa", place a "package.tipa.control" next to it
    for PKG in "$POOL_DIR"/*.tipa "$POOL_DIR"/*.ipa; do
        [ -f "$PKG" ] || continue

        CONTROL_FILE="${PKG}.control"
        if [ ! -f "$CONTROL_FILE" ]; then
            echo "  WARNING: No control file for $(basename "$PKG"), generating default..."
            BASENAME=$(basename "$PKG" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
            cat > "$CONTROL_FILE" << CTRL_EOF
Package: com.touchautomation.${BASENAME}
Name: $(basename "$PKG")
Version: 1.0
Architecture: iphoneos-arm64
Maintainer: TouchAutomation
Section: Tweaks
Description: $(basename "$PKG")
CTRL_EOF
        fi

        echo "  Processing: $(basename "$PKG") ($TYPE)"

        CONTROL=$(cat "$CONTROL_FILE")
        SIZE=$(stat -c%s "$PKG" 2>/dev/null || stat -f%z "$PKG" 2>/dev/null)
        MD5=$(md5sum "$PKG" | cut -d' ' -f1)
        SHA256=$(sha256sum "$PKG" | cut -d' ' -f1)
        FILENAME="pool/$TYPE/$(basename "$PKG")"

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
Architectures: iphoneos-arm iphoneos-arm64 iphoneos-arm64e
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
