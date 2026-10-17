# DSH 插件 UI 规范（强制）

> 本规范的每条结论都对应 **DSH 0.2.1-alpha.2 内核源码**中的一个事实，已标注出处。
> 不是风格建议，是硬性要求 —— 违反会产出"能用但和宿主不一致"或"白屏"的插件。
>
> 适用：所有 `dsh-*` 插件的浏览器侧。整改对象见文末清单。

---

## 0. 两条铁律

### 0.1 禁止自己写 UI 组件，必须用 `dsh-client-ui-primitives`

**DSH 原生组件的唯一共享入口是 `@deepseek-ai/dsh-client-ui-primitives`。**
点击菜单、下拉选择、开关、输入框、弹窗、提示、折叠行、状态点、tabs、Tooltip … 一律从它取。

官方 README 原文（`dsh-client-ui-primitives/README.zh.md`）：

> 「在功能包里写控件之前，先查这张表。**插件无法导入另一个插件的组件，因此本包是控件唯一可以共享的地方**：
> 合适的就复用，有意的视觉差异提升成 prop，而不是另起一份拷贝。」

**为什么必须用它**（内核事实）：

1. **它是冻结基座模块，require 一定成功。**
   前端 boot 的 seed 表（`dsh-web-frontend/dist/assets/index-*.js` 里 `function gM()`）
   被传给 `__ModuleLoader__.create({ staticModules: gM() })`，表内容为：

   ```js
   { react, "react/jsx-runtime", "react-dom", "react-dom/client",
     "@deepseek-ai/cordis", "@deepseek-ai/dsh-client-store",
     "@deepseek-ai/dsh-client-ui-slots",
     "@deepseek-ai/dsh-client-ui-primitives",     // ← 本包
     "@deepseek-ai/dsh-client-ui-dockkit" }
   ```

   这 9 个之外的 `@deepseek-ai/*` 一律**不可 require**。

2. **官方自己就是这么做的 —— 9/10 个官方配置页 require 它。**
   实测内核里所有 `dsh-client-ui-settings-*` 的 `lib/client.js`：

   | 官方包 | `require(...)` |
   |---|---|
   | `settings-subagent` | **primitives**, dsh-client-store, react, react/jsx-runtime |
   | `settings-account` | **primitives**, dsh-client-store, react, react-dom, react/jsx-runtime |
   | `settings-general` | **primitives**, dsh-client-store, ui-slots, react, react-dom, react/jsx-runtime |
   | `settings-models` | **primitives**, dsh-client-store, react, react/jsx-runtime |
   | `settings-session-log` | **primitives**, dsh-client-store, react/jsx-runtime |
   | `settings-plugin-inventory` | **primitives**, react, react/jsx-runtime |
   | `settings-agent-loop` | **primitives**, react/jsx-runtime |
   | `settings-shell` | **primitives**, react/jsx-runtime |
   | `settings-web-search` | **primitives**, react/jsx-runtime |
   | `settings-plugins` | ui-slots, react, react/jsx-runtime（纯壳，不渲染控件，故不用 primitives） |

   更强的交叉验证：**把内核里所有 `dsh-client-*` 官方插件的 `require` 去重后，
   没有一个落在 seed 表 9 个之外**（实跑：10 个模块，越界 0 个）。

   → 旧规则"第三方插件禁止 require 任何 Harness Client 包、只能抄 markup/CSS"**与官方实践矛盾，已作废**。
   当年白屏事故的真实原因不是"require 了官方包"，而是 require 了**不在 seed 表里**的包（见 §4）。

3. **自己抄的组件必然与宿主漂移。** primitives 组件消费 `--dsw-*` 设计 token、
   处理了 `focusWithoutRing`/`useModalLayer`/`observeComposition`（IME）等细节，
   抄一份等于把这些坑重新踩一遍。

**可用导出（33 个，来自官方组件目录表）**：

