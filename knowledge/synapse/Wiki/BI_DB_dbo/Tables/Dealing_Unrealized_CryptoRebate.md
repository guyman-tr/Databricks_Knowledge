# BI_DB_dbo.Dealing_Unrealized_CryptoRebate

## 1. Business Meaning

Monthly unrealized crypto rebate calculation for Diamond and Platinum Plus club members. Each row represents one club member's unrealized crypto exposure for a single month-end, with their calculated rebate amount based on open crypto position volume valued at end-of-month prices.

Companion table to `Dealing_CryptoRebate` (realized). Together they cover the full crypto rebate program: realized captures closed positions during the month; unrealized captures open positions still held at month-end, marked to market using EOM BidSpreaded prices. The combined TotalRebate across both tables forms the club member's monthly payout entitlement.

Written by `BI_DB_dbo.SP_M_CryptoRebateDiamond` — the same SP that writes `Dealing_CryptoRebate` first, then runs the unrealized section second in the same execution. Runs monthly (OpsDB Priority 20). Load pattern: DELETE WHERE MonthEndDate = @MonthEndDate followed by INSERT — a monthly full-refresh per period, safe to re-run.

- **786,000 rows** across **44 months** (2022-03-31 to 2026-03-31)
- **$51.2M total unrealized rebate** across all periods
- **70.3%** of rows have TotalRebate = 0 (below $5 minimum or below bracket entry threshold of $50K volume)
- Club composition: Platinum Plus 89.6%, Diamond 10.4%
- UC Target: _Not_Migrated

---

## 2. Business Logic

### Club Eligibility
Club members eligible for unrealized rebate must, at @MonthEndDate:
- Have `PlayerLevelID IN (6, 7)` in `Fact_SnapshotCustomer` (6 = Platinum Plus, 7 = Diamond)
- Have `IsValidCustomer = 1`
- Have `GuruStatusID NOT IN (2, 3, 4, 5, 6)` — Popular Investors (active PIs) are excluded from the rebate program

In practice, GuruStatus_ID is always 0 in stored data: all rows satisfy the non-PI filter, leaving only standard club members.

### Unrealized Position Scope
Only crypto long non-leveraged non-mirror positions are included:
- `InstrumentTypeID = 10` (crypto)
- `IsBuy = 1` (long only)
- `Leverage = 1` (non-leveraged)
- `MirrorID = 0` (non-mirror)
- `IsDiscounted = 0`
- `IsSettled = 1` (position still open at @MonthEndDateID in `BI_DB_PositionPnL`)
- `OpenDateID >= 20220308` — positions opened on or after 2022-03-08 only

### Volume Calculation
```
OpenedVolume  = SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1))
              — open positions valued at their open-side forex rate

ClosedVolume  = SUM(AmountInUnitsDecimal × ISNULL(BidSpreaded,1) × ISNULL(ConvertRateIsBuy_1,1))
              — same positions marked to market at EOM BidSpreaded price from Fact_CurrencyPriceWithSplit

TotalVolume   = OpenedVolume + ClosedVolume
              — double-counts each position (open side + EOM close side); this is intentional in the bracket calculation
```

`Markup = TotalVolume × 0.01` is informational only and not used in rebate math.

### Rebate Brackets
| Bracket | Volume Range | Rate | Cap |
|---------|-------------|------|-----|
| Bracket1 | $50K – $1M | 0.15% | $950,000 volume |
| Bracket2 | $1M – $5M | 0.25% | $4,000,000 volume |
| Bracket3 | > $5M | 0.50% | Uncapped |

```
Bracket1_Volume = CASE WHEN TotalVolume BETWEEN 50K AND 1M   THEN TotalVolume - 50K
                       WHEN TotalVolume > 1M                  THEN 950,000
                       ELSE 0 END

Bracket2_Volume = CASE WHEN TotalVolume BETWEEN 1M AND 5M    THEN TotalVolume - 1M
                       WHEN TotalVolume > 5M                  THEN 4,000,000
                       ELSE 0 END

Bracket3_Volume = CASE WHEN TotalVolume > 5M                 THEN TotalVolume - 5M
                       ELSE 0 END

TotalRebate = CASE WHEN (B1_Rebate + B2_Rebate + B3_Rebate) < 5
                   THEN 0
                   ELSE (B1_Rebate + B2_Rebate + B3_Rebate) END
```

