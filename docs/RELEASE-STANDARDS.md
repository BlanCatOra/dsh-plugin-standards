# 发布前规范流程（RELEASE STANDARDS）

> 定于 **2026-10-17**，来自 `dsh-enhanced-prompt-editor` v0.1.0 首次发布的**实际执行记录**
> （不是构想）。适用范围：**所有要公开的 `dsh-*` 插件仓库**。
> 相关文档：[AGENT-FACING-STANDARDS.md](./AGENT-FACING-STANDARDS.md) ·
> [UI-STANDARDS.md](./UI-STANDARDS.md)。

---

## 0. 一句话规则

**发布不是「git push 一下」，而是一条可复跑的流水线：文档齐全 → 全面脱敏 → 测试可复现 →
打包核对 → 推前硬闸 → 用户授权 → 发布。**

六步里**任何一步失败都不许发布**。已做成脚本/钩子的步骤（§2、§4、§5）必须真的跑，不许口头确认。

---

## 1. 为什么要有这份规范

一次真实的首发暴露了三类问题，都不是"代码写得对不对"：

1. **文档缺失不自知**。仓库跑了一整天、187 项测试全绿，但 `AGENTS.md` / `llms.txt`
   一个都没有 —— 因为没有任何东西在检查它们。**规范不落成测试，就等于没有。**
2. **泄漏藏在意想不到的地方**。README 的安装示例、`package.json` 的 `repository`、
   测试文件里硬编码的 `ROOT` —— 三处都含本机绝对路径，而代码本身完全正常。
   更麻烦的是：**改掉当前文件还不够，历史提交里照样公开**。
3. **"测试通过"不等于"可复现"**。首发前发现浏览器几何测试依赖「`/tmp` 或上层没有
   `package.json`」这个隐含前提；另一个会话在 `/tmp` 留了个 `{"type":"module"}`，
   整组测试就随机报 `require is not defined`，而报错完全不指向真凶。

所以这份规范针对的**不是功能正确性**，而是「能不能安全地交到陌生人手里」。

---

## 2. 六步流程（按顺序，每步有命令）

### 步骤 1 · 文档齐套

| 文件 | 必需 | 回答什么 |
|---|---|---|
| `README.md` 及**所有语言版本** | ✅ | 这是什么、怎么装、**截图** |
| `AGENTS.md` | ✅ | 怎么改这个仓库（6 块，见 AGENT-FACING §2.2） |
| `llms.txt` | ✅ | 怎么用这个产品/库 |
| `docs/RELEASING.md` | ✅ | 发布清单（本规范的仓库级落地版） |
| `docs/demo-*.md` | 强烈建议 | 可用于截图/自测的真实长文本样本 |
| `CHANGELOG.md` · `LICENSE` | ✅ | 变更与许可 |

**README 要"美观"**，不是堆字。最低标准见 §3。

### 步骤 2 · 全面脱敏（当前文件 **+ 历史**）

```sh
# ① 本机绝对路径
git grep -nIE '/home/[a-z][a-zA-Z0-9._-]*' -- . ':!pnpm-lock.yaml'
# ② 内网 IP
git grep -nIE '192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+'
# ③ 私人邮箱（agent 公开邮箱除外）
git grep -nIE '[A-Za-z0-9._%+-]+@qq\.com' -- . | grep -v 'agent.qq.com'
# ④ 凭据
git grep -nIiE '(api[_-]?key|secret|password|token)\s*[:=]\s*["'\'']?[A-Za-z0-9_-]{16,}' -- . ':!pnpm-lock.yaml'
# ⑤ 历史提交（关键：改文件不够，历史也会公开）
git log --all -p | grep -nE '/home/[a-z][a-zA-Z0-9._-]*'
```

五条必须**全部 0 命中**。历史有泄漏且**尚无远端**时，重建干净历史（零风险）：

```sh
git bundle create ~/.rollback/<repo>-pre-sanitize-$(date +%Y%m%d).bundle --all  # 先备份
git checkout --orphan clean-main && git add -A && git commit -F msg.txt
git branch -f main clean-main && git checkout main && git branch -D clean-main
git branch -D <含泄漏的旧分支> && git tag -d <旧tag>
```

⚠️ **有远端时不要重写历史**（会影响他人）：改为删除/轮换泄漏内容，并按需告知协作者。