| 类别 | 导出 |
|---|---|
| 操作 | `Button`（`variant`: primary/ghost/outline/toolbar）、`InlineEditor` |
| 选择 | `Switch`（36×20 双态，`label` 必填）、`Checkbox`、`SegmentedControl`、`SegmentedTabs` |
| 输入 | `Input`、`SettingsForm`、`SettingsFormModel` |
| 菜单浮层 | `Menu`、`MenuGroup`、`Tooltip`、`HoverCard`、`Modal`、`RiskConfirmation` |
| 展示 | `Pill`、`Tag`、`PathLabel`、`StateDot`、`ConnectionIndicator`、`DisclosureRow`、`TextShimmer` |
| 内容 | `JsonTree`、`MarkdownText`、`CommandText`、`TerminalBlock` |
| 图标/插画 | `PermissionIconReadOnlyRegular`、`PluginArtworkTerminal`、`GuideArtworkBrowser`、`FileTypeIcon`、`languageForPath` |
| 其他 | `ImageLightbox`、`Toast` |

> 用前先查官方 README 的「组件目录」表拿准确 props —— 该表是 props 的权威来源。

### 0.2 插件设置放「插件详情页」，不放「设置页」

**权威原句**（`dsh-client-ui-plugin-manager/README.zh.md`）：

> 「**注册了配置页的插件在这里、在它自己的页面上编辑；设置里只保留只读的插件列表。**」

也就是说：

- ❌ **不要**把插件自己的设置注册到 `settings.section`（那是"设置"总页，只给官方领域基座用）
- ✅ **要**注册到「插件」侧栏页里、你的插件条目下

**用户操作路径**：侧栏点「插件」→ **「已安装插件」**分组里找到你的插件 → 展开/进入详情 → 在里面改配置。

**登记插槽**（`dsh-client-ui-plugin-manager/lib/client.js` 里 `slots.register({name:"main", key:"plugins", ...})`
的 `children` 声明，权威列表）：

| 子插槽 | kind | scope | 用途 |
|---|---|---|---|
| `plugins.item` | list | root | **官方插件**详情页的配置卡片（`ItemDetail`，出现在「内置插件配置」组） |
| `plugins.detail.section` | list | root | 详情页分区 |
| `plugins.detail.actions` | list | root | 详情页操作按钮 |
| `plugins.detail.badge` | list | root | 详情页徽标 |
| `plugins.add.actions` | list | root | 「添加插件」的动作菜单项 |
| **`plugins.bundle.config`** | keyed | root | **第三方插件的配置卡片（key = 包名）—— 就放这里** |
| `plugins.row.config` | keyed | root | **插件行**级配置卡片 |
| `plugins.bundle.activation` | keyed | root | 组合包启停控件 |

**范式（照抄官方 `dsh-client-ui-settings-subagent`）**：

```js
// package.json —— 三个必需包 + locale（都必须在 dsh.client.inject 里，
// 否则服务还没就位你的 register 就跑了 → PENDING 一轮甚至失败）
"dsh": {
  "client": {
    "platform": "web",
    "inject": [
      "@deepseek-ai/dsh-client-locale",
      "@deepseek-ai/dsh-client-ui-settings",
      "@deepseek-ai/dsh-client-ui-plugin-manager"
    ]
  }
}
```

```js
// lib/client.js（factory 内）
const inject = ["slots", "locale"];        // 服务名白名单，与下面 ctx.* 一一对应

function apply(ctx) {
  try {
    const NS = "settings.<你的插件名>";
    ctx.effect(() => ctx.locale.register(NS, { zh, en }), "<包名>: settings copy");
    const t = ctx.locale.bind(NS);

    ctx.effect(() => ctx.slots.register({
      name: "plugins.bundle.config",  // ← 第三方插件用它（keyed 槽）
      key: "<包名>",                   // ← keyed 槽的身份：必须 == package.json 的 name
      order: 10,                       // 同一插槽内排序
      label: () => t("cardTitle"),
      locale: NS,
      inject: () => ({ t }),
    }, MySettingsCard), "<包名>: settings card");
  } catch (error) {
    // 见 §4：apply 绝不允许把异常抛出去
    console.error("[<包名>] settings card failed to register:", error);
  }
}
```

> ⚠️⚠️ **2026-10-16 更正**：本文档此前把 `plugins.item` 写成"最常用"的第三方入口，
> **是错的**。核查内核源码 `dsh-client-ui-plugin-manager/lib/client.js`：
>
> ```js
> const mine = listed.filter((pkg) => !pkg.official);                 // 第三方包
> renderGroup("bundles", t("bundlesTitle"), mine.map(packageCard));   // 「已安装插件」
> renderGroup("basic",   t("basicTitle"),   basicCards);              // 「内置插件配置」
> ```
>
> - 第三方包 → `PackageCard` → `PackageDetail`
>   → `renderSlot("plugins.bundle.config", { view: "page" }, { entryKey: pkg.name })`；
>   门控 `configured: ledger.bundles.has(openPkg.name)` —— **key 必须是包名**，
>   写错会**静默不渲染**（不报错）。
> - 官方包 → `ItemCard` → `ItemDetail` → `plugins.item`
>   （内核注释原文：*"An **official plugin's** page"*）。
>
> 第三方插件注册到 `plugins.item` 会出现在**「内置插件配置」**分组下（用户实测报过错位）。
> 另：`settings.plugin.item` 是更早的过时名字，内核全库 0 命中。
> **以 app.asar 里的内核源码为准，不要以文档为准。**

