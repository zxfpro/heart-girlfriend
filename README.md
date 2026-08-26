<div align="center">

# 💕 Heart Girlfriend

**恋爱养成系女友 · 有心跳的 AI 陪伴角色**

*Built on [Heart](https://github.com/zxfpro/heart) — 给 AI 一颗会爱的心。*

</div>

---

## 这是什么 / What

**Heart** 给模型一颗心跳（主观能动性：不用你开口，它会主动做事、主动找你）。
**Heart Girlfriend** 是安装了这个「心跳」能力的**衍生应用**——一个可部署运行的陪伴角色项目，内置示例角色「小鹿」。

- 💓 **主动联系** — 不用你开口，她先来找你、问你今天过得怎么样。
- 🧠 **记得你** — 跨对话记住你的喜好、说过的事、重要的日子。
- 🎭 **有自己的情绪** — 会开心、会吃醋、会失落，情绪来自她自己的心跳，不是模板。
- 🌱 **养成系** — 你们的互动会「塑造」她，性格与关系随陪伴时间演化。

---

## 快速开始 / Quick Start

**前置**：一台已接入飞书（或其它 IM）的 [Hermes](https://hermes-agent.nousresearch.com/docs) 实例。

```bash
git clone --recursive https://github.com/zxfpro/heart-girlfriend.git
cd heart-girlfriend
./deploy.sh            # 交互式：填 LLM 端点 + 会话信息，自动装配
```

`deploy.sh` 会依次：拉 heart 子模块 → 装 venv/依赖 → 配 `heart/.env` → 探测投递目标 → 写 `bridge.json` → 建桥 cron（每 3 分钟双向同步）→ 后台启动心跳（mind + hermes）。

部署完，**先给机器人发一条消息**（生成会话），她就会在飞书里主动找你了。

---

## 捏一个自己的角色 / Create your own character

小鹿只是「示例角色」。复制一份、改几个文件，就是你的角色：

```bash
cp -r characters/xiaolu characters/<你的角色名>
./deploy.sh --character <你的角色名>
```

每个角色文件夹（`characters/<名字>/`）里的文件：

| 文件 | 作用 |
|---|---|
| `AGENTS.md` | 角色「显意识」：判断潜意识想法要不要行动、行动边界、说话方式 |
| `关于我.md` | 她是谁（年龄/职业/性格） |
| `关于你.md` | 你是谁（她眼里的你，让她「认得你」） |
| `关于朋友.md` | 她和朋友/你的关系（粘人程度、相处模式） |
| `关于恋爱.md` / `喜欢的东西.md` / `小烦恼.md` | 她的恋爱观、喜好、烦恼 |
| `日记-今天.md` | 她的日记（给「想」提供当日素材） |

改完这些 `.md` 就是「捏人」——性格、语气、爱好全在这些文件里，不用碰代码。

---

## 调参 / Tuning

超参数都在 `heart/config.yaml`：

| 参数 | 含义 | 默认 |
|---|---|---|
| `interval` | 基础心跳间隔（秒，未启用动态频率时用） | 20 |
| `active_hours` | 动态频率：活跃时段 `HH:MM-HH:MM`（留空=不启用） | `09:00-23:00` |
| `active_interval` / `rest_interval` | 白天 / 晚上的心跳间隔（秒） | 90 / 300 |
| `timezone` | 时区（如 `Asia/Shanghai`），留空=实例本地时区 | 空 |
| `clinginess` | 粘人程度 0–1，越小越不主动找对方 | 1.0 |
| `proactive_files` | 触发「主动找对方」的人设文件名关键词（逗号分隔） | `关于你,关于朋友` |

- **动态频率**：白天活跃（间隔短）、晚上慢（间隔长），改 `active_hours` 即可。
- **粘人程度**：`关于朋友.md` 写「为什么想他」（动机），`clinginess` 控「多频繁找他」（频率）——一个管动机、一个管频率。

---

## 架构 / Architecture

```
heart-girlfriend/
├── heart/               ← git submodule：heart 引擎（心跳 想→判→做，记忆独立）
├── characters/
│   └── xiaolu/          ← 示例角色（人设 .md）
├── deploy.sh            ← 一键部署
└── README.md

大脑(heart)  ←———— 桥(bridge.py，在 heart 里) ————→  身体(Hermes 实例 + IM)
  · 独立记忆 facts/*.md        · 感知线：用户消息 → 对话记录.md
  · 心跳 想→判→做              · 表达线：要对你说.md → ①飞书 ②state.db ③对话记录
```

- **大脑（heart）**：记忆独立、执行后端可插拔，不绑定任何平台/角色。
- **身体（Hermes + IM）**：桥把大脑的记忆和身体的会话打通——表达线同时写 `state.db`（让原生 agent 在上下文里看到角色说过的话，不失忆），并走 Hermes 的平台抽象（`chat_id`），支持飞书之外的其它 IM。

---

## 许可证 / License

本项目以 [MIT License](LICENSE) 开源。Licensed under the [MIT License](LICENSE).

> ℹ️ **许可边界**：本项目依赖的 [Heart](https://github.com/zxfpro/heart) 采用 **AGPL-3.0**。若你**直接包含/链接 Heart 的代码**（构成衍生作品），AGPL 的 Copyleft 可能要求本项目/你的应用同样以 AGPL-3.0 开源；若仅作为**独立服务**通过 API 调用 Heart，则可保持 MIT 许可不变。
