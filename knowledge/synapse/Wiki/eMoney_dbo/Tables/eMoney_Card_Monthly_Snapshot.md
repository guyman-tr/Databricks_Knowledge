# eMoney_dbo.eMoney_Card_Monthly_Snapshot

> 566M-row monthly EOM customer panel for eToro Money debit card funnel analytics — one row per (EOM date, customer). Covers ALL eTM-eligible customers across 34 rollout countries (not just card holders); card columns are NULL for non-card customers. Spans 27 EOM snapshots from 2024-01-31 to 2026-03-31, growing from 17.1M to 24.9M rows per snapshot. Tableau debit card funnel reports are built directly on this table. Refreshed monthly (incremental) by SP_eMoney_Card_Monthly_Snapshot.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (EOM eligible universe) + eMoney_dbo.eMoney_Card_Instance_Summary (card timelines) + eMoney_dbo.eMoney_Dim_Transaction (Tx dates). Written by SP_eMoney_Card_Monthly_Snapshot. |
| **Refresh** | Monthly incremental — DELETE WHERE SnapShotDateID + INSERT per EOM date (while-loop). SP authored by Jan Iablunovskey, 2025-06-29. |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |
| **PII** | None (card dates and TX dates only; MaskedPAN not included) |

---

## 1. Business Meaning

`eMoney_Card_Monthly_Snapshot` is the monthly end-of-month customer panel for eToro Money debit card funnel tracking. **Grain**: one row per (SnapShotDate, CID) — one row per eligible customer per EOM month. As of 2026-03-31, the table holds 566,088,274 rows across 27 EOM snapshots (2024-01-31 to 2026-03-31), with the monthly eligible population growing from 17.1M customers in January 2024 to 24.9M in March 2026.

**Who is included**: Every customer present in `DWH_dbo.Fact_SnapshotCustomer` at the EOM date with `IsValidCustomer=1` who resides in one of the 34 eTM rollout countries (filtered via `eMoney_dbo.eMoney_Dim_Country_Rollout`). This is the broad eligible universe — not just card holders. In March 2026, approximately 99.65% of rows have NULL `CardCreateDate`, meaning the overwhelming majority of rows represent eTM-eligible customers who do not have a debit card.

**Card funnel signal hierarchy**:
- `FMI_Date IS NOT NULL` → customer has funded their eTM wallet (~0.29% of Mar 2026 rows)
- `CardCreateDate IS NOT NULL` → customer has been issued a card (~0.35% — card issued before funding is possible)
- `FirstInstanceActivationDate IS NOT NULL` → customer has activated their card (~0.20%)
- `Tx1_AfterFirst IS NOT NULL` → customer has made at least 1 card transaction

Tableau debit card funnel dashboards apply business funnel stage definitions on top of these signals. This table supplies the full eligible population denominator alongside the card-holding numerator — no pre-filtering to card holders.

**Snapshot vs. current attributes**: `SnapshotCountry` / `SnapshotClub` are point-in-time at the EOM date (from `Fact_SnapshotCustomer`); `Country` / `Club` are the customer's attributes at SP execution time (via `Dim_Customer`). For any historical snapshot, these columns may diverge for customers who have changed country or club tier since that EOM.

**Country distribution (Mar 2026 snapshot)**: United Kingdom (4.9M), France (3.9M), Germany (3.6M), Italy (2.9M), Spain (1.7M). 34 distinct countries.
**Club distribution (Mar 2026)**: Bronze=97.5%, Silver=0.9%, Gold=0.8%, Platinum=0.4%, Platinum Plus=0.3%.

---

## 2. Business Logic

### 2.1 Eligible Customer Universe and Snapshot Grain

**What**: One row per (SnapShotDate, CID). The eligible population at each EOM is sourced from `DWH_dbo.Fact_SnapshotCustomer` filtered to IsValidCustomer=1 and joined to the 34-country eTM rollout list in `eMoney_dbo.eMoney_Dim_Country_Rollout`.

**Columns Involved**: `SnapShotDateID`, `SnapShotDate`, `CID`, `GCID`, `SnapshotCountryID`, `SnapshotPlayerLevelID`

