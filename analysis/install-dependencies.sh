#!/usr/bin/env bash

apt-get update -qq
apt-get install -yqq libxml2-dev pandoc libxt-dev

SCRIPT_DIR="$(cd "$(dirname "$0")" &> /dev/null && pwd)"
Rscript "${SCRIPT_DIR}/install-dependencies.R"

rm -Rf /var/lib/apt/lists/*
