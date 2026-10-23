# DS 工具箱 (DS-Toolbox)

单应用 iOS / iPadOS 18 综合工具箱：网盘下载 + 文件管理器 + 浏览器 + IPA 管理 + TS 工具。

## 核心模块
- **下载中心**：五家网盘（百度/夸克/光亚/移动/天翼）直链解析、自适应并发、断点续传、限速、aria2 导入、BT 种子。
- **文件管理**：类似 MT 管理器的双栏浏览、跨栏拖拽、搜索排序、ZIP 流式解压/打包、文本/plist/JSON 编辑、文件哈希（SHA256）、格式转换。
- **内置浏览器**：多标签、书签、历史、Cookie 捕获，支持网页内拦截下载直链并交给下载器。
- **IPA 管理**：导入 IPA、证书安装、TrollStore/OTA 安装调度。
- **TS 工具**：App 管理、JIT 控制（StikDebug）、系统监控、描述文件生成、DNS 网络工具。
- **越狱调度**：内置 DarkSword 漏洞自动化流水线调度框架（需自行接入底层 exploit 二进制）。

## 安全边界
- 本项目**不内置任何内核漏洞利用代码**，只提供设备检测、偏移量匹配与自动化调度。
- SpringBoard 修改自动备份，写入前验证，失败回滚。
- 不提供签名，GitHub Actions 产出未签名 IPA，需用户自行签名安装。

## 构建说明
项目采用 XcodeGen 管理工程配置，使用 GitHub Actions（macos-15）自动编译。
产物位于 Actions 页面的 Artifacts 中：`DSToolbox-unsigned.ipa`。
