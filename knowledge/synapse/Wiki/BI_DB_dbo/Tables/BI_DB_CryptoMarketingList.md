# BI_DB_dbo.BI_DB_CryptoMarketingList

> 11.3M-row daily full-refresh crypto marketing list. Identifies 1.77M distinct GCIDs (group customer IDs) across three crypto engagement segments: active holders, recent traders (open/closed last 3M), and new crypto leads (funnel registrants not yet traded). Powers marketing outreach targeting and opt-in filtering. TRUNCATE+INSERT daily. Last refreshed: 2026-04-13.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + Dim_Position + BI_DB_PositionPnL + Dim_Instrument + Dim_Regulation + Dim_Country + External_SettingsDB_Settings_CustomerData via SP_CryptoMarketingList |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild, no date parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CryptoMarketingList is a daily-refreshed marketing segmentation table that identifies all eToro customers with any crypto engagement. It is consumed by the marketing team to target crypto-related campaigns, segment customers by engagement type, and filter for opt-in eligibility.

**Key identifier**: Uses GCID (not CID/RealCID). GCID is the marketing group customer ID in Dim_Customer — the identifier used by CRM and communication systems. One customer can appear multiple times if they hold multiple crypto instruments.

**Three segments** defined by `Category`:
1. **'Holded Postions'** (SP typo for "Positions") — customers with open crypto positions at yesterday's date, per instrument held. One row per (GCID × held crypto instrument). 6.97M rows (61.8%).
2. **'Opened/Closed Positions'** — customers who opened or closed any crypto position in the last 3 months. One row per GCID. 4.31M rows (38.2%).
3. **'Crypto Leads'** — customers who registered via the Crypto funnel (FunnelFromID=57) in the last 3 months and have not yet executed their first action. Very small (2,864 rows on 2026-04-13).

**Opt-in segmentation**: IsOptIn flags contactable customers. 'No' = customer explicitly opted out via SettingsDB (ResourceId=5564, SelectedValue='2'). Approximately 20–21% of Holded and Opened/Closed categories are opted-out. All Crypto Leads are opted-in (no opt-outs in that cohort as of 2026-04-13).

**Holding duration**: HoldedAbove buckets how long a position has been open. 67% of holders have held for >5 months — strong long-term holder base.

---

## 2. Business Logic

### 2.1 Segment 1 — Holded Positions

**What**: Customers with currently open real crypto positions at yesterday's date, one row per held instrument.

**Columns Involved**: `Category`, `CryptoHolded`, `HoldedEligibleCoins`, `HoldedAbove`

**Rules**:
- Source: BI_DB_PositionPnL WHERE DateID=yesterday AND InstrumentTypeID=10
- One row per (GCID, crypto instrument) — a GCID holding BTC + ETH appears twice
- CryptoHolded: InstrumentDisplayName if Dim_Instrument.IsMajor='Yes', else 'No'
- HoldedEligibleCoins: 'Yes' if InstrumentID IN (100000, 100001, 100002, 100003, 100005, 100020) — specific promotional eligible coins; 'No' otherwise
- HoldedAbove: holding duration in MONTH buckets based on DATEDIFF(MONTH, Occurred, Date): 'Holded_Less_1_Month', 'Holded_Above_1_Month', ..., 'Holded_Above_5_Month'
- NOTE: `Category = 'Holded Postions'` — SP contains a typo (missing 'i' in Positions). Use this exact string in queries.

### 2.2 Segment 2 — Opened/Closed Positions

**What**: Customers who were recently active in crypto trading (last 3 months).

**Columns Involved**: `Category`

**Rules**:
- Source: Dim_Position WHERE (CloseDateID BETWEEN @BeginOfPeriodID AND @DateID) OR (OpenDateID BETWEEN @BeginOfPeriodID AND @DateID) AND InstrumentTypeID=10
- One row per GCID (DISTINCT)
- CryptoHolded='No', HoldedEligibleCoins='No', HoldedAbove='Not Holded' for this segment (no holdings context)

### 2.3 Segment 3 — Crypto Leads

**What**: New registrants from the Crypto acquisition funnel who have not yet made their first trade.

**Columns Involved**: `Category`

**Rules**:
- Source: Dim_Customer WHERE FunnelFromID=57 (Crypto funnel) AND RegisteredReal >= 3 months ago
- LEFT JOIN BI_DB_First5Actions WHERE FirstAction IS NULL — no first action means pre-FTD
- Represents the earliest lifecycle stage: registered, not converted
- Very small cohort (2,864 on 2026-04-13)
- CryptoHolded='No', HoldedEligibleCoins='No', HoldedAbove='Not Holded'

### 2.4 Opt-In Eligibility

**What**: IsOptIn flags whether the customer is reachable for marketing outreach.

**Columns Involved**: `IsOptIn`

