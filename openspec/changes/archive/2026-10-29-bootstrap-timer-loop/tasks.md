## 1. 工程骨架

- [x] 1.1 建立 `Package.swift`：`BreatherCore` library + `Breather` executable + `BreatherCoreTests`，platforms macOS 14，不声明 SwiftPM 资源；`swift build --arch arm64` 与 `swift test` 通过
- [x] 1.2 编写 `Scripts/build-app.sh`：`--arch arm64` 编译、生成 Info.plist（含 Bundle ID、LSUIElement、LSMultipleInstancesProhibited、CFBundleDevelopmentRegion）、拷贝 `.lproj`、ad-hoc 签名；`plutil -lint`、`lipo -info`、`codesign -dv` 均通过
- [x] 1.3 `AppDelegate` + `main.swift` 装配 `NSStatusItem`；打包运行后为 `UIElement`、无 Dock 图标
- [x] 1.4 `Resources/en.lproj` 与 `zh-Hans.lproj` 骨架，由脚本拷入 `Contents/Resources/`；`--dump-localized` 在中英两种语言下均取到对应文案

## 2. 偏好与时钟

- [x] 2.1 `BreatherClock` 协议与 `SystemClock`（与标准库 `Clock` 撞名，故改名）
- [x] 2.2 `Preferences` 覆盖全部设置项，默认值与原版二进制一致（45/5/5/10/false），读取不写盘
- [x] 2.3 写入与持久化，跨实例一致
- [x] 2.4 单实例 `flock` 守护：锁被占用静默退出，锁基建失效降级继续运行

## 3. 计时核心

- [x] 3.1 `Phase` / `TimerState` / `TimerEngine` 骨架，注入时钟、不含 `Timer`
- [x] 3.2 工作→休息自动转移，单次 tick 只推进一个阶段
- [x] 3.3 暂停/恢复冻结并续算剩余时间
- [x] 3.4 延后：仅最后 10 秒、每周期一次、×1/×2/×3、受工作时长上限约束
- [x] 3.5 延后窗口与强制休息互不影响
- [x] 3.6 休息→`restEnded` 等用户确认，确认后回到工作
- [x] 3.7 `endBreakEarly` 在强制休息下被拒绝
- [x] 3.8 强制休息下工作最后 10 秒禁止暂停
- [x] 3.9 跨日 07:00 自动恢复，记录 `pausedAt`
- [x] 3.10 睡眠唤醒按墙钟推进，且不连跳多个阶段
- [x] 3.11 状态持久化与启动恢复，初始状态即落盘
- [x] 3.12 拖拽 slider 改变当前阶段剩余时间（`setProgress`）
- [x] 3.13 自动暂停来源区分（idle / frontmost / manual），自动恢复不解除手动暂停
- [x] 3.14 修改时长后按已流逝比例重算当前阶段（`applyDurations`）

## 4. 系统集成

- [x] 4.1 `Timer` 0.5 秒驱动 + `didWakeNotification` 立即补一次 tick
- [x] 4.2 状态项绘制实心饼图（模板单色，暂停变淡），`--dump-icons` 导出 PNG 目视确认
- [x] 4.3 退出前保存状态；真实 app 重启后 `endDate` 保持
- [x] 4.4 单实例在打包产物上验证（重复 `open`、直接执行二进制，实例数保持 1）
- [x] 4.5 `IdleMonitor` 基于 `CGEventSource.secondsSinceLastEventType`，无需权限
- [x] 4.6 前台应用监听 `didActivateApplicationNotification`，按名单暂停/恢复
- [x] 4.7 `LoginItem` 封装 `SMAppService.mainApp`，失败时回滚勾选并提示
- [x] 4.8 `SoundPlayer` 使用系统音（不打包原版音频），支持试听与音量

## 5. 主面板

- [x] 5.1 `NSPanel`（borderless + nonactivating，`canBecomeKey`），带指向状态项的箭头，位于状态项下方并做屏幕边界修正
- [x] 5.2 文案与原文一致：工作「将在 MM:SS 后休息」、休息「请在 MM:SS 后加油工作吧」
- [x] 5.3 横向 slider 反映进度且可拖拽改变剩余时间
- [x] 5.4 单一暂停/继续按钮，强制休息最后 10 秒禁用
- [x] 5.5 菜单按钮与状态项右键弹出同一菜单（偏好设定…/关于/协助资讯/Email/评分/统计数据/高级配置/退出）
- [x] 5.6 快捷键 Esc 关闭、空格延后（不可用时无效）、回车切换暂停
- [x] 5.7 点击面板外关闭且不吞点击
- [x] 5.8 置顶由偏好设定控制，面板内不提供该开关

## 6. 休息遮罩

- [x] 6.1 每屏一个窗口，`.screenSaver` 层级、`fullScreenAuxiliary`，覆盖全屏应用
- [x] 6.2 主屏显示「正是休息好时机！」+「请在 MM:SS 后加油工作吧」+「完成」按钮；副屏仅背景
- [x] 6.3 休息走满后文案切换为「休息结束！」/「快回去工作啦!」并启用按钮
- [x] 6.4 强制休息下按钮与快捷键均不可用；关闭时可提前结束并计入取消次数
- [x] 6.5 可选桌面截图背景（`CGWindowListCreateImage`），未授权时自动降级纯色
- [x] 6.6 显示器插拔时重建遮罩窗口（监听 `didChangeScreenParametersNotification`，遮罩可见时重建）

## 7. 设置界面

- [x] 7.1 偏好设定面板：工作时长/休息时长滑块、登入时启动、置顶该弹窗、开始时响铃、强制休息、保存
- [x] 7.2 保存后提示「保存偏好设置成功」并即时生效
- [x] 7.3 登入启动失败时回滚勾选并弹出错误
- [x] 7.4 高级配置窗口：空闲暂停与分钟数、前台应用名单与添加、唤醒后重置、铃声试听、背景截图与亮度
- [x] 7.5 全部设置即时持久化

## 8. 统计

- [x] 8.1 `StatsStore` 按分钟记录工作/休息，同一分钟只记一次，暂停不记
- [x] 8.2 跨天按本地时区拆分
- [x] 8.3 统计窗口：7 天柱状图 + 工作休息比环形图（Swift Charts）
- [x] 8.4 方向键切换周
- [x] 8.5 S 键导出 PNG 到桌面
- [x] 8.6 数据仅本机，无网络请求

## 9. 验收与清理

- [x] 9.1 验收矩阵：面板（浅色/深色/玻璃）、设置窗口、关于窗口、休息遮罩（普通态 + 强制休息禁用态）、菜单栏饼图、双语切换、单实例、重启恢复、1 分钟周期的 work→rest→restEnded 全链路——均已截图或命令行核对。**未覆盖**：双显示器遮罩（当前只有一块屏）、深色菜单栏下的图标观感、真实的 45/5 完整一轮
- [x] 9.2 对照 design.md 的原版取证表核对，把实现阶段发现的偏离补记进 design.md（已补记「复刻修正」小节：面板四控件、文案逐字对照、饼图图标、移除「立即进入休息」）
- [x] 9.3 README 记录构建与运行方式
- [x] 9.4 删除 `docs/HANDOFF.md`（已删除，结论并入 design.md）
