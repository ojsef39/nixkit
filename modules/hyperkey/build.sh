#!/bin/bash

swiftc hyperkey.swift -framework Cocoa -framework Carbon
codesign --entitlements hyperkey.entitlements -fs - hyperkey
#
# hidutil property --set '{"UserKeyMapping":[]}'
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'
