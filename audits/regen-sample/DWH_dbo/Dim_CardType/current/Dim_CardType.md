# DWH_dbo.Dim_CardType

> Frozen 2019 snapshot of the payment card brand lookup — 18 of the 32 production card types, used to decode CardTypeID in billing fact tables.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CardType (Legacy DWH SQL Server, 2019 snapshot) |
| **Refresh** | None (frozen migration, all rows dated 2019-06-30) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CardTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Dim_CardType is a lookup table defining payment card network brands accepted by the eToro platform for deposits. Each row represents a card type (Visa, MasterCard, Diners, etc.) with its active/inactive status. When a customer makes a card deposit, the card's BIN (Bank Identification Number) resolves to a CardTypeID — this dimension decodes that ID to the human-readable brand name.

The DWH version is a frozen 2019 snapshot migrated from the legacy DWH SQL Server. It contains 18 card types (IDs 0-17), while the current production `etoro.Dictionary.CardType` has grown to 32 entries. New card types added after 2019-06-30 do not appear in this DWH table. The production table also has an `Is3dsOn` flag (3D Secure requirement) that was dropped during the DWH migration.

Note: The column `CarTypeName` is a typo in the original DDL (should be "CardTypeName") — this is a historical artifact from the legacy DWH.

---

## 2. Business Logic

### 2.1 Card Brand Active Status

**What**: Each card type is marked active (IsActive=1) or inactive (IsActive=0) for deposit processing.

**Columns Involved**: `CardTypeID`, `CarTypeName`, `IsActive`

**Rules**:
- IsActive=1: Card brand was accepted for deposits at time of migration (2019)
- IsActive=0: Card brand is not accepted
- DWH active set: 0=None (placeholder), 1=Visa, 2=Master Card, 3=Diners
- Note: This IsActive snapshot may differ from current production — Maestro (ID=8) is active in production but shows IsActive=0 in this DWH snapshot
- CardTypeID=0 ("None") is the fallback when BIN lookup fails to identify a card brand

