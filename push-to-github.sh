#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Push MSP Analytics to GitHub
# 
# Usage:
#   ./push-to-github.sh <github-username> [repo-name]
#
# Example:
#   ./push-to-github.sh myusername msp-analytics
# ═══════════════════════════════════════════════════════════════

set -e

GITHUB_USER="${1:-}"
REPO_NAME="${2:-msp-analytics}"

if [ -z "$GITHUB_USER" ]; then
    echo "Usage: ./push-to-github.sh <github-username> [repo-name]"
    echo ""
    echo "Example: ./push-to-github.sh myusername msp-analytics"
    exit 1
fi

REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo "═══════════════════════════════════════════════════════════════"
echo "  Pushing to GitHub: ${REPO_URL}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if remote already exists
if git remote get-url origin &>/dev/null; then
    echo "Remote 'origin' already exists. Updating URL..."
    git remote set-url origin "$REPO_URL"
else
    echo "Adding remote 'origin'..."
    git remote add origin "$REPO_URL"
fi

echo ""
echo "Pushing to GitHub..."
echo "(You may be prompted for your GitHub credentials or token)"
echo ""

git push -u origin main

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  SUCCESS! Repository pushed to:"
echo "  ${REPO_URL}"
echo "═══════════════════════════════════════════════════════════════"
