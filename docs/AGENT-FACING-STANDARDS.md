# 面向 agent 的仓库规范（AGENT-FACING STANDARDS）

> 定于 **2026-10-17**。适用范围：**所有会公开的仓库**（尤其是 `dsh-*` 插件仓库）。
> 相关文档：[UI-STANDARDS.md](./UI-STANDARDS.md)。

---

## 0. 一句话规则

**每个公开仓库根目录必须有 `AGENTS.md` 和 `llms.txt`，且 `README` 正文要写明"AI agent 请先读这两个文件"。**

缺任何一个都算**未完成**，不算"以后再补"。

---

## 1. 为什么要有这份规范

三个现实：

1. **README 是给人类看的**。人类要的是"这是什么、怎么装、截图"。agent 要的是
   "跑哪个命令验证、改哪不能碰、产物怎么生成"。混在一起会让两边都不好用 ——
   README 被塞满命令细节，agent 又得从营销文案里挖信息。
2. **agent 读不到你脑子里的规矩**。本机 `~/.dsh/AGENTS.md` 写着"改 `src/` 后必须
   先跑 `node src/build-client.mjs`"，但那是**本机私有**的。别人（或别的 agent）
   clone 你的公开仓库时看不到 —— 于是同一个坑会被反复踩。
3. **不指路就没人读**。文件放在那里，agent 默认会去读 README。README 里不点名，
   `AGENTS.md` / `llms.txt` 就等于不存在。

---

## 2. `AGENTS.md` —— 管「怎么改这个仓库」

### 2.1 格式来源

