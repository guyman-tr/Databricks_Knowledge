# Billing.GetRedeemRecordsDynamic

> Enhanced version of GetRedeemRecords (Nov 2025): supports filtering by multiple redemption status IDs via a table-valued parameter and lookup by RedeemID, while using a temp table for improved query plan quality. Returns core redemption and position data without the customer profile enrichment of the original procedure.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemStatuses (TVP filter) + optional @RedeemId/@Cid/date range; returns one row per matched Billing.Redeem record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemRecordsDynamic` is the programmatic successor to `Billing.GetRedeemRecords`, designed for richer and more flexible querying of the redemption records table. It was created on 11 Nov 2025 to address two limitations of the original: (a) the original only supports filtering by a single status ID, making it impossible to query "all pending or approved redemptions" in one call, and (b) the original lacks a direct RedeemID lookup parameter.

The procedure is leaner than `GetRedeemRecords` - it deliberately omits the customer profile enrichment (Country, CustomerLevel, CustomerStatus, RegulationID) and BackOffice/Customer schema joins. This makes it suitable for programmatic, API-driven use cases where only redemption and position data are needed, not the operator-display fields.

A performance optimization was applied on 02 Apr 2026: the TVP `@RedeemStatuses` is immediately copied into a temp table `#RedeemStatuses` before the main query. This works around a known SQL Server limitation where table-valued parameters cannot have statistics, causing the optimizer to generate suboptimal plans when they appear directly in JOIN/IN conditions.

Data flow: the caller provides an `[dbo].[IdList]` TVP containing the status IDs to filter on (empty = no status filter), plus optional date range, customer, and RedeemID filters. The procedure returns redemption records joined with live P&L from `Trade.PositionForExternalUseWithPnL` and net payout amount from `Billing.WithdrawToFunding`.

---

## 2. Business Logic

### 2.1 Multi-Status TVP Filter

**What**: Unlike `GetRedeemRecords` (single status), this procedure accepts a list of status IDs and returns records matching any of them. Empty list = no status filter.

**Columns/Parameters Involved**: `@RedeemStatuses`, `#RedeemStatuses`, `BR.RedeemStatusID`

**Rules**:
- `@RedeemStatuses` is of type `[dbo].[IdList]` (a user-defined table type) - the caller passes a table of INT IDs
- The TVP is immediately copied to `#RedeemStatuses` for better query plan quality
- Filter condition: `NOT EXISTS(SELECT 1 FROM #RedeemStatuses) OR BR.RedeemStatusID IN (SELECT r.* FROM #RedeemStatuses r)`
  - When the TVP is empty (0 rows): `NOT EXISTS` is TRUE -> no status filter applied, all statuses returned
  - When the TVP has rows: `NOT EXISTS` is FALSE -> only records with RedeemStatusID in the list are returned
- This enables querying e.g., "all New(100), PositionPending(1), and Approved(3) redemptions" in a single call

### 2.2 Additional @RedeemId Parameter

**What**: Allows direct single-record lookup by RedeemID, complementing the date/status/customer filters.

**Columns/Parameters Involved**: `@RedeemId`, `BR.RedeemID`

**Rules**:
- `AND BR.RedeemID = ISNULL(@RedeemId, BR.RedeemID)` - when @RedeemId is NULL, condition is always true
- When @RedeemId is provided, returns at most one row (as RedeemID is the PK of Billing.Redeem)
- Can be combined with other filters (e.g., @RedeemId + @Cid for a verified single-record lookup)

### 2.3 Leaner Result Set vs. GetRedeemRecords

**What**: This procedure omits the customer profile enrichment columns present in GetRedeemRecords.

