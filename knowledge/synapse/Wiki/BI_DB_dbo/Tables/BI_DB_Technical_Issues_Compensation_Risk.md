# BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk

> 310K-row compensation tracking table recording credit payments made to customers as compensation for platform technical issues (best execution slippage, latency, off-market rates), sourced from etoro.History.Credit via SP_Technical_Issues_Compensation_Risk. Covers compensations from July 2023 to present across 8 regulations. Daily DELETE+INSERT refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.History.Credit (CreditTypeID=6, MoveMoneyReasonID=1, CompensationReasonID=3) via SP_Technical_Issues_Compensation_Risk (author: Artyom Bogomolsky, 2024-07-25) |
| **Refresh** | Daily (DELETE+INSERT by @DateID via OpsDB Service Broker, Priority 0) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not in Generic Pipeline mapping — may not be exported to UC_ |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Technical_Issues_Compensation_Risk` tracks credit payments made to customers as compensation for technical issues on the eToro platform. Each row represents one compensation credit event, recording the customer (CID), the payment amount, the regulatory entity, the credit identifier, and a free-text description of the technical issue.

The table contains 310K rows spanning from July 2023 to July 2025. The largest regulation by volume is CySEC (257K rows), followed by FCA (35K), ASIC & GAML (8.2K), and FSA Seychelles (6.8K). Notably, CySEC has a negative total payment (-373K), suggesting credits that are debits/reversals, while FCA has the largest positive total (977K).

Common compensation reasons visible in the descriptions include: "Best Execution Slippage", "Best execution - Latency", "First Republic Bank off market rate", and "Order display issue".

The ETL uses a dynamic external table pattern: `SP_Create_External_etoro_History_Credit` creates a temporary external table for the date's History.Credit data, the SP filters for technical issue compensations (CreditTypeID=6 AND MoveMoneyReasonID=1 AND CompensationReasonID=3), enriches with regulation from `Fact_SnapshotCustomer` + `Dim_Regulation`, and does DELETE+INSERT by DateID.

---

## 2. Business Logic

### 2.1 Technical Issue Compensation Filter

**What**: Isolates compensation credits specifically for technical/platform issues from the full History.Credit stream.
**Columns Involved**: All (the filter determines table membership)
**Rules**:
- CreditTypeID = 6 (Compensation credit type)
- MoveMoneyReasonID = 1 (specific money movement reason)
- CompensationReasonID = 3 (technical issue reason)
- All three conditions must be met — this is a highly specific filter

### 2.2 Regulation via Snapshot

**What**: Customer's regulation is determined at the snapshot date, not at compensation time.
**Columns Involved**: `Regulation`
**Rules**:
- JOINs to Fact_SnapshotCustomer (not Dim_Customer) to get RegulationID
- Uses Dim_Range to validate the @DateID falls within the snapshot's date range
- This means the regulation reflects the customer's regulatory entity at the ETL run date, which may differ from their regulation at the time of the compensation event

### 2.3 Month Bucketing

**What**: Compensation events are bucketed to month-end date for monthly aggregation.
**Columns Involved**: `Month`
**Rules**:
- EOMONTH(Occurred) — last day of the month containing the compensation event
- Enables GROUP BY Month for monthly reporting

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution with HEAP. Good for CID-level joins to Dim_Customer (also HASH on RealCID) — co-located data for single-customer queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Total compensation by regulation | `GROUP BY Regulation` |
| Monthly compensation trend | `GROUP BY Month` |
| Specific issue compensations | `WHERE Description LIKE '%Slippage%'` |
| Customer total compensation | `WHERE CID = @CID, SUM(Payment)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics |
| DWH_dbo.Dim_Regulation | Regulation = Name | Full regulation details |

### 3.4 Gotchas

