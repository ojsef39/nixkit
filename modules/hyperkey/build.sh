#!/bin/bash

swiftc hyperkey.swift -framework Cocoa -framework Carbon
codesign --entitlements hyperkey.entitlements -fs - hyperkey
