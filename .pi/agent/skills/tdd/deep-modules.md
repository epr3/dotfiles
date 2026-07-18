# Deep Modules

From *A Philosophy of Software Design*:

**Deep module** = small interface + lots of implementation

```
┌─────────────────────┐
│   Small interface   │  <- few methods, simple params
├─────────────────────┤
│                     │
│                     │
│ Deep implementation │  <- complex logic hidden
│                     │
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid)

```
┌─────────────────────────────────┐
│        Large interface          │  <- many methods, complex params
├─────────────────────────────────┤
│  Thin implementation            │  <- just passes through
└─────────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?