**Rules**:
- The while-loop iterates from the day after the last snapshot in the table to the EOM of the previous month relative to GETDATE() — it will not add the current month until it ends
- DELETE WHERE `SnapShotDateID = @StartDateDailyID` before each INSERT ensures idempotency for that month
- Customers who leave or join the eligible universe between EOM dates appear or disappear in the snapshot series
- `SnapShotDateID` is the YYYYMMDD integer form of `SnapShotDate`; both columns represent the same EOM

### 2.2 Snapshot vs. Current Attributes

**What**: Two sets of country/club columns with different temporal semantics.

**Columns Involved**: `SnapshotCountryID`, `SnapshotPlayerLevelID`, `SnapshotClub`, `SnapshotCountry` (point-in-time) vs. `Country`, `Club` (current at SP run time)

**Rules**:
- `Snapshot*` columns decode from `Fact_SnapshotCustomer` via `Dim_PlayerLevel` and `Dim_Country` at EOM — correct for cohort analysis and historical attribution
- `Country` / `Club` are derived from `Dim_Customer` (JOIN on CID) at SP execution time — correct for current segmentation on the latest snapshot
- For historical EOM snapshots, `Country` and `Club` reflect the customer's current state, not their state at that EOM; use `SnapshotCountry` / `SnapshotClub` for accurate historical attribution
- When `SnapShotDate` = the most recent snapshot (close to current date), both sets of attributes will be approximately equal

### 2.3 Card Data Columns and Source Table

**What**: All card-related columns are sourced from `eMoney_Card_Instance_Summary` (CIS) via aggregation per CID. Only customers with a record in CIS have non-NULL card columns.

**Columns Involved**: `CardCreateDate`, `LastInstanceActivationDate`, `LastInstanceTxAfterActivationCount`, `FirstInstanceCreatedDate`, `FirstInstanceActivationDate`, `FirstTxAfterActivationCount`

**Rules**:
- `LastInstance*` columns use MAX() aggregation over all CIS rows for the CID (most recent instance)
- `FirstInstance*` columns use ROW_NUMBER() by InstanceCreatedDate ASC (earliest instance)
- A customer with multiple card instances will have both First* and Last* columns populated, with Last* ≥ First* chronologically
- `AccountSubProgram` is a LEFT JOIN from `eMoney_Dim_Account` (GCID_Unique_Count=1 only); NULL for customers not in the account dimension

### 2.4 Transaction Date Columns

**What**: Tx1/Tx2 after first and last activation — earliest 1st and 2nd settled card TX dates relative to each activation milestone.

**Columns Involved**: `Tx1_AfterFirst`, `Tx2_AfterFirst`, `Tx1_AfterLast`, `Tx2_AfterLast`

**Rules**:
- Sourced from `eMoney_Dim_Transaction` (Step T6 of SP): settled card TXs (IsTxSettled=1, TxTypeID IN [1,2,3,4]) after the respective activation dates
- These dates are **not snapshot-bound** — they reflect the actual first/second transaction the customer ever made after activation, regardless of which EOM month the row is for
- NULL when the customer has not made enough settled card transactions after the respective activation milestone
- Tx1_AfterFirst ≤ Tx2_AfterFirst when both are non-NULL

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distributes rows by customer — customer-level aggregations and cross-table JOINs on CID are efficient. All 27 EOM rows for the same customer land on the same compute node. HEAP is optimal for this incrementally-appended table; no range-scan benefit exists.

