# History.ActiveCredit_BIGINT

> Primary financial ledger storing every credit/debit event for every eToro customer account - the complete audit trail of deposits, cashouts, position opens/closes, bonuses, mirror operations, and stock orders.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint, NONCLUSTERED PK with PartitionCol) |
| **Partition** | Yes - PS_ActiveCredit scheme, 10 partitions on PartitionCol (CreditID % 10) |
| **Indexes** | 7 active (1 clustered on CID/Occurred, 1 NC PK, 5 covering NCs) |

---

## 1. Business Meaning

History.ActiveCredit_BIGINT is the central financial event ledger for eToro's trading platform. Every time money moves in or changes state for a customer account - a deposit, cashout request, position opening/closing, bonus award, championship prize, stock order, mirror registration, or compensation - a row is inserted here capturing the full financial snapshot at that moment.

Without this table, it would be impossible to reconstruct a customer's complete financial history, explain why a balance changed at any point in time, or satisfy regulatory audit requirements. It is the backbone of eToro's financial reporting, DWH pipelines (the `i_nc_covering_dwh_BIGINT` index is purpose-built for this), back-office billing views, and customer-facing account history.

Data does NOT flow directly into this table from application code. Records are first written to History.ActiveCreditRecentMemoryBucket (the staging buffer), then bulk-flushed into this table by Trade.InsertActiveCredit and Trade.InsertActiveCreditPartition. This two-stage insert pattern decouples the high-frequency write path (the memory bucket) from the slower partitioned archive (this table). The `_BIGINT` suffix distinguishes this table from the legacy int-keyed version; CreditID here is bigint to support the very large record volumes accumulated over time.

---

## 2. Business Logic

### 2.1 Credit Event Type Classification

**What**: CreditTypeID is the master classification of what financial event each row represents. It determines which linked ID columns are populated.

**Columns/Parameters Involved**: `CreditTypeID`, `PositionID`, `CashoutID`, `PaymentID`, `WithdrawID`, `DepositID`, `StocksOrderID`, `MirrorID`, `ChampionshipID`

**Rules**:
- Each CreditTypeID activates specific contextual FK columns and leaves others NULL
- Position-related types (3, 4, 22-25, 27, 29, 30) populate PositionID
- Cashout types (2, 9, 15) populate CashoutID or WithdrawID
- Deposit types (1, 32) populate DepositID
- Mirror types (18-22, 27) populate MirrorID
- Bonus/campaign types (7) populate BonusTypeID and CampaignID
- Compensation types (6) populate CompensationReasonID and ManagerID
- Stock types (29, 30) populate StocksOrderID

**Diagram**:
```
CreditTypeID -> Populated FK columns:
  1  = Deposit                      -> DepositID
  2  = Cashout                      -> CashoutID, WithdrawID
  3  = Open Position                -> PositionID
  4  = Close Position               -> PositionID
  5  = Champ Winner                 -> ChampionshipID
  6  = Compensation                 -> CompensationReasonID, ManagerID
  7  = Bonus                        -> BonusTypeID, CampaignID
  8  = Reverse cashout              -> CashoutID
  9  = Cashout request              -> WithdrawID, PaymentID
 10  = IB synchronization           -> (account sync)
 11  = Chargeback                   -> PaymentID
 12  = Refund                       -> PaymentID, DepositID
 13  = Edit Stop Loss               -> PositionID
 14  = End Of Week Fee              -> (periodic)
 15  = Cashout Fee                  -> WithdrawID, PaymentID
 16  = Refund As ChargeBack         -> PaymentID
 17  = FixHistoryCreditChargeBacks  -> (maintenance)
 18  = Account balance to mirror    -> MirrorID
 19  = Mirror balance to account    -> MirrorID
 20  = Register new mirror          -> MirrorID
 21  = Unregister mirror            -> MirrorID
 22  = Mirror Hierarchical Close    -> PositionID, MirrorID
 23  = Hierarchical Open position   -> PositionID, MirrorID
 24  = Close position by recovery   -> PositionID
 25  = Open position by recovery    -> PositionID
 26  = FixBonusCreditRealizedEquity -> (maintenance)
 27  = Detach position from mirror  -> PositionID, MirrorID
 28  = Detach Stock From Mirror     -> StocksOrderID, MirrorID
 29  = Open Stock Order             -> StocksOrderID
 30  = Close Stock Order            -> StocksOrderID
 31  = Data Fix                     -> (maintenance)
 32  = Reverse Deposit              -> DepositID
 33  = Cashout Rollback             -> CashoutID
```

