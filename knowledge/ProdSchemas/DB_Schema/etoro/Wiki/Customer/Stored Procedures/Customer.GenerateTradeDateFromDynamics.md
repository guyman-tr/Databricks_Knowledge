# Customer.GenerateTradeDateFromDynamics

> Builds a comprehensive financial snapshot for all customers active since a given date (open positions, recent credit changes, or recent trades) and sends each customer's trading statistics as an XML message to Microsoft Dynamics CRM via SQL Server Service Broker.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Date (processing window start) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GenerateTradeDateFromDynamics is the full trading-status CRM sync procedure. It identifies all financially-active customers (those with open positions, recent trades, or recent credit activity) and sends each customer's real-time financial snapshot to Microsoft Dynamics CRM via Service Broker. Dynamics uses this data for CRM segmentation, sales analytics, customer health scoring, and outreach prioritization.

The procedure exists alongside Customer.DynamicsInsert (which sends profile/identity data) and Customer.GenerateMirrorDataForDynamics (which sends copy-trading stats). This procedure covers the financial trading dimension: balance, equity, unrealized P&L, margins, deposits, cashouts, and position counts.

The name is slightly misleading: despite "FromDynamics" in the name, the procedure sends data TO Dynamics (not FROM). The "Date" refers to a trade-date cutoff - the procedure processes customers active since @Date. It runs on a schedule (called externally), capturing all activity from the last run forward.

Unlike GenerateMirrorDataForDynamics (which advances a durable watermark in Maintenance.Feature), this procedure relies on the caller to manage the @Date parameter between runs. Each run enqueues one transaction-per-message in the Service Broker cursor loop.

Comment history: FB3368 (2023-02-12, pini) - TradingAccountID was changed from ISNULL(Billing.Account.AccountID, c.CID) to just c.CID, removing the Billing.Account dependency.

---

## 2. Business Logic

### 2.1 Active Customer Identification

**What**: Builds a deduplicated set of customer IDs who need their stats sent to Dynamics.

**Columns/Parameters Involved**: `@Date`, `History.Credit.Occurred`, `Trade.Position.CID`, `History.Position.OpenOccurred`, `History.Position.CloseOccurred`

**Rules**:
Three sources UNION ALL into #Customers:
- History.Credit WHERE Occurred >= @Date: customers who received/sent money (deposits, cashouts, bonuses)
- Trade.Position (all rows - no date filter): customers with any currently open position
- History.Position WHERE OpenOccurred >= @Date OR CloseOccurred >= @Date: customers with recent trading activity

Clustered index created on #Customers.CID for join performance.

### 2.2 Financial Aggregate Assembly

**What**: Joins #Customers to BackOffice aggregates and cross-schema functions for per-customer financial stats.

**Columns/Parameters Involved**: `BackOffice.CustomerAllTimeAggregatedData`, `BackOffice.GetUnrealizedPnL`, `BackOffice.GetUsedMargin`, `Trade.Position` (for TotalOpenPositions)

**Rules**:
- BackOffice.CustomerAllTimeAggregatedData provides: TotalDeposit, TotalBonus, TotalCompensation, TotalCashout, TotalLot, TotalPositionCount, TotalProfit, TotalCommission (all-time stats)
- BackOffice.GetUnrealizedPnL(CID): unrealized P&L in cents across all open positions
- BackOffice.GetUsedMargin(CID): used margin in cents across all open positions
- TotalOpenPositions: COUNT(*) FROM Trade.Position WHERE CID = a.CID (current count, not all-time)
- Equity formula: `(Credit*100 + GetUnrealizedPnL + GetUsedMargin) / 100.0` - all components normalized to money units
- UsedMargin in output: `GetUsedMargin / 100.0` (cents to money units)

### 2.3 OriginalProviderID Normalization

**What**: Applies same provider ID normalization logic as Customer.DynamicsInsert.

**Rules**:
- WHEN OriginalProviderID > 1 -> use as-is (valid affiliate/provider)
- WHEN OriginalCID = CID -> use IsReal (self-referral sentinel - customer registered themselves)
- WHEN Registered < '2007-10-02' -> use IsReal (pre-affiliate-program registrations)
- ELSE -> use OriginalProviderID

Note: Uses `c.IsReal` (0 or 1) rather than literal 1, reflecting the environment detection pattern.

### 2.4 Service Broker Dispatch (Per-Transaction Cursor)