$5 minimum threshold: members with total rebate below $5 receive 0 — this accounts for the 70.3% zero-rebate rows.

### Differences from Realized Companion (Dealing_CryptoRebate)
| Aspect | Realized | Unrealized |
|--------|----------|------------|
| Position scope | Closed during month | Open at month-end |
| Volume valuation | Trade close price | EOM BidSpreaded mark-to-market |
| Extra columns | — | IsCreditReportValidCB, IsGermanBaFin |
| Club columns | Same | Same |
| Bracket math | Identical | Identical |
| Row count | Lower | 786K (larger; open positions persist) |

---

## 3. Query Advisory

### Distribution
- ROUND_ROBIN distribution; no skew risk.
- CLUSTERED INDEX on `MonthEndDate ASC` — range scans by month are efficient.
- Filter on `MonthEndDate` first when querying a single period.

### JOINs
- JOIN to `Dealing_CryptoRebate` on `(MonthEndDate, CID)` to get combined monthly rebate per member.
- Both tables share the same Club/Regulation/Country/Region dimensions, populated from the same club eligibility snapshot — values are consistent across the two tables for the same (MonthEndDate, CID).

### Known Gotchas
1. **GuruStatus_ID is always 0.** The filter `GuruStatusID NOT IN (2,3,4,5,6)` means only non-PI club members remain; all have GuruStatus=0. The column exists for analytical completeness but carries no variation in stored data.
2. **UPdatedate typo.** The DDL column name is `UPdatedate` (capital P mid-word). Queries must use this exact casing.
3. **70.3% zero TotalRebate.** The $5 minimum threshold plus the $50K volume floor means most members in a given month receive no payout. Filter `WHERE TotalRebate > 0` to get paying rows only.
4. **TotalVolume double-counts.** OpenedVolume + ClosedVolume represents two valuations of the same positions (at open and at EOM). This is by design in the bracket logic but is not a net position value.
5. **Monthly full-refresh.** Re-running SP_M_CryptoRebateDiamond for the same @Date replaces the existing rows for that month. Historical months are not reprocessed.
6. **OpenDateID >= 20220308 gate.** Positions opened before 2022-03-08 are excluded. New customers and positions added after that date are in scope.

---

## 4. Elements

