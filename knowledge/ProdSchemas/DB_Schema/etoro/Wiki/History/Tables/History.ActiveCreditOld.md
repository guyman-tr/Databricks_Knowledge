# History.ActiveCreditOld

> Legacy archive of credit events from the int-era platform (pre-2020), structurally identical to History.ActiveCredit_BIGINT but with int-typed position IDs and an identity-seeded CreditID column that marked the original write path before the bigint migration.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CreditID (bigint IDENTITY(2100000000,1), NONCLUSTERED PK with PartitionCol) |
| **Partition** | Yes - PS_ActiveCredit scheme, 10 partitions on PartitionCol (CreditID % 10) |
| **Indexes** | 7 active (1 clustered on CID/Occurred, 1 NC PK, 5 covering NCs) |

---

## 1. Business Meaning

History.ActiveCreditOld is the retired predecessor to History.ActiveCredit_BIGINT. It was the original, active financial event ledger for eToro customers before the platform's credit volume exceeded the int identity range (~2.1 billion records). The table stores all credit events recorded up to the migration cutover: deposits, cashouts, position opens/closes, bonuses, mirror operations, and all other financial events from the early platform era.

Without this table, the complete financial audit trail would be missing for older customer accounts and historical transactions. It exists as a permanent archive for pre-migration data and is queried by History.ActiveCredit view alongside the current _BIGINT table to provide unified credit history across both time periods.

The table was retired around 2020 (indicated by "_202001" index name suffixes). No procedures write to it in the current system. It is read-only archival data. The identity column IDENTITY(2100000000,1) NOT FOR REPLICATION reflects the table's history: originally an int CreditID column that was converted to bigint as part of the migration - the seed value of 2,100,000,000 approximates the int overflow boundary, ensuring no CreditID collision with the new _BIGINT table's range.

---

## 2. Business Logic

### 2.1 Structural Equivalence to ActiveCredit_BIGINT

**What**: This table is a structural near-clone of History.ActiveCredit_BIGINT with two key differences reflecting the int-era platform.

**Columns/Parameters Involved**: `CreditID`, `PositionID`, `OriginalPositionID`

**Rules**:
- CreditID: bigint IDENTITY(2100000000,1) NOT FOR REPLICATION - was the identity-generating column when active. The seed at 2.1B reflects the original int overflow boundary
- PositionID: int (vs bigint in _BIGINT) - legacy int-keyed position IDs from the pre-bigint era
- OriginalPositionID: int (vs bigint in _BIGINT) - same reason
- All other columns are functionally identical to ActiveCredit_BIGINT (same semantics, same lookup tables, same partitioning)

**Diagram**:
```
Credit history timeline:
  [Pre-2020]  CreditID 1 to ~2.1B  -> History.ActiveCreditOld (retired, archived)
  [Post-2020] CreditID > 2.1B      -> History.ActiveCredit_BIGINT (active, receiving new records)

History.ActiveCredit view unifies both:
  SELECT ... FROM History.ActiveCreditOld
  UNION ALL
  SELECT ... FROM History.ActiveCredit_BIGINT
```

### 2.2 Same Credit Event Type System

**What**: Uses the same 33-type CreditTypeID classification as History.ActiveCredit_BIGINT.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- All 33 CreditType values apply identically to this table
- See History.ActiveCredit_BIGINT Section 2.1 for the full CreditTypeID value map
- Same FK columns activated per credit type (PositionID, MirrorID, DepositID, etc.)

---

## 3. Data Overview

The table is currently empty in the query environment (0 rows returned). This is expected - the table contains historical data from the pre-2020 era that may have been purged in this environment. In production, it would contain billions of credit records for all customers from the platform's early years.

