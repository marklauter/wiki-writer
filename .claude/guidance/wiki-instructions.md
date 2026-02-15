# Wiki instructions

- Location: `DynamoDbLite.wiki/`
- Audience: .NET developers experienced with DynamoDB, wanting container-free, in-proc drop-in replacement for testing and mobile.
- Tone: reference-style, not tutorial — assume DynamoDB familiarity.
- Scope: usage and behavior first, internals second. Core pages cover public API — method behavior, request/response shapes, expressions, configuration. Advanced pages cover architecture for contributors — SQLite schema, expression engine, concurrency.
- Link to [AWS DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/) when introducing DynamoDB concepts.
- Read relevant source code before writing — don't document from memory.
- Check `DynamoDbLite.wiki/_Sidebar.md` for page naming and navigation.
- Wiki contradicts source code? Fix directly.