- **Payment can be negative**: CySEC shows negative totals — some compensations are reversals/debits, not credits
- **Regulation is snapshot-based**: The regulation reflects the customer's status at ETL run date, not at compensation occurrence date
- **Dynamic External table**: The external table `External_etoro_History_Credit_Compensation_Risk` is created and dropped within the SP — it does not persist
- **Description is free-text**: Not normalized — same incident may have different description strings

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | ETL metadata | Standard ETL infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. From History.Credit. (Tier 1 — Customer.CustomerStatic) |
| 2 | Payment | money | YES | Credit payment amount for this compensation event. Positive = credit to customer, negative = debit/reversal. From History.Credit.Payment. (Tier 2 — SP_Technical_Issues_Compensation_Risk) |
| 3 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.Name. 8 distinct values: CySEC, FCA, ASIC & GAML, FSA Seychelles, FSRA, FinCEN+FINRA, BVI, ASIC. (Tier 1 — Dictionary.Regulation) |
| 4 | CreditID | bigint | YES | Unique identifier for this credit transaction in the History.Credit system. From History.Credit.CreditID. (Tier 2 — SP_Technical_Issues_Compensation_Risk) |
| 5 | Description | varchar(max) | YES | Free-text description of the technical issue that triggered the compensation. Common patterns: 'Best Execution Slippage', 'Best execution - Latency', 'First Republic Bank off market rate', 'Order display issue'. From History.Credit.Description. (Tier 2 — SP_Technical_Issues_Compensation_Risk) |
| 6 | DateID | int | YES | YYYYMMDD integer date key. Set to @DateID (the SP execution date converted to int). Used as partition key for DELETE+INSERT. (Tier 2 — SP_Technical_Issues_Compensation_Risk) |
| 7 | Occurred | datetime | YES | Timestamp when the compensation credit was created in the History.Credit system. From History.Credit.Occurred. (Tier 2 — SP_Technical_Issues_Compensation_Risk) |
| 8 | Month | date | YES | End-of-month date for the compensation occurrence. ETL-computed as EOMONTH(Occurred). Used for monthly aggregation reporting. (Tier 2 — SP_Technical_Issues_Compensation_Risk) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | etoro.History.Credit | CID | Passthrough (filtered) |
| Payment | etoro.History.Credit | Payment | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation (← Dictionary.Regulation) | Name | Dim-lookup via Fact_SnapshotCustomer |
| CreditID | etoro.History.Credit | CreditID | Passthrough |
| Description | etoro.History.Credit | Description | Passthrough |
| DateID | (SP parameter) | @DateID | YYYYMMDD int |
| Occurred | etoro.History.Credit | Occurred | Passthrough |
| Month | etoro.History.Credit | Occurred | EOMONTH() |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
etoro.History.Credit (production OLTP, credit transactions)
  |-- SP_Create_External_etoro_History_Credit @Date, 'Compensation_Risk' --|
  v
BI_DB_dbo.External_etoro_History_Credit_Compensation_Risk (Dynamic External table, dropped after use)
  + DWH_dbo.Fact_SnapshotCustomer (customer→regulation at date)
  + DWH_dbo.Dim_Range (date range validity)
  + DWH_dbo.Dim_Regulation (RegulationID→Name)
  |-- SP_Technical_Issues_Compensation_Risk @Date --|
  |-- Filter: CreditTypeID=6, MoveMoneyReasonID=1, CompensationReasonID=3 --|
  |-- DELETE+INSERT by @DateID --|
  v
BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk (310K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer master dimension |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulation dimension |

### 6.2 Referenced By (other objects point to this)

No consumer SPs found referencing this table.

---

## 7. Sample Queries

### 7.1 Total compensation by regulation

```sql
SELECT Regulation, COUNT(*) AS events, SUM(Payment) AS total_payment
FROM BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk
GROUP BY Regulation
ORDER BY total_payment DESC
```

### 7.2 Monthly compensation trend

```sql
SELECT Month, COUNT(*) AS events, SUM(Payment) AS total_payment
FROM BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk
GROUP BY Month
ORDER BY Month
```

### 7.3 Top compensation events by amount

```sql
SELECT TOP 20 CID, Payment, Description, Occurred, Regulation
FROM BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk
ORDER BY ABS(Payment) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 2 T1, 6 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk | Type: Table | Production Source: etoro.History.Credit via SP_Technical_Issues_Compensation_Risk*
