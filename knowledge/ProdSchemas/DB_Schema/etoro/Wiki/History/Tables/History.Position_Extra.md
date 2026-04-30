# History.Position_Extra

> Companion extension table to History.Position storing supplemental data for closed positions: accumulated P&L adjustment compensation, dividend payments, and a flag indicating whether the position is excluded from the customer's performance statistics.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionID (BIGINT, CLUSTERED PK) |
| **Partition** | No (PAGE compression, on HISTORY filegroup) |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

History.Position_Extra is a 1:1 extension table for History.Position (closed positions). It stores supplemental metadata that does not fit in the main position record without altering that table's structure: accumulated compensation amounts from P&L adjustments, dividend payments credited on closed stock positions, and a statistics exclusion flag.

The table is populated on demand - only positions that receive a P&L adjustment or dividend, or that are explicitly excluded from statistics, get a row here. Once created, the row accumulates further adjustments via UPDATE. This design keeps History.Position clean while allowing position-level enrichment.

The typical workflow: a BackOffice manager applies a P&L adjustment (CompensationReasonID=22) via Billing.AmountAdd; the system credits the customer's account balance AND marks the position with TotalCompensation and ExcludeFromStatistics=1 so it does not skew the customer's visible performance statistics.

73,968 rows span January 2013 through January 2026. 99.9% of rows have TotalCompensation > 0 and ExcludeFromStatistics=1, confirming that P&L adjustment compensation is the dominant write path. Dividend payments are written by Stocks.PayDividends but Dividend=0 for virtually all current rows in this environment.

---

## 2. Business Logic

### 2.1 P&L Adjustment Compensation (Primary Path)

**What**: When a P&L adjustment is applied to a closed position, the position's compensation is accumulated here and the position is excluded from statistics.

**Columns/Parameters Involved**: `PositionID`, `TotalCompensation`, `ExcludeFromStatistics`

**Rules**:
- Triggered by Billing.AmountAdd when @CompensationReasonID=22 (P&L Adjustment).
- @Amount is passed in cents (integer); stored as `@Amount / 100.0` (money).
- If no row exists for the PositionID: INSERT with TotalCompensation=amount, ExcludeFromStatistics=1.
- If a row already exists: UPDATE TotalCompensation += amount, ExcludeFromStatistics=1.
- ExcludeFromStatistics is always set to 1 on the P&L adjustment path - the position is removed from performance statistics calculations.
- The position must exist in History.Position_Active (not just History.Position) - only active closed positions in this environment qualify.

### 2.2 Statistics Exclusion (Direct Path)

**What**: BackOffice managers can explicitly include or exclude a position from customer statistics without changing compensation amounts.

**Columns/Parameters Involved**: `PositionID`, `ExcludeFromStatistics`

**Rules**:
- Triggered by BackOffice.ExcludePositionFromStatistics(@PositionID, @ExcludeFromStatistics).
- Position must exist in History.Position (validated before write).
- Can set ExcludeFromStatistics=0 (re-include a position in stats) or =1 (exclude).
- INSERT/UPDATE pattern: if no row exists, creates one with TotalCompensation=0; if row exists, updates only ExcludeFromStatistics.
- Allows reversing a previous exclusion decision.

### 2.3 Dividend Payment Accumulation

**What**: Stocks.PayDividends credits dividend payments to closed positions and accumulates the total dividend amount here.

**Columns/Parameters Involved**: `PositionID`, `Dividend`

**Rules**:
- Written by Stocks.PayDividends; INSERT with Dividend=@Payment and ExcludeFromStatistics=0, OR UPDATE to add to existing Dividend.
- Dividend default is 0 (all positions start with 0 dividend).
- Unlike the P&L path, dividend payment does NOT set ExcludeFromStatistics=1.
- Dividend column is virtually always 0 in the current live environment.

### 2.4 Auto-Updated LastUpdate Trigger

**What**: The History.Position_ExtraUpdate trigger maintains LastUpdate as the most recent modification timestamp.

**Columns/Parameters Involved**: `LastUpdate`

**Rules**:
- FOR UPDATE trigger fires on any UPDATE to any row.
- Sets LastUpdate = GETUTCDATE() for all updated rows.
- Default value of GETUTCDATE() also applies on INSERT.
- LastUpdate reflects when TotalCompensation or Dividend or ExcludeFromStatistics was last changed.

---

## 3. Data Overview

| PositionID | TotalCompensation | ExcludeFromStatistics | LastUpdate | Dividend |
|------------|-------------------|----------------------|------------|----------|
| 2152757013 | 111.00 | 1 (excluded) | 2026-01-12 | 0.00 |
| 2152820759 | 10.00 | 1 (excluded) | 2026-01-12 | 0.00 |
| 2152820812 | 0.00 | 1 (excluded) | 2026-01-12 | 0.00 |
| 119771005 | 50.00 | 1 (excluded) | 2017-02-16 | 0.00 |

