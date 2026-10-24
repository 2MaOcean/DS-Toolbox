#!/bin/bash
ROOT=~/DS-Toolbox/ios/DSToolbox
echo "=== DS-Toolbox 完整性检查 ==="
echo ""
echo "[1/4] 文件统计"
echo "Swift 文件数: $(find $ROOT -name '*.swift' | wc -l)"
echo "总行数: $(find $ROOT -name '*.swift' -exec cat {} + | wc -l)"
echo ""
echo "[2/4] 大括号配对"
FAIL=0
for f in $(find $ROOT -name '*.swift'); do
  o=$(grep -o '{' "$f" | wc -l)
  c=$(grep -o '}' "$f" | wc -l)
  if [ "$o" != "$c" ]; then
    echo "❌ $f: {=$o }=$c"
    FAIL=1
  fi
done
if [ $FAIL -eq 0 ]; then echo "✅ 全部配对正常"; fi
echo ""
echo "[3/4] 双引号配对"
FAIL=0
for f in $(find $ROOT -name '*.swift'); do
  n=$(grep -o '"' "$f" | wc -l)
  if [ $((n % 2)) -ne 0 ]; then
    echo "⚠️ $f: 引号数为奇数 ($n)"
    FAIL=1
  fi
done
if [ $FAIL -eq 0 ]; then echo "✅ 全部配对正常"; fi
echo ""
echo "[4/4] 关键文件"
KEY=(
  "Core/DSToolboxApp.swift"
  "Core/ToolboxEnvironment.swift"
  "Services/AIService.swift"
  "Services/ExploitEngine.swift"
  "Downloader/DownloadQueue.swift"
  "Downloader/AdaptiveDownloader.swift"
  "UI/ContentView.swift"
  "UI/AgreementView.swift"
)
for f in "${KEY[@]}"; do
  if [ -f "$ROOT/$f" ]; then echo "✅ $f"; else echo "❌ 缺失: $f"; fi
done
echo ""
echo "=== 检查完成 ==="