**What**: Sends one XML message per customer to svcDynamics, with a transaction per message.

**Rules**:
- DECLARE XMLCur CURSOR for all active customers with assembled data
- For each row: BEGIN TRANSACTION -> BEGIN DIALOG -> SEND -> COMMIT
- One transaction per message (unlike GenerateMirrorDataForDynamics which wraps all in one transaction)
- XML format: FOR XML RAW('Trade'), TYPE, BINARY BASE64, ELEMENTS
- Action = hardcoded 'Update' (all messages are updates, never inserts)
- IsDelta = 0 (hardcoded - always full snapshot, not delta)
- RealDB from Maintenance.Feature FeatureID=22 (1=real environment, 0=demo)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Date | DATETIME | NO | - | CODE-BACKED | Processing window start. Customers with credit activity (History.Credit.Occurred >= @Date), position changes (History.Position.OpenOccurred or CloseOccurred >= @Date), or any currently open position are included. Caller manages this value between runs. |

**No result set. Side effect: Service Broker XML messages enqueued to svcDynamics.**

**XML message fields sent to Dynamics (FOR XML RAW('Trade')):**

| XML Field | Source | Business Meaning |
|-----------|--------|-----------------|
| CID | Customer.Customer | Customer identifier |
| Action | Hardcoded 'Update' | Always an update message (no inserts from this procedure) |
| IsDelta | Hardcoded 0 | Always a full snapshot (not incremental delta) |
| RealDB | Maintenance.Feature FeatureID=22 | 1=real environment, 0=demo |
| CustomerName | Customer.Customer.UserName | Login username (used as name in CRM) |
| TradingAccountID | Customer.Customer.CID | Trading account identifier (previously Billing.Account.AccountID, changed FB3368) |
| OriginalCID | Customer.Customer.OriginalCID | Referring customer |
| OriginalProviderID | Derived (normalized) | Affiliate/provider (normalized - see Section 2.3) |
| ProviderID | Customer.Customer.ProviderID | Current provider |
| Balance | Customer.Customer.Credit | Raw credit balance |
| Deposits | BackOffice.CustomerAllTimeAggregatedData.TotalDeposit | All-time deposits |
| Bonuses | BackOffice.CustomerAllTimeAggregatedData.TotalBonus | All-time bonuses received |
| Compensations | BackOffice.CustomerAllTimeAggregatedData.TotalCompensation | All-time compensations |
| Cashouts | BackOffice.CustomerAllTimeAggregatedData.TotalCashout | All-time cashouts |
| UsedMargin | BackOffice.GetUsedMargin / 100.0 | Current used margin in money units |
| AccountStatus | Customer.Customer.AccountStatusID | Current account status |
| Equity | (Credit*100 + UnrealizedPnL + UsedMargin) / 100.0 | Real-time equity including open P&L |
| Lots | BackOffice.CustomerAllTimeAggregatedData.TotalLot | All-time lot count |
| PositionsCount | BackOffice.CustomerAllTimeAggregatedData.TotalPositionCount | All-time position count |
| TotalOpenPositions | COUNT(*) FROM Trade.Position | Current open position count |
| Profit | BackOffice.CustomerAllTimeAggregatedData.TotalProfit | All-time realized profit |
| Commission | BackOffice.CustomerAllTimeAggregatedData.TotalCommission | All-time commissions paid |
| LastOpenPositionDate | History.Position.InitDateTime (MAX) | Date of most recently opened position |
| LastLogin | History.Login.LoggedIn (MAX) | Most recent login date |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Date | History.Credit | Read | Customers with credit activity since @Date |
| (all) | Trade.Position | Read | All customers with open positions |
| @Date | History.Position | Read | Customers with position opens/closes since @Date |
| @CID | BackOffice.CustomerAllTimeAggregatedData | Read (JOIN) | All-time aggregated financial stats per customer |
| @Date | History.Login | Read | Most recent login per active customer |
| @Date | History.Position | Read | Most recent position open per active customer |
| @CID | Customer.Customer | Read | Profile data, credit balance, provider info |
| @CID | BackOffice.GetUnrealizedPnL | Function call | Unrealized P&L across open positions |
| @CID | BackOffice.GetUsedMargin | Function call | Used margin across open positions |
| FeatureID=22 | Maintenance.Feature | Read | Real vs demo environment flag |
| svcDynamics | SQL Server Service Broker | Message target | CRM sync message destination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in SSDT repo. | - | Called from external scheduler/service. | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GenerateTradeDateFromDynamics (procedure)
|- History.Credit (table - cross-schema, active customer discovery)
|- Trade.Position (table - cross-schema, open position discovery + count)
|- History.Position (table - cross-schema, active customer discovery + last open position)
|- BackOffice.CustomerAllTimeAggregatedData (table - cross-schema, aggregated stats)
|- History.Login (table - cross-schema, last login lookup)
|- Customer.Customer (view - profile, balance, provider)
|- BackOffice.GetUnrealizedPnL (function - cross-schema, real-time equity)
|- BackOffice.GetUsedMargin (function - cross-schema, real-time margin)
|- Maintenance.Feature FeatureID=22 (table - cross-schema, environment flag)
+-- svcDynamics (Service Broker service - async CRM dispatch)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Active customer discovery by credit date |
| Trade.Position | Table | Active customer discovery (all open positions); TotalOpenPositions count |
| History.Position | Table | Active customer discovery; LastOpenPosition date |
| BackOffice.CustomerAllTimeAggregatedData | Table | All-time financial stats (deposits, cashouts, P&L, etc.) |
| History.Login | Table | LastLogin date per active customer |
| Customer.Customer | View | Profile data, credit balance, provider/affiliate info |
| BackOffice.GetUnrealizedPnL | Function | Real-time unrealized P&L for equity calculation |
| BackOffice.GetUsedMargin | Function | Real-time used margin for equity calculation |
| Maintenance.Feature (FeatureID=22) | Table | Real/demo environment detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from external scheduler. |

