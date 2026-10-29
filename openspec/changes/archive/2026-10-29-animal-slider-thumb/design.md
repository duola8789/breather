## Context

主面板当前用 `NSSlider(controlSize: .small)`：轨道高 4pt，圆球可视直径约 14pt，滑块行帧高 18pt、宽 240pt，面板 268×102。`TimerTicker` 每 0.5s 调一次 `refresh()`，45 分钟阶段下拇指每分钟只移动约 5pt。最低支持 macOS 14，SF Symbols 5 全部可用，项目不允许第三方依赖。

见 `proposal.md` 的 Why；行为契约见 `specs/main-panel` 与 `specs/preferences`。

## Goals / Non-Goals

**Goals:**
- 用自绘视图渲染「站在轨道上的动物」拇指，五个图标可切换、默认乌龟。
- 拖拽改剩余时间、点击轨道跳转、无障碍 role 与原 `NSSlider` 等效。
- 五个图标在同一位置呈现大致一致的视觉分量。

**Non-Goals:**
- 不做逐帧走路动画、不引入定时重绘。
- 不改菜单栏饼图、休息遮罩、计时引擎。
- 不把图标做成用户自定义图片或第三方图标包。

## Decisions

### 1. 自绘 `NSView`，而不是 `NSSliderCell` 子类

系统滑块把拇指画在轨道上，图标如果用默认位置，4pt 轨道会从动物身体中间穿过。要让「脚底落在轨道中线」，图标必须整体上移，超出行帧 18pt 的下半部分。子类方案需要同时重写 `barRect`、`knobRect`、`drawBar`，且在 macOS 14 的新滑块样式下行为不保证。自绘视图约 100 行，换来确定的像素结果。

备选：
- `NSSliderCell.drawKnob` 覆盖——改动最小，但图标居中、轨道穿身，视觉不成立。
- 透明 `NSSlider` 上叠一个图标视图——两套状态同步，脆。

### 2. 逐图标光学尺寸，而不是统一高度或纯面积归一化

统一 15pt 高时乌龟宽到 28.6pt、小人只有 10.6pt 宽，视觉失衡；按不透明度面积归一化会把细线条的 `figure.walk` 放大到 25pt，顶到状态文案。实测后取折中表：

| id | 符号（semibold） | 高 | 宽（约） |
|---|---|---|---|
| `tortoise`（默认） | `tortoise.fill` | 12pt | 22.9 |
| `dog` | `dog.fill` | 15pt | 18.3 |
| `cat` | `cat.fill` | 15pt | 17.8 |
| `person` | `figure.walk` | 16pt | 12.1 |
| `hare` | `hare.fill` | 14pt | 19.6 |

字重统一 `.semibold`：`.regular` 的填充剪影在深色面板上明显比原圆球轻。尺寸上限受面板版面约束——图标顶部到状态文案约 4pt 余量，超过 17pt 会顶到文案，所以不做纯面积归一化。

### 3. 几何与绘制

```
面板 268 x 102
滑块视图帧 (14, 44, 240, 26)
  ├─ 轨道 4pt，圆角，y = 9（相对），中线 y = 9
  ├─ 拇指中心 x = inset + value * (240 - 2*inset)
  │    inset = max(iconWidth/2, 7)
  ├─ 图标底边贴轨道中线，向上绘制
  └─ 脚下阴影：约 11 x 2pt 的椭圆，白色 0.18 或黑色 0.25
```

未走轨道用 `separatorColor` 半透明，已走部分用 `controlAccentColor`，图标用 `labelColor`（浅色/深色面板自适应）。视图帧从 18pt 增到 26pt，轨道绝对位置不变，向上占用原本空着的间隙。

### 4. 偏好存储：字符串 id + 未知值回退

`Preferences` 新增 `sliderIcon: SliderIcon`，键 `sliderIcon`，默认 `.tortoise`。`BreatherCore` 新增 `SliderIcon` 枚举，负责 id ↔ 符号名/尺寸的映射：

```swift
public enum SliderIcon: String, CaseIterable {
    case tortoise, dog, cat, person, hare
    public static let `default`: SliderIcon = .tortoise
    public var symbolName: String { ... }
    public var opticalHeight: CGFloat { ... }
    public init(stored: String) { self = SliderIcon(rawValue: stored) ?? .default }
}
```

存 id 而不是索引，避免以后增删选项时旧值错位；未知值回退乌龟，保证老用户和脏数据都能正常显示。

### 5. 设置项位置

放在「偏好设定 → 外观与语言」分组的「面板背景」与「语言」之间，用 `NSPopUpButton`。窗口高度 452 → 496，`外观与语言` 标题及以上内容整体上移 44pt，插入新行后行距仍为 40pt。下拉项顺序：乌龟、小狗、小猫、小人、兔子。保存沿用现有「保存」按钮的批量提交，`onApply` 已经会触发主面板 `refresh()`。

备选：主面板里加切换入口——违反「面板只有四项」的既有约束，否决。

### 6. 无障碍

自定义视图需要补：`accessibilityRole = .slider`、`accessibilityMinValue = 0`、`accessibilityMaxValue = 100`、`accessibilityValue` 为百分比、`accessibilityValueDescription` 显示剩余时间文案；`accessibilityPerformIncrement/Decrement` 每次 5%。视图本身不接受键盘焦点，与现状一致（面板的 keyDown 只处理 Esc/空格/回车）。

### 7. 静态渲染

不做任何周期性动画或 `displayLink`。`refresh()`（0.5s 一次）更新 value 并 `needsDisplay = true`，且仅在 value 真的变化时重绘，避免静止时无谓刷新。

## Risks / Trade-offs

- **不同 macOS 版本的 SF Symbols 轮廓/度量可能有细微差异** → 按 `符号名 + 字重` 缓存 `NSImage`；用 `BREATHER_DEMO=panel` 在浅色与深色外观下各截一次图核对；符号缺失时退回圆球，不让面板空白。
- **自绘控件丢掉系统滑块的键盘与无障碍行为** → 显式实现 slider 角色与四个无障碍方法；拖拽与点击跳转补单测覆盖换算函数。
- **图标加高后可能顶到状态文案** → 16pt 是当前版面下的上限；截图核对顶部间距，必要时只允许调整图标而不是面板尺寸。
- **两端位置图标一半在轨道外** → 用 `inset = max(iconWidth/2, 7)` 夹住中心点，保证图标整体落在 240pt 内。
- **五个图标的视觉重量无法完全一致**（尤其中人 `figure.walk` 偏细） → 已按光学尺寸折中；这是符号本身的限制，不做进一步补偿。

## Migration Plan

无数据迁移：新键缺失时读默认值乌龟。回滚只需换回 `NSSlider`，用户已保存的 `sliderIcon` 值不影响旧版本运行。
