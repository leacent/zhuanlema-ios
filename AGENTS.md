# Global Agent Rules

## AI 生成 Markdown 标识（强制）

- 适用范围：所有由 AI（包含 Cursor、Codex 及其子代理）新建或改写的 Markdown 文件（`*.md`、`*.mdx`、`*.mdc`）。
- 强制要求：文件开头第一行必须写入 AI 生成标识：`> AI GENERATED: 该文档由 AI 生成或修改。`
- 保持位置：该标识必须位于文档最前面，不得放在标题或其他内容之后。
- 例外：仅当用户明确要求不要添加该标识时，才允许跳过。

## 示例

```markdown
> AI GENERATED: 该文档由 AI 生成或修改。

# 文档标题
```
