# Hedge.GetCustomerClosedPositionsData

> Aggregates customer-side closed position P&L and volume data per (HedgeServerID, InstrumentID) using dynamic SQL with a comma-separated HedgeServers parameter. IMPORTANT: The target table Hedge.CustomerClosedPositions does not exist in the database or SSDT - this procedure will fail at runtime.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferenceDate (required), @HedgeServers (required, comma-separated IDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the customer-centric counterpart to `Hedge.GetAccountClosedPositionsData`. While that procedure aggregates broker-side closed position data grouped by (HedgeServerID, LiquidityAccountID, InstrumentID), this procedure aggregates customer-side closed position data grouped by only (HedgeServerID, InstrumentID) - without a LiquidityAccount dimension.

The procedure was designed to query `Hedge.CustomerClosedPositions` - a table tracking customer P&L, commission, zero-P&L positions, and execution volume from the customer's perspective across each server/instrument pair. This data would complement the broker-side `Hedge.AccountClosedPositions` in hedge cost reconciliation: comparing what customers earned/paid vs. what the hedge account returned.

**Critical issue**: `Hedge.CustomerClosedPositions` does not exist in the database or SSDT. Executing this procedure will fail with "Invalid object name 'Hedge.CustomerClosedPositions'". This procedure appears to reference a table that was dropped or never created in this environment.

---

## 2. Business Logic

### 2.1 Dynamic SQL Construction with SQL Injection Risk

**What**: `@HedgeServers` is directly concatenated into the dynamic SQL `IN` clause without parameterization.

**Columns/Parameters Involved**: `@HedgeServers`, `@SQL`

**Rules**:
- `@HedgeServers varchar(300)` is directly embedded: `WHERE ... HedgeServerID IN (' + @HedgeServers + ')'`
- **SQL injection vulnerability**: a malicious caller could inject arbitrary SQL. The comment in the procedure acknowledges this was a deliberate performance trade-off ("Since this query runs lots of times I didn't want to have to parse XML and comma separated string")
- `@ReferenceDate` IS properly parameterized via `sp_executesql` `@ParamList = N'@ReferenceDate datetime'`
- The asymmetry - one parameter safe, one not - mirrors the pattern in `Hedge.GetAccountClosedPositionsData` and `Hedge.GetAccountTransactionsData`

### 2.2 Group By Pattern (No LiquidityAccountID)

**What**: Results are grouped by (HedgeServerID, InstrumentID) only - notably missing the LiquidityAccountID dimension present in the account-centric equivalent.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`

**Rules**:
- GROUP BY HedgeServerID, InstrumentID - customer-side view does not break down by account
- This makes sense: a customer position is not directly tied to a specific liquidity account
- The result gives a per-server, per-instrument aggregate of all customer activity
- `MAX(OccurredAt)` provides the most recent transaction timestamp for each group

### 2.3 Aggregated Metrics (When Table Exists)

**What**: Five aggregate columns would be returned per group.

**Rules**:
- `SUM(NetPL)`: total net profit/loss from customer closed positions in this group
- `SUM(CommissionOnClose)`: total commissions paid at position close
- `SUM(ZeroPL)`: sum of positions with zero P&L (likely a count proxy or weighted measure)
- `SUM(ExecutionVolumeInUSD)`: total USD-denominated execution volume (position size at open/close)
- `MAX(OccurredAt)`: most recent close timestamp in this group, filtered by @ReferenceDate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceDate | datetime | NO | - | CODE-BACKED | Required. Start of the time window. Only closed positions with `OccurredAt > @ReferenceDate` are included. Properly parameterized in sp_executesql. |
| 2 | @HedgeServers | varchar(300) | NO | - | CODE-BACKED | Required. Comma-separated list of HedgeServerIDs to include (e.g., "1,3,5,6"). DIRECTLY CONCATENATED into dynamic SQL - SQL injection risk. Must contain only integers separated by commas with no leading/trailing commas, as documented in the procedure comment. |

**Output Columns** (when target table exists):

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.CustomerClosedPositions | The hedge server on which these customer positions were closed. |
| InstrumentID | Hedge.CustomerClosedPositions | The trading instrument for this group of closed customer positions. |
| NetPL | Hedge.CustomerClosedPositions | SUM of net profit/loss from customer closed positions in this group since @ReferenceDate. |
| CommissionOnClose | Hedge.CustomerClosedPositions | SUM of commissions charged at position close for this group. |
| ZeroPL | Hedge.CustomerClosedPositions | SUM of ZeroPL values for positions in this group. |
| ExecutionVolumeInUSD | Hedge.CustomerClosedPositions | SUM of execution volume in USD for this group. |
| OccurredAt | Hedge.CustomerClosedPositions | MAX(OccurredAt) - most recent close timestamp in this group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.CustomerClosedPositions | Direct read (dynamic SQL) | TARGET TABLE DOES NOT EXIST - procedure will fail at runtime with "Invalid object name" |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetCustomerClosedPositionsData (procedure)
└── Hedge.CustomerClosedPositions (table) - DOES NOT EXIST (not in SSDT or database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerClosedPositions | Table | SELECT 7 columns (dynamic SQL) - TABLE DOES NOT EXIST. Procedure will fail at runtime. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Target table missing | CRITICAL | Hedge.CustomerClosedPositions does not exist in SSDT or the database. Executing this procedure will throw "Invalid object name 'Hedge.CustomerClosedPositions'". |
| SQL injection | Security | @HedgeServers is directly concatenated into dynamic SQL. Accepts only comma-separated integers per the procedure comment. Caller must validate input. |
| @ReferenceDate safe | Security | @ReferenceDate is properly parameterized via sp_executesql @ParamList - not vulnerable to injection |
| No LiquidityAccountID | Design | Unlike GetAccountClosedPositionsData, this procedure groups by (HedgeServerID, InstrumentID) only - no account dimension |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Equivalent query when table exists

```sql
SELECT HedgeServerID, InstrumentID,
       SUM(NetPL) AS NetPL,
       SUM(CommissionOnClose) AS CommissionOnClose,
       SUM(ZeroPL) AS ZeroPL,
       SUM(ExecutionVolumeInUSD) AS ExecutionVolumeInUSD,
       MAX(OccurredAt) AS OccurredAt
FROM Hedge.CustomerClosedPositions WITH (NOLOCK)
WHERE OccurredAt > '2026-01-01'
  AND HedgeServerID IN (1, 3, 5)
GROUP BY HedgeServerID, InstrumentID
ORDER BY HedgeServerID, InstrumentID
```

### 8.2 Compare with account-side equivalent

```sql
-- Account-side data (table EXISTS)
SELECT HedgeServerID, LiquidityAccountID, InstrumentID,
       SUM(NetPL) AS NetPL, SUM(Commission) AS Commission
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt > '2026-01-01'
  AND HedgeServerID IN (1, 3, 5)
GROUP BY HedgeServerID, LiquidityAccountID, InstrumentID
ORDER BY HedgeServerID, InstrumentID

-- Customer-side data (table does NOT exist)
-- SELECT ... FROM Hedge.CustomerClosedPositions ... -- FAILS
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*KNOWN ISSUE: Hedge.CustomerClosedPositions does not exist in SSDT or database. Procedure fails at runtime.*
*Object: Hedge.GetCustomerClosedPositionsData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetCustomerClosedPositionsData.sql*
