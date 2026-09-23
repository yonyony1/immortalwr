#!/bin/bash
# Runs before feeds update. Add custom feeds from custom-feeds.conf
set -e

echo "Using official ImmortalWrt feeds, loading custom feeds..."
if [ -f "$GITHUB_WORKSPACE/custom-feeds.conf" ];then
  cat "$GITHUB_WORKSPACE/custom-feeds.conf" >> feeds.conf.default
fi