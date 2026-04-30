# Dictionary.ManualOperationReason

> Classifies the reasons why BackOffice operations staff manually intervene in trading positions, used for audit trails and reporting on non-automated position changes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.ManualOperationReason enumerates the valid reasons for manual position operations — when a human operator (typically BackOffice dealing desk staff) needs to close, adjust, or rebalance trading positions outside of normal automated flows. Each reason documents the business justification for the manual intervention.

Without this table, the system could not track WHY manual operations occurred, making it impossible to audit dealing desk activity, detect operational patterns, or report on the root causes of manual position adjustments. Regulators and compliance teams rely on these reason codes for trade reporting.

Referenced by account statement procedures (dbo.AccountStatement_GetTransactionsReport_v10, v9, v7_1), tax reporting (BackOffice.AccountStatement_GetTaxReport_v2, v3), and the manual position operations themselves (Trade.ManualRenlance [sic], History.InsertManualOperationPositionClose_Crisis).

---

## 2. Business Logic

### 2.1 Operational Categories

**What**: Twelve reason codes covering the spectrum of manual trading interventions.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Reasons 0-2 (Other, Rebalancing, Technical Reason) cover routine operational scenarios
- Reasons 3-4 (Human Error, Bad Pricing from LP) cover error correction
- Reason 5 (Corporate Actions) covers stock splits, dividends, mergers
- Reasons 6-8 (Transfer Out, Position correction, Bad ticker Mapping) cover data integrity fixes
- Reasons 9-11 (Cancelation, Waive off, Worthless asset) cover position removal scenarios
- Each manual close/adjust operation requires selecting exactly one reason

**Diagram**:
```
Manual Operation Categories:
  Routine ──────> Other (0), Rebalancing (1), Technical Reason (2)
  Error Fix ────> Human Error (3), Bad Pricing from LP (4), Bad ticker Mapping (8)
  Corporate ───-> Corporate Actions (5)
  Data Fix ────-> Transfer Out (6), Position correction (7)
  Removal ─────-> Cancelation (9), Waive off (10), Worthless asset (11)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Other | Catch-all for manual operations that don't fit standard categories — requires free-text explanation in the operation notes |
| 1 | Rebalancing | Portfolio rebalancing — manually adjusting position sizes to match target allocations, common for CopyFund/SmartPortfolio operations |
| 4 | Bad Pricing from LP | Liquidity provider delivered incorrect pricing that caused a position to open/close at wrong rate — position must be corrected to fair value |
| 5 | Corporate Actions | Stock split, reverse split, merger, or acquisition requires manual position adjustment (when automated corporate action handler cannot process) |
| 11 | Worthless asset | Instrument has been delisted or is valued at zero — positions must be closed with no value for accounting purposes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the manual operation reason: 0=Other, 1=Rebalancing, 2=Technical Reason, 3=Human Error, 4=Bad Pricing from LP, 5=Corporate Actions, 6=Transfer Out, 7=Position correction, 8=Bad ticker Mapping, 9=Cancelation, 10=Waive off, 11=Worthless asset. Referenced by account statement and tax reporting procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable reason label displayed in BackOffice manual operation forms and account statement reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AccountStatement_GetTransactionsReport_v10 | ManualOperationReasonID | Implicit | Transaction reporting joins to show manual operation reason names |
| BackOffice.AccountStatement_GetTaxReport_v2 | ManualOperationReasonID | Implicit | Tax reporting includes manual operation reasons |
| Trade.ManualRenlance | ManualOperationReasonID | Implicit | Manual rebalancing procedure records the reason |
| History.InsertManualOperationPositionClose_Crisis | ManualOperationReasonID | Implicit | Crisis manual close records reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetTransactionsReport_v10 | Stored Procedure | JOINs to resolve reason name |
| dbo.AccountStatement_GetTransactionsReport_v9 | Stored Procedure | JOINs to resolve reason name |
| BackOffice.AccountStatement_GetTaxReport_v2 | Stored Procedure | Tax reporting |
| BackOffice.AccountStatement_GetTaxReport_v3 | Stored Procedure | Tax reporting |
| Trade.ManualRenlance | Stored Procedure | Records reason for manual rebalance |
| History.InsertManualOperationPositionClose_Crisis | Stored Procedure | Records reason for crisis closes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManualOperationReason | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all manual operation reasons
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[ManualOperationReason] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find the reason name for a specific ID
```sql
SELECT  Name
FROM    [Dictionary].[ManualOperationReason] WITH (NOLOCK)
WHERE   ID = 4;
```

### 8.3 Join with position close history to see manual operation breakdown
```sql
SELECT  mor.Name AS ManualReason,
        COUNT(*) AS OperationCount
FROM    [History].[Position_Active] hp WITH (NOLOCK)
JOIN    [Dictionary].[ManualOperationReason] mor WITH (NOLOCK)
        ON hp.ManualOperationReasonID = mor.ID
WHERE   hp.ManualOperationReasonID IS NOT NULL
GROUP BY mor.Name
ORDER BY OperationCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ManualOperationReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ManualOperationReason.sql*
