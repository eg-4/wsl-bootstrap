#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}ℹ️ ${1}${NC}"
}

log_success() {
  echo -e "${GREEN}✅ ${1}${NC}"
}

log_warn() {
  echo -e "${YELLOW}⚠️ ${1}${NC}"
}

log_error() {
  echo -e "${RED}❌ ${1}${NC}"
}

export RED
export GREEN
export YELLOW
export BLUE
export NC

export -f log_info
export -f log_success
export -f log_warn
export -f log_error
