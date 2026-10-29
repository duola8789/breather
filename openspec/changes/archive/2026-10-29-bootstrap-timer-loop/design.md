## Context

See `proposal.md` - Why. 本节只记录塑造实现方式的现状与约束。

**起点**：仓库内没有代码，只有 `docs/HANDOFF.md`（调研快照）。

**已完成的行为取证**：本轮对参考应用做了定向分析，确认了下列对外可观察的行为。这里只记录行为结论，不保留分析过程与实现细节。

| 主题 | 结论 |
|---|---|
| 默认时长 | 工作 45 分钟、休息 5 分钟 |
| 延后步长 | 5 分钟，三档 ×1/×2/×3 |
| 休息预告阈值 | 剩余 10 秒 |
| 工作→休息 | 自动，无确认对话框 |
| 休息→工作 | 休息走满后进入"等用户确认"状态 |
| 强制休息 | 休息期间不能提前结束；工作最后 10 秒不能暂停 |
| 延后与强制休息 | 互不影响，强制休息下延后仍可用 |
| 延后窗口 | 仅工作最后 10 秒，每周期一次 |
| 跨日恢复 | 暂停跨天后，次日 07:00 自动解除 |
| 计时方式 | 参考实现的计时会随回调次数累积误差，本项目不沿用 |

**关键约束**：原版的计时实现是有累积误差的递减模型，这正是我们要避免的。原版此处的实现不能作为参照。

## Goals / Non-Goals

**Goals**

- 计时核心可以在没有任何 UI 的情况下被单元测试完整驱动，测试耗时毫秒级、无需运行 app
- 状态机的每一项行为都能追溯到一条 spec scenario
- 原版行为与本项目刻意偏离之处，在本文档中显式列出并说明理由
- 首个里程碑结束后，后续变更（遮罩、设置、统计）只需消费 `TimerEngine` 的公开状态，不需改动它

**Non-Goals**

- 不复刻原版的 `workingPeriod` 整型状态（1/2/3）与计时递减实现，只对齐对外可观察行为
- 不做原版 `actionBreak` 位掩码配置，改用语义化布尔项
- 不实现 Nib/Storyboard 布局，全部代码构建 UI
- 不追求与原版像素级视觉一致

## Decisions

### D1: 工程形态 —— SwiftPM 包 + 打包脚本，而非手写 Xcode 工程

结构：`BreatherCore`（library，纯逻辑，可测）+ `Breather`（executable，AppKit 装配）+ `Scripts/build-app.sh`（把可执行文件与 `Info.plist`、资源装配成 `Breather.app`）。构建命令显式带 `--arch arm64`，不依赖构建主机架构。

**理由**：`swift test` 对 library target 开箱可用，这是本变更最重要的验收手段；手写 `.pbxproj` 体积大、易出错、diff 不可读。Xcode 可直接打开 `Package.swift` 调试，不牺牲日常开发体验。

**同机先例**：`~/projects/pin-fold` 是同一作者已有项目，采用完全相同的形态（SwiftPM + `scripts/build_app.sh` 装配 `.app` + 手写 `Info.plist` + `LSUIElement` + ad-hoc 降级），已在本机跑通。沿用其约定：版本号单一来源于源码中的 `static let version`，由构建脚本抽取注入 plist。这套形态不是未经验证的推理，降低 D1 的风险。

**备选**：手写 Xcode 工程——交互式 Nib 编辑体验好，但本变更不使用 Nib，收益消失；代价是每次改动工程结构都要改二进制式工程文件。

**残留差异**：`.app` 由脚本装配，需要单独验证 `LSUIElement` 生效与菜单栏图标出现；这一步不进入 Xcode 的 Run scheme。

### D2: 计时模型 —— 绝对截止时间 + 可注入时钟

`TimerEngine` 内部不持有 `Timer`。它只保存 `endDate: Date?`、`pausedRemaining: TimeInterval`、`pausedAt: Date?`、`phase`、`isPaused`。所有方法接收一个时间点参数（或通过注入的 `Clock` 获取），由外部驱动 `tick(now:)`。

`pausedAt` 只为跨日自动恢复而存在：判断"次日 07:00"必须知道暂停发生在哪天，仅看当前时刻是否已过 07:00 无法区分当日与次日。参考实现在暂停时同样记录了日期，这不是我们额外引入的状态。