---

## 1. 组件书写要求

### 1.1 所有文案走 locale，不要硬编码中文

```js
ctx.locale.register(NS, { zh: {...}, en: {...} });
const t = ctx.locale.bind(NS);
t("save")     // ✅
"保存"         // ❌
```

`locale` 必须在 `inject` 里声明（§3）。

### 1.2 组件必须从 `inject` 拿数据，不要自己读全局

插槽注册的 `inject: () => ({...})` 返回的对象会作为 props 传给组件。
按需订阅宿主状态，**不要在组件里 import 宿主单例**。

### 1.3 渲染期绝不允许抛错

`ui-renderer` 给每个插槽条目套 `SlotErrorBoundary`，捕获后调
`reportEntryError(..., { abdicate: true })`，条目进 `abdicated` 弱集后
**`entriesOfSlot` 从此永久跳过它**。

症状：**装了别的插件之后本插件的控件不见了**（很容易错归因成"插槽被挤"）。

最容易破功的地方是样式注入：

```js
// ❌ 一旦 head 被冻结，整个插槽条目被永久撤销
function ensureCss() { document.head.appendChild(document.createElement('style')); }

// ✅ 把 document 当不可信输入，全包 try/catch，返回 false 表示降级
function ensureCss(css) {
  try { /* ... */ return true; } catch { return false; }
}
```

### 1.4 list 槽的两种"消失"是不同机制

1. **复用别人的 id = 顶格**：去重键是 `id`（keyed 槽是 `key`），**不是注册者身份**。
   自有 id 就并排新增；复用已发布的 id 就在不同 priority 下顶掉对方。
   → **永远用自己的 id。**
2. **渲染期抛错 = 永久撤销**：见 1.3。

### 1.5 不要用 CSS 猜别人的布局做防御

工具行那排 `.tools` 是 `display:flex`、子元素有 `min-width:0`；
**自有控件只要 `flex:none` 就拿到固有宽度**，不需要改别人的样式。
真正的护身符是「自有 id + 渲染期不抛错」。

---

## 2. 分层：Host 半侧 vs 浏览器半侧

| 放哪 | 内容 |
|---|---|
| Host（`src/index.js`） | 配置读取、文件/网络 IO、HTTP 路由、LLM 路由 |
| 浏览器（`lib/client.js`） | 只用 `primitives` + `react` 渲染 UI |

- **客户端包不得依赖 Host 包**（官方 subagent 的注释原文：
  *"Spelled here rather than imported: a client package must not depend on a Host package."*）。
  命名空间用字符串字面量，不要 import。
- 需要数据 → 走 `remote` 服务或自建 Host 路由（`ctx.webServer.register`），
  **不要**在客户端直接读文件。

---

## 3. `inject` 的正确写法（白屏事故的唯一根因）

两个 `inject` 长得像、作用完全不同：

| 位置 | 内容 | 管什么 |
|---|---|---|
| `package.json` 的 `dsh.client.inject` | **包名** | 只保证**模块加载顺序** |
| 插件导出的 `inject` | **服务名** | cordis 的**服务访问白名单** |

**cordis 的 `ctx.<service>` 是代理：服务名没写进导出的 `inject`，读它就同步抛**
`cannot get property "<service>" without inject`。

后果不是"功能不可用"，而是：

1. 异常从 `apply` 冒出 → cordis `Fiber._reload()` 捕获 → fiber `FAILED`
2. web boot 遍历所有条目，非 `active` 就收集 →
   `throw new Error("web boot: N entry did not activate")`
3. **整页白屏**，而 crash log 只有一行 `<包名>: failed`（**没有堆栈**）

### 3.1 硬性要求

