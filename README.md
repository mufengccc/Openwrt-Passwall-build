# OpenWrt PassWall 自动构建

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

基于 OpenWrt 官方 SDK 构建 **PassWall / PassWall2** 相关软件包（`.apk`）的自动化项目，通过 **GitHub Actions** 一键构建：手动触发后自动编译、打包并发布到 Releases。

> **适用版本**：本仓库面向使用 **APK 包管理器** 的 **OpenWrt 25.12** 及后续版本（产物为 `.apk` 格式，不适用于旧版 `opkg`/`.ipk` 系统）。

## 目录结构

```
.github/workflows/
└── build-passwall.yml         # GitHub Actions 工作流
scripts/
└── pkg-run.sh                 # 失败包重试脚本(开 V=s 并记录日志)
```

## 构建产物

| 产物 | 说明 |
| --- | --- |
| `*.tar.gz` | 全部 `.apk` 平铺压缩包(内含 `sha256sums`) |
| `*.tar.gz.sha256` | 压缩包自身的 SHA-256 校验文件 |

包含的软件包：`luci-app-passwall`、`luci-app-passwall2`、`xray-core`、`sing-box`、`hysteria`、`ipt2socks`。

## 使用步骤

1. 将本仓库推送到 GitHub（`main` 分支）。
2. 进入 **Actions** 页 → 选择 **构建 PassWall** → **Run workflow** 手动触发。
3. 构建完成后：
   - **Releases** 页会新增一个 Release，附 `tar.gz` 与 `.sha256`（仅手动触发时发布）。
   - **Actions Artifacts** 中可下载 `编译日志-BuildLogs`（含失败包的日志，便于定位）。

> 触发权限：需仓库写权限（仓库者）。push / pull_request 不触发。

## 修改构建参数

编辑 `.github/workflows/build-passwall.yml` 中的 `env` 区：

| 变量 | 说明 |
| --- | --- |
| `SDK_TYPE` | SDK 版本类型，如 `releases/25.12.5` 或 `snapshots` |
| `SDK_NAME` | 要下载的 SDK 压缩包名（含版本，须与 `SDK_TYPE` 匹配） |
| `CORE_PKGS` | 要编译的软件包列表（空格分隔） |
| `PKG_ARCH` | 目标架构（当前定死 `x86_64`，改架构需同步改 `SDK_NAME`/URL，其他架构未经过测试） |

## 产物校验

### Linux / macOS

```bash
# 校验压缩包完整性
sha256sum -c <包名>.tar.gz.sha256

# 校验包内 apk 哈希
tar -xzf <包名>.tar.gz
cd <解压目录> && sha256sum -c sha256sums
```

### Windows

Windows 无内置 `sha256sum`，可用 PowerShell 的 `Get-FileHash`（Git Bash 用户可沿用上方 Linux 命令）：

```powershell
# 校验压缩包完整性
(Get-FileHash -Algorithm SHA256 <包名>.tar.gz).Hash.ToLower()
# 与 <包名>.tar.gz.sha256 中的 hash 对比

# 校验包内 apk 哈希(解压后, 在包目录内执行)
Get-Content sha256sums | ForEach-Object {
  $h, $f = $_ -split '\s+', 2
  $f = $f.TrimStart('*')
  $a = (Get-FileHash -Algorithm SHA256 $f).Hash.ToLower()
  if ($a -eq $h.ToLower()) { "OK   $f" } else { "FAIL $f" }
}
```

> 提示：`sha256sums` 中的 `*` 是二进制标记，`Get-FileHash` 结果需转小写后与文件中的小写 hash 对比。

## 常见问题

- **构建失败如何定位？** 下载 Artifacts 中的 `编译日志-BuildLogs`，打开 `failed_logs/` 下对应包名的日志，搜索 `error:` 定位首个错误。
- **磁盘空间不足？** 工作流已内置 runner 清理步骤。
- **找不到 apk？** 确认 `.config` 中目标包已启用（`CONFIG_PACKAGE_xxx=m`），且对应 feed 已安装成功。

## 参考

- OpenWrt 官方 SDK 下载：<https://downloads.openwrt.org>
- OpenWrt-PassWall 项目：[openwrt-passwall](https://github.com/Openwrt-Passwall) / [openwrt-passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2)

## 开源协议

本项目采用 [MIT License](LICENSE)。