**理由**：把"时间流逝"变成显式输入，测试可以用任意时间点序列驱动，不需要等待真实时间。同时天然满足"睡眠唤醒后按墙钟重算"——`now` 一旦越过 `endDate` 就推进阶段。

**备选**：内部 `Timer` + 递减计数（原版做法）——不可测、有累积误差、睡眠后必然偏差，明确否决。

### D3: 状态建模 —— 三态 phase + 正交的 paused

```swift
enum Phase { case work, rest, restEnded }
```

`restEnded` 对应原版 `workingPeriod == 3`：休息已走满、等待用户确认回到工作。把它建模为独立状态而非布尔量，是因为它有一条独占的转移（确认 → work）和独占的显示行为。

暂停不作为 phase 的第四个值，而是与 phase 正交的 `isPaused`，因为它可以作用于任何阶段且不改变阶段本身。

### D4: 单次延后的表达 —— 每周期重置的可用标志

`isSnoozeAvailable: Bool`，在进入工作阶段时置 `true`，使用一次后置 `false`。不采用"根据剩余时间推算是否已延后"的方式，因为延后后剩余时间可能与初始工作时长相同（三倍延后撞上限时），推算会误判。

### D5: 偏好存储 —— UserDefaults，沿用原版键名

键名沿用 `workPeriod`、`breakPeriod`、`postponePeriod`、`popupSecond`、`forceBreak`。

**理由**：这组名字已经过二进制验证，沿用可以在日后对照原版时零成本定位；偏离时也容易看出是"我们加的"还是"原版就有的"。

**偏离项**：原版 `actionBreak` 位掩码拆成 `showIndicatorBeforeBreak`、`showPopupBeforeBreak`、`ringBellOnBreakStart`、`ringBellOnBreakEnd`、`autoCloseBreakOverlay` 五个独立布尔。原版默认 `0x204a` 中，`0x2000` 这一位的语义未能从代码中确认（仅知它默认开启），因此我们不复刻位布局，只保证上述五项默认值与观测一致。

### D6: 面板实现 —— 非激活 NSPanel

`NSPanel`，`styleMask: [.borderless, .nonactivatingPanel]`，子类覆写 `canBecomeKey` 返回 `true`，`level` 默认为 `.floating` 且可关闭置顶。点击外部关闭用 `NSEvent.addGlobalMonitorForEvents`。

**理由**：`nonactivatingPanel` 是"显示面板但不抢焦点"的直接手段——原版在遮罩场景会主动抢焦点（`activateIgnoringOtherApps:YES`），但面板场景不该抢，否则打断用户输入。注意：原版此处行为未取证，这是我们的设计选择。

### D7: 状态项 —— 程序化绘制的 18×18 环形进度

用 `NSImage(size:)` + `NSBezierPath` 在离屏绘制轨道与进度弧，按阶段选用颜色，暂停时用灰化描边。不使用 SF Symbols 叠加进度，因为需要按比例填充弧长。

### D8: 单实例 —— 运行时 `flock` 守护

应用启动时在 `~/Library/Application Support/com.duola8789.Breather/` 下对 `instance.lock` 加排他 `flock`。`Info.plist` 同时设 `LSMultipleInstancesProhibited`，但它只是补充，不是依赖。

两种失败情形必须分开处理：

- `flock` 失败（锁被其他实例持有）→ 静默 `exit(0)`。这是唯一合法的静默退出路径。
- 锁目录创建失败或 `open` 失败（锁基础设施不可用）→ `NSLog` 记录原因并**继续启动**，降级为无锁运行。

**理由**：不能依赖 LaunchServices 复用实例这一假设。同机项目 `pin-fold` 曾专门做过 `harden-singleton-and-login-item` 变更，结论是必须自带运行时锁。合并处理两种失败会让应用在磁盘满或目录权限被改坏时"点了没反应"，比偶发双实例难诊断得多——降级运行的代价（叠图标）反而更容易被察觉。锁键与 bundle 绑定，因此开发期 `swift run` 与正式 `.app` 也会互斥，不会出现两个计时器同时跑。

**备选**：仅靠 `LSMultipleInstancesProhibited`——在 `open -n` 之外对直接执行二进制无效，且无法覆盖开发路径。

### D9: 双语 —— 从第一天建立 `Localizable.strings`，不走 SwiftPM 资源机制

