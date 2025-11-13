#!/bin/bash
# Sync mdBook sources to GitBook content/
mkdir -p gitbook/content
gitbook/.gitbook.yaml || echo "root: ./content
title: OmegaOS W3.x Book" > gitbook/.gitbook.yaml
rsync -av --delete book/src/ gitbook/content/ --exclude="images/"
echo "Synced $(find book/src/ -name '*.md' | wc -l) MD files to gitbook/content/"
# Optional: Tweak SUMMARY.md for GitBook (flatten if needed)
# sed -i 's/  - / - /g' gitbook/content/SUMMARY.md  # Example flatten
echo "Run 'cd gitbook && gitbook serve' for preview or 'gitbook push' to deploy."