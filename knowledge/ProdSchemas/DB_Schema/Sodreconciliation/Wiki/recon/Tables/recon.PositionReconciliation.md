# recon.PositionReconciliation

> Stores position-level reconciliation results comparing Apex Clearing's daily position snapshot (EXT871) against eToro's internal position data, highlighting discrepancies in quantities and values.

| Property | Value |
|----------|-------|
| **Schema** | recon |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 1 unique filtered NC + 1 NC on SodFileId) |

---

## 1. Business Meaning

This is one of the two core output tables of the SOD reconciliation system. After the SOD Azure Function imports an EXT871 (Position Activity) file from Apex Clearing, it triggers the reconciliation flow (Flow 2 per Confluence). The system fetches eToro's internal position data from the eToro Data API, compares it against the Apex position data, and writes all discrepancies to this table.

Each row represents a single position comparison - matching an Apex position record to an eToro position record by account number, symbol, and CUSIP. The `BreakValue` column quantifies the discrepancy. Rows with `BreakValue = 0` are matched; non-zero values indicate breaks that need investigation.

The SOD Reconciliation UI displays these results for a given date, allowing operations teams to investigate and resolve breaks. The `Hidden` flag allows users to suppress known/accepted discrepancies from the active view. If a discrepancy requires correction, the fix is sent to eToro Gateway API (not updated in this table - corrections are tracked in the `fix` schema tables).

---

## 2. Business Logic

### 2.1 Position Break Detection

**What**: Compares Apex and eToro position quantities to detect discrepancies.

**Columns/Parameters Involved**: `ApexTradeQuantity`, `EtoroTradeQuantity`, `BreakValue`

**Rules**:
- Rows are created for ALL positions found in either system, not just breaks
- For matched positions (BreakValue=0): typically only ONE side is populated. Most matched rows have ApexTradeQuantity=NULL with EtoroTradeQuantity populated, and the Apex side is linked via the ApexPositionId FK to EXT871_PositionActivity. The Apex quantity is accessed via the FK JOIN, not duplicated here
- For unmatched eToro-only positions: ApexTradeQuantity=NULL, ApexPositionId=NULL, EtoroTradeQuantity populated
- For unmatched Apex-only positions: EtoroTradeQuantity=NULL, ApexPositionId populated
- For quantity mismatches: both sides populated with different values
- BreakValue: Quantified discrepancy (decimal(28,2)). 0 = positions match, non-zero = break exists
- The Hidden flag allows suppressing known/accepted breaks from the active reconciliation view

### 2.2 Cross-System Matching

**What**: Links Apex position data to eToro instrument data for comparison.

**Columns/Parameters Involved**: `AccountNumber`, `Cusip`, `Symbol`, `InstrumentId`, `ApexPositionId`

**Rules**:
- AccountNumber + Cusip/Symbol: Used to match Apex positions to eToro positions
- InstrumentId: eToro's internal instrument identifier (resolved from Cusip/Symbol mapping)
- ApexPositionId: FK to apex.EXT871_PositionActivity.Id - the specific Apex position row being reconciled

---

## 3. Data Overview

~35.9 million rows. Most rows have BreakValue=0 (matched). Sample showing typical matched positions:

