# 🔧 OpenWrt PassWall 自动构建

> *一键构建 PassWall / PassWall2 的 OpenWrt 软件包*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![OpenWrt](https://img.shields.io/badge/OpenWrt-25.12-blue.svg)](https://openwrt.org) [![GitHub Actions](https://img.shields.io/badge/CI-GitHub%20Actions-black.svg)](https://github.com/features/actions)

基于 OpenWrt 官方 SDK 构建 **PassWall / PassWall2** 相关软件包（`.apk`）的自动化项目，通过 **GitHub Actions** 驱动：手动触发（`workflow_dispatch`）后自动完成 SDK 下载与校验、软件包编译、产物打包并发布到 Releases。

> [!NOTE]
> 本仓库面向使用 **APK 包管理器** 的 **OpenWrt 25.12** 及后续版本（产物为 `.apk` 格式，不适用于旧版 `opkg`/`.ipk` 系统）。

## ✨ 核心特性

- 🛠️ **一键构建** — 手动触发（`workflow_dispatch`）后自动完成 SDK 下载、校验及编译
- 📦 **一次构建、多包产出** — PassWall / PassWall2 插件及 xray-core / sing-box / hysteria 三个代理核心
- 🧪 **SHA256 校验** — SDK 与产物均校验 SHA-256 摘要，保证完整性
- 🔁 **失败自动重试** — 并行编译存在失败时，自动转为逐包串行重试并保留 `V=s` 详细日志
- 🏷️ **自动发布** — 产物自动归档为 `tar.gz` 并发布至 GitHub Releases

---

## 📑 目录

- [✨ 核心特性](#-核心特性)
- [📁 目录结构](#-目录结构)
- [📦 构建产物](#-构建产物)
- [🚀 使用步骤](#-使用步骤)
- [📥 安装说明](#-安装说明)
- [⚙️ 修改构建参数](#️-修改构建参数)
- [✅ 产物校验](#-产物校验)
- [❓ 常见问题](#-常见问题)
- [🔗 参考](#-参考)
- [📄 开源协议](#-开源协议)

---

## 📁 目录结构

```
📁 .github/workflows/
└── 📄 build-passwall.yml         # GitHub Actions 工作流
📁 scripts/
└── 📄 pkg-run.sh                 # 失败包重试脚本(开 V=s 并记录日志)
```

## 📦 构建产物

| 产物 | 说明 |
| --- | --- |
| `Passwall-<架构>-<时间戳>.tar.gz` | 各 feed 产出的 `.apk` 汇总为一个压缩包（内含 `sha256sums` 清单） |
| `Passwall-<架构>-<时间戳>.tar.gz.sha256` | 压缩包本体的 SHA-256 校验文件 |

命名示例：`Passwall-x86_64-20260815-165714.tar.gz`（Release 的 tag 与 Artifact 名称同源，均不带后缀）。

包含的软件包（即 `CORE_PKGS`）：

| 包名 | 说明 |
| --- | --- |
| `luci-app-passwall` | PassWall 插件 |
| `luci-app-passwall2` | PassWall2 插件 |
| `xray-core` | Xray 核心 |
| `sing-box` | sing-box 核心 |
| `hysteria` | Hysteria 协议核心 |
| `ipt2socks` | 将 iptables 透明代理(TProxy/REDIRECT)流量转发到 SOCKS5 |

> [!NOTE]
> `luci-app-passwall`、`luci-app-passwall2` 在编译时会自动解析并编译其依赖（如 `chinadns-ng`、`geoview`、`tcping`、`v2ray-geoip`、`v2ray-geosite` 及 OpenWrt 软件源中的其余依赖），无需在 `CORE_PKGS` 中显式列出。

## 🚀 使用步骤

1. 📥 将本仓库推送到 GitHub（`main` 分支）。
2. 🖱️ 进入 **Actions** 页 → 选中 **构建 PassWall** → 点击 **Run workflow** 手动触发。
3. 🎉 构建完成后：
   - **Releases** 页会新增一个 Release，附 `tar.gz` 与 `.sha256`（仅手动触发时发布）。
   - **Actions Artifacts** 中可下载 `编译日志-BuildLogs`（含失败包的日志，便于定位）。

> [!IMPORTANT]
> 触发条件：需对仓库具有 **Write** 权限。`push` / `pull_request` 事件不会触发该工作流。

## 📥 安装说明

以下操作在 **OpenWrt 路由器** 上执行：

1. 📤 将 `Passwall-*.tar.gz` 上传到路由器，解压出所有内容到 `tmp` 文件夹，并进入该目录：

   ```bash
   # 在路由器上执行
   cd tmp
   ```

2. 🧩 安装所有 apk（将一并安装 `luci-app-passwall`、`luci-app-passwall2`、`ipt2socks`，以及核心组件 `xray-core`、`sing-box`、`hysteria`）：

   ```bash
   # 安装 tar 包内全部 apk
   apk add --allow-untrusted ./*.apk
   ```

3. 🔌 安装完成后还需安装以下内核模块（用于 nftables 透明代理）：

   ```bash
   # 安装 nftables 透明代理内核模块
   apk add kmod-nft-socket kmod-nft-tproxy
   ```

> [!TIP]
> `kmod-*` 来自官方源，需固件可访问 OpenWrt 软件源且内核版本匹配。

## ⚙️ 修改构建参数

编辑 `.github/workflows/build-passwall.yml` 中的 `env` 区：

| 变量 | 说明 |
| --- | --- |
| `PKG_ARCH` | 目标架构（当前固定为 `x86_64`；更改时需同步指定匹配的 SDK，其他架构未经验证） |
| `SDK_TYPE` | SDK 版本路径，如 `releases/25.12.5` 或 `snapshots` |
| `SDK_NAME` | 待下载的 SDK 压缩包文件名（须与 `SDK_TYPE` 对应） |
| `FEED_PW_PKGS` | passwall 依赖包源（`src-git ...`） |
| `FEED_PW_LUCI` | passwall 插件源（`src-git ...`） |
| `FEED_PW2_LUCI` | passwall2 插件源（`src-git ...`） |
| `CORE_PKGS` | 待编译的软件包列表（以空格分隔，须与 `.config` 中启用的包一致） |
| `TZ` | 时区（默认 `Asia/Shanghai`，影响产物文件名中的时间戳及 Release 说明） |

## ✅ 产物校验

### 🐧 Linux / macOS

```bash
# 校验压缩包完整性
sha256sum -c <包名>.tar.gz.sha256

# 校验包内 apk 哈希
tar -xzf <包名>.tar.gz
cd <解压目录> && sha256sum -c sha256sums
```

### 🪟 Windows

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

> [!NOTE]
> `sha256sums` 中的 `*` 是二进制标记，`Get-FileHash` 结果需转小写后与文件中的小写 hash 对比。

## ❓ 常见问题

<details>
<summary>🐛 构建失败如何定位？</summary>

下载 Artifacts 中的 `编译日志-BuildLogs`，打开 `failed_logs/` 下对应包名的日志，搜索 `error:` 定位首个错误。

</details>

<details>
<summary>💾 磁盘空间不足？</summary>

工作流已在「清理 runner 磁盘空间」步骤中移除 `dotnet / android / ghc / powershell / mono / CodeQL` 等大体积预装组件（清理前后均打印 `df -h` 可核对）。若仍空间告急，可考虑改用自托管 runner。

</details>

<details>
<summary>🔍 找不到 apk？</summary>

确认 `.config` 中目标包已启用（`CONFIG_PACKAGE_xxx=m`），且对应 feed 已安装成功。

</details>

<details>
<summary>⚠️ apk 安装报错？</summary>

确认固件基于 **OpenWrt 25.12** 且已启用 `apk` 包管理器；`--allow-untrusted` 用于跳过签名校验。若仍安装失败，可先按 [产物校验](#-产物校验) 检查 apk 文件自身的完整性。

</details>

## 🔗 参考

| 资源 | 链接 |
| --- | --- |
| OpenWrt 官方下载 | <https://downloads.openwrt.org> |
| OpenWrt-PassWall 项目 | [openwrt-passwall](https://github.com/Openwrt-Passwall) |
| OpenWrt-PassWall2 项目 | [openwrt-passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2) |

## 📄 开源协议

> [!NOTE]
> 项目采用 **MIT 开源协议**，详见 [LICENSE](LICENSE)。

**由 [Openwrt-Passwall](https://github.com/Openwrt-Passwall) 社区驱动 · 自动构建于 GitHub Actions**
