## 1. 核心模型与偏好

- [x] 1.1 在 `BreatherCore` 新增 `SliderIcon` 枚举（`tortoise`/`dog`/`cat`/`person`/`hare`，含 `symbolName`、`opticalHeight`、`init(stored:)` 未知值回退乌龟）；新增 `SliderIconTests` 覆盖五个 id 的映射与非法值回退，`swift test` 通过
- [x] 1.2 `Preferences` 新增 `sliderIcon` 键、默认值 `tortoise` 与读写属性；在 `PreferencesTests` 覆盖默认值、写入后读回、存未知值时的回退，`swift test` 通过
- [x] 1.3 把「x 坐标 ↔ 进度」换算抽成纯函数（含两端 `inset` 夹取）；补单测覆盖 0、0.5、1 与越界输入，`swift test` 通过

## 2. 滑块视图

- [x] 2.1 新建自绘滑块视图：4pt 轨道、强调色填充段、按 `SliderIcon` 绘制图标（脚底贴轨道中线）与脚下阴影；`Scripts/build-app.sh` 后以 `BREATHER_DEMO=panel` 启动截图，确认图标不穿过轨道线、不顶到状态文案
- [x] 2.2 实现鼠标按下/拖拽/点击跳转，拖动时填充段与图标同步；单测覆盖换算函数，实机拖拽确认剩余时间随之变化
- [x] 2.3 补无障碍：`accessibilityRole = .slider`、min/max/value/valueDescription 与增减方法；用 Accessibility Inspector 或运行期断言确认角色为 slider
- [x] 2.4 `MainPanelController` 用新视图替换 `NSSlider`，`refresh()` 同步进度与当前偏好图标（值未变时不重绘）；面板截图确认暂停/继续、键盘 Esc/空格/回车仍正常

## 3. 偏好设置界面

- [x] 3.1 `PreferencesWindowController` 在「外观与语言」组新增「滑块图标」下拉（乌龟、小狗、小猫、小人、兔子），窗口高度 452 → 496 并上移该分组；`BREATHER_DEMO=prefs` 截图确认五行对齐、保存按钮不被裁切
- [x] 3.2 保存时写入 `preferences.sliderIcon` 并触发 `onApply`；`BREATHER_DEMO=save` 不闪退，重启应用后主面板仍显示所选图标

## 4. 本地化

- [x] 4.1 在 `Resources/zh-Hans.lproj` 与 `Resources/en.lproj` 补「滑块图标」及五个图标名称共 6 条文案；切换中英文后分别截图或检查 `L10n.t` 输出，确认无遗漏与占位

## 5. 验证

- [x] 5.1 `swift test` 全绿；`Scripts/build-app.sh` 构建成功
- [x] 5.2 `BREATHER_DEMO=panel` 在浅色与深色面板外观下各截一次图，逐张目视核对五个图标（改偏好逐个切换）；确认图标脚底贴线、两端不越界
- [x] 5.3 `BREATHER_DEMO=prefs` 截图核对新增设置行与窗口高度
- [x] 5.4 发布前（需用户明确同意）：按新功能把 `AppInfo.version` 从 1.0.1 升到 1.1.0，tag 用 `v1.1.0`
