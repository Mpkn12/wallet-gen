#!/bin/bash
set -e

REPO_OWNER="octra-labs"
REPO_NAME="wallet-gen"
INSTALL_DIR="$HOME/.octra"
TEMP_DIR="$HOME/.octra-tmp"

echo "=== ⚠️  SECURITY WARNING ⚠️  ==="
echo ""
echo "this tool generates real cryptographic keys. always:"
echo "  - keep your private keys secure"
echo "  - never share your mnemonic phrase"
echo "  - don't store wallet files on cloud services"
echo "  - use on a secure, offline computer for production wallets"
echo ""
read -p "press enter to continue..." < /dev/tty
echo ""

install_bun() {
  if ! command -v bun >/dev/null 2>&1; then
    echo "installing bun..."
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
  fi
}

get_latest_release() {
  curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/tags" |
    grep '"name":' |
    head -1 |
    sed 's/.*"name": "\(.*\)".*/\1/'
}

download_and_extract() {
  local tag=$1
  echo "downloading octra wallet generator..."

  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"

  local tarball_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/tarball/refs/tags/${tag}"
  curl -L -o "$TEMP_DIR/release.tar.gz" "$tarball_url"

  cd "$TEMP_DIR"
  tar -xzf release.tar.gz --strip-components=1
}

echo "fetching latest release information..."
LATEST_TAG=$(get_latest_release)
if [ -z "$LATEST_TAG" ]; then
  echo "❌ error: could not fetch latest release information."
  exit 1
fi

download_and_extract "$LATEST_TAG"
cd "$TEMP_DIR"

install_bun

echo "installing dependencies..."
bun install

echo "building standalone executable..."
bun run build

if [ ! -f "./wallet-generator" ]; then
  echo "❌ error: wallet-generator executable not found!"
  exit 1
fi

echo "installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp ./wallet-generator "$INSTALL_DIR/"

echo ""
echo "starting wallet generator server..."

cd "$INSTALL_DIR"
rm -rf "$TEMP_DIR"

echo "NOTE: open browser manually to http://localhost:8888"

./wallet-generator
