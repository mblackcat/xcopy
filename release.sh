#!/bin/bash
set -euo pipefail

#=============================================================
# ClipVault Release Script
#
# Usage:
#   ./release.sh                        仅打包（使用 Info.plist 中的当前版本号）
#   ./release.sh -v 1.2                 指定版本号打包
#   ./release.sh --upload               打包 + 上传到 Gitee Release
#   ./release.sh -v 1.2 --upload        指定版本号打包 + 上传
#   ./release.sh --help                 查看帮助
#
# 环境变量:
#   GITEE_TOKEN   Gitee 私人令牌（上传时必须）
#   GITEE_OWNER   Gitee 用户名/组织名（上传时必须）
#   GITEE_REPO    Gitee 仓库名（上传时必须）
#
# 你也可以在项目根目录创建 .release.env 文件来配置以上变量:
#   GITEE_TOKEN=xxx
#   GITEE_OWNER=your-name
#   GITEE_REPO=clipvault
#=============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
PLIST="$PROJECT_DIR/Resources/Info.plist"
APP_NAME="ClipVault"

VERSION=""
UPLOAD=false

#-------------------------------------------------------------
# 帮助信息
#-------------------------------------------------------------
usage() {
    cat <<'HELP'
ClipVault Release Script

用法:
  ./release.sh [选项]

选项:
  -v, --version VERSION   指定版本号（如 1.2、2.0.0），会同步更新 Info.plist
  -u, --upload            打包后上传到 Gitee Release
  -h, --help              显示此帮助信息

示例:
  ./release.sh                    仅打包，版本号取 Info.plist 当前值
  ./release.sh -v 1.2             以版本 1.2 打包
  ./release.sh -v 1.2 --upload    以版本 1.2 打包并上传 Gitee
  ./release.sh --upload           打包并上传 Gitee

上传配置（三选一）:
  1. 设置环境变量 GITEE_TOKEN, GITEE_OWNER, GITEE_REPO
  2. 在项目根目录创建 .release.env 文件
  3. 脚本运行时交互输入
HELP
    exit 0
}

#-------------------------------------------------------------
# 解析参数
#-------------------------------------------------------------
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

#-------------------------------------------------------------
# 读取 .release.env（如果存在）
#-------------------------------------------------------------
ENV_FILE="$PROJECT_DIR/.release.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

#-------------------------------------------------------------
# 读取 / 更新版本号
#-------------------------------------------------------------
if [[ -n "$VERSION" ]]; then
    echo ">>> 更新版本号为 $VERSION ..."
    # 更新 CFBundleVersion
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST"
    # 更新 CFBundleShortVersionString
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST"
    echo "    Info.plist 已更新"
else
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
    echo ">>> 使用当前版本号: $VERSION"
fi

TAG_NAME="v${VERSION}"
ZIP_NAME="${APP_NAME}-${TAG_NAME}-macOS.zip"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}"

#-------------------------------------------------------------
# 构建
#-------------------------------------------------------------
echo ""
echo ">>> 构建 Release ..."
"$PROJECT_DIR/scripts/bundle.sh"

#-------------------------------------------------------------
# 打包 zip
#-------------------------------------------------------------
echo ""
echo ">>> 打包 $ZIP_NAME ..."
cd "$BUILD_DIR"
rm -f "$ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$ZIP_NAME"
ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1 | xargs)
echo "    产物: $ZIP_PATH ($ZIP_SIZE)"

#-------------------------------------------------------------
# 如果不需要上传，到此结束
#-------------------------------------------------------------
if [[ "$UPLOAD" != true ]]; then
    echo ""
    echo "=== 打包完成 ==="
    echo "产物路径: $ZIP_PATH"
    echo ""
    echo "如需上传到 Gitee，请执行:"
    echo "  ./release.sh -v $VERSION --upload"
    exit 0
fi

#-------------------------------------------------------------
# 上传前检查配置
#-------------------------------------------------------------
echo ""
echo ">>> 准备上传到 Gitee ..."

if [[ -z "${GITEE_TOKEN:-}" ]]; then
    read -rp "请输入 Gitee 私人令牌 (Token): " GITEE_TOKEN
fi
if [[ -z "${GITEE_OWNER:-}" ]]; then
    read -rp "请输入 Gitee 用户名/组织名 (Owner): " GITEE_OWNER
fi
if [[ -z "${GITEE_REPO:-}" ]]; then
    read -rp "请输入 Gitee 仓库名 (Repo): " GITEE_REPO
