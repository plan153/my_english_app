#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "============================================="
echo "  PronouncePro - GitHub Auto Upload Helper"
echo "============================================="

# 1. Initialize Git if not already initialized
if [ ! -d ".git" ]; then
    echo "⚙️ Initializing local Git repository..."
    git init
    git branch -M main
else
    echo "✓ Git repository already initialized."
fi

# 2. Add remote URL if not set
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$REMOTE_URL" ]; then
    echo "⚠️ GitHub Remote Repository URL is not set."
    read -p "Enter your GitHub Repository URL (e.g., https://github.com/username/repo-name.git): " input_url
    if [ -z "$input_url" ]; then
        echo "❌ Error: GitHub repository URL cannot be empty."
        exit 1
    fi
    git remote add origin "$input_url"
    echo "✓ Linked to remote origin: $input_url"
else
    echo "✓ Linked remote origin: $REMOTE_URL"
fi

# 3. Request commit message
read -p "Enter commit message (Press Enter for default: 'feat: add GDD sentences database & translation toggle'): " commit_msg
if [ -z "$commit_msg" ]; then
    commit_msg="feat: add GDD sentences database & translation toggle"
fi

# 4. Git Operations
echo "📦 Adding files and creating commit..."
git add .

# Add a default .gitignore if missing, to prevent building artifacts upload
if [ ! -f ".gitignore" ]; then
    echo "Creating basic .gitignore..."
    cat <<EOT >> .gitignore
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
EOT
    git add .gitignore
fi

# Commit
git commit -m "$commit_msg" || echo "No changes to commit."

# 5. Push to GitHub
echo "🚀 Uploading to GitHub (git push)..."
git push -u origin main

echo "============================================="
echo "🎉 Code successfully uploaded to GitHub!"
echo "============================================="
echo "ℹ️ GitHub Actions will now automatically:"
echo "  1. Build the production version of Flutter Web."
echo "  2. Deploy the site to GitHub Pages."
echo "  "
echo "⚠️ Make sure you have enabled GitHub Pages in your repository settings:"
echo "  Settings -> Pages -> Build and deployment -> Source -> select 'GitHub Actions'"
echo "============================================="
EOT
