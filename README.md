# dsh-plugin-standards

> DSH 插件开发的**规范与硬约束**合集：UI 组件怎么用、面向 agent 的仓库怎么写、
> 发布前要走哪六步。每条结论都来自本机实测，不是通用道理。

这套文档服务于 `~/Projects/dsh-*` 下的插件仓库。**动手改插件前先读对应那份**，
发布前把 `RELEASE-STANDARDS.md` 的 checklist 逐项过一遍。

## 文档

| 文档 | 管什么 | 何时读 |
|---|---|---|
| [UI-STANDARDS.md](./docs/UI-STANDARDS.md) | 界面必须用 DSH 原生组件；设置页注册在哪；哪些写法会白屏 | 写界面 / 加设置项时 |
| [AGENT-FACING-STANDARDS.md](./docs/AGENT-FACING-STANDARDS.md) | 仓库必须有 `AGENTS.md` + `llms.txt`，README 要指路；各自写什么 | 新建仓库、补文档时 |
| [RELEASE-STANDARDS.md](./docs/RELEASE-STANDARDS.md) | **发布前六步**：文档齐套 → 全面脱敏 → 测试可复现 → 打包核对 → 推前硬闸 → 授权发布 | **发布前逐项执行** |

## 一句话规则（速查）

1. UI 一律用 `@deepseek-ai/dsh-client-ui-primitives`，别自己写组件。
2. 插件设置注册到 `plugins.bundle.config`（key = 包名），不要 `settings.section` / `plugins.item`。
3. 每个公开仓库必须有 `AGENTS.md` + `llms.txt`，README 正文前 1/3 处指路。
4. 发布前脱敏扫**五条**（路径 / 内网 IP / 私人邮箱 / 凭据 / **git 历史**），全部 0 命中。
5. `npm test` 必须一条命令跑完；关键守卫要**变异验证**。
6. `push` / 建仓库 / 发 npm 都要**用户明确授权**。

## 使用方式

本目录通常被工作区软链引用（例如 `~/Projects/dsh-plugin/docs/` → 这里的 `docs/`），
所以在插件仓库里可以直接引用：

```markdown
规范：`docs/RELEASE-STANDARDS.md`（工作区软链）
```

## 许可

MIT
