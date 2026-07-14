#!/bin/bash
# =============================================
# 暑期提分 - GitHub Pages 部署脚本
# =============================================
# 使用方法：
#   1. 先改下面这行为你的 GitHub 仓库名
#   2. 运行: bash deploy_github_pages.sh
# =============================================

REPO_NAME="summer-study"  # 改成你的仓库名

set -e

echo "📦 步骤1: 编译 Web 版本..."
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH="/c/Flutter/bin:$PATH"

flutter build web --release --base-href "/$REPO_NAME/"

echo ""
echo "📂 步骤2: 准备部署文件..."
rm -rf deploy
mkdir deploy
cp -r build/web/* deploy/

# 确保 index.html 在根目录
echo "summer-study.chat" > deploy/CNAME

echo ""
echo "🚀 步骤3: 推送到 gh-pages 分支..."
cd deploy
git init
git checkout -b gh-pages
git add -A
git commit -m "Deploy to GitHub Pages $(date '+%Y-%m-%d %H:%M')"

echo ""
echo "============================================"
echo "✅ 部署文件已准备好！"
echo ""
echo "接下来执行："
echo "  cd deploy"
echo "  git remote add origin https://github.com/你的用户名/$REPO_NAME.git"
echo "  git push -f origin gh-pages"
echo ""
echo "然后去 GitHub 仓库 Settings → Pages →"
echo "   Source: Deploy from a branch"
echo "   Branch: gh-pages  /root"
echo "   → Save → 等2分钟即可访问"
echo "============================================"
