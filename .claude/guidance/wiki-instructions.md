# Wiki instructions

- Location: the `wikiDir` path from `wiki-writer.config.json`.
- Audience and tone: read `audience` and `tone` from `wiki-writer.config.json`. These are set during `/wiki-setup`.
- Scope: usage and behavior first, internals second. Core pages cover public API. Advanced pages cover architecture for contributors.
- The target project's `CLAUDE.md` may provide additional context on audience, tone, and scope.
- Link to [AWS DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/) when introducing DynamoDB concepts.
- Read relevant source code before writing — don't document from memory.
- Check `{wikiDir}/_Sidebar.md` for page naming and navigation.
- Wiki contradicts source code? Fix directly.
