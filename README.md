# 牛马提醒 NiumaReminder

一个功能丰富的 iOS 牛马专属提醒应用，使用 SwiftUI 和 SwiftData 构建。

## 功能特性

- ✅ 添加、编辑、删除提醒
- ✅ 设置提醒时间和日期
- ✅ 本地通知推送
- ✅ 标记完成/未完成
- ✅ 重复提醒（每天、每周、每月）

### 高级功能
- 📅 7天行程 & 交互式月历视图
- 🧠 牛马品牌视觉 (气宇轩昂的牛马 Logo)
- 📂 分类管理（工作、个人、购物等）
- 🎯 优先级设置 (高、中、低)
- 📳 触觉反馈 (完成任务的多巴胺)

### 界面特性
- 现代化 SwiftUI 界面
- 支持深色模式
- 流畅的动画效果
- 直观的操作体验

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI, SwiftData
- **最低版本**: iOS 17.0+
- **架构**: MVVM

## 项目结构

```
SmartReminder/
├── SmartReminder/
│   ├── SmartReminderApp.swift    # App 入口
│   ├── Models/
│   │   ├── Reminder.swift        # 提醒数据模型
│   │   └── Category.swift        # 分类数据模型
│   ├── ViewModels/
│   │   └── ReminderStore.swift   # 数据管理
│   ├── Views/
│   │   ├── ContentView.swift     # 主界面（TabView）
│   │   ├── ReminderListView.swift    # 提醒列表
│   │   ├── ReminderRowView.swift     # 提醒行
│   │   ├── AddReminderView.swift     # 添加/编辑提醒
│   │   └── CategoryManagementView.swift  # 分类管理
│   └── Services/
│       └── NotificationManager.swift  # 通知管理
```

## 使用方法

### 1. 在 Xcode 中打开项目

双击 `SmartReminder.xcodeproj` 文件，或在终端运行：

```bash
cd SmartReminder
open SmartReminder.xcodeproj
```

### 2. 选择目标设备

在 Xcode 顶部工具栏选择：
- iPhone 模拟器（推荐 iPhone 15 Pro）
- 或连接的真机

### 3. 运行应用

点击运行按钮（⌘+R）或按 `Cmd + R` 快捷键。

### 4. 使用应用

**添加提醒**:
1. 点击右上角 "+" 按钮
2. 输入标题和备注（可选）
3. 选择时间和日期
4. 设置优先级和分类
5. 点击"保存"

**管理分类**:
1. 切换到"分类"标签
2. 点击右上角 "+" 添加新分类
3. 选择颜色和图标

**今日视图**:
- 切换到"今天"标签查看今日待办事项
- 自动显示逾期提醒

## 权限说明

应用需要以下权限：
- **通知权限**: 用于在提醒时间发送推送通知

首次启动时会自动申请权限，也可以在"设置"中手动开启。

## 自定义配置

### 添加新的默认分类

在 `Category.swift` 中编辑 `defaultCategories` 数组：

```swift
static let defaultCategories: [Category] = [
    Category(name: "工作", color: "#007AFF", icon: "briefcase.fill"),
    Category(name: "个人", color: "#34C759", icon: "person.fill"),
    // 添加你的分类...
]
```

### 修改颜色主题

在 `ReminderRowView.swift` 中修改优先级颜色：

```swift
var priorityColor: Color {
    switch reminder.priority {
    case .low: return .green
    case .medium: return .orange
    case .high: return .red
    }
}
```

## 开发计划

- [ ] iCloud 同步
- [ ] 小组件支持
- [ ] Siri 快捷指令
- [ ] 语音输入提醒
- [ ] 智能推荐

## 许可证

MIT License

## 作者

由 AI 助手创建

---

如有问题或建议，欢迎反馈！
