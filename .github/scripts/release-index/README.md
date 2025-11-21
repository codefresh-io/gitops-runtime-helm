## Channel Classification Flow

flowchart TD
    Start([Version Input]) --> Check{Matches<br/>YY.MM-patch?}
    
    Check -->|"Yes (25.04-1)"| Month{Month<br/>1-12?}
    Check -->|"No (1.2.3)"| Stable[Stable Channel]
    
    Month -->|Yes| Latest["Latest Channel<br/>(normalize: 25.4.1)"]
    Month -->|"No (25.13-1)"| Stable
    
    Latest --> ValidL{Valid<br/>semver?}
    Stable --> ValidS{"Valid semver<br/>>= 1.0.0?"}
    
    ValidL -->|Yes| AcceptL["✅ Accept as Latest"]
    ValidL -->|No| Reject["❌ Skip"]
    
    ValidS -->|Yes| AcceptS["✅ Accept as Stable"]
    ValidS -->|No| Reject
    
    style AcceptL fill:#90EE90,stroke:#2d5016
    style AcceptS fill:#87CEEB,stroke:#003d5c
    style Reject fill:#ffcccb,stroke:#8b0000
    style Latest fill:#e1f5ff,stroke:#0066cc
    style Stable fill:#f0fff0,stroke:#006400### Examples

| Input Version | Matches Pattern? | Month Valid? | Channel | Normalized | Valid? | Result |
|--------------|------------------|--------------|---------|------------|--------|--------|
| `25.04-1` | ✅ Yes | ✅ Yes (4) | Latest | `25.4.1` | ✅ Yes | ✅ **Accept Latest** |
| `25.13-1` | ✅ Yes | ❌ No (13) | Stable | `25.13-1` | ❌ No | ❌ **Skip** |
| `1.2.3` | ❌ No | - | Stable | `1.2.3` | ✅ Yes | ✅ **Accept Stable** |
| `0.9.0` | ❌ No | - | Stable | `0.9.0` | ❌ No (< 1.0.0) | ❌ **Skip** |
| `24.12-10` | ✅ Yes | ✅ Yes (12) | Latest | `24.12.10` | ✅ Yes | ✅ **Accept Latest** |