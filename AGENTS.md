# AGENTS.md

本文件给 **AI 编码 agent** 看。人类请看 [README.md](./README.md)。

本仓库是**纯文档仓库**（没有任何可执行代码），所以验证方式是"结构自检"，不是 `npm test`。

## 1. 验证（改完必须跑）

```sh
# 结构与交叉引用自检：三份文档都在、都没违反自己的规则
sh check.sh
```

⚠️ 本仓库**没有 package.json / 构建产物**：不要在这里跑 `npm install` / `npm test`。

## 2. 产物

无构建产物。**`docs/*.md` 就是最终交付物**，直接提交。

## 3. 硬性约束（违反会让规范失去效力）

1. **每条结论必须有实测依据**。写"建议…"之前先问：这条对应哪次真实故障？
   写不出来就不要写 —— 通用工程道理对 agent 没有增量价值，反而挤占上下文。
2. **规则要可执行**。能在测试/脚本里断言的，必须落成断言（参考各插件仓库的
   `test/agent-facing.test.mjs`）；只写在文档里的规则**等于没有**。
3. **示例不得写完整敏感字面量**：本机路径写 `/home/<用户>/`、内网 IP 写 `192.168.` 前缀。
   否则规范自己的脱敏扫描会误报（实测踩过，见 `RELEASE-STANDARDS.md` §6.4）。
4. **三份文档互不重复**：UI 管界面、AGENT-FACING 管文档、RELEASE 管发布流程。
   新增内容先判断属于哪份，别三处各抄一遍。

## 4. 禁区

- 不要把**本机私有信息**写进来（私人邮箱、内网 IP、本机绝对路径、凭据）。
- 不要把某一次事故的**临时绕过方案**写成规范（写"为什么错"和"正确做法"）。
- 不要给某单个插件写专属规则 —— 放回那个插件的 `AGENTS.md`。

## 5. 提交规范

```sh
git -c user.name="blancatora" -c user.email="blancatora@agent.qq.com" commit \
  -m "docs: 摘要" \
  -m "Generated-by: blancatora (DeepSeek Harness / deepseek-v4.1-flash)" \
  -m "AI-Disclosure: 本提交由 AI 编码代理生成；可能含未经人工复核的改动。"
```

**push 前必须得到用户明确授权。**

## 6. 本仓库特有的坑

### 6.1 它通常是软链目标，改这里会影响所有插件仓库

工作区把 `docs/` 软链到本仓库的 `docs/`。改文件名/删文档会**直接打断**别的仓库里
`docs/XXX-STANDARDS.md` 的引用。改名前先全盘搜引用：

```sh
grep -rn 'STANDARDS.md' ~/Projects/*/AGENTS.md ~/Projects/*/README*.md 2>/dev/null
```

### 6.2 规范里写"测试数量""文件数量"这类数字一定会过期

实测：某插件 README 写"87 项测试"，两天后已是 187 项。规范里**不写会被后续变更
改变的数字**，只写判断标准与命令。
