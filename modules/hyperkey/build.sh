#!/bin/bash

set -e pipefail

# Locate the SDK path
default_sdk="$(xcrun --show-sdk-path)"


swiftc \
    -sdk "$default_sdk" \
    -framework Cocoa \
    -framework Carbon \
    -framework Foundation \
    -framework IOKit \
    -framework ApplicationServices \
    hyperkey.swift \
    -o hyperkey


# Make the output executable
chmod +x HyperKey

echo "Build complete: ./hyperkey"

#
# hidutil property --set '{"UserKeyMapping":[]}'
# hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}' > /dev/null
