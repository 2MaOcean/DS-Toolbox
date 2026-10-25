#!/bin/bash
# 一次性扫描所有 C/ObjC 文件的语法错误，用于提前暴露全部问题
set -u
cd "${SRCROOT:-.}" || exit 1

SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
if [ -z "$SDK" ]; then
  echo "无法定位 iPhoneOS SDK，跳过全量扫描"
  exit 0
fi

TARGET="arm64-apple-ios18.0"

INCLUDES=(
  "-I$SRCROOT/ios/DSToolbox/kexploit/xpf/external/ChOma/headers"
  "-I$SRCROOT/ios/DSToolbox/kexploit/xpf/external/ChOma/src"
  "-I$SRCROOT/ios/DSToolbox/kexploit/xpf/external/ChOma/external"
  "-I$SRCROOT/ios/DSToolbox/kexploit/xpf/external/img4lib"
  "-I$SRCROOT/ios/DSToolbox/kexploit/xpf/external/img4lib/libDER"
  "-I$SRCROOT/ios/DSToolbox/kexploit/xpf/src"
  "-I$SRCROOT/ios/DSToolbox/kexploit"
)

DEFINES=(
  "-DUSE_COMMONCRYPTO=1"
  "-DUSE_LIBCOMPRESSION=1"
  "-DiOS10=1"
  "-DDER_MULTIBYTE_TAGS=1"
  "-DDER_TAG_SIZE=8"
  "-D__unused=__attribute__((unused))"
)

# 收集所有需要编译的 C/ObjC 文件（与 project.yml sources 保持一致）
mapfile -t FILES < <(find ios/DSToolbox \
  \( -name "*.c" -o -name "*.m" \) \
  -not -path "*/xpf/external/ChOma/tests/*" \
  -not -path "*/xpf/external/ChOma/include/*" \
  -not -path "*/xpf/external/img4lib/lzfse/*" \
  -not -path "*/xpf/external/img4lib/corecrypto/*" \
  -not -path "*/xpf/external/img4lib/System/*" \
  -not -name "vfs_lzvn.c" \
  -not -name "img4.c" \
  -not -name "img4test.c" \
  -not -path "*/xpf/src/cli/*" \
  | sort)

echo "========================================================"
echo " Scan All C Files: ${#FILES[@]} file(s)"
echo "========================================================"

ERR_FILES=0
ERR_LINES=0

for f in "${FILES[@]}"; do
  OUT=$(clang -fsyntax-only -isysroot "$SDK" -target "$TARGET" \
        "${INCLUDES[@]}" "${DEFINES[@]}" "$f" 2>&1)
  if echo "$OUT" | grep -q "error:"; then
    N=$(echo "$OUT" | grep -c "error:")
    echo ""
    echo "───── $f  ($N error(s)) ─────"
    echo "$OUT" | grep -E "error:" | sed 's/^/  /'
    ERR_FILES=$((ERR_FILES + 1))
    ERR_LINES=$((ERR_LINES + N))
  fi
done

echo ""
echo "========================================================"
echo " Scan Result: $ERR_FILES file(s), $ERR_LINES error(s)"
echo "========================================================"

[ "$ERR_FILES" -eq 0 ]
