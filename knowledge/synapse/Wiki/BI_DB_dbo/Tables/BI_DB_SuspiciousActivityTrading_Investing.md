# BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing

> 264-row suspicious stock trading activity detection table identifying customers with unusual trading patterns: fast trades (<3 minutes open-to-close), high-frequency same-instrument day trading (>=5/day), and heavy same-instrument 10-day trading (>=30/10 days). Single-day snapshot replaced daily. Sourced from History.Position (10-day range) via SP_SuspiciousActivityTrading_Investing. Stocks only, manual positions only (MirrorID=0).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.History.Position → SP_SuspiciousActivityTrading_Investing |
| **Refresh** | Daily full replace (DELETE ALL + INSERT; SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([RootCID] ASC) |
| **UC Target** | _Not_Migrated (not in Generic Pipeline mapping) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_SuspiciousActivityTrading_Investing detects customers exhibiting potentially suspicious stock trading patterns. The SP analyzes closed positions from the last 10 days (via `SP_Create_etoro_History_Position_Range`) and flags customers matching three detection groups:

1. **+5 trades less than 3 min a day**: The root position (TreeID parent) was opened and closed within 3 minutes, and the customer tree has >=5 such trades in a single day. Indicates potential market manipulation or wash trading.
2. **+5 trades same instrument a day**: Customer opened and closed >=5 positions of the same stock instrument in a single day. Indicates potential day-trading abuse.
3. **+30 trades same instrument last 10 days**: Customer opened and closed >=30 positions of the same stock in the last 10 days. Indicates repetitive pattern trading.

Filters applied across all groups:
- Stocks only (InstrumentType='Stocks')
- Manual positions only (MirrorID=0, excluding copy-trading)
- Valid customers: PlayerLevelID <> 4, LabelID <> 30, CountryID <> 250, AccountTypeID <> 9, PlayerStatusID <> 9

Key facts:
- 264 rows on 2026-04-13 (single-day snapshot)
- Group distribution: +30 trades/10d (258, 98%), +5 trades/instrument/day (5, 2%), +5 trades <3min/day (1, <1%)
- Full table replaced daily (DELETE WHERE always-true condition clears all rows)
- Enriched with PI status (>10 active copiers), 3-month customer flag, regulation

---

## 2. Business Logic

### 2.1 Group A: Fast Trades (<3 min)

**What**: Detects position trees where the root position was opened and closed within 3 minutes.
**Columns Involved**: RootCID, NumOfTrades, Group_Type
**Rules**:
- Root position: `DATEDIFF(minute, pc.OpenOccurred, pc.CloseOccurred) <= 3`
- Threshold: COUNT(*) >= 5 trades per CID per RootCID
- InstrumentDisplayName set to 'Not Relevant' (not instrument-specific)
- Only positions from today (OpenOccurred > GETDATE()-1)

### 2.2 Group B: Same Instrument Day Trading (>=5)

**What**: Detects customers trading the same stock instrument >=5 times in a single day.
**Columns Involved**: InstrumentDisplayName, NumOfTrades, Group_Type
**Rules**:
- Both opened and closed today (OpenOccurred > GETDATE()-1, CloseOccurred > GETDATE()-1)
- Threshold: COUNT(*) >= 5 per CID × RootCID × InstrumentDisplayName
- No 3-minute time restriction (any open-to-close duration)

### 2.3 Group C: Heavy Same Instrument (>=30 in 10 days)

**What**: Detects customers accumulating >=30 trades of the same instrument over 10 days.
**Columns Involved**: InstrumentDisplayName, NumOfTrades, Group_Type
**Rules**:
- Positions from last 10 days (OpenOccurred > GETDATE()-10)
- Threshold: COUNT(*) >= 30 per CID × RootCID × InstrumentDisplayName
- This is the most common detection (98% of flagged rows)

### 2.4 Customer Exclusion Filters

**What**: Exclusions to avoid false positives.
**Columns Involved**: CID (via Dim_Customer, BackOffice_Customer)
**Rules**:
- PlayerLevelID <> 4 (exclude Diamond tier)
- LabelID <> 30 (exclude specific internal label)
- CountryID <> 250 (exclude specific country)
- AccountTypeID <> 9 (exclude specific account type)
- PlayerStatusID <> 9 (exclude specific status)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CI on RootCID. Small table (~264 rows), full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| All flagged customers by group | `GROUP BY Group_Type` |
| High-profit suspicious traders | `ORDER BY NetProfit DESC` |
| New customers with suspicious activity | `WHERE Is3Month = 1` |
| Important PIs with suspicious patterns | `WHERE IsPI = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RootCID = RealCID | Extended customer profile |

### 3.4 Gotchas

- **Full table replace**: The DELETE statement uses `WHERE @StartRunningDate=@StartRunningDate` which always evaluates to TRUE — this deletes ALL rows, not just the current date. The table only ever contains one day of data.
- **CID vs RootCID**: RootCID is the copy-tree root (parent position owner). CID is the actual position owner. For manual trades (IsCopy='Manual'), they are typically the same. Both can differ in copy-trade scenarios, but since MirrorID=0 is filtered, CID usually equals RootCID.
- **InstrumentDisplayName = 'Not Relevant'**: Group A (fast trades) does not track instrument; the field is hardcoded to 'Not Relevant'.
- **IsPI misleading name**: Named 'IsPI' in the DDL but represents whether the RootCID is an "Important PI" (>10 active copiers), not merely whether they are a Popular Investor.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Description | Tag Pattern |
|------|-------------|-------------|
| Tier 1 | Upstream wiki verbatim | `(Tier 1 — source)` |
| Tier 2 | SP code / DDL evidence | `(Tier 2 — SP)` |
| Tier 5 | ETL metadata | `(Tier 5 — ETL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RootCID | int | YES | Copy-trade tree root customer ID. The parent position owner. For manual trades (MirrorID=0), typically equals CID. Clustered index key. (Tier 2 — SP_SuspiciousActivityTrading_Investing, History.Position tree root) |
| 2 | NetProfit | money | YES | Sum of net P&L across all qualifying trades for this CID × RootCID × Group. SUM(NetProfit) from closed positions. (Tier 2 — SP_SuspiciousActivityTrading_Investing, SUM History.Position.NetProfit) |
| 3 | NumOfTrades | int | YES | Count of qualifying trades for this detection group. Threshold: >=5 (Groups A, B) or >=30 (Group C). (Tier 2 — SP_SuspiciousActivityTrading_Investing, COUNT(*)) |
| 4 | Is3Month | int | YES | New customer flag: 1 if first deposit was within the last 3 months (ISNULL(FirstDepositDate, GETDATE()) > DATEADD(month,-3,GETDATE())), 0 otherwise. (Tier 2 — SP_SuspiciousActivityTrading_Investing, Dim_Customer.FirstDepositDate) |
| 5 | UpdateDate | datetime | YES | Row load timestamp set to GETDATE() at insert time. Not a business date. (Tier 5 — ETL metadata, GETDATE()) |
| 6 | IsPI | int | YES | Important Popular Investor flag: 1 if RootCID has >10 active copiers in Dim_Mirror, 0 otherwise. (Tier 2 — SP_SuspiciousActivityTrading_Investing, COUNT Dim_Mirror.MirrorID WHERE IsActive=1) |
| 7 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 8 | CID | int | YES | Position owner customer ID. For manual stock trades, typically equals RootCID. (Tier 2 — SP_SuspiciousActivityTrading_Investing, History.Position.CID) |
| 9 | IsCopy | varchar(6) | YES | Trade type: 'Manual' (MirrorID=0) or 'Copy' (MirrorID>0). In this table, always 'Manual' due to the MirrorID=0 filter. (Tier 2 — SP_SuspiciousActivityTrading_Investing, CASE on History.Position.MirrorID) |
| 10 | StartRunningTime | datetime | YES | SP execution timestamp (GETDATE() at start of SP run). Different from UpdateDate which is set at INSERT time. (Tier 2 — SP_SuspiciousActivityTrading_Investing, @StartRunningTime parameter) |
| 11 | UserName | varchar(20) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer via RootCID. (Tier 1 — Customer.CustomerStatic) |
| 12 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name. Populated for Groups B and C (same-instrument detection). Set to 'Not Relevant' for Group A (fast trades, not instrument-specific). Passthrough from Dim_Instrument. (Tier 2 — SP_SuspiciousActivityTrading_Investing, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 13 | Group_Type | varchar(50) | YES | Detection group: '+5 trades less than 3 min a day' (Group A), '+5 trades same instrument a day' (Group B), '+30 trades same instrument last 10 days' (Group C). (Tier 2 — SP_SuspiciousActivityTrading_Investing, literal string) |
| 14 | StartRunningDate | date | YES | Date of SP execution (CAST(@StartRunningTime AS DATE)). Used to identify the run date. (Tier 2 — SP_SuspiciousActivityTrading_Investing, @StartRunningDate parameter) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RootCID | etoro.History.Position | CID (of TreeID root) | Tree root identification |
| CID | etoro.History.Position | CID | Passthrough |
| NetProfit | etoro.History.Position | NetProfit | SUM per group |
| NumOfTrades | etoro.History.Position | — | COUNT(*) per group |
| Is3Month | DWH_dbo.Dim_Customer | FirstDepositDate | CASE within 3 months |
| IsPI | DWH_dbo.Dim_Mirror | MirrorID | CASE copiers > 10 |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup |
| UserName | DWH_dbo.Dim_Customer | UserName | Dim-lookup |
| IsCopy | etoro.History.Position | MirrorID | CASE (always 'Manual') |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup / 'Not Relevant' |
| Group_Type | SP-computed | — | Literal per detection group |
| StartRunningDate | SP parameter | GETDATE() | Date cast |
| StartRunningTime | SP parameter | GETDATE() | Datetime |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
etoro.History.Position (via SP_Create_etoro_History_Position_Range, 10-day window)
  + DWH_dbo.Dim_Customer (exclude PlayerLevelID=4, LabelID=30, CountryID=250, PlayerStatusID=9)
  + BI_DB_dbo.External_etoro_BackOffice_Customer (AccountTypeID<>9)
  + DWH_dbo.Dim_Instrument (InstrumentType='Stocks', InstrumentDisplayName)
  + DWH_dbo.Dim_Mirror (active copier count for PI flag)
  + DWH_dbo.Dim_Regulation (regulation Name)
  |-- SP_SuspiciousActivityTrading_Investing ---|
  |  Group A: >=5 trades <3 min today (tree root open-close <=3 min)
  |  Group B: >=5 trades same instrument today
  |  Group C: >=30 trades same instrument 10 days
  |  UNION ALL → #Final → DELETE ALL + INSERT
  v
BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing (264 rows, single-day snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RootCID / CID | DWH_dbo.Dim_Customer | Customer profile |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship |
|-------------------|-------------|
| Compliance/surveillance dashboards | Primary consumer (suspicious trading monitoring) |

---

## 7. Sample Queries

### 7.1 Flagged Customers by Detection Group

```sql
SELECT Group_Type, COUNT(DISTINCT RootCID) AS UniqueCIDs,
       SUM(NumOfTrades) AS TotalTrades, SUM(NetProfit) AS TotalProfit
FROM BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing
GROUP BY Group_Type
ORDER BY UniqueCIDs DESC
```

### 7.2 Profitable Suspicious Traders (Important PIs)

```sql
SELECT RootCID, UserName, Regulation, Group_Type,
       InstrumentDisplayName, NumOfTrades, NetProfit
FROM BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing
WHERE IsPI = 1
ORDER BY NetProfit DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 11 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_SuspiciousActivityTrading_Investing | Type: Table | Production Source: History.Position via SP_SuspiciousActivityTrading_Investing*