**Scale note**: At 566M rows, **always filter on `SnapShotDate` or `SnapShotDateID` first** unless intentionally scanning all months. A full-table scan without a date filter processes all 27 snapshots.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest snapshot population | `WHERE SnapShotDate = '2026-03-31'` (~24.9M rows) |
| Monthly card funnel trend | `GROUP BY SnapShotDate, CASE WHEN CardCreateDate IS NOT NULL THEN 1 ELSE 0 END` |
| Card adoption rate over time | COUNT DISTINCT CID WHERE CardCreateDate IS NOT NULL / total CID per SnapShotDate |
| Customers with activated card in cohort | `WHERE SnapShotDate = @Month AND FirstInstanceActivationDate IS NOT NULL` |
| Time-to-first-transaction after activation | `DATEDIFF(day, FirstInstanceActivationDate, Tx1_AfterFirst)` WHERE both non-NULL |
| Country-level funnel (point-in-time) | GROUP BY SnapShotDate, SnapshotCountry — use SnapshotCountry for historical accuracy |
| Country-level current state | GROUP BY SnapShotDate, Country — use Country for current-segmentation |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Card_Instance_Summary | ON snap.CID = cis.CID | Detailed card instance timelines per customer |
| eMoney_dbo.eMoney_Panel_FirstDates | ON snap.CID = fd.CID | FMI/FMO milestone cross-reference (eTM wallet history) |
| DWH_dbo.Dim_Customer | ON snap.CID = dc.RealCID | Current trading profile (regulation, segment) |
| eMoney_dbo.eMoney_Dim_Account | ON snap.GCID = mda.GCID AND mda.GCID_Unique_Count=1 | eTM account sub-program, validity |

### 3.4 Gotchas