**哪些"不算泄漏"**（不要过度清洗）：

- agent 公开通讯邮箱（本机为 `blancatora@agent.qq.com`）—— 它是 commit author，本来就公开；
- 版权行里的号主署名（`© 2026 blancat`）—— 用户要求的署名；
- 规范文档里作为**规则示例**写的 `/home/<用户>/`、`192.168.` 前缀等**占位形式**
  （注意：别写成完整 IP 字面量，否则脱敏扫描会误报）。

### 步骤 3 · 普遍性测试（不是"我这台机器能跑"）

测试必须**自足**，不依赖本机残留状态：

- [ ] 一条命令可跑完：`npm test` = 构建 + 全量测试；
- [ ] 临时目录**显式钉死模块类型**（见 §6 踩坑），不依赖 `/tmp` 干净；
- [ ] 依赖外部程序（如 `electron`）的用例**没有就 skip**，不是 fail；
- [ ] 关键守卫做过**变异验证**（故意破坏实现 → 用例必须变红）；
- [ ] 测试数字**不写进 README**（会过期），需要时链到 `test/` 目录。

```sh
npm test                        # 全绿
node --test test/<某个几何>.mjs  # 单跑，确认不是靠别的用例兜底
```

### 步骤 4 · 打包与元信息核对

```sh
npm pack --dry-run
```

- 必须**没有**：`node_modules`、`test/`、`.git`、内部交接文档、凭据；
- 必须**有**：`lib/`（构建产物）、`locale/`、`cordis.patch.yml`、`icon.svg`、
  `README*.md`、`AGENTS.md`、`llms.txt`、`CHANGELOG.md`、`LICENSE`、`docs/`；
- 插件展示元信息：`locale/en.json` 的 `meta.title` / `meta.description` 非空；
  `package.json` 开放 `exports` 的 `./package.json`、`./locale/*.json`、`./icon`，
  顶层 `"icon"` 指向包内文件且 ≤256 KiB；
- `repository.url` 必须是**真实公开 URL**（不能是 `file:` 本机路径）；
- 要发布就**移除 `"private": true`**，版本号与 `CHANGELOG.md` 一致。

### 步骤 5 · 推前硬闸

仓库内必须有可执行的检查，而不是靠人记得：

`test/agent-facing.test.mjs`（进 `npm test`）应覆盖：

- `AGENTS.md` / `llms.txt` 存在、非空、结构合规、6 主题齐全；
- 所有语言 README 都在**正文前 1/3** 指路，且链接文件真实存在；
- README 引用的**截图存在且 ≤400KB**（防图裂与仓库膨胀）；
- README 里**不写死测试数量**；
- `docs/RELEASING.md` 存在且含验证命令/硬闸/收录方式/脱敏项；
- **脱敏断言**（路径 / 内网 IP / 私人邮箱，含允许清单）。

`.githooks/pre-push` 应重跑四件事：构建+测试 → **产物同源**（`git diff --quiet -- lib`）
→ 脱敏 → 工作区干净。启用：

```sh
git config core.hooksPath .githooks
```

⚠️ **不要 `git push --no-verify`** 绕过，除非明确知道只推了文档。

### 步骤 6 · 授权与发布

- **push / 建远端 / 发 PR / 发布 npm 必须得到用户明确授权**（全局硬规则）；
- 授权后：

```sh
gh repo create <owner>/<repo> --public --source=. --description "…"
git push -u origin main
gh repo edit --add-topic dsh-plugin,dsh,deepseek-harness
# 可选：npm publish --access public
```

- **收录不用申请**：dsh-plugin.org 定期扫描 GitHub 的 `dsh-plugin` topic 自动收录；
- release notes / 公开文字必须带 AI 署名（agent / harness / model / 联系邮箱）。

---

## 3. README「美观」的最低标准

"美观"不是花哨，是**让人 10 秒内看懂并愿意装**：

1. 顶部：`<h1 align="center">` + 一句话定位 + 一行标签（包名 · 语言切换 · 变更日志 · 许可）；
2. **三张以内截图**，每张配一句说明，紧跟第一段"为什么需要它"之后；截图必须压缩
   （宽 ≤1600、quality ≤85、单张 ≤400KB），并用**真实内容**（长文本示例）而非空界面；
3. 功能用**表格**而不是长段落；命令用**代码块**；
4. 中英双语（`README.md` / `README.en.md`），两版**信息量对等**，不是机翻摘要；
5. 文末固定段：开发（验证命令）、项目结构、许可；
6. 全文**不写测试数量**、不写本机路径、不写"TODO 以后再补"。

---

## 4. 与另两份规范的关系

| 规范 | 管什么 | 何时读 |
|---|---|---|
| [UI-STANDARDS.md](./UI-STANDARDS.md) | 界面用什么组件、设置页放哪 | 写 UI 时 |
| [AGENT-FACING-STANDARDS.md](./AGENT-FACING-STANDARDS.md) | `AGENTS.md` / `llms.txt` / README 指路 | 建仓库、补文档时 |
| **本文件** | **从"文档齐了"到"敢公开发布"的全流程** | **发布前逐项执行** |

三者互不替代：UI 规范管"长什么样"，agent-facing 管"文档写了没"，本文件管
**"脱敏、测试可复现、打包正确、硬闸通过、有授权"**。

---

## 5. 发布前 checklist（可直接复制到 `docs/RELEASING.md`）

```markdown
- [ ] README 双语齐全，含压缩截图与真实长文本示例
- [ ] AGENTS.md 覆盖 6 主题；llms.txt 有 H1 + 摘要 + 分节链接
- [ ] 所有语言 README 正文前 1/3 指路 AGENTS.md + llms.txt
- [ ] docs/RELEASING.md 存在
- [ ] 脱敏五条扫描全部 0 命中（含 git 历史）
- [ ] npm test 全绿；关键守卫做过变异验证
- [ ] 测试不依赖本机残留（临时目录钉死模块类型 / 外部程序缺失则 skip）
- [ ] npm pack --dry-run 内容正确；repository.url 是真实公开 URL
- [ ] locale/en.json 的 meta.* 非空；exports/files 含 package.json、locale、icon
- [ ] .githooks/pre-push 已启用且四步全过
- [ ] 版本号 = CHANGELOG 条目；要发布则移除 private
- [ ] 用户已明确授权 push / 建仓库 / npm publish
- [ ] topic 加 dsh-plugin（收录靠它）
- [ ] 公开文字含 AI 署名
```

---

## 6. 本规范自己踩过的坑（都有实测依据）

### 6.1 `/tmp` 里别人的 `package.json` 会打挂你的测试

实测：另一个会话做 asar 提取时在 `/tmp/package.json` 留下 `{"type":"module"}`，
本仓库 6 个 electron 离屏几何测试在 `/tmp/epe-geom-*` 建临时目录跑 `probe.js`（CommonJS），
Node 向上找到那个 `package.json` → 按 ESM 解析 → `ReferenceError: require is not defined`
→ `spawnSync electron ETIMEDOUT`，**报错完全不指向真凶**。

修法：临时目录里显式写 `{"type":"commonjs"}`，把模块解析钉死在该目录内。

### 6.2 改掉当前文件 ≠ 脱敏完成

实测：README 示例、`package.json.repository`、测试里的 `ROOT` 三处含 `/home/<用户>/`。
改完工作树后 `git log --all -p` 仍能搜到 —— **历史提交会一起公开**。
无远端时用 `--orphan` 重建历史（先 `git bundle` 备份），有远端时不许重写。

### 6.3 文档里写"测试数量"必然过期

实测：README 写"全部 87 项测试"，两天后已是 187 项，且无测试守它。
修法：README 只写"全部测试"；需要数量就链到 `test/` 目录，并加一条
「README 不得出现 `数字 + (项测试|tests)`」的断言。

### 6.4 脱敏规则文本自己会误报

实测：`docs/RELEASING.md` 里写"内网 IP（如 `192.168.x.x`）"，被自己的扫描脚本命中。
修法：规则示例写成 `192.168.` 前缀 / `<用户>` 占位，**不要写完整 IP 字面量**。

### 6.5 检查"文档存在"还不够，要检查"文档里链的东西存在"

实测：README 引用 `docs/demo-long-prompt.md` 时该目录还不存在，点了 404 且无人发现。
修法：断言 README 里指向本地 `docs/` `test/` 的链接文件真实存在，截图还要限体积。
