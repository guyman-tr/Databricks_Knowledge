# Trade.GetExchangeIDsByTime

> Returns the set of exchange IDs that should be processed at a given scheduled time, with special handling for the Australian exchange which operates on a different local time trigger.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns TABLE with ExchangeID (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetExchangeIDsByTime determines which stock exchanges should be processed at a given scheduled time. It is used by batch jobs (e.g., overnight fee calculation, end-of-day snapshots) that run on a schedule and need to know which exchanges' markets have closed and are ready for processing.

The Australian exchange (ExchangeID=31, Sydney) is treated specially: it closes at a different time than global exchanges and uses Australian Eastern Standard Time for its trigger condition. All other exchanges share a single global UTC trigger hour. This separation prevents the Australian exchange from being processed at the wrong time.

---

## 2. Business Logic

### 2.1 Exchange Selection by Time

**What**: Two-branch logic separates Australian exchange from all others.

**Columns/Parameters Involved**: `@GlobalStartTimeUTC`, `@AustraliaStartTimeLocal`

**Rules**:
- Hardcoded: `@australiaExchangeID = 31` (Sydney exchange)
- **Australian branch**: If current Australian local hour (via `Trade.ConvertUtcToLocal` with 'AUS Eastern Standard Time') equals `@AustraliaStartTimeLocal`, return only ExchangeID 31
- **Global branch**: If current UTC hour equals `@GlobalStartTimeUTC`, return all exchanges from `Dictionary.ExchangeInfo` EXCEPT ExchangeID 31
- If neither condition matches, returns empty result set (no exchanges to process)

### 2.2 Hardcoded Values

| Value | Meaning | Context |
|-------|---------|---------|
| 31 | Sydney (Australian) exchange | ExchangeID in Dictionary.ExchangeInfo |
| 'AUS Eastern Standard Time' | Windows timezone identifier | Passed to Trade.ConvertUtcToLocal |

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GlobalStartTimeUTC | INT | NO | - | CODE-BACKED | UTC hour (0-23) when global (non-Australian) exchanges should be processed. |
| 2 | @AustraliaStartTimeLocal | INT | NO | - | CODE-BACKED | Australian local hour (0-23) when the Sydney exchange should be processed. Typically post-market-close + grace period. |
| 3 | ExchangeID (return) | INT | NO | - | CODE-BACKED | Exchange identifier to process. Matches Dictionary.ExchangeInfo.ExchangeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Current time conversion | Trade.ConvertUtcToLocal | Function call | Converts GETUTCDATE() to Australian local time |
| ExchangeID | Dictionary.ExchangeInfo | SELECT | Reads all non-Australian exchange IDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Batch processing jobs | Parameter | Function call | Scheduled jobs call to determine which exchanges to process |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExchangeIDsByTime (function)
  ├── Trade.ConvertUtcToLocal (function)
  │     └── sys.time_zone_info (system)
  └── Dictionary.ExchangeInfo (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ConvertUtcToLocal | Function | Converts current UTC time to Australian local time |
| Dictionary.ExchangeInfo | Table | Reads all exchange IDs for global processing |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Batch scheduling procedures | Procedures | Call to determine which exchanges are ready for processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS @tblResult TABLE | Return type | Multi-statement TVF with ExchangeID INT NOT NULL |
| Hardcoded ExchangeID=31 | Business rule | Australian exchange is always treated separately |

---

## 8. Sample Queries

### 8.1 Get exchanges to process at UTC 22:00 / Australia 17:00

```sql
SELECT  ExchangeID
FROM    Trade.GetExchangeIDsByTime(22, 17);
```

### 8.2 Check if any exchanges are ready now

```sql
DECLARE @utcHour INT = DATEPART(HOUR, GETUTCDATE());
SELECT  ExchangeID
FROM    Trade.GetExchangeIDsByTime(@utcHour, @utcHour);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExchangeIDsByTime | Type: Multi-Statement Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.GetExchangeIDsByTime.sql*