73,968 rows | Oldest: 2013-01-06 | Newest: 2026-01-12
- 73,907 rows with TotalCompensation > 0 (99.9%)
- 73,967 rows with ExcludeFromStatistics = 1 (99.999%)
- 0 rows with Dividend > 0 (dividend path not active in this env)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Closed position identifier. PK (1:1 with History.Position). Implicit FK to History.Position. Populated when a compensation or dividend is first applied, or when ExcludeFromStatistics is set. BIGINT since Jun 2021 (previously INT per BackOffice.ExcludePositionFromStatistics changelog). |
| 2 | TotalCompensation | money | YES | - | CODE-BACKED | Accumulated P&L adjustment compensation applied to this position, in USD (or account currency). Stored in standard money units (not cents). @Amount in Billing.AmountAdd is in cents / 100. 0.00 when created via the statistics exclusion or dividend paths. |
| 3 | ExcludeFromStatistics | bit | YES | - | CODE-BACKED | When 1: this position is excluded from the customer's visible performance statistics (win rate, profit/loss etc.). Set to 1 automatically when a P&L adjustment is applied. Can be toggled by BackOffice.ExcludePositionFromStatistics. 99.9% of rows have this set to 1. |
| 4 | LastUpdate | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC datetime of the most recent modification. Set to GETUTCDATE() on INSERT (default) and automatically maintained by the History.Position_ExtraUpdate trigger on every UPDATE. |
| 5 | Dividend | money | YES | 0 | CODE-BACKED | Total dividend payments accumulated for this closed position, in money units. Default 0. Written by Stocks.PayDividends. When a stock pays dividends after a position closes, the amount is credited here. Nearly always 0 in current data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.Position | Implicit PK/FK | One row per closed position. BackOffice.ExcludePositionFromStatistics validates existence in History.Position before write. |
| PositionID | History.Position_Active | Implicit | Billing.AmountAdd validates existence in History.Position_Active before the P&L compensation write path. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AmountAdd | @PositionID + @CompensationReasonID=22 | WRITER | INSERT/UPDATE TotalCompensation and ExcludeFromStatistics on P&L adjustment. |
| BackOffice.ExcludePositionFromStatistics | @PositionID | WRITER | INSERT/UPDATE ExcludeFromStatistics flag. |
| Stocks.PayDividends | @PositionID | WRITER | INSERT/UPDATE Dividend accumulation. |
| BackOffice.GetCustomerClosedPositions | PositionID | READER | Reads TotalCompensation and ExcludeFromStatistics when fetching customer's closed position details. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (no explicit FK constraints).

---

### 6.1 Objects This Depends On

No enforced FK constraints. Implicit dependency on History.Position for PositionID validity.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AmountAdd | Stored Procedure | WRITER - inserts/updates compensation on P&L adjustment (CompensationReasonID=22) |
| BackOffice.ExcludePositionFromStatistics | Stored Procedure | WRITER - manages ExcludeFromStatistics flag |
| BackOffice.GetCustomerClosedPositions | Stored Procedure | READER - includes extra data when presenting closed positions |
| Stocks.PayDividends | Stored Procedure | WRITER - accumulates dividend payments for closed positions |
| Billing.AmountAddBonus | Stored Procedure | READER/WRITER - may interact with position compensation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Position_Extra | CLUSTERED PK | PositionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Position_Extra | PRIMARY KEY | One row per PositionID |
| DF_History_Position_Extra_LastUpdate | DEFAULT | LastUpdate = GETUTCDATE() on INSERT |
| DF_HistoryPosition_Extra__Divident | DEFAULT | Dividend = 0 on INSERT (note: "Divident" misspelling in constraint name) |

### 7.3 Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| History.Position_ExtraUpdate | FOR UPDATE | Sets LastUpdate = GETUTCDATE() for all updated rows |

### 7.4 Storage

| Property | Value |
|----------|-------|
| Filegroup | HISTORY |
| Data Compression | PAGE |

---

## 8. Sample Queries

### 8.1 Get positions with compensation and statistics exclusion

```sql
SELECT pe.PositionID, pe.TotalCompensation, pe.ExcludeFromStatistics, pe.Dividend, pe.LastUpdate
FROM History.Position_Extra pe WITH (NOLOCK)
WHERE pe.TotalCompensation > 0
ORDER BY pe.LastUpdate DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
```

### 8.2 Get total compensation applied to a customer's closed positions

```sql
SELECT SUM(pe.TotalCompensation) AS TotalCompensationUSD,
       COUNT(*) AS PositionCount
FROM History.Position_Extra pe WITH (NOLOCK)
JOIN History.Position hp WITH (NOLOCK) ON hp.PositionID = pe.PositionID
WHERE hp.CustomerID = 12345;
```

### 8.3 Find positions with dividends accumulated

```sql
SELECT pe.PositionID, pe.Dividend, pe.LastUpdate
FROM History.Position_Extra pe WITH (NOLOCK)
WHERE pe.Dividend > 0
ORDER BY pe.Dividend DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Position_Extra | Type: Table | Source: etoro/etoro/History/Tables/History.Position_Extra.sql*
