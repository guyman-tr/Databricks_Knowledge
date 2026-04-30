# Customer.GetCurrentFinancialDataByGCID

> Real-time financial snapshot by GCID: returns a single customer's current account balance, active mirror count, realized equity, and total equity including unrealized P&L - the GCID-keyed companion to GetCurrentFinancialDataByCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @GCID int (returns 0 or 1 rows) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetCurrentFinancialDataByGCID is the GCID-keyed equivalent of Customer.GetCurrentFinancialDataByCID. It returns the same five financial values (CID, Credit, NumberOfActiveMirrors, RealizedEquity, UnRealizedEquity) but accepts @GCID as the lookup key instead of @CID.

The function exists because some callers (particularly newer services built after the GCID migration) hold a GCID and need financial data without first resolving to CID. Using this function avoids a CID-lookup round trip.

**Important known issue**: The call to `BackOffice.GetUnrealizedPnL(@GCID)` passes @GCID where the function likely expects a CID. The companion function GetCurrentFinancialDataByCID correctly passes @CID. If BackOffice.GetUnrealizedPnL is CID-keyed (likely), then UnRealizedEquity in this function may return incorrect values for customers whose GCID differs from their CID (most modern customers have GCID != CID). This is a latent bug.

---

## 2. Business Logic

### 2.1 Equity Calculation: Realized vs Unrealized

**What**: Same as GetCurrentFinancialDataByCID - RealizedEquity excludes floating P&L; UnRealizedEquity includes it.

**Columns/Parameters Involved**: `RealizedEquity`, `UnRealizedEquity`

**Rules**:
- `RealizedEquity`: from Customer.Customer (CustomerMoney) - settled cash + closed-position P&L
- `UnRealizedEquity = RealizedEquity + BackOffice.GetUnrealizedPnL(@GCID) / 100`
- **Bug**: @GCID is passed to GetUnrealizedPnL. If that function internally filters by CID (which it likely does given its companion ByCID passes @CID), the unrealized P&L will be 0 or incorrect for customers where GCID != CID.

### 2.2 Active Mirror Count

**What**: NumberOfActiveMirrors counts active copy-trading relationships by CID (correlated to CCST.CID), not by GCID.

**Columns/Parameters Involved**: `NumberOfActiveMirrors`

**Rules**:
- `SELECT COUNT(*) FROM Trade.Mirror WHERE CID = CCST.CID AND IsActive = 1`
- Correctly uses CCST.CID (the resolved CID from the GCID lookup), so mirror count is accurate
- This column is NOT affected by the @GCID bug

---

## 3. Data Overview

N/A for Inline TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | VERIFIED | Group Customer ID to look up. Returns 0 rows if GCID not found. Returns exactly 1 row when found. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.Customer (CustomerStatic). Returned so callers have both CID and GCID available. |
| 2 | Credit | money | YES | - | VERIFIED | Current cash balance (USD). From Customer.Customer (CustomerMoney). Liquid cash available in the account, excluding open position values. |
| 3 | NumberOfActiveMirrors | int | NO | - | CODE-BACKED | Count of active copy-trading relationships: COUNT(*) from Trade.Mirror WHERE CID=CCST.CID AND IsActive=1. Correctly uses resolved CID. 0 = not copying any leader. |
| 4 | RealizedEquity | money | YES | - | VERIFIED | Cumulative settled P&L plus current cash. From Customer.Customer (CustomerMoney). Excludes floating P&L on open positions. |
| 5 | UnRealizedEquity | money | YES | - | CODE-BACKED | Total mark-to-market equity: RealizedEquity + (BackOffice.GetUnrealizedPnL(@GCID) / 100). WARNING: passes @GCID to a function that likely expects CID - may return incorrect values for modern customers with GCID != CID. Use Customer.GetCurrentFinancialDataByCID when CID is available to avoid this issue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Credit, RealizedEquity | Customer.Customer | FROM (CCST alias) WHERE GCID=@GCID | Customer profile and financial state via GCID lookup |
| NumberOfActiveMirrors | Trade.Mirror | Correlated subquery (COUNT WHERE CCST.CID AND IsActive=1) | Active copy-trading count |
| UnRealizedEquity (component) | BackOffice.GetUnrealizedPnL | Scalar function call with @GCID (potential bug: likely expects CID) | Floating P&L in cents |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. See companion Customer.GetCurrentFinancialDataByCID (preferred when CID is available).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCurrentFinancialDataByGCID (function)
|-  Customer.Customer (view)
|     |-  Customer.CustomerStatic (table)
|     `-  Customer.CustomerMoney (table)
|-  Trade.Mirror (table) [cross-schema, correlated subquery]
`-  BackOffice.GetUnrealizedPnL (function) [cross-schema, scalar call with @GCID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (CCST alias) WHERE GCID=@GCID - CID, Credit, RealizedEquity |
| Trade.Mirror | Table (cross-schema) | Correlated subquery COUNT(*) WHERE CID=CCST.CID AND IsActive=1 |
| BackOffice.GetUnrealizedPnL | Scalar Function (cross-schema) | Called with @GCID (potential CID/GCID mismatch bug) |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE CCST.GCID = @GCID | Row filter | Returns at most 1 row per call |
| IsActive = 1 | Subquery filter | Only live copy relationships counted |
| / cast(100 as money) | Unit conversion | BackOffice.GetUnrealizedPnL returns cents; dividing by 100 converts to dollars |
| BackOffice.GetUnrealizedPnL(@GCID) | Potential bug | @GCID passed where @CID expected - UnRealizedEquity may be inaccurate for GCID != CID customers |

---

## 8. Sample Queries

### 8.1 Current financial state for a specific customer by GCID

```sql
SELECT CID, Credit, NumberOfActiveMirrors, RealizedEquity, UnRealizedEquity
FROM Customer.GetCurrentFinancialDataByGCID(98765) WITH (NOLOCK);
```

### 8.2 Prefer ByCID for accuracy when CID is available

```sql
-- Recommended: resolve GCID to CID first, then use GetCurrentFinancialDataByCID
SELECT fd.GCID, fd.Credit, fd.NumberOfActiveMirrors, fd.RealizedEquity, fd.UnRealizedEquity
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetCurrentFinancialDataByCID(c.CID) fd
WHERE c.GCID = 98765;
```

### 8.3 Financial data for a cohort of customers by GCID

```sql
SELECT
    c.UserName,
    fd.Credit,
    fd.NumberOfActiveMirrors,
    fd.RealizedEquity
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetCurrentFinancialDataByGCID(c.GCID) fd
WHERE c.IsReal = 1
  AND c.GCID IN (98765, 98766, 98767);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCurrentFinancialDataByGCID | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.GetCurrentFinancialDataByGCID.sql*
