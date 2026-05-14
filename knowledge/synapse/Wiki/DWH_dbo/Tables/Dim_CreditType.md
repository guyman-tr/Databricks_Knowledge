# DWH_dbo.Dim_CreditType

> Small dictionary (33 rows) classifying account credit/debit transaction types in the eToro platform. Used to categorize every movement in a customer's credit history.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CreditType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CreditTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_credittype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CreditType` is a 33-row reference dictionary classifying every type of account balance change in the eToro platform. It covers the full lifecycle of customer funds: deposits (ID=1), cashouts (ID=2), position open/close events (IDs 3-4), bonuses and compensation (IDs 5-7), reversals and chargebacks (IDs 8,11-12,16-17,32-33), trading-related fees (IDs 13-15), mirror/copy trading events (IDs 18-28), stock orders (IDs 29-30), data fixes (ID=31), and IB synchronization (ID=10).

The source is `etoro.Dictionary.CreditType`. The staging table `DWH_staging.etoro_Dictionary_CreditType` passes through CreditTypeID and renames `Name` to `CreditTypeName`. The ETL is a full TRUNCATE-and-INSERT daily reload. `UpdateDate` is injected as GETDATE() by the SP.

Important: `CreditTypeName` uses `char(50)` - values have trailing spaces. Use `RTRIM(CreditTypeName)` when displaying or comparing.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md`.

---

## 2. Business Logic

### 2.1 Credit Transaction Type Classification

**What**: 33 categories classify every account balance event from deposits to complex copy-trading operations.

**Columns Involved**: `CreditTypeID`, `CreditTypeName`

**Rules**:
- ID=1 (Deposit): Customer funds added to account
- ID=2 (Cashout): Customer funds withdrawn from account
- ID=3 (Open Position): Funds allocated when opening a trade
- ID=4 (Close Position): Funds released when closing a trade
- ID=5 (Champ Winner): Championship prize credit
- ID=6 (Compensation): Manual compensation payment
- ID=7 (Bonus): Promotional bonus credit
- ID=8 (Reverse cashout): Cashout reversal (chargeback or failed withdrawal)
- ID=9 (Cashout request): Cashout initiated (pending state)
- ID=10 (IB synchronization): Introducing Broker balance sync
- ID=11 (Chargeback): Card chargeback credit
- ID=12 (Refund): Fee refund
- ID=13 (Edit Stop Loss): Stop-loss amendment fee
- ID=14 (End Of Week Fee): Weekly CFD rollover fee
- ID=15 (Cashout Fee): Fee charged on cashout
- ID=16 (Refund As ChargeBack): Chargeback processed as a refund
- ID=17 (FixHistoryCreditChargeBacks): Data fix for historical chargebacks
- ID=18 (Account balance to mirror): Funds transferred to a copy-trading portfolio
- ID=19 (Mirror balance to account): Funds returned from copy-trading portfolio
- ID=20 (Register new mirror): Copy portfolio creation event
- ID=21 (Unregister mirror): Copy portfolio termination event
- ID=22 (Mirror Hierarchical Close position): Cascaded close from mirror portfolio
- ID=23 (Hierarchical Open position): Position opened via mirror hierarchy
- ID=24 (Close position by recovery): Recovery mechanism close
- ID=25 (Open position by recovery): Recovery mechanism open
- ID=26 (FixBonusCreditRealizedEquity): Bonus equity fix
- ID=27 (Detach position from mirror): Manual position detachment from copy portfolio
- ID=28 (Detach Stock From Mirror): Real stock detached from copy portfolio
- ID=29 (Open Stock Order): Real stock purchase order
- ID=30 (Close Stock Order): Real stock sale order
- ID=31 (Data Fix): Administrative data correction
- ID=32 (Reverse Deposit): Deposit reversed/returned
- ID=33 (Cashout Rollback): Cashout reversal before processing

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE is correct for 33 rows. CLUSTERED INDEX on CreditTypeID is appropriate for point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (33 rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode credit type in credit history | `JOIN DWH_dbo.Dim_CreditType d ON f.CreditTypeID = d.CreditTypeID` |
| Filter deposits only | `WHERE CreditTypeID = 1` |
| Separate fund flows vs fees | `WHERE CreditTypeID IN (1,2,7,12)` (deposits, cashouts, bonuses, refunds) |
| Trailing spaces in name | Use `RTRIM(CreditTypeName)` in SELECT/WHERE |

### 3.3 Gotchas

- `CreditTypeName` is `char(50)` - all values have trailing spaces. Use `RTRIM()` when displaying or comparing.
- IDs start at 1, no ID=0 placeholder.
- IDs 17, 26, 31 are data-fix/maintenance types - filter these out for business-facing reports.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CreditTypeID | tinyint | NO | Financial operation type identifier (1-33). Classifies every balance change: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB synchronization, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18-28=Mirror/CopyTrading operations, 29-30=Close Stock Order, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Tier 1 — Dictionary.CreditType) |
| 2 | CreditTypeName | char(50) | NO | Human-readable operation name. Unique constraint ensures no duplicate names. Used in financial reports, transaction history, and reconciliation tools. Note: char(50) with trailing spaces — always RTRIM when displaying. DWH note: renamed from Name in source. (Tier 1 — Dictionary.CreditType) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CreditTypeID | etoro.Dictionary.CreditType | CreditTypeID | passthrough |
| CreditTypeName | etoro.Dictionary.CreditType | Name | rename (Name -> CreditTypeName) |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CreditType
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_CreditType (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_CreditType (33 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CreditType | 33-row credit type lookup in production etoro database. |
| Staging | DWH_staging.etoro_Dictionary_CreditType | Raw staging. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Name -> CreditTypeName. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_CreditType | Final DWH dimension (33 rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| - | - | No outbound foreign key references. Self-contained lookup. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH credit history fact tables | CreditTypeID | Credit/debit history fact tables reference this table for transaction type classification. [UNVERIFIED - no SP grep match; inferred from naming convention] |

---

## 7. Sample Queries

### 7.1 List all credit types
```sql
SELECT CreditTypeID, RTRIM(CreditTypeName) AS CreditTypeName, UpdateDate
FROM [DWH_dbo].[Dim_CreditType]
ORDER BY CreditTypeID;
```

### 7.2 Group credit history by type
```sql
SELECT RTRIM(d.CreditTypeName) AS CreditType, COUNT(*) AS EventCount
FROM [DWH_dbo].[Fact_CustomerCredit] f
JOIN [DWH_dbo].[Dim_CreditType] d ON f.CreditTypeID = d.CreditTypeID
GROUP BY d.CreditTypeName
ORDER BY EventCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md`.

---

*Generated: 2026-03-19 | Quality: 7.2/10 (3 stars) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 3/10, Sources: 7/10*
*Object: DWH_dbo.Dim_CreditType | Type: Table | Production Source: etoro.Dictionary.CreditType*