**Diagram**:
```
CardTypeID -> CarTypeName -> IsActive (as of 2019-06-30)

Active (IsActive=1):
  0  = None (placeholder/unknown)
  1  = Visa
  2  = Master Card
  3  = Diners

Inactive (IsActive=0):
  4  = Amex
  5  = Fire Pay
  6  = JCB
  7  = American Express
  8  = Maestro (active in production, inactive in this DWH snapshot)
  9  = Laser
 10  = Switch
 11  = UK Local Credit Card
 12  = Discover
 13  = Local Card
 14  = China Union Pay
 15  = Solo
 16  = Cirrus
 17  = GE Capital
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `CardTypeID ASC`. At 18 rows, REPLICATE gives each compute node a local copy for zero-movement JOINs. Any query joining on CardTypeID will be optimally local.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Delta (MANAGED), no partitioning. Full scan is optimal at 18 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode CardTypeID in billing facts | JOIN DWH_dbo.Dim_CardType ON CardTypeID for CarTypeName |
| Which card types were active in 2019? | WHERE IsActive = 1 |
| All card types including inactive | SELECT * FROM Dim_CardType ORDER BY CardTypeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit (expected) | ON f.CardTypeID = d.CardTypeID | Decode card brand for billing facts |

### 3.4 Gotchas

- **Column name typo**: The column is `CarTypeName`, not `CardTypeName` — this is a DDL bug from the legacy DWH. Use the exact name in queries.
- **Frozen 2019 snapshot**: This table has not been updated since 2019-06-30. Production Dictionary.CardType has 32 entries; 14 card types added after 2019 are missing from DWH. If a CardTypeID not in DWH appears in fact data, it has no match here.
- **Missing Is3dsOn**: Production has a 3D Secure flag that was NOT migrated. Do not expect 3DS information from this table.
- **IsActive discrepancy**: Maestro (ID=8) is active in current production but shows IsActive=0 in this 2019 snapshot. Do not use this table's IsActive to determine current acceptance rules.
- **CardTypeID=0 IsActive=1**: DWH marks the "None" placeholder as active=1; production marks it inactive=0. Likely a migration artifact.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CardTypeID | int | YES | Card network identifier. Active brands (IsActive=1 as of 2019): 0=None (unknown/fallback), 1=Visa, 2=Master Card, 3=Diners. Inactive: 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro (active in production today), 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. DWH note: snapshot covers IDs 0-17 only; production has 32 types including newer IDs. (Tier 1 - upstream wiki, Dictionary.CardType) |
| 2 | CarTypeName | varchar(50) | YES | Card brand name. DDL note: column has a typo ("Car" instead of "Card") — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Diners, Amex, American Express, Maestro, Discover, China Union Pay. (Tier 1 - upstream wiki, Dictionary.CardType, column: Name) |
| 3 | IsActive | int | YES | Whether this card brand was accepted for deposits as of the 2019 migration snapshot: 1=active, 0=inactive. DWH note: production uses bit type; DWH uses int. This snapshot may not reflect current production acceptance (e.g., Maestro/ID=8 is active in production but shows 0 here). (Tier 1 - upstream wiki, Dictionary.CardType) |
| 4 | UpdateDate | datetime | YES | ETL migration timestamp. All 18 rows = 2019-06-30 — the date this table was migrated from the legacy DWH SQL Server. Not a production field from Dictionary.CardType (which has no UpdateDate). (Tier 2 - DWH_Migration.Dim_CardType) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CardTypeID | etoro.Dictionary.CardType (2019 snapshot) | CardTypeID | passthrough |
| CarTypeName | etoro.Dictionary.CardType (2019 snapshot) | Name | rename (Name -> CarTypeName, with typo) |
| IsActive | etoro.Dictionary.CardType (2019 snapshot) | IsActive | cast (bit -> int) |
| UpdateDate | DWH ETL | — | ETL-computed (migration load date, not from source) |

Note: etoro.Dictionary.CardType is in Generic Pipeline (ID 229, daily override), but DWH_dbo.Dim_CardType does NOT receive live updates — it remains a frozen 2019 snapshot.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CardType (production, etoroDB-REAL)
  -> Generic Pipeline (ID 229, daily) -> Bronze/etoro/Dictionary/CardType/ [not consumed by DWH]
  -> Legacy DWH SQL Server (Dim_CardType, 2019)
       -> DWH_Migration.Dim_CardType (NoDbObjectsScripts, 2024-09-16)
            -> DWH_dbo.Dim_CardType (frozen snapshot, no active ETL)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CardType | Production card type master |
| Legacy | Legacy DWH SQL Server.Dim_CardType | Historical DWH dimension (2019 snapshot) |
| Migration | DWH_Migration.Dim_CardType | One-time migration staging DDL |
| Target | DWH_dbo.Dim_CardType | Current Synapse dimension (18 rows, frozen) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none) | - | Leaf dimension - no foreign keys |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_CountryBin | CardTypeID | Country-BIN mapping table includes CardTypeID (via SP_Dictionaries_DL_To_Synapse) |
| DWH_dbo.Fact_BillingDeposit (expected) | CardTypeID | Billing deposit fact likely references card type |

---

## 7. Sample Queries

### 7.1 List all active card types
```sql
SELECT CardTypeID, CarTypeName, IsActive
FROM [DWH_dbo].[Dim_CardType]
WHERE IsActive = 1
ORDER BY CardTypeID;
```

### 7.2 Decode card type in billing data
```sql
SELECT
    f.CID,
    f.Amount,
    ct.CarTypeName AS CardBrand,
    ct.IsActive AS WasActiveIn2019
FROM [DWH_dbo].[Fact_BillingDeposit] f
LEFT JOIN [DWH_dbo].[Dim_CardType] ct ON f.CardTypeID = ct.CardTypeID
ORDER BY f.CID;
```

### 7.3 Full card type reference list
```sql
SELECT CardTypeID, CarTypeName, IsActive, UpdateDate
FROM [DWH_dbo].[Dim_CardType]
ORDER BY CardTypeID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP unavailable this session.)

---

*Generated: 2026-03-18 | Quality: 7.9/10 (★★★★☆) | Phases: 11/14*
*Tiers: 3 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CardType | Type: Table | Production Source: etoro.Dictionary.CardType (2019 snapshot via legacy DWH)*
