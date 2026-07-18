# Refactor Candidates

After a TDD cycle, look for:

- **Duplication** -> extract a function/class
- **Long methods** -> break into private helpers (keep tests on the public interface)
- **Shallow modules** -> combine or deepen
- **Feature envy** -> move logic to where the data lives
- **Primitive obsession** -> introduce value objects
- **Existing code** the new code reveals as problematic
