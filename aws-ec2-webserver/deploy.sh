#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script with sudo: sudo bash deploy.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="/var/www/html"

for file in index.html style.css script.js; do
  if [[ ! -f "${SCRIPT_DIR}/${file}" ]]; then
    echo "Required file is missing: ${SCRIPT_DIR}/${file}" >&2
    exit 1
  fi
done

dnf install -y httpd
install -d -o root -g root -m 0755 "${WEB_ROOT}"
install -o root -g root -m 0644 "${SCRIPT_DIR}/index.html" "${WEB_ROOT}/index.html"
install -o root -g root -m 0644 "${SCRIPT_DIR}/style.css" "${WEB_ROOT}/style.css"
install -o root -g root -m 0644 "${SCRIPT_DIR}/script.js" "${WEB_ROOT}/script.js"

systemctl enable --now httpd
systemctl is-active --quiet httpd

echo "Website deployed. Apache is active and serving files from ${WEB_ROOT}."
