# History.ActiveCredit

> Canonical read interface for the complete financial event ledger - a direct wrapper over History.ActiveCredit_BIGINT exposing every credit/debit transaction for every eToro customer account.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CreditID (bigint) from base table History.ActiveCredit_BIGINT |
| **Partition** | N/A (view inherits partitioned storage of base table) |
| **Indexes** | N/A (view - queries use base table indexes) |

---

## 1. Business Meaning

History.ActiveCredit is the **standard query interface** for eToro's complete financial event ledger. It is a simple SELECT wrapper over `History.ActiveCredit_BIGINT`, exposing all 35 columns without filtering or transformation. Any code that needs to read credit history - back-office statements, billing reports, TAPI credit history endpoints, interest calculations, compliance queries - does so through this view rather than querying the underlying partitioned table directly.

Without this view, every consumer would need to know the current physical table name (`ActiveCredit_BIGINT`). The view decouples the query interface from the storage implementation - when eToro migrated from int-keyed to bigint-keyed storage, only this view definition needed to change, not every downstream procedure. The commented-out UNION ALL block (which would have merged `History.ActiveCredit_INT` for records before April 2021) is evidence of this: the migration was completed by removing the INT source, leaving only the BIGINT table active.

Reads from this view hit the underlying `History.ActiveCredit_BIGINT` table which has 7 active indexes - the clustered index on (CID, Occurred DESC) serves most per-customer queries, the DWH covering index (`i_nc_covering_dwh_BIGINT`) serves extract pipelines, and filtered indexes support WithdrawID and CreditTypeID lookups. Consumers of this view benefit from all of these without needing to reference the physical table directly.

---

## 2. Business Logic

### 2.1 Active Source: BIGINT Only

**What**: The view currently reads exclusively from the BIGINT-keyed table; the INT predecessor is fully decommissioned.

**Columns/Parameters Involved**: (all columns, via base table selection)

**Rules**:
- All 35 output columns are direct pass-throughs from `History.ActiveCredit_BIGINT` - no transformations, no filters, no derived columns
- The commented-out UNION ALL block (`History.ActiveCredit_INT WHERE Occurred >= '20210401'`) was the transitional bridge during the int-to-bigint migration; it is now fully deactivated
- CreditID values are bigint throughout - consumers can rely on this data type without coalescing logic

**Diagram**:
```
History.ActiveCredit (view - this object)
    |
    v  SELECT all 35 columns, no filter
History.ActiveCredit_BIGINT (table - 7 active indexes, 10 partitions)

[DECOMMISSIONED - commented out]
-- UNION ALL
-- History.ActiveCredit_INT (WHERE Occurred >= '20210401')
```

### 2.2 Role in the Credit Abstraction Layer

**What**: This view sits at the center of a multi-view credit access hierarchy. Four other History views build on top of it.

**Columns/Parameters Involved**: CreditID, CID, CreditTypeID, Credit, TotalCash, MirrorCash

**Rules**:
- History.ActiveCreditBucket_VW, History.ActiveCreditSafty, History.ActiveCreditView, and History.Credit all reference History.ActiveCredit as their base - not the underlying table directly
- This makes History.ActiveCredit the single chokepoint for all credit history access in the History schema: change this view, and all downstream views and their procedure consumers are affected
- Procedures from Billing, BackOffice, SalesForce, Trade, Customer, Maintenance, Monitor, and dbo schemas all consume credit data through this abstraction layer

---

## 3. Data Overview

Sample from the view (SELECT TOP 5 ... ORDER BY CreditID DESC - live as of 2026-03-21):

| CreditID | CID | CreditTypeID | Credit | Payment | Occurred | Meaning |
|---|---|---|---|---|---|---|
| 2174752045 | 24860041 | 1 (Deposit) | 400 | 100 | 2026-03-21 | A $100 deposit credited to this customer's account. Credit shows the new running balance ($400), Payment shows the inflow amount ($100). The account has prior balance of $300. |
| 2174752044 | 25006152 | 1 (Deposit) | 300 | 100 | 2026-03-21 | Another $100 deposit to a different customer. New balance is $300. SubCreditTypeID is NULL indicating a standard deposit with no sub-classification. |
| 2174752043 | 24996684 | 1 (Deposit) | 300 | 100 | 2026-03-21 | Standard deposit event; balance reaches $300. PositionID is NULL confirming this is a deposit type (not position-related). |
| 2174752042 | 24860384 | 1 (Deposit) | 400 | 100 | 2026-03-21 | Deposit to a customer whose balance reaches $400. Multiple deposit events for the same CID appear as separate rows, each updating the running Credit total. |
| 2174752041 | 25158719 | 3 (Open Position) | 232.93 | -20.19 | 2026-03-21 | A position opened for $20.19. Payment is negative (funds reserved for position margin). Credit drops accordingly. PositionID 2152976745 identifies the specific trading position. |

