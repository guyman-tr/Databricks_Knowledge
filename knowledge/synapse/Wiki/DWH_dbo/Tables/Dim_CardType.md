# DWH_dbo.Dim_CardType

> 18-row replicated dimension table listing payment card network brands (Visa, MasterCard, Diners, etc.) with their active status. Sourced from etoro production `Dictionary.CardType` via one-time migration (last updated 2019-06-30). Used as a lookup dimension by billing and deposit SPs across BI_DB_dbo.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `Dictionary.CardType` (etoro production) via DWH_Migration staging |
| **Refresh** | Daily (Generic Pipeline, Override, 1440 min) — but data unchanged since 2019-06-30 |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CardTypeID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override) |

---

## 1. Business Meaning

Dim_CardType is a small lookup dimension defining the 18 payment card network brands recognized by the eToro platform in the DWH layer. It is a subset of the production `Dictionary.CardType` table (which has 32 entries). When a customer deposits via credit or debit card, the card's BIN (Bank Identification Number) is resolved to a CardTypeID, and this dimension provides the human-readable brand name and active status.

The table was loaded via a one-time migration from production (`DWH_Migration.Dim_CardType` staging table) and all 18 rows share the same UpdateDate of 2019-06-30, indicating no incremental refreshes have occurred since the initial load. The Generic Pipeline exports this table daily to Unity Catalog as a Gold Override, but the underlying data has not changed.

Notable: the DWH copy carries only 18 of the 32 production card types (CardTypeID 0–17) and does NOT include the `Is3dsOn` column from the production source. The `IsActive` values in the DWH differ from production for some card types (e.g., CardTypeID 0 "None" is IsActive=1 in DWH but IsActive=0 in production; Maestro (8) is IsActive=0 in DWH but IsActive=1 in production), suggesting the DWH snapshot was taken at a different point in time.

---

## 2. Business Logic

### 2.1 Card Brand Lookup

**What**: Maps CardTypeID integers to human-readable card network brand names.

**Columns Involved**: `CardTypeID`, `CarTypeName`

**Rules**:
- CardTypeID 0 = "None" (fallback when BIN lookup fails to identify a card network)
- CardTypeID 1 = Visa, 2 = Master Card, 3 = Diners, 8 = Maestro — the four historically active brands in production
- CardTypeIDs 4–7, 9–17 are inactive/legacy brands (Amex, Fire Pay, JCB, American Express, Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital)

### 2.2 Active Status Flag

**What**: Indicates whether a card brand is accepted for deposits.

**Columns Involved**: `IsActive`

