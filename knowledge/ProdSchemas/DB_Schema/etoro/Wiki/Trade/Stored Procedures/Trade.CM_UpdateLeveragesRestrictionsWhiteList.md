# Trade.CM_UpdateLeveragesRestrictionsWhiteList

> Content Management procedure that batch-updates existing per-customer leverage restriction overrides using a table-valued parameter, modifying max/min/default leverage values and comments for existing GCID+InstrumentID combinations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 on success |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CM_UpdateLeveragesRestrictionsWhiteList is a Content Management (CM) procedure that updates existing per-customer leverage restriction overrides in bulk. While its companion procedure (CM_InsertLeveragesRestrictionsWhiteList) creates new overrides, this procedure modifies values for combinations that already exist in the whitelist.

This procedure is essential for maintaining leverage compliance as regulations change. When ESMA adjusts leverage caps, when a customer's regulatory classification changes (e.g., retail to professional), or when risk management needs to tighten limits for specific accounts, this procedure updates the existing overrides in a single transactional batch.

The procedure accepts a table-valued parameter containing multiple GCID+InstrumentID combinations with new leverage values, updates all matching rows in Trade.LeveragesRestrictionsWhiteList within a single transaction, and sets LastUpdateDate to the current UTC time.

---

## 2. Business Logic

### 2.1 Batch Update with Transaction Safety

**What**: All leverage updates are applied atomically within a single transaction.

**Columns/Parameters Involved**: `@UpdateLeveragesRestrictionsWhiteListTable`, Trade.LeveragesRestrictionsWhiteList

**Rules**:
- All updates succeed or all roll back - no partial application
- Matches on composite key: GCID + InstrumentID
- Updates four fields: MinLeverage, MaxLeverage, DefaultLeverage, Comments
- Sets LastUpdateDate = GETUTCDATE() automatically
- Non-matching rows in the TVP are silently ignored (no error for missing combinations)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UpdateLeveragesRestrictionsWhiteListTable | Trade.CM_UpdateLeveragesRestrictionsWhiteListTable (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing rows with GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, and Comments. Each row updates the matching whitelist entry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Trade.LeveragesRestrictionsWhiteList | Writer | Updates MinLeverage, MaxLeverage, DefaultLeverage, Comments, and LastUpdateDate for existing GCID+InstrumentID combinations |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called from Content Management UI or back-office tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CM_UpdateLeveragesRestrictionsWhiteList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | UPDATE target for leverage override records |
| Trade.CM_UpdateLeveragesRestrictionsWhiteListTable | User Defined Type | TVP type for the input parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CM_InsertLeveragesRestrictionsWhiteList | Stored Procedure | Companion procedure for creating new whitelist entries |
| Trade.CM_DeleteLeveragesRestrictionsWhiteList | Stored Procedure | Companion procedure for deleting whitelist entries |
| Trade.CM_GetLeveragesRestrictionsWhiteList | Stored Procedure | Companion procedure for reading whitelist entries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check current whitelist values before update
```sql
SELECT GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, Comments, LastUpdateDate
FROM   Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE  GCID = 12345
```

### 8.2 Verify update was applied
```sql
SELECT GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, LastUpdateDate
FROM   Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE  LastUpdateDate >= DATEADD(MINUTE, -5, GETUTCDATE())
ORDER BY LastUpdateDate DESC
```

### 8.3 Check all whitelist entries for an instrument
```sql
SELECT GCID, MinLeverage, MaxLeverage, DefaultLeverage, Comments
FROM   Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE  InstrumentID = 1001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this procedure. See companion procedure Trade.CM_InsertLeveragesRestrictionsWhiteList for related regulatory context.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CM_UpdateLeveragesRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CM_UpdateLeveragesRestrictionsWhiteList.sql*