**Rules**:
- 'Yes': customer is NOT in the opt-out list for ResourceId=5564, SelectedValue='2' in External_SettingsDB_Settings_CustomerData — default for all customers who haven't explicitly opted out
- 'No': customer has explicitly opted out of marketing communications
- ~79% opted-in, ~21% opted-out across Holded and Opened/Closed segments

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP — no clustered index. Full-table scans required. Filter early on Category and IsOptIn before joining.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Opt-in crypto holders eligible for campaign | `WHERE Category='Holded Postions' AND IsOptIn='Yes'` |
| Long-term holders (>5 months) for retention | `WHERE Category='Holded Postions' AND HoldedAbove='Holded_Above_5_Month'` |
| Eligible coin holders for specific promotion | `WHERE HoldedEligibleCoins='Yes' AND IsOptIn='Yes'` |
| Crypto leads for conversion campaign | `WHERE Category='Crypto Leads'` |
| Recent traders not currently holding | `WHERE Category='Opened/Closed Positions' AND IsOptIn='Yes'` |
| Customers with eToro wallet | `WHERE HasWallet=1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON ml.GCID = dc.GCID` | Get RealCID, email, or other customer attributes |
| BI_DB_dbo.BI_DB_CryptoDashboardNew | `ON dc.RealCID = cd.CID AND cd.DateID=X` | Add AUA / PnL for portfolio-based targeting |

### 3.4 Gotchas

- **GCID, not CID**: This table uses GCID (marketing group customer ID), not RealCID. Use Dim_Customer.GCID for joins to other tables, not Dim_Customer.RealCID.
- **SP typo in Category**: The value 'Holded Postions' (not 'Holded Positions') is stored verbatim from the SP. Queries must use the misspelled string.
- **One row per instrument per GCID**: Customers holding multiple crypto instruments appear multiple times in the 'Holded Postions' segment. `COUNT(DISTINCT GCID)` to count customers, not `COUNT(*)`.
- **TRUNCATE + INSERT — no date column**: The table has no DateID or Date column. It reflects yesterday's state at any given time. Historical point-in-time analysis is not supported from this table alone.
- **HoldedEligibleCoins hardcoded IDs**: The eligible coin list (InstrumentIDs 100000-100020) is hardcoded in the SP. Changes to eligible coins require SP modification.
- **Crypto Leads very small**: 2,864 as of 2026-04-13 — not a high-volume segment. Size can fluctuate with crypto funnel activity.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (authoritative) |
| Tier 2 | Derived from ETL SP code analysis — high confidence |
| Tier 3 | Derived from external/config sources — moderate confidence |
| Propagation | ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Marketing group customer ID from Dim_Customer.GCID — the identifier used by CRM and marketing communication systems. Note: this is NOT RealCID (the analytics CID). One GCID can appear multiple rows for the 'Holded Postions' segment — one row per held crypto instrument. Use with Dim_Customer.GCID for joins. (Tier 2 — SP_CryptoMarketingList) |
| 2 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — DWH_dbo.Dim_Regulation wiki) |
| 3 | Country | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dim_Country wiki) |
| 4 | IsOptIn | varchar(3) | NO | Marketing opt-in eligibility: 'Yes' = customer has NOT opted out of marketing communications (default — contactable); 'No' = customer explicitly opted out (External_SettingsDB_Settings_CustomerData ResourceId=5564, SelectedValue='2'). Approximately 79% Yes, 21% No across crypto segments. (Tier 2 — SP_CryptoMarketingList) |
| 5 | Category | varchar(23) | NO | Customer engagement segment. Values: 'Holded Postions' (SP typo — note misspelling), 'Opened/Closed Positions', 'Crypto Leads'. Distribution on 2026-04-13: Holded 61.8%, Opened/Closed 38.2%, Leads <0.1%. (Tier 2 — SP_CryptoMarketingList) |
| 6 | HasWallet | int | YES | Binary flag (0/1) from Dim_Customer: 1 if the customer has an active eToro Money wallet linked to their account; 0 otherwise. (Tier 2 — Dim_Customer.HasWallet) |
| 7 | HoldedEligibleCoins | varchar(3) | NO | 'Yes' if the customer holds a position in one of the promotional eligible coins (Dim_Instrument.InstrumentID IN: 100000, 100001, 100002, 100003, 100005, 100020 — hardcoded in SP). 'No' otherwise, or for non-Holded categories. Used to filter for specific promotional campaigns. (Tier 2 — SP_CryptoMarketingList) |
| 8 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time (TRUNCATE+INSERT). All rows in the table share the same UpdateDate from the last daily run. (Propagation) |
| 9 | CryptoHolded | varchar(50) | YES | Instrument display name of the held crypto (e.g., 'XRP', 'Ethereum', 'Flare', 'Songbird'). Only populated for 'Holded Postions' segment with Dim_Instrument.IsMajor='Yes'; otherwise 'No'. One row per held instrument for major coins, 'No' for non-major. (Tier 2 — SP_CryptoMarketingList) |
| 10 | HoldedAbove | varchar(100) | YES | Holding duration bucket based on DATEDIFF(MONTH, position open date, snapshot date). Values: 'Holded_Less_1_Month', 'Holded_Above_1_Month', 'Holded_Above_2_Month', 'Holded_Above_3_Month', 'Holded_Above_4_Month', 'Holded_Above_5_Month', 'Not Holded' (for non-Holded categories). Distribution: 67% Holded_Above_5_Month. (Tier 2 — SP_CryptoMarketingList) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| GCID | DWH_dbo.Dim_Customer | GCID | Direct passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Dim_Customer.RegulationID |
| Country | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID |
| IsOptIn | External_SettingsDB_Settings_CustomerData | SelectedValue | NOT IN opt-out list (ResourceId=5564, SelectedValue='2') |
| Category | SP literal | — | 'Holded Postions' / 'Opened/Closed Positions' / 'Crypto Leads' |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | Direct passthrough |
| HoldedEligibleCoins | DWH_dbo.Dim_Instrument | InstrumentID | IN (100000,100001,100002,100003,100005,100020) |
| CryptoHolded | DWH_dbo.Dim_Instrument | InstrumentDisplayName | CASE WHEN IsMajor='Yes' THEN name |
| HoldedAbove | BI_DB_dbo.BI_DB_PositionPnL | Occurred + Date | DATEDIFF MONTH bucketed |

