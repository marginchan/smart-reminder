---
name: smartreminder-bugfix-features
overview: 根据用户明确的 5 条需求，梳理现有实现差距并制定修复与功能完善方案（分类默认选中/不可删除提示、便签搜索自然语言解析、月历功能增强、首页过滤逻辑调整）。
design:
  architecture:
    framework: html
  styleKeywords:
    - 移动端清爽
    - 日历卡片
    - 高层级对比
    - 轻量提示
  fontSystem:
    fontFamily: PingFang SC
    heading:
      size: 20px
      weight: 600
    subheading:
      size: 16px
      weight: 500
    body:
      size: 14px
      weight: 400
  colorSystem:
    primary:
      - "#2F80ED"
      - "#EB5757"
    background:
      - "#F7F8FA"
      - "#FFFFFF"
    text:
      - "#111111"
      - "#6B7280"
    functional:
      - "#27AE60"
      - "#F2994A"
      - "#EB5757"
todos:
  - id: adjust-reminder-filtering
    content: 调整 ReminderStore 过滤规则以匹配首页与月历的显示要求
    status: completed
  - id: default-category-and-toast
    content: 完善默认分类选中逻辑并加入删除拦截提示浮层
    status: completed
  - id: enhance-calendar-month
    content: 增强月历视图：默认选中、翻月范围、日历详情与农历节日展示
    status: completed
  - id: note-nlp-search
    content: 实现便签自然语言搜索解析与日期范围过滤逻辑
    status: completed
---

## User Requirements

- 新建提醒时默认自动选中“默认”分类，避免空分类保存
- 在分类管理中“默认”分类不可删除，尝试删除需弹出轻提示
- 便签搜索需支持自然语言解析，提升按语义检索的准确性
- 月历弹窗默认选中当天，可前后翻 12 个月；点击日期展示当日提醒列表，并显示中国农历与节日信息
- 首页仅展示当天预期提醒，历史/未来不在首页呈现；月历可查看历史每天提醒

## Product Overview

- 一款提醒与便签结合的移动应用，首页聚焦当天提醒，月历提供历史日历视图与详情查看，分类管理具备安全提示与限制

## Core Features

- 默认分类自动选中与删除保护提示
- 自然语言驱动的便签搜索
- 月历视图支持默认选中、跨月浏览、农历与节日展示、按日详情列表
- 首页仅展示当天提醒，减少信息噪音

## Tech Stack Selection

- 客户端：SwiftUI
- 数据层：SwiftData
- 通知：UserNotifications
- 日期与农历计算：Foundation Calendar + 自定义农历/节日计算模块

## Implementation Approach

- 以现有 View 与 Store 为主线，调整提醒筛选与默认分类逻辑，确保首页与月历的展示规则一致且可追溯。
- 月历增强采用“日期模型 + 农历/节日服务 + UI 展示”分层方式，避免 UI 直接承担复杂计算。
- 便签搜索引入自然语言解析层，将时间语义转换为日期范围并与更新日期筛选结合，优先复用现有解析逻辑并补充规则。
- 性能方面对日期格式化与农历计算做缓存或轻量化，避免滚动中重复计算带来卡顿。

## Implementation Notes

- 继续沿用 ReminderStore 作为单一数据源，避免新增全局状态。
- 首页筛选逻辑与月历详情逻辑要明确边界，避免互相影响。
- 农历与节日展示需支持缓存与降级策略（如无法识别节日时仅显示农历）。
- Toast 提示建议使用轻量 View Overlay，避免阻塞操作流程。

## Architecture Design

- 数据流：View 交互 → ReminderStore/Service 处理 → SwiftData 更新 → View 刷新
- 新增 Lunar/Festival 服务作为独立模块供月历调用，保持 UI 轻量。

## Directory Structure Summary

本次实现将在现有结构上扩展月历与搜索逻辑，并增加农历/节日工具与轻提示视图。

project-root/
├── SmartReminder/
│   ├── ViewModels/
│   │   └── ReminderStore.swift  # [MODIFY] 调整首页过滤、历史逾期规则、便签自然语言搜索解析与日期过滤逻辑
│   ├── Views/
│   │   ├── AddReminderView.swift  # [MODIFY] 默认分类选中逻辑强化，避免分类空值
│   │   ├── ReminderListView.swift # [MODIFY] 首页展示规则调整，仅显示当天提醒
│   │   ├── ContentView.swift      # [MODIFY] 月历默认选中、翻月范围、详情刷新与农历展示入口
│   │   ├── CategoryManagementView.swift # [MODIFY] 默认分类删除拦截与轻提示显示
│   │   ├── NotesView.swift        # [MODIFY] 便签搜索与自然语言结果绑定逻辑更新
│   │   └── ToastView.swift        # [NEW] 轻提示浮层组件，支持短时自动消失
│   ├── Services/
│   │   └── LunarFestivalService.swift # [NEW] 农历与节日计算与缓存服务，提供日期到农历/节日的映射

## 设计风格

- 移动端清爽日历风格，强调时间线与日期信息的层级清晰度
- 月历界面使用卡片化网格布局，日期、农历、节日采用不同字重与色彩区分
- 详情列表保持简洁但信息密度高，突出时间与标题

## 交互与视觉

- 选中日期使用高对比背景与轻微放大动效
- 节日信息使用强调色与小标签样式呈现
- Toast 采用轻量浮层，透明背景与短时淡入淡出