**Rules**:
- IsActive = 1: Card brand is accepted for deposits. In the DWH snapshot: Visa (1), Master Card (2), Diners (3), and None (0) show as active
- IsActive = 0: Card brand is not accepted — card will be rejected at deposit time
- Note: DWH values may diverge from current production state (snapshot from 2019-06-30)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Ideal for this 18-row lookup: JOINs never require data movement.
- **CLUSTERED INDEX** on `CardTypeID` — efficient for point lookups and range scans by ID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What card brands are active? | `SELECT * FROM DWH_dbo.Dim_CardType WHERE IsActive = 1` |
| Resolve CardTypeID to name | JOIN to Dim_CardType on CardTypeID |
| Full card type list | `SELECT * FROM DWH_dbo.Dim_CardType ORDER BY CardTypeID` (only 18 rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact_BillingDeposit | `ON d.CardTypeID = ct.CardTypeID` | Resolve card brand for deposit transactions |
| Dim_CountryBin | `ON cb.CardTypeID = ct.CardTypeID` | Link BIN records to card brand names |

### 3.4 Gotchas

- **Column name typo**: The column is `CarTypeName` (missing "d" — not `CardTypeName`). This is in the DDL and cannot be changed without an ALTER.
- **IsActive divergence**: DWH IsActive values reflect a 2019 snapshot and may differ from current production `Dictionary.CardType.IsActive`.
- **Missing Is3dsOn**: The production `Dictionary.CardType` has an `Is3dsOn` column for 3D Secure configuration that is NOT carried into the DWH dimension. If 3DS status is needed, query production directly.
- **Subset of production**: Only 18 of 32 production card types are present (CardTypeIDs 0–17). CardTypeIDs 18–31 are not in the DWH.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (Dictionary.CardType) |
| Tier 2 | Derived from ETL code or SP logic |
| Tier 3 | Inferred with explicit reasoning |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CardTypeID | int | YES | Card network identifier. Active brands: 1=Visa, 2=Master Card, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 2 | CarTypeName | varchar(50) | YES | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 3 | IsActive | int | YES | Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. Type widened from bit to int in DWH. Only 4 of 32 are currently active in production. DWH note: DWH snapshot values may differ from current production state. (Tier 1 — Dictionary.CardType) |
| 4 | UpdateDate | datetime | YES | ETL metadata timestamp recording when the row was loaded into the DWH. All 18 rows show 2019-06-30 00:22:57, indicating a single bulk migration load. (Tier 2 — DWH_Migration load) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CardTypeID | Dictionary.CardType | CardTypeID | Passthrough |
| CarTypeName | Dictionary.CardType | Name | Rename (Name → CarTypeName) |
| IsActive | Dictionary.CardType | IsActive | Passthrough, type widened (bit → int) |
| UpdateDate | — | — | ETL-added (getdate() at migration load) |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CardType (production, 32 rows)
  |-- One-time migration (2019-06-30) ---|
  v
DWH_Migration.Dim_CardType (staging, ROUND_ROBIN)
  |-- INSERT INTO ... SELECT ---|
  v
DWH_dbo.Dim_CardType (18 rows, REPLICATE)
  |-- Generic Pipeline (Override, daily, parquet) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype (UC Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH_dbo.Dim_CountryBin | CardTypeID | Implicit FK | BIN-to-country records reference card brand |
| BI_DB_dbo.SP_DepositWithdrawFee | CardTypeID | SP JOIN | Deposit/withdrawal fee calculations by card type |
| BI_DB_dbo.SP_H_Deposits | CardTypeID | SP JOIN | Historical deposit reporting by card brand |
| BI_DB_dbo.SP_AllDeposits | CardTypeID | SP JOIN | All-deposits aggregation by card type |
| BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts | CardTypeID | SP JOIN | Audit deposit/cashout reports |
| BI_DB_dbo.SP_EY_Audit_BO_Deposits_With_PIPs | CardTypeID | SP JOIN | Audit BO deposits with PIPs |
| BI_DB_dbo.SP_Deposit_Reversals_PIPs | CardTypeID | SP JOIN | Deposit reversal PIP calculations |
| BI_DB_dbo.SP_Withdraw_Rollback_PIPs | CardTypeID | SP JOIN | Withdrawal rollback PIP calculations |
| BI_DB_dbo.SP_Finance_Cashout_RollbackDetails | CardTypeID | SP JOIN | Finance cashout rollback details |

---

## 7. Sample Queries

### 7.1 List all active card types
```sql
SELECT CardTypeID, CarTypeName
FROM DWH_dbo.Dim_CardType
WHERE IsActive = 1
ORDER BY CardTypeID;
```

### 7.2 Card type distribution in deposits
```sql
SELECT ct.CarTypeName AS CardBrand,
       COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit d
JOIN DWH_dbo.Dim_CardType ct ON d.CardTypeID = ct.CardTypeID
GROUP BY ct.CarTypeName
ORDER BY DepositCount DESC;
```

### 7.3 Full card type reference
```sql
SELECT CardTypeID, CarTypeName, IsActive, UpdateDate
FROM DWH_dbo.Dim_CardType
ORDER BY CardTypeID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Tiers: 3 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Lineage: 9/10*
*Object: DWH_dbo.Dim_CardType | Type: Table | Production Source: Dictionary.CardType (etoro)*
