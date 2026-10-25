# DS-Toolbox 开发铁律（修订版 2026-10-25）

1. 单段代码不超过 25–35 行，超过必拆段。
2. 改文件三选一，按风险从低到高：sed -i 定点替换 → cat > 整文件覆盖 → cat >> 末尾追加。cat >> 只能新增，禁止用它修改已有行。
3. 短文件可合并成一段。
4. 不要删除"被引 0"的文件，可能是未接入口的功能。
5. 推前跑 ./ds_check.sh，但它只查语法配平，不查类型。编译真相以 GitHub Actions 为准；本地绿≠CI 绿。
6. 修改前先说"本批改动"，再给代码。
7. iOS 沙盒无 Foundation.Process；ProcessCompat.runAndWait 仅在越狱/TrollStore 环境真执行，非越狱必须降级。
8. import ZSign（module）≠ product: ZSignApple（project.yml）。
9. ptrace 第 4 参类型是 CInt，传 0 不传 nil。
10. Darwin 已 import 后直接 Darwin.kill，不写 Darwin.Darwin.kill。
11. 本地只有 iSH 无 Xcode，编译反馈只看 Actions 最新 job 日志。
12. 三个功能挂点不要删：Resolver/CookieResolveTemplate.swift:22、IPA/AppleIDSigningService.swift:19、Services/SpringBoardManager.swift:54。