**Rules**:
- NOT included: `RegulationID` (from BackOffice.Customer), `CustomerStatus` (Dictionary.PlayerStatus), `CustomerLevel` (Dictionary.PlayerLevel), `Country` (Dictionary.Country)
- NOT joined: `BackOffice.Customer`, `Customer.Customer`, `Dictionary.PlayerLevel`, `Dictionary.PlayerStatus`, `Dictionary.Country`
- This makes the procedure faster and simpler for programmatic/API callers that don't need operator display data
- Use `Billing.GetRedeemRecords` when customer profile context is needed

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemStatuses | [dbo].[IdList] READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the set of `RedeemStatusID` values to filter on. Pass an empty table to return all statuses. Pass rows with RedeemStatusID values (e.g., 1, 3, 100) to filter to those states. Type `[dbo].[IdList]` is a UDT with a single INT column. |
| 2 | @FromDate | DATETIME | YES | NULL | CODE-BACKED | Lower bound for `Billing.Redeem.LastModificationDate` (inclusive). NULL = no lower bound. |
| 3 | @TillDate | DATETIME | YES | NULL | CODE-BACKED | Upper bound for `Billing.Redeem.LastModificationDate` (inclusive). NULL = no upper bound. |
| 4 | @Cid | INT | YES | NULL | CODE-BACKED | Filter to a specific customer. NULL = all customers. |
| 5 | @RedeemId | INT | YES | NULL | CODE-BACKED | Filter to a specific redemption record by PK. NULL = all records. When provided, returns at most one row. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | RedeemID | INT | NO | - | CODE-BACKED | PK of the redemption request in `Billing.Redeem`. |
| 7 | OperationID | INT | YES | - | CODE-BACKED | Trading/balance operation ID for cross-system reconciliation. |
| 8 | RedeemTypeID | INT | YES | - | CODE-BACKED | Redemption type: 0=standard, 1=NFT/special. Note: appears twice in the SELECT list (DDL anomaly inherited from GetRedeemRecords); both instances return the same value. |
| 9 | RedeemStatusID | INT | YES | - | CODE-BACKED | Current redemption lifecycle state. See `Billing.Redeem` Section 2.1 for state machine (100=New, 1=PositionPending, 8=TransactionDone, 20=Terminated). |
| 10 | RedeemReasonID | INT | YES | - | CODE-BACKED | Termination/rejection reason. NULL for active redemptions. FK to `Dictionary.RedeemReason`. |
| 11 | Units | DECIMAL | YES | - | CODE-BACKED | Crypto units being redeemed. |
| 12 | AmountOnRequest | DECIMAL | YES | - | CODE-BACKED | USD position value at request submission. |
| 13 | AmountOnClose | DECIMAL | YES | - | CODE-BACKED | USD position value at trade close. NULL until position closes. |
| 14 | WalletFee | DECIMAL | YES | - | CODE-BACKED | Blockchain network/gas fee for the crypto transfer. |
| 15 | RedeemFee | DECIMAL | YES | - | CODE-BACKED | eToro redemption fee in crypto units. |
| 16 | BlockchainFee | DECIMAL | YES | - | CODE-BACKED | Additional blockchain processing fee component. |
| 17 | PositionID | INT | YES | - | CODE-BACKED | Trading position being redeemed. FK to `Trade.PositionTbl`. |
| 18 | CID | INT | NO | - | CODE-BACKED | Customer identifier. |
| 19 | InstrumentID | INT | YES | - | CODE-BACKED | Crypto instrument. FK to `Trade.Instrument`. |
| 20 | CryptoID | INT | YES | - | CODE-BACKED | Internal crypto asset ledger identifier. |
| 21 | FundingID | INT | YES | - | CODE-BACKED | Destination payment instrument for proceeds. FK to `Billing.Funding`. |
| 22 | RequestDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of redemption request submission. |
| 23 | LastModificationDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of last status change. |
| 24 | WithdrawToFundingID | INT | YES | - | CODE-BACKED | FK to `Billing.WithdrawToFunding` payment leg. NULL until payout is initiated. |
| 25 | ManagerOpsID | INT | YES | - | CODE-BACKED | Operations manager who acted on this redemption. 0 = automated. |
| 26 | ManagerID | INT | YES | - | CODE-BACKED | Manager ID at last modification. |
| 27 | Remark | NVARCHAR | YES | - | CODE-BACKED | Free-text operator notes. |
| 28 | PositionCurrentValue | DECIMAL | YES | - | CODE-BACKED | Live estimated USD value: `AmountOnRequest + Gp.PnLInDollars` from `Trade.PositionForExternalUseWithPnL`. NULL when position is no longer in the live view. |
| 29 | NetAmount | DECIMAL | YES | - | CODE-BACKED | Net payout amount from `Billing.WithdrawToFunding.Amount`. NULL when no payment leg exists yet. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemStatuses | [dbo].[IdList] | TVP type | User-defined table type for the status filter |
| RedeemID | Billing.Redeem | SELECT (primary source) | Core redemption fields |
| PositionID | Trade.PositionForExternalUseWithPnL | LEFT JOIN | Live P&L for open positions |
| WithdrawToFundingID | Billing.WithdrawToFunding | LEFT OUTER JOIN | Net payout amount |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application APIs / programmatic callers | @RedeemStatuses | EXEC | Multi-status queries for redemption management and monitoring services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemRecordsDynamic (procedure)
├── [dbo].[IdList] (user defined type)
├── Billing.Redeem (table)
├── Trade.PositionForExternalUseWithPnL (view, cross-schema)
└── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [dbo].[IdList] | User Defined Type | TVP type for @RedeemStatuses parameter |
| Billing.Redeem | Table | Primary source of redemption fields |
| Trade.PositionForExternalUseWithPnL | View | LEFT JOIN for live position P&L |
| Billing.WithdrawToFunding | Table | LEFT OUTER JOIN for net payout amount |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application redemption APIs | External | Multi-status redemption queries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TVP to temp table copy | Performance | @RedeemStatuses is copied to #RedeemStatuses before the main query (Apr 2026 optimization) to give the optimizer statistics on the status filter set |
| Empty TVP = no filter | Design | `NOT EXISTS(SELECT 1 FROM #RedeemStatuses)` makes an empty status list equivalent to "all statuses" - caller must pass at least one status to actually filter |
| Duplicate RedeemTypeID | DDL anomaly | RedeemTypeID appears twice in SELECT; inherited from GetRedeemRecords DDL pattern |
| NOLOCK on all tables | Concurrency | All table reads use NOLOCK |

---

## 8. Sample Queries

### 8.1 Get all New and PositionPending redemptions
```sql
DECLARE @statuses [dbo].[IdList];
INSERT INTO @statuses VALUES (100), (1);  -- New=100, PositionPending=1
EXEC Billing.GetRedeemRecordsDynamic @RedeemStatuses = @statuses;
```

### 8.2 Look up a specific redemption by ID
```sql
DECLARE @statuses [dbo].[IdList];  -- empty = no status filter
EXEC Billing.GetRedeemRecordsDynamic
    @RedeemStatuses = @statuses,
    @RedeemId = 500001;
```

### 8.3 Get all completed redemptions in a date range
```sql
DECLARE @statuses [dbo].[IdList];
INSERT INTO @statuses VALUES (8);  -- TransactionDone
EXEC Billing.GetRedeemRecordsDynamic
    @RedeemStatuses = @statuses,
    @FromDate = '2026-03-01',
    @TillDate = '2026-03-18';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemRecordsDynamic | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemRecordsDynamic.sql*
