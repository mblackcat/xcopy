#!/bin/bash
set -euo pipefail

#=============================================================
# ClipVault Release Script
#
# Usage:
#   ./release.sh                        仅打包（使用 Info.plist 中的当前版本号）
#   ./release.sh -v 1.2                 指定版本号打包
#   ./release.sh --upload               打包 + 发布到 GitHub Releases
#   ./release.sh -v 1.2 --upload        指定版本号打包 + 发布
#   ./release.sh --help                 查看帮助
#
# 发布依赖:
#   - 已安装 GitHub CLI (`gh`)
#   - 已完成 `gh auth login`
#=============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
PLIST="$PROJECT_DIR/Resources/Info.plist"
APP_NAME="ClipVault"
REPO_SLUG="mblackcat/xcopy"

VERSION=""
UPLOAD=false

usage() {
    cat <<'HELP'
ClipVault Release Script

用法:
  ./release.sh [选项]

选项:
  -v, --version VERSION   指定版本号（如 1.2、2.0.0），会同步更新 Info.plist
  -u, --upload            打包后发布到 GitHub Releases
  -h, --help              显示此帮助信息

示例:
  ./release.sh                    仅打包，版本号取 Info.plist 当前值
  ./release.sh -v 1.2             以版本 1.2 打包
  ./release.sh --upload           打包并发布到 GitHub Releases
  ./release.sh -v 1.2 --upload    以版本 1.2 打包并发布到 GitHub Releases

发布前请确保:
  1. 已安装 GitHub CLI (`gh`)
  2. 已执行 `gh auth login`
  3. 当前仓库远程指向 GitHub 仓库
HELP
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -u|--upload)
            UPLOAD=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 ./release.sh --help 查看帮助"
            exit 1
            ;;
    esac
done

if [[ -n "$VERSION" ]]; then
    echo ">>> 更新版本号为 $VERSION ..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
    echo "    Info.plist 已更新"
else
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
    echo ">>> 使用当前版本号: $VERSION"
fi

TAG_NAME="v${VERSION}"
RELEASE_NAME="ClipVault ${TAG_NAME}"
ZIP_NAME="${APP_NAME}-${TAG_NAME}-macOS.zip"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}"
RELEASE_NOTES=$(cat <<'EOF'
## What's new

- Default global shortcut is now Option+V
- README updated for the GitHub repository and release flow
- Added a noncommercial license for public distribution

## Features

- Clipboard history for text, images, rich text, files, and folders
- Menu bar access with a global hotkey
- Automatic paste back into the current app
- Local-only storage under ~/Library/Application Support/ClipVault/

## Requirements

- macOS 13.0+
- Accessibility permission required for automatic paste
EOF
)

echo ""
echo ">>> 构建 Release ..."
"$PROJECT_DIR/scripts/bundle.sh"

echo ""
echo ">>> 打包 $ZIP_NAME ..."
cd "$BUILD_DIR"
rm -f "$ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$ZIP_NAME"
ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1 | xargs)
echo "    产物: $ZIP_PATH ($ZIP_SIZE)"

if [[ "$UPLOAD" != true ]]; then
    echo ""
    echo "=== 打包完成 ==="
    echo "产物路径: $ZIP_PATH"
    echo ""
    echo "如需发布到 GitHub Releases，请执行:"
    echo "  ./release.sh -v $VERSION --upload"
    exit 0
fi

echo ""
echo ">>> 检查 GitHub CLI ..."
if ! command -v gh >/dev/null 2>&1; then
    echo "错误: 未找到 gh 命令，请先安装 GitHub CLI"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "错误: GitHub CLI 尚未登录，请先执行 gh auth login"
    exit 1
fi

echo ""
echo ">>> 检查 Git Tag: $TAG_NAME ..."
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "    Tag $TAG_NAME 已存在（本地）"
else
    echo "    创建 Tag $TAG_NAME ..."
    git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
fi

echo "    推送 Tag 到 origin ..."
git push origin "$TAG_NAME"

echo ""
echo ">>> 创建或更新 GitHub Release ..."
if gh release view "$TAG_NAME" --repo "$REPO_SLUG" >/dev/null 2>&1; then
    echo "    Release 已存在，更新说明并上传制品 ..."
    gh release edit "$TAG_NAME" \
        --repo "$REPO_SLUG" \
        --title "$RELEASE_NAME" \
        --notes "$RELEASE_NOTES"
else
    echo "    创建新的 GitHub Release ..."
    gh release create "$TAG_NAME" \
        --repo "$REPO_SLUG" \
        --title "$RELEASE_NAME" \
        --notes "$RELEASE_NOTES"
fi

echo ""
echo ">>> 上传附件: $ZIP_NAME ..."
gh release upload "$TAG_NAME" "$ZIP_PATH" \
    --repo "$REPO_SLUG" \
    --clobber

echo ""
echo "==========================================="
echo "  ClipVault ${TAG_NAME} 发布完成!"
echo "==========================================="
echo ""
echo "  Release 页面: https://github.com/${REPO_SLUG}/releases/tag/${TAG_NAME}"
echo "  本地产物:     $ZIP_PATH"
echo ""