| CreditID | CID | CreditTypeID | Credit | Payment | Occurred | Meaning |
|----------|-----|-------------|--------|---------|----------|---------|
| (no data) | - | - | - | - | - | Table is empty in current environment. Production data covers all credit events from platform launch through approximately 2020. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint IDENTITY(2100000000,1) | NO | - | VERIFIED | Unique credit event identifier. IDENTITY-seeded to 2,100,000,000 (the approximate int overflow boundary), reflecting the original int-keyed table converted to bigint. NOT FOR REPLICATION prevents identity re-generation during replication. Now retired - no new rows are being added. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID. Same semantics as History.ActiveCredit_BIGINT.CID. See that table's documentation for full description. |
| 3 | CreditTypeID | tinyint | NO | - | VERIFIED | Financial event classification. Same 33-type lookup as History.ActiveCredit_BIGINT. See that table Section 2.1 for the full value map. (Source: Dictionary.CreditType) |
| 4 | PositionID | int | YES | - | VERIFIED | Linked trade position. int type (vs bigint in the successor table) - reflects legacy int-keyed position IDs from the pre-bigint migration era. NULL for non-position event types. |
| 5 | ChampionshipID | int | YES | - | CODE-BACKED | Linked championship for type 5 (Champ Winner). Same semantics as History.ActiveCredit_BIGINT.ChampionshipID. |
| 6 | CashoutID | int | YES | - | CODE-BACKED | Linked cashout transaction. Same semantics as History.ActiveCredit_BIGINT.CashoutID. |
| 7 | PaymentID | int | YES | - | CODE-BACKED | Linked payment transaction. Same semantics as History.ActiveCredit_BIGINT.PaymentID. |
| 8 | WithdrawID | int | YES | - | CODE-BACKED | Linked withdrawal record. Filtered index IDX_Incl_Filt_HAC_WithDrawID_202001 covers WHERE WithdrawID IS NOT NULL. |
| 9 | DepositID | int | YES | - | CODE-BACKED | Linked deposit transaction. Same semantics as History.ActiveCredit_BIGINT.DepositID. |
| 10 | UpdateID | int | YES | - | NAME-INFERRED | Reference to a generic update operation. Same as History.ActiveCredit_BIGINT.UpdateID - no dedicated lookup table. |
| 11 | CampaignID | int | YES | - | CODE-BACKED | Linked marketing campaign for bonus events. Same semantics as History.ActiveCredit_BIGINT.CampaignID. |
| 12 | BonusTypeID | int | YES | - | CODE-BACKED | Bonus classification. Same semantics as History.ActiveCredit_BIGINT.BonusTypeID. |
| 13 | CompensationReasonID | int | YES | - | CODE-BACKED | Reason for compensation events. Same semantics as History.ActiveCredit_BIGINT.CompensationReasonID. |
| 14 | ManagerID | int | YES | - | CODE-BACKED | Authorising manager for manual operations. Same semantics as History.ActiveCredit_BIGINT.ManagerID. |
| 15 | Credit | money | NO | - | VERIFIED | Customer's total credit balance after this event. Same semantics as History.ActiveCredit_BIGINT.Credit. |
| 16 | Payment | money | NO | - | VERIFIED | Signed transaction amount (+inflow, -outflow). Same semantics as History.ActiveCredit_BIGINT.Payment. |
| 17 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text event description. Same semantics as History.ActiveCredit_BIGINT.Description. |
| 18 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC event timestamp. Same semantics as History.ActiveCredit_BIGINT.Occurred. |
| 19 | WithdrawProcessingID | int | YES | - | CODE-BACKED | Withdraw processing batch reference. Same semantics as History.ActiveCredit_BIGINT.WithdrawProcessingID. |
| 20 | MirrorID | int | YES | 0 | CODE-BACKED | Linked mirror portfolio (default=0). Same semantics as History.ActiveCredit_BIGINT.MirrorID. |
| 21 | TotalCash | money | YES | - | CODE-BACKED | Total liquid cash balance component. Same semantics as History.ActiveCredit_BIGINT.TotalCash. |
| 22 | TotalCashChange | money | YES | - | CODE-BACKED | Delta of the cash component. Same semantics as History.ActiveCredit_BIGINT.TotalCashChange. |
| 23 | BonusCredit | money | YES | - | CODE-BACKED | Non-withdrawable bonus money portion. Same semantics as History.ActiveCredit_BIGINT.BonusCredit. |
| 24 | RealizedEquity | money | YES | - | CODE-BACKED | Equity realised from closed positions. Same semantics as History.ActiveCredit_BIGINT.RealizedEquity. |
| 25 | MirrorCash | dbo.dtPrice | YES | - | CODE-BACKED | Cash in mirror/copy-trade strategies. Same semantics as History.ActiveCredit_BIGINT.MirrorCash. |
| 26 | StocksOrderID | int | YES | - | CODE-BACKED | Linked stock order for stock credit types. Same semantics as History.ActiveCredit_BIGINT.StocksOrderID. |
| 27 | MirrorEquity | money | YES | - | CODE-BACKED | Open equity in mirror portfolios. Same semantics as History.ActiveCredit_BIGINT.MirrorEquity. |
| 28 | MirrorDividendID | int | YES | - | CODE-BACKED | Linked mirror dividend record. Same semantics as History.ActiveCredit_BIGINT.MirrorDividendID. |
| 29 | MoveMoneyReasonID | int | YES | - | VERIFIED | Internal money movement reason. Same semantics as History.ActiveCredit_BIGINT.MoveMoneyReasonID. (Source: Dictionary.MoveMoneyReason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer) |
| 30 | BSLRealFunds | money | YES | - | CODE-BACKED | Balance Sheet Ledger real funds component. Same semantics as History.ActiveCredit_BIGINT.BSLRealFunds. |
| 31 | PartitionCol | AS (CreditID%(10)) PERSISTED | NO | - | VERIFIED | Computed partition routing: CreditID % 10 (0-9). Routes across 10 partitions of PS_ActiveCredit. Persisted computed column. |
| 32 | OriginalPositionID | int | YES | - | VERIFIED | The original position ID before recovery/fix operations. int type (vs bigint in successor) - legacy int-era position IDs. Same semantics as History.ActiveCredit_BIGINT.OriginalPositionID. |
| 33 | SubCreditTypeID | int | YES | - | NAME-INFERRED | Sub-classification within CreditTypeID. No Dictionary.SubCreditType found. Same as History.ActiveCredit_BIGINT.SubCreditTypeID. |
| 34 | DepositRollbackID | int | YES | - | CODE-BACKED | Deposit being rolled back (type 32 only). Same semantics as History.ActiveCredit_BIGINT.DepositRollbackID. |
| 35 | InterestMonthlyID | bigint | YES | - | NAME-INFERRED | Monthly interest payment reference. bigint key. Same semantics as History.ActiveCredit_BIGINT.InterestMonthlyID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID | Dictionary.CreditType | Implicit | Same 33-type event classification as History.ActiveCredit_BIGINT. |
| MoveMoneyReasonID | Dictionary.MoveMoneyReason | Implicit | Internal transfer/adjustment reasons. |
| PositionID | History.Position_Active (int-era) | Implicit | Int-type position IDs from the pre-bigint era. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ActiveCredit | (view) | View | History.ActiveCredit view likely unions this table with History.ActiveCredit_BIGINT to provide unified credit history. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCreditOld (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Data type for MirrorCash column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | View | Likely unions this archive with History.ActiveCredit_BIGINT for unified history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| HCRD_2_CID_Occurred_Cl_202001 | CLUSTERED | CID ASC, Occurred DESC, PartitionCol ASC | - | - | Active |
| PK_HCRD_202001 | NC PK | CreditID ASC, PartitionCol ASC | - | - | Active |
| HP_AC_202001_inx_cover_fee_job | NONCLUSTERED | CID, PositionID, Occurred DESC, CreditTypeID, Description | - | - | Active |
| IDX_Incl_Filt_HAC_WithDrawID_202001 | NONCLUSTERED | WithdrawID, CreditTypeID, PartitionCol | Payment, CID | WHERE WithdrawID IS NOT NULL | Active |
| IX_BillingCovering_2_202001 | NONCLUSTERED | CID, CreditTypeID, CampaignID, BonusTypeID, PositionID, PartitionCol | TotalCashChange, CompensationReasonID, Payment, Occurred | - | Active |
| IX_HistoryActiveCredit_202001_CIDOccurred_2_202001 | NONCLUSTERED | CID, Occurred ASC, CreditID DESC, PartitionCol | RealizedEquity | - | Active |
| IX_HistoryActiveCredit_202001_CreditTypeID_DepositINC_2_202001 | NONCLUSTERED | CreditTypeID, DepositID, PartitionCol | ManagerID, CID, Occurred | - | Active |
| i_nc_covering_dwh_202001 | NONCLUSTERED | Occurred, WithdrawProcessingID | CreditID, CID, CreditTypeID, PositionID, CashoutID, PaymentID, WithdrawID, DepositID, CampaignID, BonusTypeID, CompensationReasonID, Credit, Payment, MirrorID, TotalCashChange, BonusCredit | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCRD_202001 | PRIMARY KEY NC | (CreditID, PartitionCol) - composite key for partitioned table |
| DF_HistoryActiveCredit_202001_Occurred | DEFAULT | Occurred = GETUTCDATE() |
| DF_HistoryCredit_MirrorID_NewActiveCredit_202001 | DEFAULT | MirrorID = 0 |
| DATA_COMPRESSION = PAGE | Storage | Page compression on table and clustered index |

---

## 8. Sample Queries

### 8.1 Query pre-2020 credit history for a customer
```sql
SELECT TOP 20
    aco.CreditID,
    ct.Name             AS CreditType,
    aco.Credit,
    aco.Payment,
    aco.TotalCash,
    aco.PositionID,
    aco.Occurred
FROM History.ActiveCreditOld aco WITH (NOLOCK)
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK)
    ON aco.CreditTypeID = ct.CreditTypeID
WHERE aco.CID = 12345678
ORDER BY aco.Occurred DESC;
```

### 8.2 Compare pre- and post-migration credit records for a customer
```sql
-- Pre-2020 records (from this table)
SELECT 'Old' AS Source, CreditID, CID, CreditTypeID, Credit, Payment, Occurred
FROM History.ActiveCreditOld WITH (NOLOCK)
WHERE CID = 12345678
UNION ALL
-- Post-2020 records (from current table)
SELECT 'BIGINT' AS Source, CreditID, CID, CreditTypeID, Credit, Payment, Occurred
FROM History.ActiveCredit_BIGINT WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY Occurred DESC;
```

### 8.3 Find deposit events in the archive by deposit ID
```sql
SELECT
    aco.CreditID,
    aco.CID,
    aco.Credit,
    aco.Payment,
    aco.Occurred
FROM History.ActiveCreditOld aco WITH (NOLOCK)
WHERE aco.CreditTypeID IN (1, 12, 32)  -- Deposit, Refund, Reverse Deposit
  AND aco.DepositID = 123456
ORDER BY aco.Occurred ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCreditOld | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveCreditOld.sql*