---

## 7. Technical Details

### 7.1 Indexes

| Temp Table | Index | Columns | Purpose |
|------------|-------|---------|---------|
| #Customers | CIDX_Customers (CLUSTERED) | CID | Optimizes JOIN to #Customers in subsequent queries |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRANSACTION per cursor row | Design | Each Service Broker send is its own transaction (vs GenerateMirrorDataForDynamics which wraps all in one) |
| IsDelta = 0 (hardcoded) | Design | Always sends full customer snapshot; no partial/delta messages |
| Action = 'Update' (hardcoded) | Design | All messages are updates - Dynamics receives no 'Insert' or 'Delete' from this procedure |
| BackOffice.GetUnrealizedPnL and GetUsedMargin called per row | Performance | These functions execute per customer in both #agg build and cursor XML - double call per customer |
| Trade.Position scanned without date filter | Design | ALL open positions included regardless of @Date - ensures any currently-open customer is captured |
| FB3368 (2023-02-12) | Change history | TradingAccountID changed from Billing.Account.AccountID to CID; billing account link removed |

---

## 8. Sample Queries

### 8.1 Run a trading stats sync for the last 24 hours

```sql
EXEC Customer.GenerateTradeDateFromDynamics
    @Date = DATEADD(DAY, -1, GETDATE())
```

### 8.2 Check how many customers would be in scope for a given date

```sql
SELECT COUNT(DISTINCT CID) AS ActiveCustomers
FROM (
    SELECT DISTINCT CID FROM History.Credit WITH (NOLOCK) WHERE Occurred >= DATEADD(DAY, -1, GETDATE())
    UNION ALL
    SELECT DISTINCT CID FROM Trade.Position WITH (NOLOCK)
    UNION ALL
    SELECT DISTINCT CID FROM History.Position WITH (NOLOCK)
        WHERE OpenOccurred >= DATEADD(DAY, -1, GETDATE())
           OR CloseOccurred >= DATEADD(DAY, -1, GETDATE())
) A
```

### 8.3 Preview financial snapshot for a specific customer

```sql
SELECT
    c.CID,
    c.Credit AS Balance,
    a.TotalDeposit AS Deposits,
    a.TotalCashout AS Cashouts,
    CAST((CAST(c.Credit*100 AS BIGINT) + BackOffice.GetUnrealizedPnL(c.CID) + BackOffice.GetUsedMargin(c.CID))/100.0 AS MONEY) AS Equity,
    (SELECT COUNT(*) FROM Trade.Position p WITH (NOLOCK) WHERE p.CID = c.CID) AS TotalOpenPositions
FROM Customer.Customer c WITH (NOLOCK)
JOIN BackOffice.CustomerAllTimeAggregatedData a ON a.CID = c.CID
WHERE c.CID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GenerateTradeDateFromDynamics | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GenerateTradeDateFromDynamics.sql*
