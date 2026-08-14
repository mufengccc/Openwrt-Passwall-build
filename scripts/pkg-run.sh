#!/usr/bin/env bash
# ============================================================================
# 对"首次执行失败的包"执行重试并记录日志 (供 GitHub Actions 调用)
# ----------------------------------------------------------------------------
# 行为:
#   1) 仅处理传入的包列表 (来自环境变量 CORE_PKGS, 由调用方填入需重试的包);
#   2) 对每个包执行一次 make <目标> V=s, 输出写入 failed_logs/{前缀}<包>.log;
#   3) 有任一包重试仍失败则退出失败(使 job 标红)。
#
# 用法: CORE_PKGS="<需重试的包列表>" bash pkg-run.sh <make目标> [日志前缀]
#   例:  CORE_PKGS="xray-core badpkg" bash pkg-run.sh compile ""
#
# 依赖环境变量: CORE_PKGS (此处应为需重试的包, 空格分隔)
# 工作目录应位于 SDK 根目录
# ============================================================================
set -o pipefail

target="${1:?用法: bash pkg-run.sh <make目标> [日志前缀]}"
prefix="${2:-}"

# 无包需重试则直接成功
if [ -z "$CORE_PKGS" ]; then
  echo "无失败包, 无需重试"
  exit 0
fi

mkdir -p failed_logs
FAILED=""

for p in $CORE_PKGS; do
  echo "== 重试 ${target}: $p =="
  # 重试时开启 V=s 并记录日志供定位
  if make -j"$(nproc)" "package/${p}/${target}" V=s 2>&1 | tee "failed_logs/${prefix}${p}.log"; then
    echo "重试 OK: $p"
  else
    echo "FAILED: $p"
    FAILED="${FAILED} $p"
  fi
done

if [ -n "$FAILED" ]; then
  echo "错误: 以下包${target}重试仍失败:${FAILED}"
  exit 1
fi