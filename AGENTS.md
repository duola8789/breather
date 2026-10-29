# AGENTS.md

给自动化代理的工作说明。项目背景见 `README.md`，用户级约定见 `CLAUDE.md`。

## 快速开始

```bash
swift test                # 先确认基线是绿的
Scripts/build-app.sh      # 构建可用产物
open dist/Breather.app    # 实际验证
```

## 验证要求

- 纯逻辑改动：必须补 `Tests/BreatherCoreTests/` 里的用例，`swift test` 全绿
- UI 改动：必须构建并在 `dist/Breather.app` 上实际运行，**并且自己截图确认**。
  屏幕录制与辅助功能权限已授权给 IntelliJ IDEA；如果 `screencapture` 报
  `could not create image from display`，说明权限被系统重置了，先让用户重新授权并重启 IDEA，
  **不要凭代码推断外观，也不要说"应该没问题"**。确实无法截图时必须写明"未做视觉验证"
- 打包相关改动：`plutil -lint`、`lipo -info`、`codesign -dv` 三项都要过
- 截图核对：`BREATHER_DEMO=panel|prefs|about` 启动会把对应窗口摆到固定位置并跳过"失焦即关"，
  配合 `screencapture` 可以在无鼠标操作时验证外观
- `BREATHER_DEMO=save` 会在设置窗口打开一秒后自动触发一次「保存」，用于回归保存弹窗这条路径
  （曾经因为提前释放窗口控制器而闪退）

## 边界

- 不引入第三方依赖
- 不打包任何原版应用的资源（图标、音频、本地化文件、Chart.js）
- 不实现 Pro 内购
- 统计与高级配置窗口的形态尚未定稿，见 `openspec/changes/next-iteration-backlog/`，不要擅自重做
- 修改前先读 `openspec/changes/bootstrap-timer-loop/design.md`，那里有行为对照表
  （默认时长、强制休息规则、面板控件、文案）

## 提交

提交信息用中文，一句话说清"改了什么、为什么"。

## 发布与提交规矩

- **push 和打 tag 之前必须得到用户明确同意**，不要自动推。
- 版本号语义（`Sources/BreatherCore/AppInfo.swift` 里的 `version`）：

  | 位 | 什么时候改 |
  |---|---|
  | 第一位（major） | 大的版本升级 |
  | 第二位（minor） | 中等功能更新、新功能 |
  | 第三位（patch） | 优化改进、bug 修复 |

- tag 用 `v<version>`，与 `AppInfo.version` 一致。
- CI 只在推 tag 时发布 Release；推 master 只跑测试与构建，不发版。
