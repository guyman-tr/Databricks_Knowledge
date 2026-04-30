# Billing.CreditCardRoutingTransactionsVerification

> Diagnostic health check for credit card deposit routing: scans the last hour of CC deposits and returns rows where the assigned routing reason violates the expected routing hierarchy (Regulation > BIN > Country > Priority/Quota); used by ops/monitoring to catch misconfigured routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Threshold (quota completion % threshold) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CreditCardRoutingTransactionsVerification` is a monitoring procedure that validates credit card deposit routing decisions from the past hour against the expected routing hierarchy. It is called by operations/monitoring tooling (not in the real-time payment flow) to detect misrouted deposits before they cause financial or settlement issues.

The routing system assigns each CC deposit a `RoutingReasonID` based on the highest-priority applicable rule:
1. **Regulation** (ID=5): Customer's designated regulation maps to a specific protocol - highest priority
2. **BIN** (ID=3): Card BIN number maps to a specific protocol - overrides country, not regulation
3. **Country** (ID=6): Card issuer country maps to a specific protocol
4. **Priority/Quota** (ID=2): Route to the processor with available quota capacity
5. **Quota** (ID=1): Standard quota-based routing
6. **Undefined** (ID=0): Routing failed to classify - always an error

This procedure checks whether deposits were routed according to this hierarchy. A deposit routed by BIN when a Regulation rule applies is a discrepancy. A deposit routed as Priority when no provider has reached the quota threshold is a discrepancy. The procedure returns each violating DepositID with a human-readable description of the problem.

Note: The original procedure comment at the end of the SQL file reads `-- [BackOffice].[CreditCardRoutingTransactionsVerification]`, indicating this procedure was migrated from BackOffice schema at some point.

---

## 2. Business Logic

### 2.1 Input Scoping - Active CC Depots and Last-Hour Deposits

**What**: Narrows the analysis window to credit card deposits from the last hour at active CC depots.

**Rules**:
- Active CC depots: `Billing.Depot WHERE FundingTypeID = 1 AND IsActive = 1` -> stored in `#CreditCardDepots`
- Last-hour CC deposits: `Billing.Deposit WHERE PaymentStatusID IN (2,3,4)` (Processed/Approved states) AND `DepotID IN #CreditCardDepots` AND `PaymentDate >= DATEADD(hh,-1,GETUTCDATE())`
- Only deposits with a `RoutingReasonID` that exists in `Billing.RoutingReason` are included (junk/legacy IDs excluded)
- Working set stored in `#LastCCDeposits (CID, DepositID, DepotID, RoutingReasonID)`

### 2.2 Check 1 - Undefined Routing

**What**: Detects deposits where routing could not be classified.

**Rule**: Any deposit in `#LastCCDeposits` with `RoutingReasonID = 0` (Undefined) is inserted into `#RoutingDiscrepancies` with `DiscrepancyDetails = 'Undefined CreditCard Routing Plan'`.

**Significance**: RoutingReasonID=0 means the routing engine failed to find any applicable rule. This is always an error - every deposit must have a valid routing reason.

### 2.3 Check 2 - Priority Routing When No Quota Exceeded

**What**: Priority routing (ID=2) should only be used when at least one provider has reached the quota threshold. If no provider is at or above @Threshold%, using Priority routing is incorrect.

**Rules**:
- Builds `#CurrentQuotaSnapshots` from `Billing.MonthlyQuota` joined to `Billing.QuotaManagement` for current year/month: calculates `CompletePercentage = (Amount / QuotaMin) * 100` per protocol
- `@CountOfProvidersReachedThreshold = COUNT(*) WHERE CompletePercentage > @Threshold`
- IF `@CountOfProvidersReachedThreshold = 0`: inserts all Priority-routed deposits (RoutingReasonID=2) as discrepancies: `'Wrong Credit Card Priority Routing Plan, Quota beyound 100%'`
- Note: If at least one provider is at/above threshold, Priority routing is valid and no discrepancy is recorded

### 2.4 Check 3 - Regulation Routing Validation

**What**: Deposits marked as Regulation-routed (ID=5) should route to a depot whose protocol matches the customer's designated regulation. If they don't, the routing config is wrong.

**Rules**:
- Builds `#RouteByRegulation`: deposits with RoutingReasonID=5 JOINed to `BackOffice.Customer` (DesignatedRegulationID) and `Billing.ProtocolToRegulation`, filtered where `BD.DepotID.ProtocolID = BPR.ProtocolID AND BPR.RegulationID = BC.DesignatedRegulationID`
- Compares `@AllRoutedByRegulation` (total regulation-routed deposits) vs `@RouteByRegulationBySettings` (deposits that match the expected regulation/protocol pairing)
- IF counts differ: deposits in `#LastCCDeposits` with RoutingReasonID=5 NOT in `#RouteByRegulation` are discrepancies: `'Wrong Credit Card Routing by Regulation Plan, Wrong Configuration'`

### 2.5 Check 4 - BIN Routing Hierarchy Violations

