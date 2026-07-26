# Streak Daily

> 用户可见的 app 名为 **Streak Daily**(bundle id `com.dienbell.streak`)。内部 Xcode 项目/模块名仍为 `StreckDaily`,故构建产物为 `StreckDaily.xcworkspace`。

一个帮助你对**少数几件每天要做的事**(比如定时学习)保持专注的 iOS app。
为每个学习项目设置**每天定时本地提醒**,鼓励"少而精"——同时进行的活跃项目建议不超过 3 个。

> 设计与架构规则见 [`CLAUDE.md`](./CLAUDE.md)(面向 AI 协作);本 README 面向使用者和贡献者。

---

## 目录

- [功能](#功能)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [使用说明](#使用说明)
- [构建与测试](#构建与测试)
- [项目结构](#项目结构)
- [架构概览](#架构概览)
- [已知限制与路线图](#已知限制与路线图)

---

## 功能

- **学习项目** 带 5 种生命周期状态:`notStarted` / `inProgress` / `paused` / `failed` / `completed`,状态转换有显式规则(终态不可逆)。
- **多个每日提醒**:每个项目可设最多 **3 个**提醒时间(`08:00`、`12:30`、`20:00`…),各自一条独立的每天重复本地通知。
- **本地通知**(`UserNotifications`):进入活跃状态时申请权限,暂停 / 完成 / 放弃 / 删除时自动取消提醒,修改时间自动替换。App 启动时自动与系统对齐。
- **专注建议**:同时激活第 4 个项目时弹窗提醒(软限制,不自动暂停别的项目)。
- **本地存储**(`SwiftData`),无网络、无账号、无第三方依赖。
- 全程 **Swift 6 严格并发** + Observation 框架 + 现代 SwiftUI。

## 环境要求

| 项 | 版本 |
|---|---|
| Xcode | 26+ |
| iOS 部署目标 | 26.0 |
| Swift | 6(SWIFT_STRICT_CONCURRENCY = complete) |
| 项目生成 | [Tuist](https://tuist.io) 4.x(经 [mise](https://mise.jdx.dev) 安装) |

## 快速开始

```bash
# 1. 安装 mise 和 Tuist(首次)
brew install mise
mise use -g tuist@latest

# 2. 生成 Xcode 工程(Tuist 读取 Project.swift)
mise exec -- tuist generate

# 3. 打开工作区
open StreckDaily.xcworkspace
```

> `StreckDaily.xcworkspace` / `StreckDaily.xcodeproj` / `Derived/` 都是**生成物**,不要手动改、也不必提交(见 `.gitignore`)。

### 便捷命令(可选)

仓库根目录有 `Makefile`,免去手敲 `mise exec --`:

```bash
make gen     # tuist generate
make build   # tuist build
make test    # tuist test
make open    # generate 后打开 workspace
make clean   # 删除生成物
```

> 想直接用 `tuist ...`(不带 `mise exec --` 前缀):在 `~/.zshrc` 加一行 `eval "$(mise activate zsh)"`,新开终端即可。

## 何时需要 `tuist generate`(即 `make gen`)

**只在以下情况**需要重新生成,**不是每次都要**:

- ➕➖✏️ 新增 / 删除 / **重命名** 源文件或资源文件(Tuist 在生成时把文件清单写进 `.xcodeproj`,新文件不会自动被发现)
- ⚙️ 改了 **`Project.swift`**(settings、bundle id、Info.plist、resources、依赖)
- 📦 改了 **`Tuist/Dependencies.swift`**
- 🔄 **全新 clone / pull** 之后(`.xcodeproj` / `.xcworkspace` 被 gitignore,不在仓库里)

**不需要**重新生成:只是**编辑已有文件的内容**——Xcode 在 build 时自动识别改动。

## 使用说明

1. **新建项目**:列表页右上角 **+** → 填标题(必填)+ 每日具体活动(可选)+ 提醒时间。新项目默认 `notStarted`。
2. **设置提醒**:在 "Reminders" 区打开 **Daily Reminders**,用 **Add Time** 增加时间(最多 3 个),左滑删除某条。
3. **开始**:进入项目详情,点 **Start**。首次会请求通知权限——**允许**后,提醒才会在到点时发出。
4. **提醒到点**:即使 app 关闭也会收到本地通知;前台时同样横幅+声音提示。
5. **状态管理**(详情页显式动作):
   - `inProgress` ↔ **Pause** / **Resume**
   - **Mark Completed**(终态,需确认)/ **Abandon**(终态,需确认)
   - 终态项目不能改回;放弃/完成会取消其全部提醒。
6. **编辑 / 删除**:详情页右上角菜单 → **Edit** / **Delete Project**(删除级联清除历史与提醒)。

> 提醒时间建议:手测时把某条设到**当前时间 1 分钟后**,锁屏等待确认到点。

## 构建与测试

```bash
make gen     # 新增/删除源文件后先重新生成(等同 mise exec -- tuist generate)
make build   # 构建 app
make test    # 运行全部单测
```

- 测试用 **Swift Testing**(`@Test` / `#expect`),共约 50 个,覆盖:状态转换、活跃项目策略、每日 finalization 不可变性、日历归一化(DST/时区/午夜)、通知标识符、SwiftData 持久化与级联、`ProjectService` 的多提醒调度/取消/校验。
- `tuist test` 会自动选择一个可用的 iOS 模拟器(开发用 iPhone 17)。
- **`make test` 已带 `--no-selective-testing`**:每次都跑**全量**。若你直接敲 `tuist test`,Tuist 默认开启**选择性测试**——没有改动时会跳过、提示 "no tests to run"(那是正常缓存行为,不代表失败)。

## 项目结构

```
StreckDaily/
├── Project.swift                # Tuist 清单(app + 单测两个 target)
├── Tuist/Dependencies.swift     # 标记 Tuist 根目录(空依赖)
├── StreckDaily/                  # app target
│   ├── App/                     # 入口、组合根、导航路由、启动对齐
│   ├── Domain/                  # 纯领域:模型/枚举/策略/错误(无 SwiftUI/SwiftData 依赖)
│   │   ├── Models/              # ProjectStatus, ReminderTime, ReminderPolicy ...
│   │   ├── Policies/            # 状态转换 / 活跃项目数 / 每日 finalization
│   │   └── Errors/
│   ├── Persistence/             # SwiftData @Model + ModelContainerFactory
│   ├── Services/                # ProjectService、CalendarService、Notifications/
│   ├── Features/                # 按特性组织的 SwiftUI 视图(List/Detail/Editor)
│   └── Shared/                  # 分组、错误包装等展示层工具
└── StreckDailyTests/       # 单测 + TestSupport(Mock、FixedCalendarProvider)
```

## 架构概览

分层 + 依赖单向向下:**Features → Services → Domain / Persistence**。

- **领域层**(`Domain/`)是纯值类型 / 策略,可独立单测;`ProjectStatusTransitionPolicy`、`ActiveProjectPolicy`、`DailyCheckInPolicy` 集中承载产品不变量。
- **持久层**(`Persistence/`):`LearningProject` 拥有 `DailyCheckIn`(每日打卡)与 `ReminderEntry`(提醒条目)两个级联关系。
- **服务层**(`Services/`):`ProjectService`(`@MainActor @Observable`)集中所有写操作与状态转换授权;`SystemNotificationService` 封装 `UNUserNotificationCenter`,协议化便于测试注入。
- **通知标识符** 确定性可解析:`project.daily-reminder.<projectUUID>.<reminderUUID>`,启动时 `AppReconciliationService` 做 nuke-and-pave 式幂等对齐。
- 写数据**先**落库,通知副作用用 `try?` 尽力而为,绝不阻塞数据保存。
- 完整规则、不变量与实现顺序见 [`CLAUDE.md`](./CLAUDE.md)(§7/§11/§15/§37 等)。

## 已知限制与路线图

按 `CLAUDE.md` §35 的阶段推进,当前完成 **Phase 1 / 2 / 4**:

- [x] 领域 + 持久化 + 策略
- [x] 项目管理 UI(列表/详情/编辑)+ 状态转换 + 三活跃项目软限制
- [x] 本地通知(权限、多提醒调度、取消、启动对齐、前台展示)
- [ ] **Phase 3 每日打卡**:`DailyCheckInService`、Completed/Not Completed 不可变 finalization、历史页,以及通知上的 **Completed / Not Completed 动作按钮**
- [ ] 通知 tap 深链路由到对应项目
- [ ] 通知被拒时的显式提示 + "去设置"入口
- [ ] **Phase 5 本地化**(String Catalog,中文/英文)、无障碍与 Dynamic Type 复核、snapshot 测试
- [ ] SwiftData 正式迁移方案(目前为干净安装;见下)

> **迁移提示**:本项目仍处 dev(v0.1),未提供 `VersionedSchema`。若模拟器/设备上装过旧版,改 schema 后旧 store 可能无法打开——**卸载重装**即可。
