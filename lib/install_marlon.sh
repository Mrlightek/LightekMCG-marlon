#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-$(pwd)}"
GEM_NAME="marlon"
BIN_TARGET="/usr/local/bin/marlon"

echo "Installing MARLON from ${REPO_URL}"

# If REPO_URL is a git URL, clone; otherwise assume local path
if [[ "${REPO_URL}" =~ ^https?:// ]] || [[ "${REPO_URL}" =~ ^git@ ]]; then
  TMPDIR="$(mktemp -d)"
  echo "Cloning ${REPO_URL} -> ${TMPDIR}"
  git clone "${REPO_URL}" "${TMPDIR}"
  cd "${TMPDIR}"
else
  cd "${REPO_URL}"
fi

# Ensure Ruby exists
if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby is required. Please install Ruby and retry."
  exit 1
fi

# Install bundler if missing
if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler missing. Installing bundler..."
  gem install bundler
fi

# Install dependencies & build gem
bundle install --path vendor/bundle || gem install bundler # try to continue even if bundle fails

if [ -f marlon.gemspec ]; then
  gem build marlon.gemspec
  GEMFILE=$(ls marlon-*.gem | tail -n1)
  echo "Installing gem ${GEMFILE}"
  gem install --local "${GEMFILE}"
else
  echo "No marlon.gemspec found - cannot build gem."
fi

# Symlink exe
if [ -f exe/marlon ]; then
  sudo ln -sf "$(ruby -e 'puts Gem.bindir')/marlon" "${BIN_TARGET}" 2>/dev/null || \
  sudo ln -sf "$(pwd)/exe/marlon" "${BIN_TARGET}"
  echo "Installed marlon binary to ${BIN_TARGET}"
else
  echo "No exe/marlon found to symlink. You can run the command with: ruby exe/marlon"
fi

echo "MARLON installation complete."