**What**: BIN routing (ID=3) is only valid if no Regulation rule applies. Two sub-checks validate this.

**Sub-check 4a - Must be Regulation**: If a deposit was BIN-routed but the assigned depot's protocol also exists in `Billing.ProtocolToRegulation` for that customer's regulation -> the deposit should have been Regulation-routed:
- Discrepancy: `'Wrong Credit Card Routing by Bin Plan, Must be Routed by Regulation'`

**Sub-check 4b - Wrong BIN Config**: If a deposit was BIN-routed but the card's BIN (extracted from `Billing.Funding.FundingData` XML as `Funding[1]/BinCodeAsString[1]`) is NOT in `Billing.ProtocolByBin` -> no BIN routing rule should have fired:
- Discrepancy: `'Wrong Credit Card Routing by Bin Plan, Wrong Configuration'`

### 2.6 Check 5 - Country Routing Hierarchy Violations

**What**: Country routing (ID=6) is only valid if neither Regulation nor BIN rules apply. Three sub-checks validate this.

**Context data built**: `#RouteByCountry` extracts BinCode and BinCountryID from `Billing.Funding.FundingData` XML for Country-routed deposits.

**Sub-check 5a - Wrong Config**: If the card's BinCountryID is NOT in `Billing.ProtocolCountry` OR the depot's ProtocolID is NOT in `Billing.ProtocolCountry`:
- Discrepancy: `'Wrong Credit Card Routing by Country, Wrong Configuration'`

**Sub-check 5b - Must be Regulation**: If the depot protocol and customer regulation both exist in `Billing.ProtocolToRegulation` (matched via a double-join):
- Discrepancy: `'Wrong Credit Card Routing by Country, Must be Routed by Regulation'`

**Sub-check 5c - Must be BIN**: If the card's BinCode exists in `Billing.ProtocolByBin`:
- Discrepancy: `'Wrong Credit Card Routing by Country, Must be Routed by BIN'`

### 2.7 Result Set

Returns the accumulated `#RoutingDiscrepancies` table (SELECT *). Zero rows = no discrepancies found in the last hour. Each row identifies one deposit with one discrepancy type.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Threshold | DECIMAL(18,2) | YES | 100 | VERIFIED | Quota completion percentage threshold for Check 2 (Priority routing validation). A provider is considered "at quota" when `(Amount/QuotaMin)*100 > @Threshold`. Default=100 means at least one provider must have fully exceeded its quota minimum for Priority routing to be valid. Lower values (e.g., 80) make the check more sensitive. |

**Result set columns** (from `#RoutingDiscrepancies`):

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | DepositID | INT | The deposit ID with the routing discrepancy. FK to Billing.Deposit.DepositID. |
| 2 | DepotID | INT | The depot (payment terminal) the deposit was routed to. FK to Billing.Depot.DepotID. |
| 3 | RoutingReasonID | INT | The routing reason that was applied: 0=Undefined, 2=Priority, 3=Bin, 5=Regulation, 6=Country. Indicates which check detected the discrepancy. |
| 4 | DiscrepancyDetails | NVARCHAR(100) | Human-readable description of the specific discrepancy detected. Values: 'Undefined CreditCard Routing Plan', 'Wrong Credit Card Priority Routing Plan, Quota beyound 100%', 'Wrong Credit Card Routing by Regulation Plan, Wrong Configuration', 'Wrong Credit Card Routing by Bin Plan, Must be Routed by Regulation', 'Wrong Credit Card Routing by Bin Plan, Wrong Configuration', 'Wrong Credit Card Routing by Country, Wrong Configuration', 'Wrong Credit Card Routing by Country, Must be Routed by Regulation', 'Wrong Credit Card Routing by Country, Must be Routed by BIN'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #CreditCardDepots | Billing.Depot | Read | Active CC depots (FundingTypeID=1, IsActive=1) used to scope deposit search |
| #LastCCDeposits | Billing.Deposit | Read | Approved/processed CC deposits from last hour |
| RoutingReasonID filter | Billing.RoutingReason | Read | Validates that RoutingReasonIDs are known; filters to recognized routing reasons only |
| Check 2 | Billing.MonthlyQuota | Read | Current month processed amounts per protocol |
| Check 2 | Dictionary.Protocol | Read | Protocol names for quota snapshot |
| Check 2 | Billing.QuotaManagement | Read | Quota minimums per protocol |
| Checks 3,4,5 | BackOffice.Customer | Read | Customer's DesignatedRegulationID for regulation-based routing validation |
| Checks 3,4,5 | Billing.ProtocolToRegulation | Read | Maps regulation to protocol for hierarchy validation |
| Checks 4,5 | Billing.Funding | Read | XML FundingData containing BinCodeAsString and BinCountryIDAsInteger |
| Check 4 | Billing.ProtocolByBin | Read | BIN-to-protocol routing config for BIN routing validation |
| Check 5 | Billing.ProtocolCountry | Read | Country-to-protocol routing config for Country routing validation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ops/monitoring tooling | @Threshold | Caller | Called periodically to detect routing misconfigurations before they accumulate |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardRoutingTransactionsVerification (procedure)
+-- Billing.Depot (table) [READ: active CC depots]
+-- Billing.Deposit (table) [READ: last-hour CC deposits]
+-- Billing.RoutingReason (table) [READ: valid routing reason IDs]
+-- Billing.MonthlyQuota (table) [READ: current month quota amounts]
+-- Dictionary.Protocol (table) [READ: protocol names]
+-- Billing.QuotaManagement (table) [READ: quota minimums]
+-- BackOffice.Customer (table) [READ: customer regulation assignments]
+-- Billing.ProtocolToRegulation (table) [READ: regulation-to-protocol mapping]
+-- Billing.Funding (table) [READ: XML FundingData for BIN/Country]
+-- Billing.ProtocolByBin (table) [READ: BIN routing config]
+-- Billing.ProtocolCountry (table) [READ: country routing config]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | Active CC depots filter |
| Billing.Deposit | Table | Last-hour CC deposit reads |
| Billing.RoutingReason | Table | Routing reason validation filter |
| Billing.MonthlyQuota | Table | Quota snapshot for Priority check |
| Dictionary.Protocol | Table | Protocol name lookup |
| Billing.QuotaManagement | Table | Quota minimum values |
| BackOffice.Customer | Table | Customer's DesignatedRegulationID |
| Billing.ProtocolToRegulation | Table | Regulation-to-protocol hierarchy rules |
| Billing.Funding | Table | Card BIN/country from XML FundingData |
| Billing.ProtocolByBin | Table | BIN routing configuration |
| Billing.ProtocolCountry | Table | Country routing configuration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Ops monitoring tooling | External | Periodic health check on CC routing accuracy |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Temp table pattern**: Uses 7 `#` temp tables (not `##` global) - session-scoped and auto-dropped. No explicit DROP TABLE needed.

