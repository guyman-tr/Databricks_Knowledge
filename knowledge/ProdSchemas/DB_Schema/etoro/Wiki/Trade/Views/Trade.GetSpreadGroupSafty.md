# Trade.GetSpreadGroupSafty

> Schema-bound safety wrapper over Trade.GetSpreadGroup providing stable access to spread group configuration - SpreadGroupID, Name, SpreadID, ProviderID, InstrumentID, Bid, and Ask.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | SpreadGroupID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetSpreadGroupSafty is a **SCHEMABINDING safety wrapper** over the Trade.GetSpreadGroup view. The "Safty" (safety) naming convention indicates this view is used by critical system components that require schema stability - the SCHEMABINDING option prevents any underlying table changes that would break this view's contract.

This view provides spread group configuration data: which spread applies to which provider-instrument combination, and the current bid/ask spread values. It is used by real-time trading operations that need guaranteed access to spread data without risk of schema drift.

The view passes through all columns from Trade.GetSpreadGroup without transformation: SpreadGroupID, Name, SpreadID, ProviderID, InstrumentID, Bid, Ask.

---

## 2. Business Logic

No complex business logic. This is a direct pass-through with SCHEMABINDING for schema stability.

---

## 3. Data Overview

N/A - output is identical to Trade.GetSpreadGroup. See [Trade.GetSpreadGroup](Trade.GetSpreadGroup.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadGroupID | int | NO | - | CODE-BACKED | FK to Trade.SpreadGroup. Identifies the spread group configuration. |
| 2 | Name | nvarchar | YES | - | CODE-BACKED | Spread group name for display/identification. From Trade.SpreadGroup. |
| 3 | SpreadID | int | YES | - | CODE-BACKED | FK to Trade.Spread. The specific spread definition applied. |
| 4 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider. Which execution provider this spread applies to. |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Which instrument this spread applies to. |
| 6 | Bid | float | YES | - | CODE-BACKED | Bid spread markup. Applied to the instrument's bid price. |
| 7 | Ask | float | YES | - | CODE-BACKED | Ask spread markup. Applied to the instrument's ask price. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | Trade.GetSpreadGroup | View | Direct pass-through with SCHEMABINDING. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetSpreadGroupSafty (view)
+-- Trade.GetSpreadGroup (view)
      +-- Trade.SpreadGroup (table)
      +-- Trade.SpreadToGroup (table)
      +-- Trade.Spread (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetSpreadGroup | View | SCHEMABINDING pass-through of all columns |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | View Option | Prevents underlying table/view DDL changes that would break this view |

---

## 8. Sample Queries

### 8.1 Get spread configuration for an instrument

```sql
SELECT SpreadGroupID, Name, Bid, Ask
FROM Trade.GetSpreadGroupSafty WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID AND ProviderID = @ProviderID
```

### 8.2 All spread groups with their bid/ask values

```sql
SELECT SpreadGroupID, Name, InstrumentID, Bid, Ask
FROM Trade.GetSpreadGroupSafty WITH (NOLOCK)
ORDER BY InstrumentID, SpreadGroupID
```

### 8.3 Instruments with wide spreads

```sql
SELECT InstrumentID, SpreadGroupID, Bid, Ask, (Ask - Bid) AS SpreadWidth
FROM Trade.GetSpreadGroupSafty WITH (NOLOCK)
WHERE (Ask - Bid) > @Threshold
ORDER BY (Ask - Bid) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetSpreadGroupSafty | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetSpreadGroupSafty.sql*