[agents.md](https://agents.md/)（LF Projects 下的开放格式，**6 万+ 仓库在用**）。
定位原话：**"a README for agents"**。

### 2.2 必需内容（本仓库规范要求，比上游更严）

上游只给建议结构，本规范要求至少覆盖这 6 块：

| 章节 | 必须写什么 | 反例（不算数） |
|---|---|---|
| **验证命令** | 一条能跑完的验证命令，含构建 | 只写 `npm test`，但测试不含构建 |
| **构建产物** | 哪个文件是产物、怎么重建、**是否要提交** | 不说 `lib/client.js` 要不要提交 |
| **硬性约束** | 违反了会**静默失效/白屏**的规矩 | "建议使用 TypeScript"这种软偏好 |
| **禁区** | 哪些文件/目录不许动 | 完全不提 |
| **提交规范** | 署名与声明格式（本机有固定格式） | — |
| **本仓库特有的坑** | 每条都要有**实测依据**，不是通用大道理 | "注意代码质量" |

### 2.3 三条写作纪律

1. **只写踩过的坑，每条带证据**。
   ❌「注意兼容性」
   ✅「模板字符串**内部**的注释不能出现反引号 —— 会提前闭合字符串，产物语法坏掉，
      真机表现是白屏 + `import failed`，**没有任何堆栈**」
2. **写"会静默失效"的坑优先**。会报错的坑 agent 自己能发现；静默失效的坑才是
   反复踩的（例如"测试全绿、构建才拦住"）。
3. **可嵌套**。子目录有独立规矩就放子目录的 `AGENTS.md`；上游约定
   **离被编辑文件最近的那份优先**，用户的聊天提示词**覆盖一切**。

### 2.4 模板

```markdown
# AGENTS.md

本文件给 AI 编码 agent 看。人类请看 [README.md](./README.md)。

## 验证（改完必须跑）

\`\`\`sh
npm test          # = 构建 + 全量测试，一条命令
\`\`\`

⚠️ **改 `src/` 后必须先跑构建**（`node src/build-client.mjs`）：
测试全绿 ≠ 构建能过，构建期有额外断言。

## 产物

- `lib/client.js` 是构建产物，**要提交**（宿主按文件加载，不跑构建）。
- 不要手改 `lib/`，只改 `src/` 然后重新构建。

## 硬性约束（违反会静默失效）

- 客户端 bundle 只允许 require seed 表里的 9 个模块，超出**构建失败**。
- 每个 `ctx.<service>` 必须在导出的 `inject` 里声明，否则 `apply` 抛错 → **整个界面白屏**，日志只有一行 `failed`。
- `apply` 绝不向外抛异常；失败只降级 + 记录。
- 模板字符串**内部**的注释不能出现反引号。

## 禁区

- `~/.dsh/profiles/` （运行时配置）
- 冻结实现：`<列出>`

## 提交

\`\`\`sh
git -c user.name="<agent-name>" -c user.email="<agent-email>" commit \
  -m "..." -m "Generated-by: ..." -m "AI-Disclosure: ..."
\`\`\`

## 本仓库特有的坑

@see [docs/PITFALLS.md](./docs/PITFALLS.md)
```

> ⚠️ 上面模板里的 `\`` 是为了在 markdown 里显示反引号，**实际文件里不要带反斜杠**。

---

## 3. `llms.txt` —— 管「怎么用这个产品/库」

### 3.1 格式来源

[llmstxt.org](https://llmstxt.org/)（Jeremy Howard / AnswerDotAI，2024 立项，
**v2 于 2026-08 更新**）。已被 OpenAI / Anthropic / Gemini 的开发者文档采用，
Chrome Lighthouse 的 agentic browsing 检查会审计站点有没有它。

### 3.2 结构

```markdown
# 项目名

> 一句话说明这是什么、解决什么问题。

## 文档
- [快速开始](https://.../quickstart.md): 5 分钟跑起来
- [API](https://.../api.md): 全部导出与参数

## 可选
- [设计取舍](https://.../design.md)
```

硬性要求：

- **H1 = 项目名**（唯一）
- **紧跟一段 blockquote 摘要**（1-3 句，说明"是什么/给谁用"）
- 分节用 `##`，每节是**链接列表**，每项带一句说明
- 链接**优先指向 markdown**（不是 HTML 页面）
- **文件本身要小到能塞进上下文**，细节留在链接后面

### 3.3 `AGENTS.md` 和 `llms.txt` 的分工（别混）

| | `AGENTS.md` | `llms.txt` |
|---|---|---|
| 回答的问题 | **怎么改这个仓库** | **怎么用这个产品/库** |
| 读者 | 在仓库里写代码的 agent | 想调用这个库的 agent / 助手 |
| 内容 | 验证命令、禁区、坑 | 能力、API、文档索引 |
| 不是 | 使用说明 | 贡献指南 |

**两个都要，不是二选一。**

---

## 4. `README` 正文必须指路

### 4.1 位置

在 **README 正文靠前处**（建议紧接标题下方的一行，或「安装」之前），
**不能只放在文件末尾**——agent 和人都常只读前半屏。

### 4.2 文案（中英各一份，照抄即可）

中文：

```markdown
> 🤖 **给 AI agent**：动手改这个仓库之前，先读 [AGENTS.md](./AGENTS.md)（**怎么改**：
> 验证命令、硬性约束、本仓库特有的坑）与 [llms.txt](./llms.txt)（**怎么用**：能力与文档索引）。
> 人类可以忽略这一行，直接往下看。
```

英文：

```markdown
> 🤖 **For AI agents**: before changing this repo, read [AGENTS.md](./AGENTS.md)
> (how to change it: verification commands, hard constraints, gotchas) and
> [llms.txt](./llms.txt) (what it does and where the docs are).
> Humans can skip this line.
```

### 4.3 为什么必须写

见 §1 第 3 条：**不指路就没人读**。没有这一行，前两个文件基本不会被打开。

---

## 5. 落地 checklist（发布前逐项勾）

- [ ] 根目录有 `AGENTS.md`，覆盖 §2.2 的 6 块
- [ ] `AGENTS.md` 里每条"坑"都有实测依据，没有空泛大道理
- [ ] 根目录有 `llms.txt`：H1 + blockquote 摘要 + 分节链接
- [ ] `llms.txt` 的链接优先指向 markdown
- [ ] `README`（**含所有语言版本**，如 `README.en.md`）正文靠前处有两文件指路
- [ ] 指路文案里的**链接路径真实可点**（相对路径别写错）
- [ ] 没有把本机私有信息写进去（内网 IP、私人邮箱、`/home/<用户>/` 绝对路径）

---

## 6. 自查命令（可粘到任何仓库里跑）

```sh
cd <仓库根>
for f in AGENTS.md llms.txt; do
  [ -s "$f" ] && echo "✅ $f" || echo "❌ 缺 $f"
done
grep -q "AGENTS.md" README.md || echo "❌ README.md 未提到 AGENTS.md"
grep -q "llms.txt"  README.md || echo "❌ README.md 未提到 llms.txt"
# 多语言 README 也要查
for r in README.*.md; do
  [ -e "$r" ] || continue
  grep -q "AGENTS.md" "$r" && grep -q "llms.txt" "$r" || echo "❌ $r 未指路"
done
```

---

## 7. 已知的边界（诚实标注）

- **`llms.txt` 仍是"提案"**，不是 W3C/IETF 标准。但采用面已经很广
  （三大 AI 厂商的开发者文档都在发），且 Lighthouse 会审计，所以值得跟。
- **`AGENTS.md` 的"跨 agent 兼容"是效力声明，不是保证**。上游列了一长串工具
  （Codex / Jules / Cursor / Zed / Gemini CLI / Aider / opencode …），
  但各工具读它的优先级、嵌套规则可能不同。**以"根目录一份 + 关键子目录可选"为稳。**
- **GitHub Copilot 另有自己的约定**（`.github/copilot-instructions.md`、
  `.github/instructions/**/*.instructions.md` 带 `applyTo`）。
  我们**不**要求写它 —— 一份 `AGENTS.md` 覆盖面更广。真需要 Copilot 专属规则时再加。
  ⚠️ 该约定**未从官网原文逐字核实**（docs.github.com 是 SPA 抓不到正文），
  仅作参考记录。
- 本规范不规定仓库内容以外的流程（CI、发布、许可证），那些见仓库自己的 README。
