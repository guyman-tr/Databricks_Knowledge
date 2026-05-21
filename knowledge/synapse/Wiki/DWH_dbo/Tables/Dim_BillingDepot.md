# DWH_dbo.Dim_BillingDepot

> Lookup dimension of payment gateway endpoints ("depots"), each configuring one (FundingType + PaymentType + Protocol) routing combination. Sourced daily from etoro.Billing.Depot via SP_Dictionaries_DL_To_Synapse. 163 rows; 114 active.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Depot |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DepotID) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BillingDepot is the DWH version of etoro.Billing.Depot -- the central payment gateway routing configuration table. Each row defines one payment depot: a named combination of payment method (FundingTypeID), payment direction (PaymentTypeID: Deposit/Cashout/Refund), and processing gateway (ProtocolID). The routing engine selects a depot to process each transaction based on these three dimensions plus customer-specific factors (regulation, BIN, quotas).

Source: etoro.Billing.Depot on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Billing/Depot/ and staged into DWH_staging.etoro_Billing_Depot. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

163 rows total (DepotID range 1-174 with gaps); 114 active (70%), 49 inactive (legacy or decommissioned). The DWH includes only 7 of the 8 production columns -- PayoutGeneration and Features are excluded by the ETL SELECT.

Sample depots: 1=MoneyBookers USD, 7=Neteller, 10=Wire, 3=WebMoney, 4=Giropay.

---

## 2. Business Logic

### 2.1 Depot Routing Selection

**What**: The payment routing engine selects a depot for each transaction based on FundingTypeID, PaymentTypeID, and ProtocolID combined with customer-specific routing criteria.

**Columns Involved**: `DepotID`, `FundingTypeID`, `PaymentTypeID`, `ProtocolID`, `IsActive`

**Rules**:
- Only depots with IsActive=1 are eligible for routing (114 of 163)
- IsActive=0 or NULL means the depot is inactive (legacy or decommissioned) -- excluded from routing
- The (FundingTypeID, PaymentTypeID, ProtocolID) triple uniquely identifies a depot endpoint
- PaymentTypeID: 1=Deposit, 2=Cashout, 3=Refund

**Dimension Relationships**:
- FundingTypeID references Dictionary.FundingType (payment method: CreditCard, Wire, Neteller, etc.)
- PaymentTypeID references Dictionary.PaymentType (1=Deposit, 2=Cashout, 3=Refund)
- ProtocolID references Dictionary.Protocol (specific gateway API)

### 2.2 DWH Completeness Note

**Excluded from DWH**: The production Billing.Depot table also has PayoutGeneration (automated payout file support) and Features (per-depot JSON/XML configuration flags). These columns are not in the SP SELECT and are not present in Dim_BillingDepot. Analyses requiring payout generation capability or feature flags must query the production source.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on DepotID. REPLICATE is correct for a 163-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs. The clustered index on DepotID supports efficient point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 163-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active payment depots | WHERE IsActive = 1 |
| Deposit depots by payment method | WHERE PaymentTypeID = 1, GROUP BY FundingTypeID |
| Cashout-capable depots | WHERE PaymentTypeID = 2 AND IsActive = 1 |
| Depots for a specific gateway | WHERE ProtocolID = N |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON DepotID | MID configuration per depot |
| Fact tables (deposit/cashout) | ON DepotID | Resolve depot name and attributes for transactions |

### 3.4 Gotchas

