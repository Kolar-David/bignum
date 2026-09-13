#!/usr/bin/env bash

set -e

mkdir -p ./build

ghc -outputdir ./build -o Tests Tests.hs
