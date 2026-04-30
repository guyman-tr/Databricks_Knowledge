# Trade.DividendsSetPaymentIsComplete_DryRun

> Marks dividend records as payment-complete (Status=2) in the sandbox Trade.IndexDividends_DryRun table, mirroring the production procedure for testing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the **dry-run (sandbox) equivalent** of `Trade.DividendsSetPaymentIsComplete`. It performs the identical Status=1→2 transition but against `Trade.IndexDividends_DryRun` instead of the production `Trade.IndexDividends` table. This allows the dividend service to test or preview payment completion logic without affecting production dividend state.

The _DryRun table mirrors the structure of Trade.IndexDividends and is populated during dividend dry-run cycles to validate the full pipeline before committing to production.

---

## 2. Business Logic

### 2.1 Payment Completion Update (Dry Run)

**What**: Transitions dry-run dividend records to payment-complete status.

**Columns/Parameters Involved**: `Trade.IndexDividends_DryRun.Status`, `Trade.IndexDividends_DryRun.DividendID`

**Rules**:
- UPDATE Trade.IndexDividends_DryRun SET Status = 2
- JOIN @DividendIDs TVP on DividendID = Id
- WHERE Status = 1 (same guard as production version)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendIDs | Trade.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of DividendID values to mark as payment-complete in the dry-run table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendIDs | Trade.IndexDividends_DryRun | Write | Updates Status from 1 → 2 |
| @DividendIDs | Trade.IdIntList | UDT (TVP) | Integer list table type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Dividends service) | N/A | Application caller | Called during dividend dry-run cycles |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendsSetPaymentIsComplete_DryRun (procedure)
+-- Trade.IndexDividends_DryRun (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends_DryRun | Table | Sandbox dividend state tracking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Identical logic to `Trade.DividendsSetPaymentIsComplete` but targeting the _DryRun table. See also `Trade.DividendsSetSnapshotIsReady_DryRun` for the snapshot equivalent.

---

## 8. Sample Queries

### 8.1 Check dry-run dividend status

```sql
SELECT  DividendID, Status
FROM    Trade.IndexDividends_DryRun WITH (NOLOCK)
WHERE   Status IN (1, 2)
ORDER BY DividendID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendsSetPaymentIsComplete_DryRun | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DividendsSetPaymentIsComplete_DryRun.sql*
