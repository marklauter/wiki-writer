name: Documentation
description: Report a documentation issue — inaccuracy, clarity problem, or style violation
labels: documentation

## Fields

### Page
- required: true
- description: Wiki page filename.
- example: Query-and-Scan.md

### Editorial lens
- required: true
- description: Which editorial lens found this issue?
- options:
  - Structure — organization, flow, gaps, redundancies
  - Line — sentence-level clarity and tightening
  - Copy — grammar, formatting, terminology consistency
  - Accuracy — claims that contradict source code

### Severity
- required: true
- options:
  - must-fix — readers will be confused or misled
  - suggestion — works but could be better

### Finding
- required: true
- description: What's wrong. Quote the problematic text.

### Recommendation
- required: true
- description: What to do about it. Include corrected text for line/copy edits. Cite source file and line for accuracy issues.

### Source file
- required: false
- description: Source file that contradicts the doc (accuracy issues only).
- example: src/DynamoDbLite/DynamoDbClient.Query.cs:45

### Notes
- required: false
- description: Optional context — related pages, cross-reference issues, etc.
