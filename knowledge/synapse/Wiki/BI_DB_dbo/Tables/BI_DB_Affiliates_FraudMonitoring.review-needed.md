# Review Needed: BI_DB_dbo.BI_DB_Affiliates_FraudMonitoring

Generated: 2026-04-23 | Batch: 54 | Pipeline: build-wiki-bidb-batch

---

## 🟡 MEDIUM — ChurnAlert Excluded from Selection Filter (Intentional or Bug?)

**Column**: ChurnAlert

The affiliate selection threshold sums only 5 alerts:
```sql
WHERE ConversionAlert+FTDAAlert+SameIPAlert+SameCountryIPAlert+LowTradingAlert>=3
-- ChurnAlert NOT included
```

This means an affiliate with ConversionAlert=1 + FTDAAlert=1 + ChurnAlert=1 (but no other alerts) would NOT appear in the output despite having 3 signals. It is unclear whether this exclusion is intentional (churn considered a secondary signal) or an oversight.

**Action**: Confirm with the fraud team (Michail Vryoni) whether ChurnAlert exclusion is by design. If not, add ChurnAlert to the selection sum.

---

## 🟡 MEDIUM — AvgFTDA Grain Is Affiliate × Country (Not Affiliate-Only)

`AvgFTDA` is computed per `AffiliateID, Country` — not at the affiliate level. The FTDAAlert threshold ($50) fires per row. If an affiliate has customers from multiple countries, some country-groups may trigger FTDAAlert while others don't, and the same affiliate may have both FTDAAlert=0 and FTDAAlert=1 rows in the output.

Downstream consumers who aggregate FTDAAlert at the affiliate level should be aware of this grain.

---

## 🟡 MEDIUM — SP Comment References Unresolved Issue

Line ~270 in the SP contains:
```sql
---------------------HERE IS ISSUE WITH [BackOffice].[CustomerRisk]-------------
```

This suggests a known data quality issue with the External_etoro_BackOffice_CustomerRisk table used for the LowTrading flag. The nature of the issue is not described.

**Action**: Investigate what the known issue is and whether it affects LowTradingAlert reliability.

---

## ℹ️ INFO — Special Characters in Column Names

Several column names contain SQL-reserved or special characters (`#`, `%`, `<`): `#Aff_RegisteredClients`, `%SameIP`, `%SameCountry`, `CIDChurn<10days`, etc. Always use bracket quoting when referencing in SQL. These names are a legacy design choice from the original SP.

---

## ℹ️ INFO — UC Migration Status

**UC Target**: `_Not_Migrated`

No Unity Catalog migration target is defined. Note that column names with `#`, `%`, `<` characters may require renaming for UC compatibility.

---

## ℹ️ INFO — Heap Table Design

The table uses ROUND_ROBIN HEAP with no index. Given the very small row count (typically <5K rows total across all months), this is acceptable for current usage but would degrade if the fraud detection scope expands significantly.