fi

if [[ -z "$GITEE_TOKEN" || -z "$GITEE_OWNER" || -z "$GITEE_REPO" ]]; then
    echo "错误: GITEE_TOKEN, GITEE_OWNER, GITEE_REPO 均不能为空"
    exit 1
fi

API_BASE="https://gitee.com/api/v5/repos/${GITEE_OWNER}/${GITEE_REPO}"

#-------------------------------------------------------------
# 创建 Git Tag（如果不存在）
#-------------------------------------------------------------
echo ""
echo ">>> 检查 Git Tag: $TAG_NAME ..."
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "    Tag $TAG_NAME 已存在（本地）"
else
    echo "    创建 Tag $TAG_NAME ..."
    git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
fi

# 确定推送用的 remote（优先用指向 gitee 的 remote）
GITEE_REMOTE=""
for r in origin gitee; do
    if git remote get-url "$r" 2>/dev/null | grep -q "gitee.com"; then
        GITEE_REMOTE="$r"
        break
    fi
done
if [[ -z "$GITEE_REMOTE" ]]; then
    echo "    添加 gitee remote ..."
    git remote add gitee "https://gitee.com/${GITEE_OWNER}/${GITEE_REPO}.git"
    GITEE_REMOTE="gitee"
fi

echo "    推送代码到 Gitee ($GITEE_REMOTE) ..."
git push "$GITEE_REMOTE" HEAD 2>&1 || true
echo "    推送 Tag 到 Gitee ..."
git push "$GITEE_REMOTE" "$TAG_NAME" 2>&1 || true

# 获取当前分支名，供 Release API 使用
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

#-------------------------------------------------------------
# 创建 Gitee Release
#-------------------------------------------------------------
echo ""
echo ">>> 创建 Gitee Release ..."

RELEASE_BODY="## ClipVault ${TAG_NAME}

- 版本: ${VERSION}
- 构建时间: $(date '+%Y-%m-%d %H:%M:%S')
- 系统要求: macOS 13.0+"

CREATE_RESP=$(curl -s -X POST "${API_BASE}/releases" \
    -H "Content-Type: application/json" \
    -d "{
        \"access_token\": \"${GITEE_TOKEN}\",
        \"tag_name\": \"${TAG_NAME}\",
        \"name\": \"ClipVault ${TAG_NAME}\",
        \"body\": $(printf '%s' "$RELEASE_BODY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
        \"target_commitish\": \"${CURRENT_BRANCH}\",
        \"prerelease\": false
    }")

# 提取 release id
RELEASE_ID=$(echo "$CREATE_RESP" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('id', ''))
except:
    print('')
" 2>/dev/null)

if [[ -z "$RELEASE_ID" ]]; then
    echo "错误: 创建 Release 失败"
    echo "响应: $CREATE_RESP"
    echo ""
    echo "如果 Release 已存在，你可以手动上传附件:"
    echo "  在 Gitee 仓库页面 → 发行版 → $TAG_NAME → 编辑 → 上传文件"
    exit 1
fi

echo "    Release 创建成功 (ID: $RELEASE_ID)"

#-------------------------------------------------------------
# 上传附件
#-------------------------------------------------------------
echo ""
echo ">>> 上传附件: $ZIP_NAME ..."

UPLOAD_RESP=$(curl -s -X POST \
    "${API_BASE}/releases/${RELEASE_ID}/attach_files" \
    -F "access_token=${GITEE_TOKEN}" \
    -F "file=@${ZIP_PATH}")

DOWNLOAD_URL=$(echo "$UPLOAD_RESP" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    url = data.get('browser_download_url', '')
    print(url)
except:
    print('')
" 2>/dev/null)

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "警告: 附件上传可能失败"
    echo "响应: $UPLOAD_RESP"
    echo "请到 Gitee 网页端手动检查并补传"
else
    echo "    上传成功!"
fi

#-------------------------------------------------------------
# 汇总
#-------------------------------------------------------------
echo ""
echo "==========================================="
echo "  ClipVault ${TAG_NAME} 发布完成!"
echo "==========================================="
echo ""
echo "  Release 页面: https://gitee.com/${GITEE_OWNER}/${GITEE_REPO}/releases/tag/${TAG_NAME}"
if [[ -n "$DOWNLOAD_URL" ]]; then
    echo "  下载链接:     $DOWNLOAD_URL"
fi
echo "  本地产物:     $ZIP_PATH"
echo ""