```js
// ① 服务名必须与实际用到的 ctx.* 一一对应
export const inject = ["slots", "locale"];
// 用到 ctx.slots -> "slots"；ctx.locale -> "locale"

// ② 提供这些服务的官方包也要进 dsh.client.inject
//    否则服务要等下一轮 refresh 才到，本插件先 PENDING 一轮
```

官方参考（实测）：
- `settings-subagent` → `dsh.client.inject: [dsh-client-locale, dsh-client-ui-settings, dsh-client-ui-plugin-manager, dsh-api-remotes]`
- `settings-shell` → `[dsh-client-locale, dsh-client-ui-settings, dsh-client-ui-plugin-manager]`

### 3.2 探测可选服务用 `ctx.get()`

```js
ctx.get('configForms')     // ✅ 不存在返回 undefined，不抛
ctx.configForms            // ❌ 没写进 inject 会抛
```

**不要**为了"可能没有"的服务把它写进 `inject` —— 写进去＝绑死成必需，别人挂了你也起不来。

### 3.3 `apply` 绝不允许把异常抛出去

每个表面**各自**包 guard，失败只降级 + 留痕：

```js
function apply(ctx) {
  try { registerCard(ctx); }
  catch (e) {
    console.error("[<包名>] card registration failed:", e);
    // 写 localStorage（渲染进程里唯一事后能从磁盘读回来的地方）
  }
}
```

### 3.4 必须写静态守卫测试

运行时测试抓不到（mock ctx 是普通对象、没有 inject 代理）：
扫描客户端源码里所有 `ctx.<name>`（去掉注释/字符串，排除 `effect`/`inject`/`get`/`fiber`
等 Context 自带成员），断言每个都出现在导出的 `inject` 里，**并反向断言 `inject` 里没有无用项**。

---

## 4. 构建期产物守卫（必须）

`src/build-client.mjs` 里加 `assertBundleShape()`：

1. **`new Function(code)` 解析产物** —— 语法坏掉立即构建失败。
   （模板字符串**内部**注释里的反引号会提前闭合字符串 → 产物语法坏掉 →
   真机白屏 + `import failed` 且无堆栈。）
2. **正则扫 `require(...)`，只允许 seed 表 9 个模块**：

   ```js
   const ALLOWED = new Set([
     'react', 'react/jsx-runtime', 'react-dom', 'react-dom/client',
     '@deepseek-ai/cordis', '@deepseek-ai/dsh-client-store',
     '@deepseek-ai/dsh-client-ui-slots',
     '@deepseek-ai/dsh-client-ui-primitives',
     '@deepseek-ai/dsh-client-ui-dockkit',
   ]);
   ```

   > 只允许这 9 个 —— 超出即构建失败，不靠人记。

`npm test` 要**先 build 再 test**，否则测的是过期产物。

### 4.1 接线层测试必须执行真实 `lib/client.js`

**2026-10-15 实测事故（`dsh-opendesign-usage`）**：它的接线测试直接
`import('../src/client.js')`，而 `apply` 里取 react 用 `ctx.import ?? ctx.require ?? globalThis.__DSH_IMPORT__`
—— 宿主**没有**这两个成员，真机上 `apply` 抛错被吞掉后 `return`，
**输入框控件与设置页一个都没注册**；测试全绿是因为 `makeCtx()` 自己塞了：

```js
import: (name) => { if (name === 'react') return react; … }   // ← 生产里不存在
```

**这是"测试全绿、真机全废"的教科书形状：mock 把被实现搞错的外部契约补齐了。**

规矩：接线层必须用最小 `window.__ModuleLoader__` 外壳执行 `lib/client.js`，
`factory(require)` 的 `require` 提供基座模块。helper 建议叫 `test/helpers/load-client.mjs`，
支持 `loadClient({ react })`；传 `{ react: undefined }` 即可复现降级路径。

---

## 5. 整改检查清单

每个插件逐条过：

- [ ] 客户端 `require` 只出现 seed 表 9 个模块（其余一律删）
- [ ] 控件、菜单、开关、弹窗、Tooltip **全部**来自 `primitives`，无自写 SVG/自写 dropdown
- [ ] 设置注册在 **`plugins.bundle.config`**（key = 包名；第三方插件）
      或 `plugins.row.config`，**不在** `settings.section`，**也不在** `plugins.item`
      （后者是官方插件的「内置插件配置」分组）