| AccountNumber | Cusip | Symbol | ApexTradeQuantity | EtoroTradeQuantity | InstrumentId | BreakValue | Meaning |
|---|---|---|---|---|---|---|---|
| xxxx | 67066G104 | NVDA | NULL | 1.1712 | 1137 | 0 | Matched NVIDIA position. ApexQty NULL = eToro-only row (Apex match via ApexPositionId FK). |
| xxxx | 02079K107 | GOOG | NULL | 0.39526 | 1002 | 0 | Matched Alphabet position. Fractional shares (0.39526). |
| xxxx | 88160R101 | TSLA | NULL | 370.0244 | 1111 | 0 | Matched Tesla position. Large holding (370 shares). |
| xxxx | 037833100 | AAPL | NULL | 0.00903 | 1001 | 0 | Matched Apple position. Very small fractional holding. |
| xxxx | 08862E109 | BYND | NULL | 209.79032 | 1187 | 0 | Matched Beyond Meat position. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | CODE-BACKED | Primary key for the reconciliation result row. |
| 2 | SodFileId | uniqueidentifier | NO | - | VERIFIED | FK to apex.SodFiles.Id. Links to the EXT871 file import that triggered this reconciliation run. CASCADE DELETE. |
| 3 | ApexPositionId | uniqueidentifier | YES | - | VERIFIED | FK to apex.EXT871_PositionActivity.Id. The specific Apex position row being compared. NULL when eToro has a position that Apex does not (eToro-only break). Unique filtered index ensures 1:1 mapping. |
| 4 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex account number (MASKED for PII). Identifies the customer account holding this position. |
| 5 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security being reconciled. |
| 6 | ApexTradeQuantity | decimal(28,10) | YES | - | VERIFIED | Position quantity from Apex EXT871. Often NULL for matched positions - the Apex quantity is accessed via the ApexPositionId FK JOIN to EXT871_PositionActivity instead of being duplicated here. Populated when there is a quantity mismatch or Apex-only position. |
| 7 | EtoroTradeQuantity | decimal(28,10) | YES | - | VERIFIED | Position quantity from eToro Data API. Populated for most rows (eToro-side data). NULL only for Apex-only positions that have no eToro match. Fractional shares are common (e.g., 0.12995 shares of NKE). |
| 8 | Symbol | varchar(35) | YES | - | CODE-BACKED | Ticker symbol of the security being reconciled. |
| 9 | InstrumentId | int | YES | - | CODE-BACKED | eToro internal instrument identifier. Resolved from CUSIP/symbol mapping. References the main etoro database. |
| 10 | BreakValue | decimal(28,2) | NO | - | VERIFIED | Quantified discrepancy between Apex and eToro positions. 0 = matched, non-zero = break requiring investigation. This is the primary metric for reconciliation status. |
| 11 | EtoroAverageOpenPrice | decimal(28,10) | YES | - | CODE-BACKED | Average open price of the position from eToro's records. Used for value-based comparison. |
| 12 | Hidden | bit | NO | CONVERT(bit,0) | VERIFIED | Whether this reconciliation result is hidden/suppressed in the UI. 0 = visible (default), 1 = hidden. Users can hide known/accepted breaks to focus on new discrepancies. |
| 13 | EtoroAverageClosePrice | decimal(28,10) | YES | - | CODE-BACKED | Average close price from eToro. Used for closed position reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to the EXT871 file import that triggered reconciliation |
| ApexPositionId | apex.EXT871_PositionActivity | FK | Links to the specific Apex position row being compared |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SOD Reconciliation UI | N/A | Read | Displays position reconciliation results for a given date |
| fix.PositionReconciliationLogs | N/A | Related | Tracks corrections applied to position breaks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
recon.PositionReconciliation (table)
├── apex.SodFiles (table) [SodFileId FK]
└── apex.EXT871_PositionActivity (table) [ApexPositionId FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId (CASCADE DELETE) |
| apex.EXT871_PositionActivity | Table | FK from ApexPositionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SOD Reconciliation UI | External | Reads and displays results |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionReconciliation | CLUSTERED PK | Id | - | - | Active |
| IX_PositionReconciliation_ApexPositionId | UNIQUE NC | ApexPositionId | - | WHERE ApexPositionId IS NOT NULL | Active |
| IX_PositionReconciliation_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PositionReconciliation_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| FK_PositionReconciliation_EXT871_PositionActivity_ApexPositionId | FOREIGN KEY | ApexPositionId -> apex.EXT871_PositionActivity.Id |
| (default) | DEFAULT | CONVERT(bit,0) for Hidden - visible by default |

---

## 8. Sample Queries

### 8.1 Find position breaks for a date

```sql
SELECT pr.AccountNumber, pr.Symbol, pr.Cusip,
       pr.ApexTradeQuantity, pr.EtoroTradeQuantity, pr.BreakValue
FROM recon.PositionReconciliation pr WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON pr.SodFileId = f.Id
WHERE f.ProcessDate = '2026-04-10' AND pr.BreakValue <> 0 AND pr.Hidden = 0
ORDER BY ABS(pr.BreakValue) DESC;
```

### 8.2 Count breaks vs matches for a file

```sql
SELECT CASE WHEN BreakValue = 0 THEN 'Matched' ELSE 'Break' END AS Status,
       COUNT(*) AS PositionCount
FROM recon.PositionReconciliation WITH (NOLOCK)
WHERE SodFileId = 'A75D4256-A035-F111-8EF3-7C1E52718022'
GROUP BY CASE WHEN BreakValue = 0 THEN 'Matched' ELSE 'Break' END;
```

### 8.3 Find eToro-only positions (no Apex match)

```sql
SELECT AccountNumber, Symbol, EtoroTradeQuantity, BreakValue
FROM recon.PositionReconciliation WITH (NOLOCK)
WHERE ApexPositionId IS NULL AND Hidden = 0
ORDER BY SodFileId DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Flow 2 - Data reconciliation: eToro positions fetched from Data API if EXT871, compared to Apex data, discrepancies written to recon.PositionReconciliation. UI shows results and allows manual fixes via Gateway API. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: recon.PositionReconciliation | Type: Table | Source: Sodreconciliation/Sodreconciliation/recon/Tables/recon.PositionReconciliation.sql*