### 5.2 ETL Pipeline

```
BI_DB_dbo.External_SettingsDB_Settings_CustomerData (ResourceId=5564, SelectedValue='2')
  |-- #OptOut: opt-out GCIDs
DWH_dbo.Dim_Customer (IsValidCustomer=1, NOT IN #OptOut)
  |-- #OptIn: contactable customers (IsOptIn='Yes')
BI_DB_dbo.BI_DB_PositionPnL (InstrumentTypeID=10, DateID=yesterday)
  |-- #holdings: Holded Positions segment (CryptoHolded, HoldedEligibleCoins, HoldedAbove)
DWH_dbo.Dim_Position (InstrumentTypeID=10, open/close in last 3M)
  |-- #openclosepositions: Opened/Closed Positions segment
DWH_dbo.Dim_Customer (FunnelFromID=57, RegisteredReal in last 3M)
  LEFT JOIN BI_DB_First5Actions WHERE FirstAction IS NULL
  |-- #cryptoleads: Crypto Leads segment
UNION ALL three segments → JOIN Dim_Customer + Dim_Country + Dim_Regulation + #OptIn + #holdings → #final
  |
TRUNCATE BI_DB_dbo.BI_DB_CryptoMarketingList + INSERT #final
  ↓
BI_DB_dbo.BI_DB_CryptoMarketingList
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| DWH_dbo.Dim_Customer | Source — all segments | GCID, HasWallet, CountryID, RegulationID, FunnelFromID |
| BI_DB_dbo.BI_DB_PositionPnL | Source — Holded Positions | Daily crypto PnL snapshot for active holdings |
| DWH_dbo.Dim_Position | Source — Opened/Closed | Position open/close dates for 3M activity |
| DWH_dbo.Dim_Instrument | Source — crypto filter | InstrumentTypeID=10, IsMajor, InstrumentDisplayName, InstrumentID |
| DWH_dbo.Dim_Regulation | Source — Regulation name | ID → Name lookup |
| DWH_dbo.Dim_Country | Source — Country name | CountryID → Name lookup |
| BI_DB_dbo.BI_DB_First5Actions | Source — leads | FirstAction NULL check for Crypto Leads |
| BI_DB_dbo.External_SettingsDB_Settings_CustomerData | Source — opt-out | ResourceId=5564, SelectedValue='2' |

---

## 7. Sample Queries

```sql
-- Opted-in crypto holders for a campaign (distinct GCIDs)
SELECT COUNT(DISTINCT GCID) AS contactable_holders
FROM BI_DB_dbo.BI_DB_CryptoMarketingList
WHERE Category = 'Holded Postions'
  AND IsOptIn = 'Yes';

-- Eligible coin holders by coin and holding duration
SELECT CryptoHolded, HoldedAbove, COUNT(DISTINCT GCID) AS holders
FROM BI_DB_dbo.BI_DB_CryptoMarketingList
WHERE HoldedEligibleCoins = 'Yes'
  AND IsOptIn = 'Yes'
  AND Category = 'Holded Postions'
GROUP BY CryptoHolded, HoldedAbove
ORDER BY holders DESC;

-- Long-term holders (>5 months) by country for targeting
SELECT Country, COUNT(DISTINCT GCID) AS long_term_holders
FROM BI_DB_dbo.BI_DB_CryptoMarketingList
WHERE Category = 'Holded Postions'
  AND HoldedAbove = 'Holded_Above_5_Month'
  AND IsOptIn = 'Yes'
GROUP BY Country
ORDER BY long_term_holders DESC;

-- Crypto leads pipeline (unconverted registrants)
SELECT Regulation, Country, COUNT(*) AS leads
FROM BI_DB_dbo.BI_DB_CryptoMarketingList
WHERE Category = 'Crypto Leads'
GROUP BY Regulation, Country
ORDER BY leads DESC;
```

---

## 8. Atlassian / External References

No Confluence pages or Jira tickets found for BI_DB_CryptoMarketingList.

---

*Wiki generated: 2026-04-23 | Quality: 8.9/10 | Pipeline: dwh-semantic-doc v2 | Batch 82*
