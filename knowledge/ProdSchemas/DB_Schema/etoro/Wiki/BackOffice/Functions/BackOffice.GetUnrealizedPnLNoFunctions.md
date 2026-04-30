# BackOffice.GetUnrealizedPnLNoFunctions

> Performance-optimized scalar function returning the total unrealized PnL (in cents) for a customer by reading directly from the Trade.PnL table instead of the view-based GetUnrealizedPnL function.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT - total PnL in cents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUnrealizedPnLNoFunctions` is the performance-optimized successor to `BackOffice.GetUnrealizedPnL`. Both functions return the total unrealized profit and loss (in cents) for all open positions of a customer, but this function reads directly from the `Trade.PnL` table rather than the `Trade.PositionForExternalUseWithPnL` view.

The optimization was created by Itay Hay in September 2024 as part of MIMOPSA-13954 ("Performance - function: GetUnrealizedPnLNoFunctions", P2 Epic, PROD-398), addressing performance issues in the MiMo (Mirror/Copy trading) system where the view-based calculation was causing bottlenecks when processing high volumes of copy trades. By bypassing the view layer and reading directly from a pre-computed table (`Trade.PnL`), the function delivers the same result with significantly lower execution overhead.

**Name explanation**: "NoFunctions" refers to not calling intermediate functions or complex view expressions - it reads a pre-computed PnL value directly from a table.

**Change history**:
- Yitzchak Wahnon (23/07/2023): Added NOLOCK (emergency fix) to prevent interference with instrument addition
- KateM (19/12/2023): PnL calculation change (aligned with view-based version change)
- ItayH (05/09/2024): Created this performance variant (MIMOPSA-13954) - switched from view to table

The key behavioral difference vs. `GetUnrealizedPnL`: this function returns NULL (not 0) when the customer has no positions, since `DECLARE @RetVal BIGINT` defaults to NULL and there is no `ISNULL` wrapper on the return. Callers must handle the NULL case.

---

## 2. Business Logic

### 2.1 Direct Table PnL Read (Performance Optimization)

**What**: Reads pre-computed PnL directly from Trade.PnL table instead of computing it via a view chain.

**Columns/Parameters Involved**: `@CID`, `@RetVal`

**Rules**:
- `SELECT @RetVal = SUM(PnLInCents) FROM Trade.PnL WHERE CID = @CID`
- No ISNULL wrapper: if CID has no rows in Trade.PnL, @RetVal remains NULL (unlike GetUnrealizedPnL which returns 0).
- No WITH (NOLOCK) in the FROM clause (emergency fix comment from Yitzchak mentioned nolock but current DDL reads without explicit hint - the table itself may use NOLOCK internally or the performance improvement removes the locking concern).
- Trade.PnL contains pre-computed PnLInCents per position, updated by the trading engine as prices change.

### 2.2 Performance vs. Correctness Trade-off

**What**: The distinction between this function and GetUnrealizedPnL represents a speed-vs-view-freshness trade-off.

**Columns/Parameters Involved**: @CID (drives which function is selected by callers)

**Rules**:
- GetUnrealizedPnL reads Trade.PositionForExternalUseWithPnL (view) - may include real-time calculation logic
- GetUnrealizedPnLNoFunctions reads Trade.PnL (table) - pre-computed values, potentially milliseconds stale but dramatically faster
- MIMOPSA-13954 (P2 Epic, still Open as of 2026-03-17) tracks ongoing performance work related to this function - indicating continued interest in optimizing this calculation path
- Callers choosing between the two functions should prefer this one for performance-sensitive contexts (bulk reports, high-frequency calls)

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the customer whose total unrealized PnL to calculate. Filters Trade.PnL by CID to sum all pre-computed PnL values for that customer's open positions. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return value) | BIGINT | YES | NULL | CODE-BACKED | Total unrealized PnL in cents for all open positions of the customer, read from Trade.PnL. Positive = in profit, negative = in loss. Returns NULL (not 0) if the customer has no rows in Trade.PnL - callers must use ISNULL/COALESCE. Contrast with GetUnrealizedPnL which returns 0 via ISNULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PnL | Table read | SUM(PnLInCents) WHERE CID = @CID. Trade.PnL is a pre-computed table that stores PnL per position, updated by the trading engine. Reading a table is faster than computing via a view chain. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used in performance-sensitive BackOffice and MiMo contexts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUnrealizedPnLNoFunctions (function)
└── Trade.PnL (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PnL | Table | SUM(PnLInCents) WHERE CID = @CID. Pre-computed PnL table - no view computation overhead. |

### 6.2 Objects That Depend On This

No dependents found in BackOffice stored procedures. Used by the MiMo system and performance-sensitive callers (external to SSDT repo or using dynamic calls).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get unrealized PnL using the performance-optimized function

```sql
SELECT ISNULL(BackOffice.GetUnrealizedPnLNoFunctions(12345), 0) / 100.0 AS UnrealizedPnLUSD;
-- Note: ISNULL needed since function returns NULL (not 0) for customers with no positions
```

### 8.2 Compare performance-optimized vs. view-based function

```sql
SELECT
    ISNULL(BackOffice.GetUnrealizedPnLNoFunctions(12345), 0) AS PnLFromTable_Cents,
    BackOffice.GetUnrealizedPnL(12345) AS PnLFromView_Cents;
-- Should return the same value; discrepancy may indicate Trade.PnL staleness
```

### 8.3 Get PnL directly from Trade.PnL table (avoids scalar function overhead entirely)

```sql
SELECT ISNULL(SUM(PnLInCents), 0) / 100.0 AS UnrealizedPnLUSD
FROM Trade.PnL WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-13954: Performance - function GetUnrealizedPnLNoFunctions](https://etoro-jira.atlassian.net/browse/MIMOPSA-13954) | Jira Epic | P2 performance epic (Reporter: Itay Hay, Sep 2024). Function created to bypass view-based PnL computation by reading Trade.PnL table directly. Part of PROD-398 "MiMo bugs" parent epic. Still Open as of 2026-03-17 indicating ongoing performance optimization work. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUnrealizedPnLNoFunctions | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUnrealizedPnLNoFunctions.sql*
