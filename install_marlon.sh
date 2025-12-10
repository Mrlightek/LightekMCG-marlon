#!/usr/bin/env bash
set -euo pipefail

# Usage:
# REPO_URL=https://github.com/you/marlon.git bash install_marlon.sh
REPO_URL="${REPO_URL:-$(pwd)}"
GEM_NAME="marlon"
BIN_TARGET="/usr/local/bin/marlon"

echo "Installing MARLON from ${REPO_URL}"

if [[ "${REPO_URL}" =~ ^https?:// ]] || [[ "${REPO_URL}" =~ ^git@ ]]; then
  TMPDIR="$(mktemp -d)"
  git clone "${REPO_URL}" "${TMPDIR}"
  cd "${TMPDIR}"
else
  cd "${REPO_URL}"
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby is required. Please install Ruby and retry."
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler missing. Installing bundler..."
  gem install bundler
fi

bundle install --path vendor/bundle || true

if [ -f marlon.gemspec ]; then
  gem build marlon.gemspec
  GEMFILE=$(ls marlon-*.gem | tail -n1)
  echo "Installing gem ${GEMFILE}"
  gem install --local "${GEMFILE}"
else
  echo "No marlon.gemspec found - cannot build gem."
fi

if [ -f exe/marlon ]; then
  if command -v gem >/dev/null 2>&1; then
    GEM_BIN_DIR=$(ruby -e 'puts Gem.bindir')
    if [ -f "${GEM_BIN_DIR}/marlon" ]; then
      sudo ln -sf "${GEM_BIN_DIR}/marlon" "${BIN_TARGET}"
    else
      sudo ln -sf "$(pwd)/exe/marlon" "${BIN_TARGET}"
    fi
  else
    sudo ln -sf "$(pwd)/exe/marlon" "${BIN_TARGET}"
  fi
  echo "Installed marlon binary to ${BIN_TARGET}"
else
  echo "No exe/marlon found to symlink. Use: ruby exe/marlon"
fi

echo "MARLON installation complete."
