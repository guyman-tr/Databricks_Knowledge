# Dictionary.Duration

## 1. Business Meaning

### What It Is
A lookup table defining time duration configurations for legacy forex/game trading sessions. Each entry pairs a time interval (in minutes) with a fixed/variable duration flag.

### Why It Exists
In the legacy "game-style" trading mode, users could open positions with predefined time durations (e.g., 1-minute, 5-minute, 50-minute trades). This table defined the available duration options and whether the duration was fixed (exact expiry time) or floating.

### How It's Used
Referenced by legacy game/session views (`Customer.GetSessionWithTrade`, `Customer.GetGameWithTrade`, `Game.GetForexResult`, `OldStyle.GetForexGame`) that join on `DurationID`. Part of the early eToro "social forex game" model that has since been replaced by standard CFD trading.

---

## 2. Business Logic

### Naming Convention
Each Name follows the pattern `{Interval}{F|T}`:
- The numeric prefix is the interval in minutes (00, 01, 02, 03, 04, 05, 10, 50)
- **F** suffix = variable/floating duration (IsFixDuration = false)
- **T** suffix = fixed/true duration (IsFixDuration = true)

### Duration Pairs
Every interval (except 0) has both a fixed and variable variant:

```
Interval 0: 00F (variable only), 00T (variable — special: both are IsFixDuration=false)
Interval 1: 01F (variable), 01T (fixed)
Interval 2: 02F (variable), 02T (fixed)
Interval 3: 03F (variable), 03T (fixed)
Interval 4: 04F (variable), 04T (fixed)
Interval 5: 05F (variable), 05T (fixed)
Interval 10: 10F (variable), 10T (fixed)
Interval 50: 50F (variable), 50T (fixed)
```

> **Note**: Interval 0 with both F and T variants having `IsFixDuration=false` suggests the 0-minute interval is a special "no duration" / instant-close mode.

---

## 3. Data Overview

| DurationID | Name | Interval | IsFixDuration |
|-----------|------|----------|---------------|
| 0 | 00F | 0 | false |
| 1 | 00T | 0 | false |
| 2 | 01F | 1 | false |
| 3 | 01T | 1 | true |
| 4 | 02F | 2 | false |
| 5 | 02T | 2 | true |
| 6 | 03F | 3 | false |
| 7 | 03T | 3 | true |
| 8 | 04F | 4 | false |
| 9 | 04T | 4 | true |
| 10 | 05F | 5 | false |
| 11 | 05T | 5 | true |
| 12 | 10F | 10 | false |
| 13 | 10T | 10 | true |
| 14 | 50F | 50 | false |
| 15 | 50T | 50 | true |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DurationID** | `int` | NO | Primary key. Sequential 0-15 identifier. | `MCP` |
| **Name** | `char(50)` | NO | Duration code in `{Interval}{F\|T}` format. Padded with spaces (char, not varchar). Unique index. | `MCP` |
| **Interval** | `int` | NO | Time interval in minutes (0, 1, 2, 3, 4, 5, 10, 50). | `MCP` |
| **IsFixDuration** | `bit` | NO | Whether the duration is fixed (true=exact expiry, false=variable/floating). | `MCP` |

---

## 5. Relationships

### Referenced By
| Table/View | Relationship |
|-----------|-------------|
| Customer.GetSessionWithTrade | Legacy view — joins on DurationID for session duration display |
| Customer.GetGameWithTrade | Legacy view — joins on DurationID for game duration display |
| Game.GetForexResult | Legacy view — joins on DurationID for forex result display |
| OldStyle.GetForexGame | Legacy view — joins on DurationID for old-style game display |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- Legacy game/session views in Customer, Game, and OldStyle schemas

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `DurationID` (clustered, PK_DDUR) |
| **Indexes** | `DDUR_NAME` — unique on Name |
| **Filegroup** | DICTIONARY |
| **Row Count** | 16 |
| **Identity** | No |
| **Temporal** | No |

> **Note**: Name column uses `char(50)` (fixed-width, space-padded) rather than `varchar(50)` — legacy design choice.

---

## 8. Sample Queries

```sql
-- Get all duration options
SELECT  DurationID,
        RTRIM(Name)         AS Name,
        Interval,
        IsFixDuration
FROM    Dictionary.Duration WITH (NOLOCK)
ORDER BY Interval, IsFixDuration;

-- Get only fixed-duration options
SELECT  DurationID,
        RTRIM(Name)         AS Name,
        Interval
FROM    Dictionary.Duration WITH (NOLOCK)
WHERE   IsFixDuration = 1
ORDER BY Interval;

-- Get distinct intervals available
SELECT  DISTINCT Interval
FROM    Dictionary.Duration WITH (NOLOCK)
ORDER BY Interval;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table. Legacy game/trading feature — pre-dates current documentation practices.

---

*Generated: 2026-03-14 | Quality Score: 9.0 | Phases: DDL ✓ MCP ✓ Codebase ✓*
