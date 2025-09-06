#!/bin/bash
set -e

echo "🔄 Updating devcontainer environment files..."

# Create backup directory if it doesn't exist
mkdir -p .devcontainer/backups

# Update VS Code extensions
echo "📦 Capturing VS Code extensions..."
if command -v code &> /dev/null; then
    code --list-extensions > .devcontainer/current-extensions.txt
    echo "   ✅ Extensions saved to .devcontainer/current-extensions.txt"
else
    echo "   ⚠️  VS Code CLI not available"
fi

# Update Python requirements
echo "🐍 Updating Python requirements..."
if command -v pip &> /dev/null; then
    pip freeze > requirements.txt
    echo "   ✅ Python packages saved to requirements.txt"
else
    echo "   ⚠️  pip not available"
fi

# Update system packages
echo "📋 Capturing system packages..."
if command -v dpkg &> /dev/null; then
    dpkg --get-selections > .devcontainer/installed-packages.txt
    apt-mark showmanual > .devcontainer/manual-packages.txt 2>/dev/null || echo "   ⚠️  Could not get manual packages"
    echo "   ✅ System packages saved to .devcontainer/installed-packages.txt"
else
    echo "   ⚠️  dpkg not available"
fi

# Update Node.js dependencies if package.json exists
if [ -f "package.json" ] && command -v npm &> /dev/null; then
    echo "📦 Updating Node.js dependencies..."
    npm list --depth=0 > .devcontainer/npm-packages.txt 2>/dev/null || echo "   ⚠️  Could not capture npm packages"
    echo "   ✅ Node packages saved to .devcontainer/npm-packages.txt"
fi

# Create timestamp
echo "⏰ Environment captured at: $(date)" > .devcontainer/last-updated.txt

echo ""
echo "✅ Environment files updated successfully!"
echo ""
echo "📁 Files created/updated:"
echo "   • .devcontainer/current-extensions.txt"
echo "   • requirements.txt"
echo "   • .devcontainer/installed-packages.txt"
echo "   • .devcontainer/manual-packages.txt"
if [ -f "package.json" ]; then
    echo "   • .devcontainer/npm-packages.txt"
fi
echo "   • .devcontainer/last-updated.txt"
echo ""
echo "🔧 To apply extensions to devcontainer.json, run:"
echo "   cat .devcontainer/current-extensions.txt | sed 's/.*/"&",/' > .devcontainer/extensions-formatted.txt"
