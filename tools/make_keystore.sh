#!/usr/bin/env bash
# Creates the Nudge release key and prints the four values to store as GitHub
# repository secrets. Run it once, keep the .jks file and the password
# somewhere safe (a password manager): if the key is lost, installed copies can
# only be replaced by uninstalling first.
#
#   bash tools/make_keystore.sh [output.jks]
#
# Needs keytool (any JDK) and openssl.
set -euo pipefail

out="${1:-nudge-release.jks}"
alias_name="nudge"

command -v keytool >/dev/null || { echo "keytool not found: install a JDK"; exit 1; }
command -v openssl >/dev/null || { echo "openssl not found"; exit 1; }
[ ! -e "$out" ] || { echo "$out already exists; refusing to overwrite it"; exit 1; }

password="$(openssl rand -base64 36 | tr -dc 'A-Za-z0-9' | cut -c1-28)"

keytool -genkeypair -keystore "$out" -storetype PKCS12 \
  -alias "$alias_name" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$password" -keypass "$password" \
  -dname "CN=Jolly Panda Works, O=Jolly Panda Works"

echo
echo "Created $out. Add these repository secrets"
echo "(GitHub > Settings > Secrets and variables > Actions > New repository secret):"
echo
echo "NUDGE_KEYSTORE_PASSWORD = $password"
echo "NUDGE_KEY_ALIAS         = $alias_name"
echo "NUDGE_KEYSTORE_BASE64   = (the single line below)"
base64 < "$out" | tr -d '\n'
echo
echo
echo "NUDGE_KEY_PASSWORD is optional: the key password is the same as the store password."
echo "Do not commit $out."