| # | Column | Type | Nullable | PK | Description | Tier |
|---|--------|------|----------|----|-------------|------|
| 1 | MonthEndDate | date | YES | — | Last calendar day of the reporting month. Derived as EOMONTH of @Date parameter. Clustered index key; use in WHERE to scope to a period. | Tier 2 |
| 2 | Club | nvarchar(50) | YES | — | Club tier name at MonthEndDate. Values: '1 Diamond' (PlayerLevelID=7) or '1 Platinum Plus' (PlayerLevelID=6). Mapped via Dim_PlayerLevel + Dim_Range SCD2 snapshot. | Tier 2 |
| 3 | CID | int | YES | — | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. | Tier 1 |
| 4 | IsCreditReportValidCB | bit | YES | — | Credit report validity flag from Fact_SnapshotCustomer at MonthEndDate. 1 = valid credit report on file. Used as a regulatory dimension in rebate reporting. Not present in realized companion table. | Tier 2 |
| 5 | IsGermanBaFin | bit | YES | — | 1 if the customer has German BaFin-regulated status at @MonthEndDateID, per V_GermanBaFin. 0 otherwise. Regulatory dimension for compliance reporting. Not present in realized companion table. | Tier 2 |
| 6 | GuruStatus_ID | int | YES | — | PopularInvestor status ID from Fact_SnapshotCustomer. FK to Dim_GuruStatus. Always 0 in stored data — the eligibility filter excludes all active PIs (GuruStatusID IN 2-6), leaving only non-PI club members. | Tier 2 |
| 7 | Country | nvarchar(50) | YES | — | Customer country name at MonthEndDate. Resolved via Fact_SnapshotCustomer.CountryID → Dim_Country.CountryID → Dim_Country.Name. | Tier 2 |
| 8 | Region | nvarchar(50) | YES | — | Geographic region grouping from Fact_SnapshotCustomer. Passthrough from snapshot. | Tier 2 |
| 9 | Regulation | nvarchar(50) | YES | — | Regulatory entity name. Resolved via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID → Dim_Regulation.Name. | Tier 2 |
| 10 | OpenedVolume | float | YES | — | Open position USD exposure at open-side forex rate. SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1)) for all qualifying open crypto positions at @MonthEndDateID. | Tier 2 |
| 11 | ClosedVolume | float | YES | — | EOM mark-to-market close-side valuation. SUM(AmountInUnitsDecimal × ISNULL(BidSpreaded,1) × ISNULL(ConvertRateIsBuy_1,1)) using Fact_CurrencyPriceWithSplit at OccurredDateID=@MonthEndDateID. | Tier 2 |
| 12 | TotalVolume | float | YES | — | OpenedVolume + ClosedVolume. Double-counts each position (open side + EOM close side). Serves as input to bracket volume splits. Not a net position value. | Tier 2 |
| 13 | Markup | float | YES | — | TotalVolume × 0.01 (1% spread proxy). Informational only; not used in rebate calculation. | Tier 2 |
| 14 | Bracket1_Volume | float | YES | — | Volume falling in the first rebate bracket ($50K–$1M). Capped at $950,000. Zero if TotalVolume < $50K. | Tier 2 |
| 15 | Bracket2_Volume | float | YES | — | Volume falling in the second rebate bracket ($1M–$5M). Capped at $4,000,000. Zero if TotalVolume ≤ $1M. | Tier 2 |
| 16 | Bracket3_Volume | float | YES | — | Volume falling in the third rebate bracket (> $5M). Uncapped. Zero if TotalVolume ≤ $5M. | Tier 2 |
| 17 | Bracket1_Rebate | float | YES | — | Bracket1_Volume × 0.0015 (0.15% rate). | Tier 2 |
| 18 | Bracket2_Rebate | float | YES | — | Bracket2_Volume × 0.0025 (0.25% rate). | Tier 2 |
| 19 | Bracket3_Rebate | float | YES | — | Bracket3_Volume × 0.005 (0.50% rate, highest tier). | Tier 2 |
| 20 | TotalRebate | float | YES | — | Sum of Bracket1_Rebate + Bracket2_Rebate + Bracket3_Rebate, with $5 minimum threshold applied. Rows below $5 sum receive TotalRebate = 0. | Tier 2 |
| 21 | UPdatedate | datetime | YES | — | ETL load timestamp. GETDATE() at INSERT time. Note: column name contains a mid-word capital P (UPdatedate) — use exact casing in queries. | Propagation |

---

## 5. Lineage

See: [Dealing_Unrealized_CryptoRebate.lineage.md](Dealing_Unrealized_CryptoRebate.lineage.md)

**Writer SP**: `BI_DB_dbo.SP_M_CryptoRebateDiamond`
**Refresh**: Monthly (OpsDB Priority 20). Second INSERT in SP (after Dealing_CryptoRebate).
**Load Pattern**: DELETE WHERE MonthEndDate = @MonthEndDate + INSERT

### Source Objects
| Source | Role |
|--------|------|
| `DWH_dbo.Fact_SnapshotCustomer` | Club membership, IsCreditReportValidCB, GuruStatusID, CountryID, RegulationID, Region |
| `DWH_dbo.Dim_Range` | SCD2 time-bounded snapshot lookup for PlayerLevelID at @MonthEndDate |
| `DWH_dbo.Dim_PlayerLevel` | PlayerLevelID → Club tier name ('1 Diamond', '1 Platinum Plus') |
| `DWH_dbo.Dim_Country` | CountryID → Country name |
| `DWH_dbo.Dim_Regulation` | DWHRegulationID → Regulation name |
| `BI_DB_dbo.V_GermanBaFin` | IsGermanBaFin flag by CID at @MonthEndDateID |
| `BI_DB_dbo.BI_DB_PositionPnL` | Open crypto positions at @MonthEndDateID (IsSettled=1) |
| `DWH_dbo.Dim_Position` | Position filters (IsDiscounted, IsBuy, MirrorID, Leverage, OpenDateID gate) |
| `DWH_dbo.Dim_Instrument` | InstrumentTypeID=10 (crypto) filter |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | EOM crypto prices (BidSpreaded, ConvertRateIsBuy_1) for unrealized valuation |
| `Customer.CustomerStatic` | CID Tier 1 source (etoro production, via Fact_SnapshotCustomer.RealCID) |