`Resources/en.lproj/Localizable.strings` 与 `Resources/zh-Hans.lproj/Localizable.strings` 以普通目录形式存在，由 `Scripts/build-app.sh` 原样拷入 `Breather.app/Contents/Resources/`。代码中一律 `NSLocalizedString`，查找走 `Bundle.main`。`Info.plist` 设 `CFBundleDevelopmentRegion=en`。

**理由**：`NSLocalizedString` 默认查 `Bundle.main`，而 SwiftPM 会把 `Package.swift` 声明的资源打进独立的 `<Package>_<Target>.bundle`，其位置与手工装配的 `.app` 的 `Contents/Resources` 对不上，`Bundle.module` 也无法替代（它指向 SwiftPM 的 bundle，且需在库目标内声明）。手工装配的 `.app` 本身就是标准 bundle 结构，把 `.lproj` 直接放进 `Contents/Resources` 是系统原生查找路径，最直白。

**备选**：用 SwiftPM 资源 + `Bundle.module`——需要额外保证资源 bundle 落在可查找位置，且与 `NSLocalizedString` 的默认查找路径冲突，为省一个拷贝步骤引入不透明的耦合。

**补充**：补加本地化需要遍历所有硬编码字符串，成本随时间线性增长；一开始就建骨架成本接近零。

## Risks / Trade-offs

**[计时器驱动频率与功耗] → 外部以 0.5 秒间隔驱动 `tick(now:)`，状态项只在整秒变化时重绘；`tick` 触发阶段转移时不做额外轮询。**

**[原版"休息走满后等用户确认"这一点与直觉相反] → 在 M1b 面板中必须显式呈现 `restEnded` 状态并给出确认入口，否则用户会以为计时卡住。这条行为有代码证据（`unlock` 后 `workingPeriod = 3`，且 `doneBtn` 重新启用），但未做运行时验证。**

**[ad-hoc 签名导致 TCC 与登录项不稳定] → 本轮不涉及这两项。后续引入登入启动时，改用钥匙串中的自签名证书保持签名身份稳定；`SMAppService` 是否接受自签名需实测。**

**[`actionBreak & 0x2000` 语义未知] → 不复刻位掩码，见 D5。风险上限是某个默认开关与我们不同，不影响核心循环。**

**[Bundle ID] → 定为 `com.duola8789.Breather`，与同机项目 `pin-fold` 的 `com.duola8789.PinFold` 共用同一反向域名。该值一经产出可运行 `.app` 便写入 TCC 授权记录与统计存储路径，之后修改需要手工清理残留授权，故本轮定死。**

**[开发期运行路径与打包运行路径不同] → `swift run` 与 `Breather.app` 在 `LSUIElement`、单实例、`Bundle.main` 资源查找上行为不同，验收必须以打包产物为准，不以 `swift run` 为准。**

## Migration Plan

全新项目，无迁移。回滚即删除本变更新增的目录。

## Open Questions

- 菜单栏环形图在各阶段的具体配色与线宽——属视觉细节，可在实现时对照原版截图确定，不影响 spec 与任务拆分
- 原版面板的尺寸与布局——同上，不阻塞

## 复刻修正（实现阶段）

首版界面是按功能清单自造的，与参照应用不一致。以下是修正后的结论，只记录对外表现。

### 主面板

面板只有四个元素：一行状态文案、右上角的菜单按钮、一条横向滑块、一个暂停/继续按钮。滑块可拖拽，拖拽会改变当前阶段的剩余时间。

### 文案

工作阶段「将在 MM:SS 后休息」；休息阶段「请在 MM:SS 后加油工作吧」；按钮「暂停 / 继续」；延后按钮「暂停 N 分钟」；遮罩「正是休息好时机！」/「休息结束！」/「完成」。首版把「继续」写成「恢复」、把「暂停 N 分钟」写成「延后 N 分钟」，已更正。

### 状态项图标

实心饼图（单色模板），已流逝的部分挖空，暂停时变淡。首版做成了空心环，已更正。

### 移除了「立即进入休息」

首版把一条未经证实的猜测写进了面板需求。参照应用的面板里没有这个入口，已从规格与实现中删除。

### 默认时长

45 / 5 为出厂默认；截图里出现的 55 分钟是用户自行修改后的值。
