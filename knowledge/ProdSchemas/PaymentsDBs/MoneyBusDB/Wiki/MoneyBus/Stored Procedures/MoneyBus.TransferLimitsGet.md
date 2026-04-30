# MoneyBus.TransferLimitsGet

> Retrieves all transfer limit configuration rows for application-side caching, returning the full set of min/max amount rules by account type pair, currency, and optional filters.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full result set from TransferLimits |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransferLimitsGet retrieves all rows from the TransferLimits configuration table with no filtering parameters. The application calls this procedure at startup or on a cache refresh cycle to load the entire set of transfer limit rules into memory, then evaluates the appropriate rule in code based on the transaction context (debit/credit account types, currency, flow, country, player level).

This parameterless design indicates a "load all, filter in app" pattern - appropriate because TransferLimits is a small configuration table (currently 8 rows) where the full dataset easily fits in application memory.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a full table read.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It returns all columns from MoneyBus.TransferLimits: CountryID, DebitAccountTypeID, CreditAccountTypeID, MinAmount, MaxAmount, CurrencyID, PlayerLevelID, FlowID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.TransferLimits | Reader | Reads all configuration rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransferLimitsGet (procedure)
└── MoneyBus.TransferLimits (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransferLimits | Table | SELECT FROM - reads all limit configuration rows |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all transfer limits
```sql
EXEC MoneyBus.TransferLimitsGet;
```

### 8.2 Application-side filter example (post-retrieval)
```sql
-- After loading all limits via TransferLimitsGet, app filters like:
-- SELECT * FROM @CachedLimits
-- WHERE DebitAccountTypeID = 1 AND CreditAccountTypeID = 3
--   AND CurrencyID = 1 AND (FlowID IS NULL OR FlowID = @FlowID)
```

### 8.3 Verify limits count
```sql
SELECT COUNT(*) AS TotalRules FROM MoneyBus.TransferLimits WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransferLimitsGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransferLimitsGet.sql*