- [ ] 插槽注册用了**自有 id**（不与官方或其他插件重复）
- [ ] 每个 `ctx.<service>` 都在导出的 `inject` 里；`inject` 无多余项
- [ ] 提供这些服务的官方包都在 `dsh.client.inject` 里
- [ ] `apply` 全包 try/catch，不向外抛
- [ ] 渲染期不抛错；`document` 操作全包 try/catch
- [ ] 文案全走 `ctx.locale`，无硬编码中文
- [ ] `build-client.mjs` 有 `assertBundleShape()`（`new Function` + require 白名单）
- [ ] 接线测试执行真实 `lib/client.js`，不 mock 宿主契约
- [ ] 客户端代码不 import 任何 Host 包
- [ ] `npm test` 先 build 再 test

---

## 6. 待整改插件（本机）

| 插件 | 位置 | 备注 |
|---|---|---|
| `dsh-opendesign-usage` | `~/Projects/dsh-opendesign-usage` | ⚠️ **用户尚未确认复核通过，禁止推送**（见 workspace AGENTS.md） |
| `dsh-enhanced-prompt-editor` | `~/Projects/dsh-enhanced-prompt-editor` | 参考模板（`boot-diagnostics.js`、`css.js` 是正确形状） |
| `dsh-local-model-guard` | `~/Projects/dsh-local-model-guard` | 纯 Host 插件，可能无需改 |
| `dsh-zen-free-bridge` | `~/Projects/dsh-zen-free-bridge` | 已挂 profile |
| `dsh-dsml-repair` | `~/Projects/dsh-dsml-repair` | 纯 Host 插件？需确认 |
| `dsh-cetus` | profile 依赖 | 第三方，仅作参考 |
| `dsh-connect-workbuddy` | profile 依赖 | **参考实现**（设置卡片 + locale + try/catch 范式） |

> ⚠️ 整改 `dsh-opendesign-usage` 前先读
> `~/Projects/dsh-opendesign-usage/HANDOFF-inject-and-react-20261015.md`。

---

## 7. 参考实现（直接抄这几个）

| 想抄什么 | 看哪里 |
|---|---|
| 插件详情页设置卡片 | 内核 `dsh-client-ui-settings-subagent/lib/client.js` |
| 组合包级配置卡片 | `dsh-connect-workbuddy/lib/client.js` |
| 启动降级 + localStorage 留痕 | `~/Projects/dsh-enhanced-prompt-editor/src/boot-diagnostics.js` |
| 样式注入安全形状 | `~/Projects/dsh-enhanced-prompt-editor/src/css.js` |
| 接线层真实 bundle 测试 | `~/Projects/dsh-enhanced-prompt-editor/test/bundle.test.mjs` |

读取内核里的官方实现（asar 已解包到 `/tmp/asar-x/`，重启后需重新提取）：

```sh
python3 - <<'PY'
import struct, json
p='/usr/lib/deepseek-harness-desktop/resources/app.asar'
with open(p,'rb') as f:
    vals=struct.unpack('<4I', f.read(16)); jl=vals[3]
    j=json.loads(f.read(jl).decode('utf-8'))
hs=8+vals[1]                      # ← 数据区起点，别用 16+headerSize
def walk(n,path=''):
    for name,v in n.get('files',{}).items():
        cur=path+'/'+name
        if 'files' in v: yield from walk(v,cur)
        else: yield cur,v
# 例：导出官方 subagent 配置页源码
for p_,v in walk(j):
    if p_.endswith('dsh-client-ui-settings-subagent/lib/client.js'):
        open('/tmp/ref.js','wb').write(open(p,'rb').read()[hs+int(v['offset']):hs+int(v['offset'])+v['size']])
PY
```

---

## 8. 本规范的来源

- 内核事实：DSH 0.2.1-alpha.2，`app.asar` 内 `dsh-web-frontend`、`dsh-client-ui-primitives`、
  `dsh-client-ui-plugin-manager`、`dsh-client-ui-settings-*` 的实际源码。
- 踩坑教训：`~/.dsh/TASTE.md` 台账 E-001…E-007、`dsh-plugin-hardening` skill。
- **与本文件冲突的旧说法以本文件为准**：skill `dsh-plugin-development` §7
  「禁止 require 任何 Harness Client 包、抄 markup/CSS」已被内核实测推翻
  —— 官方配置页全部 require `primitives`，它是 seed 表里的冻结基座模块。
  真正的红线是 **§4 的 9 模块白名单**。