### 2.2 Credit vs Payment Financial Fields

**What**: Credit and Payment together capture the financial state after each event - the new running balance and the transaction delta.

**Columns/Parameters Involved**: `Credit`, `Payment`, `TotalCash`, `TotalCashChange`, `BonusCredit`, `RealizedEquity`, `MirrorCash`, `MirrorEquity`, `BSLRealFunds`

**Rules**:
- Credit = the customer's total credit balance after this event (running total)
- Payment = the signed amount of this transaction (+inflow, -outflow)
- TotalCash = total liquid cash component of the credit after this event
- TotalCashChange = delta of the cash component caused by this event
- BonusCredit = portion of the credit that consists of non-withdrawable bonus money
- RealizedEquity = equity that has been realised (from closed positions) at this point
- MirrorCash = cash allocated to mirror/copy-trade strategies (dbo.dtPrice type)
- MirrorEquity = equity in open mirror positions
- BSLRealFunds = Balance Sheet Ledger real funds component

**Diagram**:
```
Example cashout sequence for CID=25484622:
  CreditTypeID=15 (Cashout Fee):    Credit=200095, Payment=-5      -> Fee of $5 deducted
  CreditTypeID=9  (Cashout req):    Credit=90,     Payment=-200005 -> Cashout of $200005 requested
```

### 2.3 Two-Stage Insert Pipeline

**What**: Records are not inserted directly - they flow through a staging buffer before landing here.

**Columns/Parameters Involved**: `CreditID`, `PartitionCol`, `Occurred`

**Rules**:
- Application code first inserts into History.ActiveCreditRecentMemoryBucket (the recent-memory staging table)
- Trade.InsertActiveCredit flushes a batch from the bucket to this table by CreditID range
- Trade.InsertActiveCreditPartition is a variant that targets specific partitions
- PartitionCol = CreditID % 10 (computed, PERSISTED) - routes each row to one of 10 partitions
- The staging buffer allows the write path to be decoupled from the partitioned storage

---

## 3. Data Overview