- **IsActive NULL = Inactive**: The column is nullable. NULL should be treated as inactive (not eligible for routing). Use `WHERE IsActive = 1` rather than `WHERE IsActive <> 0`.
- **No InsertDate**: Unlike most other Dim_ tables loaded by SP_Dictionaries, this table has only UpdateDate (no InsertDate, no StatusID, no DWH surrogate key).
- **PayoutGeneration/Features not in DWH**: Two production columns are excluded. For payout batch analysis, the production source must be queried directly.
- **163 rows total, 114 active**: Inactive rows represent legacy/decommissioned gateway integrations. Do not assume all rows are usable.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Billing.Depot) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepotID | int | NOT NULL | Primary key. Manually assigned (no IDENTITY). Stable identifier for this payment gateway endpoint. Range 1-174 with gaps; 163 rows. Referenced by fact deposit/cashout tables and MID settings. (Tier 1 - upstream wiki, Billing.Depot) |
| 2 | FundingTypeID | int | NOT NULL | Payment method type (e.g., 1=CreditCard, 6=Wire, 7=PayPal). References Dictionary.FundingType. 38 distinct values across 163 depots. |
| 3 | PaymentTypeID | int | NOT NULL | Direction of payment flow. 1=Deposit, 2=Cashout, 3=Refund. References Dictionary.PaymentType. (Tier 1 - upstream wiki, Billing.Depot) |
| 4 | ProtocolID | int | NOT NULL | Payment processing protocol/gateway. References Dictionary.Protocol. Identifies the specific API or connection (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). (Tier 1 - upstream wiki, Billing.Depot) |
| 5 | Name | varchar(50) | NOT NULL | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 - upstream wiki, Billing.Depot) |
| 6 | IsActive | bit | YES | Whether this depot currently accepts transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. (Tier 1 - upstream wiki, Billing.Depot) |
| 7 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production depot configuration changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DepotID | etoro.Billing.Depot | DepotID | Passthrough |
| FundingTypeID | etoro.Billing.Depot | FundingTypeID | Passthrough |
| PaymentTypeID | etoro.Billing.Depot | PaymentTypeID | Passthrough |
| ProtocolID | etoro.Billing.Depot | ProtocolID | Passthrough |
| Name | etoro.Billing.Depot | Name | Passthrough |
| IsActive | etoro.Billing.Depot | IsActive | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| *(excluded)* | etoro.Billing.Depot | PayoutGeneration | Not loaded into DWH |
| *(excluded)* | etoro.Billing.Depot | Features | Not loaded into DWH |

### 5.2 ETL Pipeline

```
etoro.Billing.Depot -> Generic Pipeline (daily, Override) -> Bronze/etoro/Billing/Depot/ -> DWH_staging.etoro_Billing_Depot -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BillingDepot
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.Depot | 163-row payment depot registry (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/Depot/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Billing_Depot | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; 7 of 8 production columns loaded; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_BillingDepot | 163 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DepotID | etoro.Billing.Depot | Production source (upstream reference) |
| FundingTypeID | etoro.Dictionary.FundingType | Payment method lookup (implicit -- no FK in DWH) |
| PaymentTypeID | etoro.Dictionary.PaymentType | Payment direction lookup (implicit -- no FK in DWH) |
| ProtocolID | etoro.Dictionary.Protocol | Gateway protocol lookup (implicit -- no FK in DWH) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | DepotID | MID configuration per depot |

---

## 7. Sample Queries

### 7.1 List active depots

```sql
SELECT DepotID, Name, FundingTypeID, PaymentTypeID, ProtocolID
FROM [DWH_dbo].[Dim_BillingDepot]
WHERE IsActive = 1
ORDER BY FundingTypeID, PaymentTypeID
```

### 7.2 Count depots by payment direction

```sql
SELECT
    PaymentTypeID,
    CASE PaymentTypeID WHEN 1 THEN 'Deposit' WHEN 2 THEN 'Cashout' WHEN 3 THEN 'Refund' ELSE 'Unknown' END AS Direction,
    COUNT(*) AS TotalDepots,
    SUM(CAST(ISNULL(IsActive, 0) AS INT)) AS ActiveDepots
FROM [DWH_dbo].[Dim_BillingDepot]
GROUP BY PaymentTypeID
ORDER BY PaymentTypeID
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS DepotCount
FROM [DWH_dbo].[Dim_BillingDepot]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 6 T1, 1 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BillingDepot | Type: Table | Production Source: etoro.Billing.Depot*