**XML extraction**: `Billing.Funding.FundingData` is an XML column. BIN data is extracted via `.value('Funding[1]/BinCodeAsString[1]','INT')` and `.value('Funding[1]/BinCountryIDAsInteger[1]','INT')`. This is a typed XML query - performance depends on the XML index on Billing.Funding.

**NOLOCK on most reads**: Most JOINs use `WITH(NOLOCK)` except `Billing.Depot AS BD` in Check 4 regulation sub-check (missing hint). This is a diagnostic read-only procedure so NOLOCK is appropriate.

**Typo in discrepancy text**: The Priority check discrepancy message reads `'Quota beyound 100%'` (misspelled "beyond"). This is preserved verbatim in the production code and result set.

**Schema migration comment**: The last line `-- [BackOffice].[CreditCardRoutingTransactionsVerification]` suggests the procedure was originally in BackOffice schema and moved to Billing.

---

## 8. Sample Queries

### 8.1 Run with default threshold (check if any routing issues in last hour)

```sql
EXEC Billing.CreditCardRoutingTransactionsVerification
-- @Threshold defaults to 100
-- Returns discrepancies; 0 rows = routing looks correct
```

### 8.2 Run with stricter threshold (flag Priority routing when quota >80% full)

```sql
EXEC Billing.CreditCardRoutingTransactionsVerification @Threshold = 80
-- Returns Priority-routed deposits as discrepancies if no provider is >80% quota
```

### 8.3 Check current CC routing reason distribution (last 24h)

```sql
SELECT
    RR.RoutingReason,
    D.RoutingReasonID,
    COUNT(D.DepositID) AS DepositCount
FROM Billing.Deposit D WITH(NOLOCK)
JOIN Billing.RoutingReason RR WITH(NOLOCK) ON RR.RoutingReasonID = D.RoutingReasonID
WHERE D.PaymentStatusID IN (2,3,4)
  AND D.PaymentDate >= DATEADD(hh,-24,GETUTCDATE())
  AND D.DepotID IN (
      SELECT DepotID FROM Billing.Depot WITH(NOLOCK)
      WHERE FundingTypeID = 1 AND IsActive = 1
  )
GROUP BY RR.RoutingReason, D.RoutingReasonID
ORDER BY DepositCount DESC
```

### 8.4 Check current quota status (inputs to Check 2)

```sql
SELECT
    DP.Name AS Processor,
    MQ.Amount AS ProcessedAmount,
    BQM.QuotaMin,
    CAST((MQ.Amount / BQM.QuotaMin) * 100 AS DECIMAL(10,2)) AS CompletePercentage
FROM Billing.MonthlyQuota MQ WITH(NOLOCK)
JOIN Dictionary.Protocol DP WITH(NOLOCK) ON DP.ProtocolID = MQ.ProtocolID
JOIN Billing.QuotaManagement BQM WITH(NOLOCK) ON BQM.ProtocolID = MQ.ProtocolID
WHERE MQ.[Year] = YEAR(GETUTCDATE())
  AND MQ.[Month] = MONTH(GETUTCDATE())
ORDER BY CompletePercentage DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CreditCardRoutingTransactionsVerification | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CreditCardRoutingTransactionsVerification.sql*