- **NULL card columns are the norm**: ~99.65% of rows have NULL CardCreateDate. Do not treat NULL as missing data — it means the customer has not applied for a card.
- **Tx dates are not snapshot-scoped**: Tx1_AfterFirst / Tx2_AfterFirst / Tx1_AfterLast / Tx2_AfterLast reflect lifetime transaction dates, not EOM-bounded values. The same Tx date will appear in every EOM snapshot row for that customer after the transaction occurred.
- **SnapShotDate vs. UpdateDate**: SnapShotDate is the EOM business date; UpdateDate is the SP run timestamp. For filtering, always use SnapShotDate.
- **Snapshot* vs. Country/Club**: Always use Snapshot* columns for historical EOM analysis. Country/Club are current attributes and will be identical across all EOM rows for the same customer (they do not change per snapshot).
- **GCID NULLs**: A small number of customers may have NULL GCID if their FiatAccount record is not linked. AccountSubProgram will also be NULL for these rows.
- **No deduplication needed**: The grain is (SnapShotDate, CID) with a guaranteed DELETE before INSERT per month — one row per customer per EOM.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB or etoro DB_Schema) |
| Tier 2 | Derived from ETL SP code or DWH computation logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | SnapShotDateID | int | NO | YYYYMMDD integer representing the end-of-month date for this row (e.g., 20240131). Derived from the while-loop variable @StartDateDailyID. Used as the partition key in the DELETE+INSERT idempotency pattern. Filter on this column or SnapShotDate when querying a single month. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 2 | SnapShotDate | date | NO | Calendar end-of-month date for this row (e.g., 2024-01-31). Derived from the while-loop variable @StartDateDaily. Range: 2024-01-31 to 2026-03-31 (27 distinct values). Preferred filter column over SnapShotDateID for readability. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 3 | CID | bigint | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. DWH note: passthrough via Fact_SnapshotCustomer.GCID. (Tier 1 — dbo.FiatAccount) |
| 5 | SnapshotCountryID | int | YES | Numeric country code at the EOM snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer.CountryID — the point-in-time country recorded at that EOM. Decoded to text via SnapshotCountry. May differ from current CountryID for customers who have relocated. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 6 | SnapshotPlayerLevelID | int | YES | Club tier ID at the EOM snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer.PlayerLevelID — the point-in-time club tier recorded at that EOM. Decoded to text via SnapshotClub. May differ from current club for customers who have changed tier since that EOM. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 7 | SnapshotClub | nvarchar(50) | YES | Club tier name at the EOM snapshot date — JOIN decode of SnapshotPlayerLevelID via DWH_dbo.Dim_PlayerLevel.Name. Mar 2026 distribution: Bronze=97.5%, Silver=0.9%, Gold=0.8%, Platinum=0.4%, Platinum Plus=0.3%. Point-in-time; use for historical cohort analysis. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 8 | SnapshotCountry | nvarchar(100) | YES | Country name at the EOM snapshot date — JOIN decode of SnapshotCountryID via DWH_dbo.Dim_Country.Name. Mar 2026 top 5: United Kingdom (4.9M), France (3.9M), Germany (3.6M), Italy (2.9M), Spain (1.7M). 34 distinct countries. Point-in-time; use for historical cohort analysis. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 9 | AccountSubProgram | nvarchar(50) | YES | eToro Money account sub-program classification. LEFT JOIN from eMoney_Dim_Account.AccountSubProgram on GCID_Unique_Count=1. NULL for customers not in the account dimension or with multiple eMoney accounts. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 10 | FMI_Date | date | YES | Date of the customer's first settled money-in transaction in eToro Money. Sourced from eMoney_Card_Instance_Summary.FMI_Date (originally derived in eMoney_Panel_FirstDates from eMoney_Dim_Transaction). NULL for customers who have never funded. (Tier 2 — eMoney_Card_Instance_Summary) |
| 11 | CardCreateDate | date | YES | Date the customer's most recently created card was issued (FiatCards.Created). MAX(eMoney_Card_Instance_Summary.CardCreateDate) per CID. NULL for the majority of rows (~99.65%) where the customer has not applied for a debit card. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 12 | LastInstanceActivationDate | date | YES | Date the customer's most recently activated card instance was activated. MAX(eMoney_Card_Instance_Summary.InstanceActivationDate) per CID. NULL for customers who have never activated a card. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 13 | LastInstanceTxAfterActivationCount | int | YES | Count of settled card transactions on the customer's most recently active card instance. MAX(eMoney_Card_Instance_Summary.TxAfterActivationCount) per CID. NULL for customers with no card data. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 14 | FirstInstanceCreatedDate | date | YES | Date the customer's first-ever card instance was issued. MIN(InstanceCreatedDate) via ROW_NUMBER() ASC from eMoney_Card_Instance_Summary. NULL for customers with no card status history recorded. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 15 | FirstInstanceActivationDate | date | YES | Date the customer first activated any card instance. MIN(InstanceActivationDate) via ROW_NUMBER() from eMoney_Card_Instance_Summary. NULL for customers who have never activated a card. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 16 | FirstTxAfterActivationCount | int | YES | Count of settled card transactions on the customer's first (oldest) activated card instance. TxAfterActivationCount for the instance with ROW_NUMBER=1 ordered by InstanceCreatedDate ASC. NULL for customers with no card instances. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 17 | Tx1_AfterFirst | date | YES | Date of the customer's 1st settled card transaction after first card activation (FirstInstanceActivationDate). Derived from eMoney_Dim_Transaction (TxTypeID IN [1,2,3,4], IsTxSettled=1). Not snapshot-bounded — same value across all EOM rows once the event occurs. NULL if no settled card transaction after first activation. (Tier 2 — eMoney_Dim_Transaction) |
| 18 | Tx2_AfterFirst | date | YES | Date of the customer's 2nd settled card transaction after first card activation. NULL if fewer than 2 settled card transactions after first activation. Not snapshot-bounded. (Tier 2 — eMoney_Dim_Transaction) |
| 19 | Tx1_AfterLast | date | YES | Date of the customer's 1st settled card transaction after most recent card activation (LastInstanceActivationDate). Not snapshot-bounded. NULL if no settled card transaction after last activation. (Tier 2 — eMoney_Dim_Transaction) |
| 20 | Tx2_AfterLast | date | YES | Date of the customer's 2nd settled card transaction after most recent card activation. NULL if fewer than 2 settled card transactions after last activation. Not snapshot-bounded. (Tier 2 — eMoney_Dim_Transaction) |
| 21 | Country | nvarchar(100) | YES | Customer's CURRENT country name at SP execution time. Derived via DWH_dbo.Dim_Customer (current CountryID) JOIN DWH_dbo.Dim_Country.Name. Identical across all EOM snapshot rows for the same customer — does not change per snapshot. Use SnapshotCountry for historical attribution. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 22 | Club | nvarchar(50) | YES | Customer's CURRENT club tier name at SP execution time. Derived via DWH_dbo.Dim_Customer (current PlayerLevelID) JOIN DWH_dbo.Dim_PlayerLevel.Name. Identical across all EOM snapshot rows for the same customer — does not change per snapshot. Use SnapshotClub for historical attribution. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |
| 23 | UpdateDate | datetime | NO | Timestamp when this snapshot batch was written by the SP. Set to GETDATE() at INSERT time. All rows for the same SnapShotDateID from the same SP run share the same UpdateDate. Not a business event timestamp. (Tier 2 — SP_eMoney_Card_Monthly_Snapshot) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | etoro.Customer.CustomerStatic | CID | Passthrough via Fact_SnapshotCustomer.RealCID |
| GCID | FiatDwhDB.dbo.FiatAccount | Gcid | Passthrough via Fact_SnapshotCustomer.GCID |
| SnapshotCountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | Point-in-time country at EOM |
| SnapshotPlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Point-in-time club at EOM |
| SnapshotClub | DWH_dbo.Dim_PlayerLevel | Name | Decode of SnapshotPlayerLevelID |
| SnapshotCountry | DWH_dbo.Dim_Country | Name | Decode of SnapshotCountryID |
| AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | LEFT JOIN on GCID_Unique_Count=1 |
| FMI_Date | FiatDwhDB.dbo.FiatTransactions (via CIS) | TxStatusModificationDate | From eMoney_Card_Instance_Summary.FMI_Date |
| CardCreateDate | FiatDwhDB.dbo.FiatCards | Created | MAX per CID via eMoney_Card_Instance_Summary |
| LastInstanceActivationDate | FiatDwhDB.dbo.FiatCardStatuses | EventTimestamp | MAX InstanceActivationDate per CID via CIS |
| LastInstanceTxAfterActivationCount | eMoney_dbo.eMoney_Card_Instance_Summary | TxAfterActivationCount | MAX per CID |
| FirstInstanceCreatedDate | FiatDwhDB.dbo.FiatCardStatuses | EventTimestamp | MIN InstanceCreatedDate (RNDasc=1) via CIS |
| FirstInstanceActivationDate | FiatDwhDB.dbo.FiatCardStatuses | EventTimestamp | MIN InstanceActivationDate (RNDasc=1) via CIS |
| FirstTxAfterActivationCount | eMoney_dbo.eMoney_Card_Instance_Summary | TxAfterActivationCount | For RNDasc=1 instance |
| Tx1_AfterFirst | eMoney_dbo.eMoney_Dim_Transaction | TxStatusModificationDate | 1st settled card TX after first activation |
| Tx2_AfterFirst | eMoney_dbo.eMoney_Dim_Transaction | TxStatusModificationDate | 2nd settled card TX after first activation |
| Tx1_AfterLast | eMoney_dbo.eMoney_Dim_Transaction | TxStatusModificationDate | 1st settled card TX after last activation |
| Tx2_AfterLast | eMoney_dbo.eMoney_Dim_Transaction | TxStatusModificationDate | 2nd settled card TX after last activation |
| Country | DWH_dbo.Dim_Country | Name | Current country via Dim_Customer JOIN Dim_Country |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Current club via Dim_Customer JOIN Dim_PlayerLevel |
| UpdateDate | ETL metadata | — | GETDATE() at INSERT |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1, EOM customer universe)
  + eMoney_dbo.eMoney_Dim_Country_Rollout (34-country eTM filter)
  + DWH_dbo.Dim_Range (valid snapshot period JOIN)
  + DWH_dbo.Dim_PlayerLevel, Dim_Country (EOM attribute decode)
  + eMoney_dbo.eMoney_Dim_Account (AccountSubProgram; LEFT JOIN GCID_Unique_Count=1)
  |-- SP Step T2: #T2 (EOM eligible customer base) ---|
  v
