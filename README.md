# Breather

macOS 菜单栏休息提醒工具。工作一段时间后自动进入休息，休息结束再回到工作，循环往复。

界面、文案与交互按一款 2019 年的同类应用逐控件核对后重新实现，原生 arm64，不依赖 Rosetta。
没有统计上报、没有账号、没有网络请求，所有数据只存在本机。

## 它能做什么

- 工作 45 分钟 / 休息 5 分钟后自动切换（时长可调）
- 菜单栏图标是一枚饼图，剩余时间越少挖空越多，一眼看出还剩多久
- 点图标展开面板：剩余时间、可拖拽改变剩余时间的进度条、暂停/继续
- 工作最后 10 秒可以延后一次（5 / 10 / 15 分钟三档）
- 休息时全屏遮罩，强制你停下来
- 可选「强制休息」：最后 10 秒不能暂停，休息期间不能提前结束
- 中英文界面，可在偏好设定里手动切换

## 安装

从 [Releases](https://github.com/duola8789/breather/releases) 下载 `.dmg`，
打开后把 **Breather** 拖进「应用程序」文件夹，然后双击启动。
启动后只在菜单栏出现图标，没有 Dock 图标。

需要 macOS 14 或更新版本、Apple Silicon。

### 提示"无法验证开发者"怎么办

本应用**没有通过 Apple 公证**（需要付费的 Developer ID 证书），从浏览器下载的副本会被 Gatekeeper 拦下，
提示「Apple 无法验证 Breather.app 是否包含可能危害 Mac 的恶意软件」。这不是病毒，是分发方式所致。

三种解法，任选其一：

- **系统设置 → 隐私与安全性**，页面下方找到「已阻止使用 Breather」的提示，点 **仍要打开**，再确认一次；
- **在访达里右键点 Breather.app → 打开**，弹窗里再点一次「打开」；
- **终端去掉隔离属性**：

  ```bash
  xattr -dr com.apple.quarantine /Applications/Breather.app
  ```

> 用命令行下载（`curl`、`brew`）的副本不会带隔离属性，不会触发上述拦截。

## 从源码构建

需要 Xcode 15 或更新版本（完整版，不是 Command Line Tools）。

```bash
git clone https://github.com/duola8789/breather.git
cd breather
Scripts/build-app.sh
open dist/Breather.app
```

脚本会用 `swift build -c release --arch arm64` 编译，装配 `dist/Breather.app`，
把 `Resources/*.lproj` 拷进 bundle，然后签名。签名身份按顺序挑选：

```
Developer ID Application  →  Apple Development（免费的 Xcode 个人团队证书）  →  ad-hoc
```

前两种在钥匙串里存在时会被自动使用，并且**签名身份在多次构建之间保持不变**；
ad-hoc 是兜底，它的身份是二进制哈希，每次构建都会变。

真实证书的签名一律带安全时间戳（`--timestamp`），app 和 DMG 都是。这不是可选项：
Apple Development 证书一年后过期，没有时间戳的签名会在证书过期那一刻失效，
连带已经分发出去的包一起变成"签名无效"。ad-hoc 没有证书可打，因此不带时间戳。

跑测试：

```bash
swift test
```

## 诊断命令

```bash
dist/Breather.app/Contents/MacOS/Breather --version
dist/Breather.app/Contents/MacOS/Breather --dump-localized -AppleLanguages '(zh-Hans)'
dist/Breather.app/Contents/MacOS/Breather --dump-icons /tmp/breather-icons
```

## 已知行为

- **签名身份决定权限记忆**：系统按签名身份记录隐私授权与登录项。用 Developer ID 或 Apple Development
  签名时，身份稳定，屏幕录制授权和「登入时启动」重建后依然有效；用 ad-hoc（身份是二进制哈希）时，
  每次重建都被当成另一个应用，授权要重新给、登录项可能注册失败。可以用 `Scripts/build-app.sh` 的输出
  确认这次用的是哪种身份。

- **CI 产物是 ad-hoc 签名**：GitHub Actions 上没有你的证书，所以 Release 里的 DMG 内应用是 ad-hoc 签名，
  每次发布的签名都不同。只有本机构建的产物才享受稳定身份。
- **休息遮罩的背景截图**需要屏幕录制权限，没授权时自动退化为纯黑遮罩，计时与按钮不受影响。
- **铃声**用的是系统音（Glass / Ping），没有打包任何第三方音频。

## 目录结构

```
Sources/BreatherCore/   纯逻辑：计时状态机、偏好、统计记录、空闲检测、单实例锁
Sources/Breather/       AppKit 层：菜单栏、面板、遮罩、设置窗口
Resources/              中英文文案
Scripts/build-app.sh    构建与打包
Tests/BreatherCoreTests 单元测试
openspec/               需求与设计记录
```

## 许可

[MIT](LICENSE) © 2026 duola8789

界面文案与交互参考自另一款应用的公开行为，本项目不包含其任何源代码、图标、音频或本地化文件。
