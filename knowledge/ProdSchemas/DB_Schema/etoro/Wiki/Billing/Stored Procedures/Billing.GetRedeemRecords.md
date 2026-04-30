# Billing.GetRedeemRecords

> Flexible admin/backoffice report returning redemption records enriched with customer profile data (country, player level, status), live position P&L, and net payout amount; all parameters are optional, enabling full-table or filtered queries by status, date range, or customer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Optional @Cid / @RedeemStatus / date range filters; returns one row per matched Billing.Redeem record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemRecords` is the primary backoffice reporting and operations procedure for crypto redemptions. Operators and the redemption management UI use it to view lists of redemption requests filtered by status, date window, and/or customer, with all relevant context attached: the customer's country and tier, the regulation they operate under, the current position value (if still open), the net payout amount, and all fee components.

The procedure was progressively extended over multiple releases (Ran Ovadia Nov 2018, Avraham Lahmi Feb 2019 added live P&L, Oleg S. Sep 2020 added net payout amount, Alexei Jun 2022 PTL-76 added RedeemTypeID NFT support, Yehuda Jul 2022 added country/level/status enrichment). It now serves as a comprehensive single-query source for the redemption management screens.

Data flow: called with optional filters; when all parameters are NULL the procedure returns all redemptions (unfiltered). The `OPTION (RECOMPILE)` hint forces a fresh execution plan on each call to avoid plan cache pollution from the ISNULL-based optional filter pattern. Note: `RedeemTypeID` appears twice in the SELECT list (lines 36 and 49) - this is a DDL anomaly; both columns return the same value.

---

## 2. Business Logic

### 2.1 Optional Filter Pattern

**What**: All four parameters are optional; any combination can be specified to narrow the result set.

**Columns/Parameters Involved**: `@RedeemStatus`, `@FromDate`, `@TillDate`, `@Cid`, `RedeemStatusID`, `LastModificationDate`, `CID`

**Rules**:
- `WHERE RedeemStatusID = ISNULL(@RedeemStatus, RedeemStatusID)` - when @RedeemStatus is NULL, the condition is always true (all statuses returned)
- `AND BR.CID = ISNULL(@Cid, BR.CID)` - when @Cid is NULL, all customers returned
- `AND LastModificationDate BETWEEN ISNULL(@FromDate, LastModificationDate) AND ISNULL(@TillDate, LastModificationDate)` - when both dates are NULL, the condition collapses to `LastModificationDate BETWEEN LastModificationDate AND LastModificationDate` (always true); partial date specification (only @FromDate or only @TillDate) narrows on one side
- `OPTION (RECOMPILE)` prevents plan caching; forces recompilation each time to generate an optimal plan for the actual parameter values provided

### 2.2 Live Position Value Enrichment

**What**: For redemptions where the position is still open, the current market value is calculated and combined with the original request amount to give the "PositionCurrentValue".

**Columns/Parameters Involved**: `PositionCurrentValue`, `Trade.PositionForExternalUseWithPnL`, `BR.AmountOnRequest`

**Rules**:
- `LEFT JOIN Trade.PositionForExternalUseWithPnL Gp ON Gp.PositionID = BR.PositionID` - LEFT JOIN means rows with no open position (already closed) will have NULL Gp.PnLInDollars
- `PositionCurrentValue = BR.AmountOnRequest + CAST(Gp.PnLInDollars AS DECIMAL(16,2))`
- For closed positions (AmountOnClose IS NOT NULL), `Gp.PnLInDollars` is likely 0 or NULL (the position is no longer in the live view); PositionCurrentValue reflects the pre-close snapshot
- The view `Trade.PositionForExternalUseWithPnL` provides the real-time P&L denominated in USD

### 2.3 Customer Profile Enrichment

**What**: Customer country, tier, and account status are joined from multiple tables for operator context.

**Columns/Parameters Involved**: `Country`, `CustomerLevel`, `CustomerStatus`, `RegulationID`

**Rules**:
- `RegulationID` from `BackOffice.Customer` - the regulatory framework for this customer (ESMA, FCA, ASIC, etc.)
- `CustomerStatus` from `Dictionary.PlayerStatus` via `Customer.Customer.PlayerStatusID` - e.g., Active, Suspended
- `CustomerLevel` from `Dictionary.PlayerLevel` via `Customer.Customer.PlayerLevelID` - VIP tier name (Bronze, Silver, etc.)
- `Country` from `Dictionary.Country` via `Customer.Customer.CountryID` - customer's country of registration
- All these joins are LEFT OUTER - if customer profile data is missing, the row is still returned with NULLs for these enrichment columns

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemStatus | INT | YES | NULL | CODE-BACKED | Filter by redemption status. NULL = all statuses. Maps to `Billing.Redeem.RedeemStatusID`. See `Billing.Redeem` Section 2.1 for state values (e.g., 1=PositionPending, 8=TransactionDone). |
| 2 | @FromDate | DATETIME | YES | NULL | CODE-BACKED | Start of date window (inclusive). Filters `Billing.Redeem.LastModificationDate >= @FromDate`. NULL = no lower bound. |
| 3 | @TillDate | DATETIME | YES | NULL | CODE-BACKED | End of date window (inclusive). Filters `Billing.Redeem.LastModificationDate <= @TillDate`. NULL = no upper bound. |
| 4 | @Cid | INT | YES | NULL | CODE-BACKED | Filter to a specific customer. NULL = all customers. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | RedeemID | INT | NO | - | CODE-BACKED | PK of the redemption request. |
| 6 | OperationID | INT | YES | - | CODE-BACKED | Trading/balance operation ID linked to this redemption for cross-system reconciliation. |
| 7 | RedeemTypeID | INT | YES | - | CODE-BACKED | Redemption type: 0=standard crypto, 1=NFT/special. From `Billing.Redeem.RedeemTypeID`. Note: appears twice in the SELECT list (DDL anomaly) - both instances return the same value. |
| 8 | RedeemStatusID | INT | YES | - | CODE-BACKED | Current redemption lifecycle state. See `Billing.Redeem` Section 2.1 for full state machine (100=New, 1=PositionPending, 8=TransactionDone, 20=Terminated). |
| 9 | RedeemReasonID | INT | YES | - | CODE-BACKED | Termination/rejection reason code. NULL for active redemptions; populated when a redemption fails or is cancelled. FK to `Dictionary.RedeemReason`. |
| 10 | Units | DECIMAL | YES | - | CODE-BACKED | Crypto units being redeemed. |
| 11 | AmountOnRequest | DECIMAL | YES | - | CODE-BACKED | USD value of the position at request submission time. |
| 12 | AmountOnClose | DECIMAL | YES | - | CODE-BACKED | USD value of the position at trade close time. NULL until position is closed. |
| 13 | WalletFee | DECIMAL | YES | - | CODE-BACKED | Blockchain network fee charged for the crypto transfer (gas fee / network fee). |
| 14 | RedeemFee | DECIMAL | YES | - | CODE-BACKED | eToro redemption fee in crypto units (percentage of position, subject to min/max caps per `Billing.RedeemFeeSettings`). |
| 15 | BlockchainFee | DECIMAL | YES | - | CODE-BACKED | Additional blockchain processing fee component. Related to WalletFee for on-chain transfer costs. |
| 16 | PositionID | INT | YES | - | CODE-BACKED | Trading position being redeemed. FK to `Trade.PositionTbl`. |
| 17 | CID | INT | NO | - | CODE-BACKED | Customer identifier. |
| 18 | InstrumentID | INT | YES | - | CODE-BACKED | Crypto instrument (e.g., Bitcoin, Ethereum). FK to `Trade.Instrument`. |
| 19 | CryptoID | INT | YES | - | CODE-BACKED | Internal crypto asset identifier. May differ from InstrumentID when an instrument maps to a specific crypto ledger entry. |
| 20 | FundingID | INT | YES | - | CODE-BACKED | Payment instrument selected to receive the redemption proceeds. FK to `Billing.Funding`. |
| 21 | RequestDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp when the customer submitted the redemption request. |
| 22 | LastModificationDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of the most recent status change to this redemption record. Used as the date filter target. |
| 23 | WithdrawToFundingID | INT | YES | - | CODE-BACKED | FK to `Billing.WithdrawToFunding` - the payment execution leg. NULL until payout is initiated. |
| 24 | ManagerOpsID | INT | YES | - | CODE-BACKED | Operations manager who acted on this redemption (e.g., approved, terminated). 0 = automated. |
| 25 | ManagerID | INT | YES | - | CODE-BACKED | Manager ID at the point of last modification (may differ from ManagerOpsID). |
| 26 | Remark | NVARCHAR | YES | - | CODE-BACKED | Free-text operator notes attached to the redemption record. |
| 27 | RegulationID | INT | YES | - | CODE-BACKED | Regulatory framework for this customer (from `BackOffice.Customer`). Determines which rules apply (ESMA, FCA, ASIC, etc.). |
| 28 | PositionCurrentValue | DECIMAL | YES | - | CODE-BACKED | Estimated current USD value of the position: `AmountOnRequest + Gp.PnLInDollars`. For open positions, uses real-time P&L from `Trade.PositionForExternalUseWithPnL`. NULL when position is not in the live view. |
| 29 | NetAmount | DECIMAL | YES | - | CODE-BACKED | Net payout amount from `Billing.WithdrawToFunding.Amount`. The actual USD amount sent to the customer's payment instrument after fees. NULL when no payout leg exists yet. |
| 30 | CustomerStatus | NVARCHAR | YES | - | CODE-BACKED | Human-readable account status label from `Dictionary.PlayerStatus` (e.g., "Active", "Suspended"). |
| 31 | CustomerLevel | NVARCHAR | YES | - | CODE-BACKED | Human-readable VIP tier name from `Dictionary.PlayerLevel` (e.g., "Bronze", "Silver", "Platinum"). |
| 32 | Country | NVARCHAR | YES | - | CODE-BACKED | Customer's country of registration name from `Dictionary.Country`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemID | Billing.Redeem | SELECT (primary source) | All redemption fields |
| PositionID | Trade.PositionForExternalUseWithPnL | LEFT JOIN | Live P&L for open positions |
| CID | BackOffice.Customer | INNER JOIN | RegulationID |
| CID | Customer.Customer | INNER JOIN | PlayerLevelID, PlayerStatusID, CountryID for enrichment |
| WithdrawToFundingID | Billing.WithdrawToFunding | LEFT OUTER JOIN | Net payout amount |
| PlayerLevelID | Dictionary.PlayerLevel | LEFT OUTER JOIN | Tier name (CustomerLevel) |
| PlayerStatusID | Dictionary.PlayerStatus | LEFT OUTER JOIN | Status name (CustomerStatus) |
| CountryID | Dictionary.Country | LEFT OUTER JOIN | Country name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice redemption management UI | various filters | EXEC | Primary data source for admin redemption list views |
| Operations staff | various filters | EXEC | Ad-hoc redemption status queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemRecords (procedure)
├── Billing.Redeem (table)
├── Trade.PositionForExternalUseWithPnL (view, cross-schema)
├── BackOffice.Customer (table, cross-schema)
├── Customer.Customer (table, cross-schema)
├── Billing.WithdrawToFunding (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.PlayerStatus (table)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Primary source of all redemption fields |
| Trade.PositionForExternalUseWithPnL | View | LEFT JOIN for live position P&L |
| BackOffice.Customer | Table | INNER JOIN for RegulationID |
| Customer.Customer | Table | INNER JOIN for player level/status/country IDs |
| Billing.WithdrawToFunding | Table | LEFT JOIN for net payout amount |
| Dictionary.PlayerLevel | Table | LEFT JOIN for tier label |
| Dictionary.PlayerStatus | Table | LEFT JOIN for status label |
| Dictionary.Country | Table | LEFT JOIN for country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice redemption UI / operations tooling | External | Primary reporting data source |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Performance | Forces recompilation on each call; necessary because ISNULL-based optional parameters cause parameter sniffing issues and suboptimal cached plans |
| Duplicate RedeemTypeID | DDL anomaly | RedeemTypeID appears twice in the SELECT list (positions 7 and after NetAmount); both return identical values. Caller should use the first instance. |
| NOLOCK on all tables | Concurrency | All table reads use NOLOCK; acceptable for reporting queries where minor staleness is tolerable |

---

## 8. Sample Queries

### 8.1 Get all in-process redemptions (PositionPending)
```sql
EXEC Billing.GetRedeemRecords @RedeemStatus = 1;
```

### 8.2 Get all redemptions for a specific customer in a date range
```sql
EXEC Billing.GetRedeemRecords
    @Cid = 12345678,
    @FromDate = '2026-01-01',
    @TillDate = '2026-03-18';
```

### 8.3 Get all redemptions in a date window regardless of status
```sql
EXEC Billing.GetRedeemRecords
    @FromDate = '2026-03-01 00:00:00',
    @TillDate = '2026-03-18 23:59:59';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PTL-76 (referenced in DDL comment, Alexei, 30/06/2022) | Jira | Added RedeemTypeID (NFT support) to the result set (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemRecords.sql*