| CreditID | CID | CreditTypeID | Credit | Payment | TotalCash | Occurred | Meaning |
|----------|-----|-------------|--------|---------|-----------|----------|---------|
| 2174731419 | 25484627 | 1 (Deposit) | 100 | 100 | 100 | 2026-03-19 | A $100 deposit to a new account - first credit event, balance goes from 0 to $100. Both Credit and Payment are $100. |
| 2174731420 | 25484625 | 15 (Cashout Fee) | 95 | -5 | 95 | 2026-03-19 | A $5 cashout fee deducted. Balance drops from $100 to $95. Payment is negative (outflow). |
| 2174731421 | 25484625 | 9 (Cashout request) | 70 | -25 | 70 | 2026-03-19 | A $25 cashout request. Balance drops from $95 to $70 after the pending cashout is registered. |
| 2174731418 | 25484622 | 9 (Cashout request) | 90 | -200005 | 90 | 2026-03-19 | A large $200,005 cashout request. The balance remaining after this request is $90. |
| 2174731417 | 25484622 | 15 (Cashout Fee) | 200095 | -5 | 200095 | 2026-03-19 | Cashout fee of $5 assessed before the above cashout request (earlier in same sequence). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | VERIFIED | Unique identifier for this credit event. bigint to support the very large volumes accumulated over the platform's lifetime. Used as the partition key basis (PartitionCol = CreditID % 10). Written by Trade.InsertActiveCredit as the range key for batch flushes from the memory bucket. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID - the eToro customer whose account this credit event belongs to. The clustered index leads with CID to optimise per-customer balance history queries. Central lookup key for all customer financial history. |
| 3 | CreditTypeID | tinyint | NO | - | VERIFIED | Classification of the financial event. 33 defined types covering the full lifecycle: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 10=IB synchronization, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End Of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close position, 23=Hierarchical Open position, 24=Close position by recovery, 25=Open position by recovery, 26=FixBonusCreditRealizedEquity, 27=Detach position from mirror, 28=Detach Stock From Mirror, 29=Open Stock Order, 30=Close Stock Order, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Source: Dictionary.CreditType) |
| 4 | PositionID | bigint | YES | - | CODE-BACKED | Linked trade position for position-related credit types (3=Open, 4=Close, 13=Edit SL, 22-25, 27, 28). NULL for non-position events (deposits, cashouts, bonuses). bigint to match the position table key type. |
| 5 | ChampionshipID | int | YES | - | CODE-BACKED | Linked championship game for type 5 (Champ Winner). Identifies which championship competition awarded this prize. NULL for non-championship events. |
| 6 | CashoutID | int | YES | - | CODE-BACKED | Linked cashout transaction for cashout-related credit types (2=Cashout, 8=Reverse cashout, 33=Cashout Rollback). Ties the credit event to the Billing cashout record. NULL otherwise. |
| 7 | PaymentID | int | YES | - | CODE-BACKED | Linked payment/billing transaction for payment-related types (9=Cashout request, 11=Chargeback, 12=Refund, 15=Cashout Fee, 16=Refund As ChargeBack). NULL for non-payment events. |
| 8 | WithdrawID | int | YES | - | CODE-BACKED | Linked withdrawal record for withdrawal-based credit types (2=Cashout, 9=Cashout request, 15=Cashout Fee). Filtered index IDX_Incl_Filt_HAC_WithDrawID_BIGINT covers WHERE WithdrawID IS NOT NULL, optimising cashout lookup queries. |
| 9 | DepositID | int | YES | - | CODE-BACKED | Linked deposit transaction for deposit-related types (1=Deposit, 12=Refund, 32=Reverse Deposit). Ties the credit event to the Billing deposit record. |
| 10 | UpdateID | int | YES | - | NAME-INFERRED | Reference to a generic update operation that triggered this credit event. No dedicated lookup table found in Dictionary schema. |
| 11 | CampaignID | int | YES | - | CODE-BACKED | Linked marketing campaign for bonus-related types (7=Bonus). Identifies the promotion or campaign that awarded the bonus credit. NULL for non-campaign events. |
| 12 | BonusTypeID | int | YES | - | CODE-BACKED | Bonus classification for type 7 (Bonus) events. No active Dictionary.BonusType table found - values may be managed in the application layer. NULL for non-bonus events. |
| 13 | CompensationReasonID | int | YES | - | CODE-BACKED | Reason code for compensation events (type 6=Compensation). Identifies why manual compensation was granted (e.g., technical error, goodwill). NULL for non-compensation events. Covered in IX_BillingCovering_2_BIGINT index for reporting queries. |
| 14 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager or agent who authorised or processed this credit event (primarily for compensation type=6 and manual operations). NULL for system-generated events. |
| 15 | Credit | money | NO | - | VERIFIED | Customer's total credit balance after this event (running total). Represents the new account balance in monetary units. See TotalCash for the liquid component breakdown. |
| 16 | Payment | money | NO | - | VERIFIED | Signed amount of this transaction: positive for inflows (deposits, bonuses, position profits, reversals), negative for outflows (cashouts, fees, position losses). Payment = new Credit - previous Credit. |
| 17 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text description of the credit event. Often empty ("") for system-generated events. Used for manual entries or compensation notes. Not indexed; for display/audit purposes only. |
| 18 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this credit event occurred. Default is GETUTCDATE(). The clustered index includes Occurred (DESC) after CID to optimise "get latest N events for customer" queries. Also used by the DWH covering index i_nc_covering_dwh_BIGINT. |
| 19 | WithdrawProcessingID | int | YES | - | CODE-BACKED | Links to the withdraw processing batch or workflow that generated this cashout-related credit event. Part of the DWH covering index key columns for extract pipelines. |
| 20 | MirrorID | int | NO | 0 | CODE-BACKED | Linked mirror (copy-trade portfolio) for mirror-related types (18-23, 27-28). Default = 0 (no mirror). Non-zero values link to a specific copy-trade portfolio that this credit event relates to. |
| 21 | TotalCash | money | YES | - | CODE-BACKED | Total liquid cash component of the customer's account after this event. Distinct from BonusCredit (non-withdrawable) and MirrorCash (allocated to copy trades). NULL for older records before this field was added. |
| 22 | TotalCashChange | money | YES | - | CODE-BACKED | Delta of the TotalCash component caused by this event. Covered in IX_BillingCovering_2_BIGINT and i_nc_covering_dwh_BIGINT for reporting queries. NULL if not tracked for this event type. |
| 23 | BonusCredit | money | YES | - | CODE-BACKED | Non-withdrawable bonus money portion of the Credit balance at this point. Covered in the DWH index. NULL if no bonus component exists. Bonuses are typically time-limited and subject to trading conditions before conversion to real credit. |
| 24 | RealizedEquity | money | YES | - | CODE-BACKED | Equity realised from closed positions at this point. Covered in IX_HistoryActiveCredit_202001_CIDOccurred_2_BIGINT (added Jan 2020 based on index name). NULL for event types that do not affect realised equity. |
| 25 | MirrorCash | dbo.dtPrice | YES | - | CODE-BACKED | Cash allocated to mirror/copy-trade strategies at this point. Uses the dbo.dtPrice user-defined type (decimal precision type for prices). NULL if no mirror allocation. |
| 26 | StocksOrderID | int | YES | - | CODE-BACKED | Linked stock order for stock-related credit types (29=Open Stock Order, 30=Close Stock Order, 28=Detach Stock From Mirror). NULL for non-stock events. |
| 27 | MirrorEquity | money | YES | - | CODE-BACKED | Open unrealised equity in the customer's mirror/copy-trade portfolios at this point. Complements MirrorCash to give a full mirror portfolio valuation snapshot. |
| 28 | MirrorDividendID | int | YES | - | CODE-BACKED | Linked mirror dividend record for dividend-related credit events in copy-trade portfolios. NULL for non-dividend events. |
| 29 | MoveMoneyReasonID | int | YES | - | VERIFIED | Reason for internal money movement operations. FK to Dictionary.MoveMoneyReason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer. NULL for standard transactions. Used when compliance or operations manually moves funds between accounts. |
| 30 | BSLRealFunds | money | YES | - | CODE-BACKED | Balance Sheet Ledger component representing real (non-bonus, non-mirror) funds in the account at this point. BSL = Balance Sheet Ledger, used for regulatory reporting. NULL for events where BSL tracking is not applicable. |
| 31 | PartitionCol | AS (CreditID%(10)) PERSISTED | NO | - | VERIFIED | Computed partition routing column: CreditID modulo 10, yielding 0-9. Persisted to enable partitioned index inclusion. Routes rows across 10 partitions of PS_ActiveCredit. Included in all index keys to keep queries partition-aligned. |
| 32 | OriginalPositionID | bigint | YES | - | CODE-BACKED | The position ID before any reassignment or recovery operation. Used for recovery and data-fix credit types (24=Close by recovery, 25=Open by recovery, 31=Data Fix) where the original position may differ from the corrected PositionID. NULL for standard events. |
| 33 | SubCreditTypeID | int | YES | - | NAME-INFERRED | Sub-classification within a CreditTypeID. No Dictionary.SubCreditType table found in the schema. Likely managed at the application layer for fine-grained credit event categorisation beyond the 33 main types. NULL in all observed live records. |
| 34 | DepositRollbackID | int | YES | - | CODE-BACKED | Links to the deposit that is being rolled back for type 32 (Reverse Deposit). Identifies the specific deposit reversal operation. NULL for all other event types. |
| 35 | InterestMonthlyID | bigint | YES | - | NAME-INFERRED | Reference to a monthly interest payment record. bigint key suggests it links to a high-volume interest log table. NULL for non-interest events. No dedicated lookup table found for resolution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID | Dictionary.CreditType | Implicit | 33-type classification of the financial event. No FK constraint, enforced by application logic. |
| MoveMoneyReasonID | Dictionary.MoveMoneyReason | Implicit | Reason for manual money movement: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer. |
| PositionID | History.Position_Active / Trade.PositionTbl | Implicit | Links credit events to their originating positions (types 3, 4, 13, 22-25, 27-28). |
| MirrorID | History.Mirror | Implicit | Links mirror-related credit events to the copy-trade portfolio (types 18-23, 27-28). |
| DepositID | History.Deposit | Implicit | Links deposit-related credit events to the originating deposit record. |
| WithdrawID | History.WithdrawLog | Implicit | Links cashout-related credit events to the withdrawal record. |
| StocksOrderID | History.StocksOrders | Implicit | Links stock-related credit events to the stock order. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ActiveCredit | (view) | View | History.ActiveCredit view wraps this table as the canonical read path for credit history queries. |
| Trade.InsertActiveCredit | CreditID | Writer | Flushes records from History.ActiveCreditRecentMemoryBucket into this table by CreditID range. |
| Trade.InsertActiveCreditPartition | CreditID | Writer | Partition-targeted variant of the flush procedure. |
| BackOffice.BillingDepositsPCIVersion | CreditID | Reader | Back-office billing deposits report reading from this table (PCI-compliance version). |
| BackOffice.BillingDepositsPCIVersion_Old | CreditID | Reader | Legacy version of the back-office deposits report. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCredit_BIGINT (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Data type for MirrorCash column (decimal price precision type) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | View | Wraps this table as the canonical credit history read view |
| Trade.InsertActiveCredit | Stored Procedure | Writer - bulk inserts from memory bucket by CreditID range |
| Trade.InsertActiveCreditPartition | Stored Procedure | Writer - partition-targeted bulk insert from memory bucket |
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | Reader - deposit audit/reporting queries |
| BackOffice.BillingDepositsPCIVersion_Old | Stored Procedure | Reader - legacy deposit reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| HCRD_2_CID_Occurred_Cl_BIGINT | CLUSTERED | CID ASC, Occurred DESC, PartitionCol ASC | - | - | Active |
| PK_HCRD_BIGINT | NC PK | CreditID ASC, PartitionCol ASC | - | - | Active |
| HP_AC_inx_cover_fee_job_BIGINT | NONCLUSTERED | CID, PositionID, Occurred DESC, CreditTypeID, Description | - | - | Active |
| IDX_Incl_Filt_HAC_WithDrawID_BIGINT | NONCLUSTERED | WithdrawID, CreditTypeID, PartitionCol | Payment, CID | WHERE WithdrawID IS NOT NULL | Active |
| IX_BillingCovering_2_BIGINT | NONCLUSTERED | CID, CreditTypeID, CampaignID, BonusTypeID, PositionID, PartitionCol | TotalCashChange, CompensationReasonID, Payment, Occurred | - | Active |
| IX_HistoryActiveCredit_202001_CIDOccurred_2_BIGINT | NONCLUSTERED | CID, Occurred ASC, CreditID DESC, PartitionCol | RealizedEquity | - | Active |
| IX_HistoryActiveCredit_202001_CreditTypeID_DepositINC_2_BIGINT | NONCLUSTERED | CreditTypeID, DepositID, PartitionCol | ManagerID, CID, Occurred | - | Active |
| i_nc_covering_dwh_BIGINT | NONCLUSTERED | Occurred, WithdrawProcessingID | CreditID, CID, CreditTypeID, PositionID, CashoutID, PaymentID, WithdrawID, DepositID, CampaignID, BonusTypeID, CompensationReasonID, Credit, Payment, MirrorID, TotalCashChange, BonusCredit | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCRD_BIGINT | PRIMARY KEY NC | (CreditID, PartitionCol) - composite key required for partitioned table |
| DF_HistoryActiveCredit_Occurred_BIGINT | DEFAULT | Occurred = GETUTCDATE() - auto-stamps UTC time if not provided |
| DF_HistoryCredit_MirrorID_ActiveCredit_BIGINT | DEFAULT | MirrorID = 0 - zero means no mirror association |
| DATA_COMPRESSION = PAGE | Storage | Table and clustered index use page compression to reduce storage cost of this very large table |

---

## 8. Sample Queries

### 8.1 Get recent credit event history for a customer
```sql
SELECT TOP 20
    ac.CreditID,
    ct.Name             AS CreditType,
    ac.Credit,
    ac.Payment,
    ac.TotalCash,
    ac.PositionID,
    ac.Description,
    ac.Occurred
FROM History.ActiveCredit_BIGINT ac WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ac.CreditTypeID = ct.CreditTypeID
WHERE ac.CID = 12345678
ORDER BY ac.Occurred DESC;
```

### 8.2 Find all deposit events linked to a specific deposit record
```sql
SELECT
    ac.CreditID,
    ac.CID,
    ac.Credit,
    ac.Payment,
    ac.Occurred
FROM History.ActiveCredit_BIGINT ac WITH (NOLOCK)
WHERE ac.CreditTypeID IN (1, 12, 32)  -- Deposit, Refund, Reverse Deposit
  AND ac.DepositID = 987654
ORDER BY ac.Occurred ASC;
```

### 8.3 Cashout-related events with withdrawal context
```sql
SELECT
    ac.CreditID,
    ac.CID,
    ct.Name             AS CreditType,
    ac.Credit,
    ac.Payment,
    ac.WithdrawID,
    ac.MoveMoneyReasonID,
    mmr.MoveMoneyReason,
    ac.Occurred
FROM History.ActiveCredit_BIGINT ac WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON ac.CreditTypeID = ct.CreditTypeID
LEFT JOIN Dictionary.MoveMoneyReason mmr WITH (NOLOCK)
    ON ac.MoveMoneyReasonID = mmr.MoveMoneyReasonID
WHERE ac.WithdrawID IS NOT NULL
  AND ac.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY ac.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.4/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCredit_BIGINT | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveCredit_BIGINT.sql*