### Pipeline
```
Customer.CustomerStatic (etoro production)
  └─ Generic Pipeline (Bronze export)
     └─> DWH_dbo.Fact_SnapshotCustomer + Dim_PlayerLevel/Country/Regulation/Range
           Filter: PlayerLevelID IN(6,7), IsValidCustomer=1, GuruStatusID NOT IN(2-6)
           └─> #club_members (Diamond + Platinum Plus at @MonthEndDate)

BI_DB_PositionPnL (at @MonthEndDateID, IsSettled=1)
  + Dim_Position (IsDiscounted=0, IsBuy=1, MirrorID=0, Leverage=1, OpenDateID>=20220308)
  + Dim_Instrument (InstrumentTypeID=10)
  └─> #UnrealizedOpen → #UnrealizedVolumeOpen (InitForexRate valuation)

Fact_CurrencyPriceWithSplit (OccurredDateID=@MonthEndDateID)
  └─> #UnrealizedVolumeClose (BidSpreaded EOM mark-to-market)

SP_M_CryptoRebateDiamond(@Date) — second INSERT in SP
  └─> bracket volume splits → rebate calc → $5 threshold
      DELETE FROM Dealing_Unrealized_CryptoRebate WHERE MonthEndDate = @MonthEndDate
      INSERT INTO BI_DB_dbo.Dealing_Unrealized_CryptoRebate
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| `BI_DB_dbo.Dealing_CryptoRebate` | Sibling (same SP, same club eligibility) | Realized companion. JOIN on (MonthEndDate, CID) for combined monthly rebate. Does NOT include IsCreditReportValidCB or IsGermanBaFin. |
| `DWH_dbo.Fact_SnapshotCustomer` | Source (club membership snapshot) | PlayerLevelID, IsCreditReportValidCB, GuruStatusID, CountryID, RegulationID, Region |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source (open position snapshot) | Open crypto positions at @MonthEndDateID |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Source (EOM prices) | BidSpreaded, ConvertRateIsBuy_1 for unrealized mark-to-market |
| `BI_DB_dbo.V_GermanBaFin` | Source (BaFin status view) | IsGermanBaFin flag |

---

## 7. Sample Queries

### Monthly unrealized rebate payout summary (paying members only)
```sql
SELECT
    MonthEndDate,
    Club,
    Regulation,
    COUNT(*)          AS Members,
    SUM(TotalRebate)  AS TotalUnrealizedRebate
FROM BI_DB_dbo.Dealing_Unrealized_CryptoRebate
WHERE MonthEndDate = '2026-03-31'
  AND TotalRebate > 0
GROUP BY MonthEndDate, Club, Regulation
ORDER BY Club, Regulation;
```

### Combined realized + unrealized rebate per member for a month
```sql
SELECT
    r.MonthEndDate,
    r.CID,
    r.Club,
    r.Regulation,
    r.TotalRebate          AS RealizedRebate,
    u.TotalRebate          AS UnrealizedRebate,
    r.TotalRebate
    + ISNULL(u.TotalRebate, 0) AS CombinedRebate
FROM BI_DB_dbo.Dealing_CryptoRebate r
LEFT JOIN BI_DB_dbo.Dealing_Unrealized_CryptoRebate u
    ON u.MonthEndDate = r.MonthEndDate
   AND u.CID = r.CID
WHERE r.MonthEndDate = '2026-03-31'
ORDER BY CombinedRebate DESC;
```

### Volume bracket utilization by tier (latest month)
```sql
SELECT
    Club,
    COUNT(*)                                AS Members,
    COUNT(CASE WHEN Bracket1_Volume > 0 THEN 1 END) AS InBracket1,
    COUNT(CASE WHEN Bracket2_Volume > 0 THEN 1 END) AS InBracket2,
    COUNT(CASE WHEN Bracket3_Volume > 0 THEN 1 END) AS InBracket3,
    SUM(TotalVolume)                        AS TotalExposure,
    SUM(TotalRebate)                        AS TotalRebate
FROM BI_DB_dbo.Dealing_Unrealized_CryptoRebate
WHERE MonthEndDate = (SELECT MAX(MonthEndDate) FROM BI_DB_dbo.Dealing_Unrealized_CryptoRebate)
GROUP BY Club;
```

---

## 8. Atlassian Knowledge

No Confluence or Jira sources found for this table. Business context derived from SP code analysis and realized companion documentation.