---

## 4. Elements

All 35 columns are direct pass-throughs from `History.ActiveCredit_BIGINT`. Column descriptions are inherited from the base table doc.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | VERIFIED | Unique identifier for this credit event. bigint to support the very large volumes accumulated over the platform's lifetime. Used as the partition key basis (PartitionCol = CreditID % 10) in the underlying table. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID - the eToro customer whose account this credit event belongs to. The underlying table's clustered index leads with CID to optimise per-customer balance history queries. |
| 3 | CreditTypeID | tinyint | NO | - | VERIFIED | Classification of the financial event. 33 defined types covering the full lifecycle: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 10=IB synchronization, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End Of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close, 23=Hierarchical Open position, 24=Close by recovery, 25=Open by recovery, 26=FixBonusCreditRealizedEquity, 27=Detach position from mirror, 28=Detach Stock From Mirror, 29=Open Stock Order, 30=Close Stock Order, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Source: Dictionary.CreditType) |
| 4 | PositionID | bigint | YES | - | CODE-BACKED | Linked trade position for position-related credit types (3, 4, 13, 22-25, 27, 28). NULL for non-position events (deposits, cashouts, bonuses). |
| 5 | ChampionshipID | int | YES | - | CODE-BACKED | Linked championship game for type 5 (Champ Winner). Identifies which championship competition awarded this prize. NULL for non-championship events. |
| 6 | CashoutID | int | YES | - | CODE-BACKED | Linked cashout transaction for cashout-related types (2=Cashout, 8=Reverse cashout, 33=Cashout Rollback). Ties the credit event to the Billing cashout record. NULL otherwise. |
| 7 | PaymentID | int | YES | - | CODE-BACKED | Linked payment/billing transaction for payment-related types (9=Cashout request, 11=Chargeback, 12=Refund, 15=Cashout Fee, 16=Refund As ChargeBack). NULL for non-payment events. |
| 8 | WithdrawID | int | YES | - | CODE-BACKED | Linked withdrawal record for withdrawal-based types (2=Cashout, 9=Cashout request, 15=Cashout Fee). The underlying table has a filtered index on WHERE WithdrawID IS NOT NULL for efficient cashout lookup. |
| 9 | DepositID | int | YES | - | CODE-BACKED | Linked deposit transaction for deposit-related types (1=Deposit, 12=Refund, 32=Reverse Deposit). Ties the credit event to the Billing deposit record. |
| 10 | UpdateID | int | YES | - | NAME-INFERRED | Reference to a generic update operation that triggered this credit event. No dedicated lookup table found in Dictionary schema. |
| 11 | CampaignID | int | YES | - | CODE-BACKED | Linked marketing campaign for bonus-related types (7=Bonus). Identifies the promotion or campaign that awarded the bonus credit. NULL for non-campaign events. |
| 12 | BonusTypeID | int | YES | - | CODE-BACKED | Bonus classification for type 7 (Bonus) events. Values managed in the application layer. NULL for non-bonus events. |
| 13 | CompensationReasonID | int | YES | - | CODE-BACKED | Reason code for compensation events (type 6=Compensation). Identifies why manual compensation was granted (e.g., technical error, goodwill). NULL for non-compensation events. |
| 14 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager or agent who authorised or processed this credit event (primarily for type 6=Compensation and manual operations). NULL for system-generated events. |
| 15 | Credit | money | NO | - | VERIFIED | Customer's total credit balance after this event (running total). Represents the new account balance in monetary units. |
| 16 | Payment | money | NO | - | VERIFIED | Signed amount of this transaction: positive for inflows (deposits, bonuses, position profits), negative for outflows (cashouts, fees, position losses). Payment = new Credit - previous Credit. |
| 17 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text description of the credit event. Often empty for system-generated events. Used for manual entries or compensation notes. |
| 18 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this credit event occurred. The underlying clustered index sorts by (CID, Occurred DESC) to optimise per-customer recency queries. |
| 19 | WithdrawProcessingID | int | YES | - | CODE-BACKED | Links to the withdraw processing batch that generated this cashout-related credit event. Part of the DWH covering index key columns for extract pipelines. |
| 20 | MirrorID | int | NO | 0 | CODE-BACKED | Linked mirror (copy-trade portfolio) for mirror-related types (18-23, 27-28). Default = 0 (no mirror). Non-zero links to a specific copy-trade portfolio. |
| 21 | TotalCash | money | YES | - | CODE-BACKED | Total liquid cash component of the customer's account after this event. Distinct from BonusCredit (non-withdrawable) and MirrorCash (allocated to copy trades). NULL for older records. |
| 22 | TotalCashChange | money | YES | - | CODE-BACKED | Delta of the TotalCash component caused by this event. Covered in multiple underlying table indexes for reporting queries. NULL if not tracked for this event type. |
| 23 | BonusCredit | money | YES | - | CODE-BACKED | Non-withdrawable bonus money portion of the Credit balance at this point. NULL if no bonus component exists. Bonuses are typically time-limited and subject to trading conditions before conversion to real credit. |
| 24 | RealizedEquity | money | YES | - | CODE-BACKED | Equity realised from closed positions at this point. NULL for event types that do not affect realised equity. |
| 25 | MirrorCash | dbo.dtPrice | YES | - | CODE-BACKED | Cash allocated to mirror/copy-trade strategies at this point. Uses the dbo.dtPrice user-defined type (decimal precision for prices). NULL if no mirror allocation. |
| 26 | StocksOrderID | int | YES | - | CODE-BACKED | Linked stock order for stock-related credit types (29=Open Stock Order, 30=Close Stock Order, 28=Detach Stock From Mirror). NULL for non-stock events. |
| 27 | MirrorEquity | money | YES | - | CODE-BACKED | Open unrealised equity in the customer's mirror/copy-trade portfolios at this point. Complements MirrorCash for a full mirror portfolio valuation snapshot. |
| 28 | MirrorDividendID | int | YES | - | CODE-BACKED | Linked mirror dividend record for dividend-related credit events in copy-trade portfolios. NULL for non-dividend events. |
| 29 | MoveMoneyReasonID | int | YES | - | VERIFIED | Reason for internal money movement: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer. NULL for standard transactions. (Source: Dictionary.MoveMoneyReason) |
| 30 | BSLRealFunds | money | YES | - | CODE-BACKED | Balance Sheet Ledger real funds component at this point. Used for regulatory reporting. NULL for events where BSL tracking is not applicable. |
| 31 | PartitionCol | AS (CreditID%(10)) PERSISTED | NO | - | VERIFIED | Computed partition routing column from the underlying table: CreditID modulo 10 (0-9). Exposed here for partition-aligned queries when needed. |
| 32 | OriginalPositionID | bigint | YES | - | CODE-BACKED | Position ID before any reassignment or recovery operation. Used for recovery and data-fix credit types (24, 25, 31) where the original position may differ from the corrected PositionID. NULL for standard events. |
| 33 | SubCreditTypeID | int | YES | - | NAME-INFERRED | Sub-classification within a CreditTypeID. No Dictionary.SubCreditType table found. Likely managed at the application layer for fine-grained categorisation beyond the 33 main types. NULL in all observed live records. |
| 34 | DepositRollbackID | int | YES | - | CODE-BACKED | Links to the deposit being rolled back for type 32 (Reverse Deposit). NULL for all other event types. |
| 35 | InterestMonthlyID | bigint | YES | - | NAME-INFERRED | Reference to a monthly interest payment record. bigint key suggests a high-volume interest log table. NULL for non-interest events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.ActiveCredit_BIGINT | View | Simple wrapper - all data originates from the base table. No additional JOIN targets. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ActiveCreditBucket_VW | History.ActiveCredit | View (JOIN) | Filters to the rolling recent-memory bucket window |
| History.ActiveCreditSafty | History.ActiveCredit | View (JOIN) | Safety/monitoring filter over credit events |
| History.ActiveCreditView | History.ActiveCredit | View (JOIN) | Another filtered view of the credit ledger |
| History.Credit | History.ActiveCredit | View (JOIN) | Combines with legacy dbo.Credit_2007..2020 archive tables |
| Trade.InsertActiveCredit | (base table) | Writer (via base table) | Bulk-inserts from memory bucket into History.ActiveCredit_BIGINT |
| Trade.InsertActiveCreditPartition | (base table) | Writer (via base table) | Partition-targeted insert variant |
| Billing.* (multiple) | History.ActiveCredit | Reader | Billing reports, cashout/deposit queries |
| BackOffice.* (multiple) | History.ActiveCredit | Reader | Account statements, tax reports, customer history |
| Trade.TAPI_GetFlatCreditHistoryByCID* | History.ActiveCredit | Reader | Customer-facing credit history TAPI endpoints |
| Maintenance.JOB_InsertHistoryCreditExtended* | History.ActiveCredit | Reader | Scheduled job computing running totals for History.ActiveCreditExtended |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCredit (view)
└── History.ActiveCredit_BIGINT (table - leaf node)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit_BIGINT | Table | Sole data source - SELECT all 35 columns with no filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditBucket_VW | View | Reads from this view for recent-bucket window |
| History.ActiveCreditSafty | View | Reads from this view for safety monitoring |
| History.ActiveCreditView | View | Reads from this view for filtered credit access |
| History.Credit | View | Reads from this view as the BIGINT credit source |
| History.FindDetachedPositionsTest | Stored Procedure | Reader - diagnostic test for detached positions |
| History.ActiveCredit_CashoutRollbackSet | Stored Procedure | Reader/Modifier - cashout rollback operation |
| History.GetFaultedPIBonusFlow | Stored Procedure | Reader - identifies faulted bonus flow records |
| Billing.* (10+ procedures) | Stored Procedure | Reader - billing reports and cashout processing |
| BackOffice.* (10+ procedures) | Stored Procedure | Reader - account statements, customer history |
| Trade.TAPI_* (4 procedures) | Stored Procedure | Reader - TAPI credit history endpoints |
| Maintenance.JOB_InsertHistoryCreditExtended* | Stored Procedure | Reader - running total computation job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries against this view use the underlying `History.ActiveCredit_BIGINT` indexes. Key indexes available:
- CLUSTERED: (CID ASC, Occurred DESC, PartitionCol) - per-customer recency queries
- NC PK: (CreditID, PartitionCol) - direct CreditID lookups
- Filtered NC: (WithdrawID, CreditTypeID, PartitionCol) WHERE WithdrawID IS NOT NULL
- DWH Covering: (Occurred, WithdrawProcessingID) INCLUDE (CreditID, CID, CreditTypeID, PositionID, ...)

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get recent credit history for a customer
```sql
SELECT TOP 20
    ac.CreditID,
    ac.CreditTypeID,
    ac.Credit,
    ac.Payment,
    ac.TotalCash,
    ac.PositionID,
    ac.Occurred
FROM History.ActiveCredit ac WITH (NOLOCK)
WHERE ac.CID = 12345678
ORDER BY ac.Occurred DESC;
```

### 8.2 Get all deposit and cashout events for a customer with type labels
```sql
SELECT
    ac.CreditID,
    ct.Name     AS EventType,
    ac.Payment,
    ac.Credit,
    ac.Occurred
FROM History.ActiveCredit ac WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ac.CreditTypeID = ct.CreditTypeID
WHERE ac.CID = 12345678
  AND ac.CreditTypeID IN (1, 2, 8, 9, 15, 32, 33)  -- deposit/cashout family
ORDER BY ac.Occurred DESC;
```

### 8.3 Find credit events linked to a specific withdrawal
```sql
SELECT
    ac.CreditID,
    ac.CID,
    ac.CreditTypeID,
    ac.Credit,
    ac.Payment,
    ac.Occurred
FROM History.ActiveCredit ac WITH (NOLOCK)
WHERE ac.WithdrawID = 9876543
ORDER BY ac.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.ActiveCredit (view). Business context inherited from History.ActiveCredit_BIGINT documentation and code analysis across 99 referencing files.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.6/10, Logic: 8.0/10, Relationships: 9.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED (inherited from base table) | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 99 files analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ActiveCredit | Type: View | Source: etoro/etoro/History/Views/History.ActiveCredit.sql*
