# BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks

> 164K-row tax compliance flag table identifying eToro customers who have traded CFD US stocks but have never traded REAL (settled) US stocks, sourced from Dim_Customer + Fact_CustomerAction + Dim_Instrument via SP_Tax_Compliance_W8_AND_TIN. Daily UPDATE refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + Dim_Customer + Dim_Instrument via SP_Tax_Compliance_W8_AND_TIN |
| **Refresh** | Daily (UPDATE on matched CID via OpsDB Service Broker, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | _Not in Generic Pipeline mapping — may not be exported to UC_ |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Tax_Compliance_Trade_CFD_US_Stocks` is a simple flag table identifying 164K customers who have traded CFD (Contract for Difference) US stocks but have never executed a settled (REAL) US stock trade. This distinction matters for US tax compliance because CFD trading and real stock ownership have different tax reporting obligations.

The ETL logic in `SP_Tax_Compliance_W8_AND_TIN` (CFD US Stocks section):
1. Filters US stocks from Dim_Instrument (InstrumentTypeID IN (5=Stock, 6=ETF) AND ISINCode starts with 'US')
2. Gets valid depositor CIDs from Dim_Customer (IsValidCustomer=1 AND IsDepositor=1), joined to Dim_Regulation for regulation context
3. Queries Fact_CustomerAction (ActionTypeID IN (1,2,3) = Buy/Sell/Limit actions) to find CIDs that have `MAX(IsSettled=0)=1` (traded CFD) AND `MAX(IsSettled=1)=0` (never traded REAL)
4. UPDATE-only merge (original MERGE with INSERT/DELETE is commented out)

This table is consumed alongside BI_DB_Tax_Compliance_TIN and BI_DB_Tax_Compliance_W8 for tax compliance reporting workflows.

---

## 2. Business Logic

### 2.1 CFD-Only US Stock Filter

**What**: Identifies customers who have ONLY traded CFD US stocks, never settled/real US stocks.
**Columns Involved**: `CID` (the output is binary membership — presence in this table = CFD-only)
**Rules**:
- US stocks: Dim_Instrument.InstrumentTypeID IN (5, 6) AND LEFT(ISINCode, 2) = 'US'
- CFD trade: Fact_CustomerAction.IsSettled = 0
- Real trade: Fact_CustomerAction.IsSettled = 1
- Inclusion: MAX(IsSettled=0) = 1 AND MAX(IsSettled=1) = 0 (has CFD trades, zero real trades)
- Only valid depositors (Dim_Customer.IsValidCustomer=1 AND IsDepositor=1)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CID. Simple flag table — best used as a filter in JOINs.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Is this customer CFD-only for US stocks? | `WHERE EXISTS (SELECT 1 FROM BI_DB_Tax_Compliance_Trade_CFD_US_Stocks WHERE CID = @CID)` |
| Count of CFD-only US stock traders | `SELECT COUNT(*) FROM BI_DB_Tax_Compliance_Trade_CFD_US_Stocks` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics for CFD-only traders |
| BI_DB_dbo.BI_DB_Tax_Compliance_TIN | CID = CID | TIN data for CFD-only traders |
| BI_DB_dbo.BI_DB_Tax_Compliance_W8 | CID = CID | W8 form status for CFD-only traders |

### 3.4 Gotchas

- **Membership = flag**: Presence in this table means the customer is CFD-only for US stocks. There is no explicit flag column — the table IS the flag.
- **UPDATE-only ETL**: Like the TIN table, the MERGE is commented out. New qualifying CIDs may not appear if they were never initially inserted.
- **No Regulation column stored**: The SP calculates regulation in a temp table (#validusers) but does not persist it to the output.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 5 | ETL metadata | Standard ETL infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID. Filtered to valid depositors who traded CFD US stocks but never REAL US stocks. (Tier 1 — Customer.CustomerStatic) |
| 2 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer (← Customer.CustomerStatic) | RealCID | Rename; filtered by CFD-only US stock trading logic |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID IN 5,6, ISINCode LIKE 'US%')
  + DWH_dbo.Fact_CustomerAction (ActionTypeID IN 1,2,3)
  + DWH_dbo.Dim_Regulation (regulation context)
  |-- SP_Tax_Compliance_W8_AND_TIN @Date (CFD US Stocks section) --|
  |-- Filter: MAX(IsSettled=0)=1 AND MAX(IsSettled=1)=0 --|
  v
BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks (164K rows)
  |-- No UC mapping found --|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer master dimension |

### 6.2 Referenced By (other objects point to this)

No consumer SPs found referencing this table beyond the writer SP.

---

## 7. Sample Queries

### 7.1 CFD-only US stock traders with customer details

```sql
SELECT t.CID, dc.UserName, dc.CountryID, dc.RegulationID, t.UpdateDate
FROM BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks t
JOIN DWH_dbo.Dim_Customer dc ON t.CID = dc.RealCID
```

### 7.2 CFD-only traders with TIN data

```sql
SELECT t.CID, tin.TIN_CountryName, tin.TIN_Value, tin.TypeIDName
FROM BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks t
JOIN BI_DB_dbo.BI_DB_Tax_Compliance_TIN tin ON t.CID = tin.CID AND tin.RN_TIN_CID_Country = 1
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 0 T2, 0 T3, 0 T4, 1 T5 | Elements: 2/2, Logic: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks | Type: Table | Production Source: Dim_Customer + Fact_CustomerAction + Dim_Instrument via SP_Tax_Compliance_W8_AND_TIN*
