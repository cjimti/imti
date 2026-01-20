#!/bin/bash
# Build for production
rm -rf docs
hugo
echo "Built to docs/ with baseurl: https://imti.co"

# TIP: For dev server, use:
# hugo server --disableFastRender --buildDrafts -M
# The -M flag renders to memory, never touches docs/