eMoney_dbo.eMoney_Card_Instance_Summary (card timelines per CID)
  |-- SP Steps T3–T4: #T3 (last instance per CID), #T4 (first instance per CID) ---|
  v
DWH_dbo.Dim_Customer (current country/club)
  |-- SP Step T5: #T5 (pre-final join) ---|
  v
eMoney_dbo.eMoney_Dim_Transaction (settled card TXs after activation)
  |-- SP Step T6: #T6 (Tx1/Tx2 after first/last activation) ---|
  v
SP_eMoney_Card_Monthly_Snapshot: DELETE WHERE SnapShotDateID + INSERT per EOM
  v
eMoney_dbo.eMoney_Card_Monthly_Snapshot (566M rows, 27 EOM snapshots, HASH(CID), HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (via RealCID) | Current customer trading profile |
| GCID | FiatDwhDB.dbo.FiatAccount (via Synapse external) | eTM account identity |
| SnapshotCountryID | DWH_dbo.Dim_Country | Country decode |
| SnapshotPlayerLevelID | DWH_dbo.Dim_PlayerLevel | Club tier decode |
| EOM universe | DWH_dbo.Fact_SnapshotCustomer | Source of eligible customer population per EOM |
| Country filter | eMoney_dbo.eMoney_Dim_Country_Rollout | 34-country eTM rollout gate |
| Card data | eMoney_dbo.eMoney_Card_Instance_Summary | Source of all card date and TX count columns |
| Tx dates | eMoney_dbo.eMoney_Dim_Transaction | Source of Tx1/Tx2 after activation dates |
| AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | Sub-program classification (LEFT JOIN) |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| Tableau debit card funnel dashboards | Primary data source for monthly eTM card funnel KPIs |
| main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot | UC Gold export (Generic Pipeline, delta) |

---

## 7. Sample Queries

```sql
-- Latest EOM snapshot: card funnel stages by country
SELECT
    SnapshotCountry,
    COUNT(*) AS eligible_customers,
    SUM(CASE WHEN CardCreateDate IS NOT NULL THEN 1 ELSE 0 END) AS card_issued,
    SUM(CASE WHEN FirstInstanceActivationDate IS NOT NULL THEN 1 ELSE 0 END) AS card_activated,
    SUM(CASE WHEN Tx1_AfterFirst IS NOT NULL THEN 1 ELSE 0 END) AS first_tx_made,
    SUM(CASE WHEN Tx2_AfterFirst IS NOT NULL THEN 1 ELSE 0 END) AS second_tx_made
FROM eMoney_dbo.eMoney_Card_Monthly_Snapshot
WHERE SnapShotDate = '2026-03-31'
GROUP BY SnapshotCountry
ORDER BY card_issued DESC;
```

```sql
-- Monthly card activation rate trend (all 27 EOM snapshots)
SELECT
    SnapShotDate,
    COUNT(*) AS total_eligible,
    SUM(CASE WHEN FirstInstanceActivationDate IS NOT NULL THEN 1 ELSE 0 END) AS activated,
    CAST(SUM(CASE WHEN FirstInstanceActivationDate IS NOT NULL THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS activation_rate_pct
FROM eMoney_dbo.eMoney_Card_Monthly_Snapshot
GROUP BY SnapShotDate
ORDER BY SnapShotDate;
```

```sql
-- Time-to-first transaction after first card activation (activated customers only)
SELECT
    SnapShotDate,
    AVG(DATEDIFF(day, FirstInstanceActivationDate, Tx1_AfterFirst)) AS avg_days_to_first_tx,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(day, FirstInstanceActivationDate, Tx1_AfterFirst)) 
        OVER (PARTITION BY SnapShotDate) AS median_days_to_first_tx
FROM eMoney_dbo.eMoney_Card_Monthly_Snapshot
WHERE SnapShotDate = '2026-03-31'
    AND FirstInstanceActivationDate IS NOT NULL
    AND Tx1_AfterFirst IS NOT NULL;
```

---

## 8. Sources

No Atlassian documentation found for this object.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 2 T1, 21 T2, 0 T3, 0 T4, 0 T5 | Elements: 23/23*

> **Phase Gate Check**: T1 columns (CID, GCID) verified against upstream wikis — descriptions match eMoney_Account_Mappings.md (#14 GCID), eMoney_Dim_Account.md (#3 GCID), eMoney_Card_Instance_Summary.md (#1 CID). All 23 elements documented. Snapshot vs current attribute distinction documented in Business Logic 2.2. Funnel signal hierarchy documented in Business Meaning. Scale advisory (566M rows, date-filter first) in Section 3.

> **T1 Copy Verification**: CID — verbatim "Customer ID - platform-internal primary key..." from Customer.CustomerStatic (matches eMoney_Card_Instance_Summary #1). GCID — verbatim "Global Customer ID. Identifies the customer across all eToro platforms..." from dbo.FiatAccount (matches eMoney_Account_Mappings #14, eMoney_Panel_FirstDates #2, eMoney_Dim_Account #3).
