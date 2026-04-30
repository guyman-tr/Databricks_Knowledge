# Trade.CopyTradeSettlementRestrictions

> Configures which countries, regulations, instrument types, exchanges, and instruments are restricted or permitted for copy-trading settlement, supporting jurisdictional and product-level compliance rules.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (PK, IDENTITY) |
| **Partition** | No |
| **Indexes** | 2 (PK + UQ) |

---

## 1. Business Meaning

**WHAT**: This table stores **copy-trading settlement restrictions**—rules that determine whether customers in specific countries, under specific regulations, or for specific instrument types/exchanges/instruments can perform copy-trading operations (or have them restricted). Each row defines one restriction configuration keyed by the combination of `CountryID`, `RegulationID`, `AccountTypeID`, `GroupID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `UnblockReasonId`, and `RegistrationDate`.

**WHY**: Regulatory and business requirements mandate that certain jurisdictions or products cannot participate in copy-trading or require additional verification. This table centralizes those rules so that `Trade.GetSmartCopyRestrictions`, `Trade.GetSmartCopyRestrictions_TRDOPS`, and customer-facing APIs can efficiently evaluate whether a user can copy a given instrument or open certain positions. Without it, copy-trading eligibility would be hardcoded or scattered across application logic.

**HOW**: Data enters via `Trade.InsertCopyTradeSettlementRestrictions`, `Trade.InsertCopyTradeSettlementRestrictions_TRDOPS`, and `Trade.AddCopyTradeSettlementRestriction` (INSERT); rows are removed by `Trade.DeleteCopyTradeSettlementRestriction`, `Trade.DeleteCopyTradeSettlementRestrictionsValues`, and `Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS` (DELETE). The table is system-versioned; history is kept in `History.CopyTradeSettlementRestrictions`. A `CK_CopyTradeSettlementRestriction_Asset` constraint ensures at least one of `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, or `GroupID` is non-NULL (the restriction must target at least one asset dimension). `RestrictionTypeID` maps to `Dictionary.RestrictionType` (e.g., block vs allow).

---

## 2. Business Logic

### 2.1 Restriction Type Semantics

**What**: `RestrictionTypeID` defines whether the row represents a block or an allow. Live data shows `RestrictionTypeID` 0, 1, 2, 3 with high usage of 2 and 3. The lookup is in `Dictionary.RestrictionType`; `Trade.GetSmartCopyRestrictions` joins to resolve `RestrictionTypeName`.

**Columns Involved**: `RestrictionTypeID`

**Rules**:
- Must exist in `Dictionary.RestrictionType` (validated in `InsertCopyTradeSettlementRestrictions`)
- Common values in data: 0 (237 rows), 1 (969), 2 (8771), 3 (10386)

### 2.2 Asset Scoping (Instrument / Exchange / Type / Group)

**What**: A restriction can apply at different granularities: a specific instrument, an exchange, an instrument type, or an instrument group. The constraint `CK_CopyTradeSettlementRestriction_Asset` enforces that at least one of `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `GroupID` is set.

**Columns Involved**: `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `GroupID`

**Rules**:
- At least one must be non-NULL
- Can combine (e.g., CountryID + InstrumentTypeID) for country + asset-type rules
- `InstrumentTypeID` 5 (Crypto), 6, 10 appear in live samples

### 2.3 Jurisdictional and Regulation Scoping

**What**: Restrictions are scoped by `CountryID`, `RegulationID`, and `AccountTypeID` to support country-specific and regulation-specific rules (e.g., EU vs US vs others).

**Columns Involved**: `CountryID`, `RegulationID`, `AccountTypeID`

**Rules**:
- `CountryID` 35, 43, 44, 49 observed in live data
- NULL `RegulationID` means rule applies across regulations for that country
- `AccountTypeID` can further narrow to certain account types

### 2.4 Unblock Reason and Registration Date

**What**: Some restrictions can be overridden by an approved unblock reason (e.g., compliant KYC). `UnblockReasonId` links to `Dictionary.BlockUnBlockReason`. `RegistrationDate` supports time-bounded rules.

**Columns Involved**: `UnblockReasonId`, `RegistrationDate`

---

## 3. Data Overview

| CountryID | RegulationID | InstrumentTypeID | RestrictionTypeID | Meaning |
|-----------|--------------|------------------|------------------|---------|
| 35 | NULL | 5 | 1 | Restriction for country 35, instrument type 5 (Crypto), restriction type 1 |
| 43 | NULL | 5 | 1 | Same pattern for country 43 |
| 43 | NULL | 6 | 1 | Country 43, instrument type 6 |
| 44 | NULL | 10 | 1 | Country 44, instrument type 10 |
| 49 | NULL | 5 | 1 | Country 49, instrument type 5 |

*RestrictionTypeID distribution (live): 0≈237, 1≈969, 2≈8,771, 3≈10,386*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Country for which this restriction applies. References `Dictionary.Country`. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | Regulation scope; NULL = all regulations for that country. References `Dictionary.Regulation`. |
| 3 | InstrumentTypeID | int | YES | - | CODE-BACKED | Instrument type (e.g., Crypto=5). References `Dictionary.CurrencyType`. Part of CK: at least one of InstrumentTypeID/ExchangeID/InstrumentID/GroupID required. |
| 4 | ExchangeID | int | YES | - | CODE-BACKED | Exchange scope; NULL = not exchange-specific. References `Dictionary.ExchangeInfo`. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Specific instrument; NULL = not instrument-specific. References `Trade.InstrumentMetaData`. |
| 6 | RestrictionTypeID | tinyint | NO | - | VERIFIED | Type of restriction (block/allow). References `Dictionary.RestrictionType`. Validated on INSERT. |
| 7 | ID | int | NO | IDENTITY | CODE-BACKED | Surrogate primary key. |
| 8 | DbLoginName | AS (suser_name()) | - | - | CODE-BACKED | Computed: current SQL login. |
| 9 | AppLoginName | AS (CONVERT(varchar(500), context_info())) | - | - | CODE-BACKED | Computed: application login from CONTEXT_INFO. |
| 10 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start. |
| 11 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end. |
| 12 | UnblockReasonId | int | YES | - | CODE-BACKED | If set, restriction can be overridden by this reason. References `Dictionary.BlockUnBlockReason`. |
| 13 | GroupID | int | YES | - | CODE-BACKED | Instrument group scope. References `Dictionary.TradingInstrumentGroups`. Part of CK. |
| 14 | RegistrationDate | datetime | YES | - | CODE-BACKED | Optional registration date for time-bounded rules. Part of UQ. |
| 15 | AccountTypeID | int | YES | - | CODE-BACKED | Account type scope. Part of UQ. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | Country for restriction |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulation scope |
| InstrumentTypeID | Dictionary.CurrencyType | Implicit FK | Instrument type |
| ExchangeID | Dictionary.ExchangeInfo | Implicit FK | Exchange |
| InstrumentID | Trade.InstrumentMetaData | Implicit FK | Specific instrument |
| RestrictionTypeID | Dictionary.RestrictionType | Implicit FK | Restriction type |
| UnblockReasonId | Dictionary.BlockUnBlockReason | Implicit FK | Unblock reason |
| GroupID | Dictionary.TradingInstrumentGroups | Implicit FK | Instrument group |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertCopyTradeSettlementRestrictions | @RequestedRestrictionsTable | WRITER (INSERT) | Adds new restrictions |
| Trade.InsertCopyTradeSettlementRestrictions_TRDOPS | @RequestedRestrictionsTable | WRITER (INSERT) | TRDOPS variant |
| Trade.AddCopyTradeSettlementRestriction | @RequestedRestrictionsTable | WRITER (INSERT) | Bulk add |
| Trade.DeleteCopyTradeSettlementRestriction | C | DELETER | Bulk delete by matching keys |
| Trade.DeleteCopyTradeSettlementRestrictionsValues | C | DELETER | Delete by table-valued params |
| Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS | C | DELETER | TRDOPS variant |
| Trade.GetCopyTradeSettlementRestrictions | - | READER | Returns all rows |
| Trade.GetSmartCopyRestrictions | restriction | READER | Joins to Dictionary + InstrumentMetaData |
| Trade.GetSmartCopyRestrictions_TRDOPS | restriction | READER | TRDOPS variant |
| History.CopyTradeSettlementRestrictions | - | History | System-versioned history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CopyTradeSettlementRestrictions (table)
├── Dictionary.RestrictionType [validated on INSERT]
├── Dictionary.Country, Regulation, CurrencyType, ExchangeInfo (implicit)
├── Trade.InstrumentMetaData (implicit)
├── Dictionary.BlockUnBlockReason, TradingInstrumentGroups (implicit)
└── History.CopyTradeSettlementRestrictions (history table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RestrictionType | Table | FK/validation for RestrictionTypeID |
| Dictionary.Country | Table | Lookup for CountryID |
| Dictionary.Regulation | Table | Lookup for RegulationID |
| Dictionary.CurrencyType | Table | Lookup for InstrumentTypeID |
| Dictionary.ExchangeInfo | Table | Lookup for ExchangeID |
| Trade.InstrumentMetaData | Table | Lookup for InstrumentID |
| Dictionary.BlockUnBlockReason | Table | Lookup for UnblockReasonId |
| Dictionary.TradingInstrumentGroups | Table | Lookup for GroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertCopyTradeSettlementRestrictions | Stored Procedure | INSERT |
| Trade.InsertCopyTradeSettlementRestrictions_TRDOPS | Stored Procedure | INSERT |
| Trade.AddCopyTradeSettlementRestriction | Stored Procedure | INSERT |
| Trade.DeleteCopyTradeSettlementRestriction | Stored Procedure | DELETE |
| Trade.DeleteCopyTradeSettlementRestrictionsValues | Stored Procedure | DELETE |
| Trade.DeleteCopyTradeSettlementRestrictionsValues_TRDOPS | Stored Procedure | DELETE |
| Trade.GetCopyTradeSettlementRestrictions | Stored Procedure | SELECT |
| Trade.GetSmartCopyRestrictions | Stored Procedure | SELECT with joins |
| Trade.GetSmartCopyRestrictions_TRDOPS | Stored Procedure | SELECT with joins |
| History.CopyTradeSettlementRestrictions | Table | System-versioned history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CopyTradeSettlementRestrictions | CLUSTERED PK | ID ASC | - | - | Active |
| UQ_CopyTradeSettlementRestriction | UNIQUE NONCLUSTERED | CountryID, RegulationID, AccountTypeID, GroupID, InstrumentTypeID, ExchangeID, InstrumentID, UnblockReasonId, RegistrationDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CopyTradeSettlementRestrictions | PK | ID |
| UQ_CopyTradeSettlementRestriction | UQ | Prevents duplicate restriction configurations |
| CK_CopyTradeSettlementRestriction_Asset | CHECK | (InstrumentTypeID IS NOT NULL OR ExchangeID IS NOT NULL OR InstrumentID IS NOT NULL OR GroupID IS NOT NULL) |
| DF_CopyTradeSettlementRestrictions_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_CopyTradeSettlementRestrictions_SysEnd | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |

### 7.3 Triggers

| Trigger | Event | Purpose |
|---------|-------|---------|
| TRG_T_CopyTradeSettlementRestrictions | INSERT | No-op UPDATE (legacy; column self-update pattern) |

---

## 8. Sample Queries

### 8.1 All restrictions by country and instrument type

```sql
SELECT  r.ID,
        r.CountryID,
        c.Name AS CountryName,
        r.InstrumentTypeID,
        r.RestrictionTypeID,
        rt.RestrictionTypeName
FROM    Trade.CopyTradeSettlementRestrictions r WITH (NOLOCK)
LEFT JOIN Dictionary.Country c WITH (NOLOCK) ON r.CountryID = c.CountryID
LEFT JOIN Dictionary.RestrictionType rt WITH (NOLOCK) ON r.RestrictionTypeID = rt.RestrictionTypeID
WHERE   r.InstrumentTypeID IS NOT NULL
ORDER BY r.CountryID, r.InstrumentTypeID
```

### 8.2 Restrictions for a specific country

```sql
SELECT  r.*,
        rt.RestrictionTypeName
FROM    Trade.CopyTradeSettlementRestrictions r WITH (NOLOCK)
INNER JOIN Dictionary.RestrictionType rt WITH (NOLOCK) ON r.RestrictionTypeID = rt.RestrictionTypeID
WHERE   r.CountryID = 43
  AND   r.SysEndTime = '9999-12-31 23:59:59.9999999'
```

### 8.3 Restriction type distribution

```sql
SELECT  r.RestrictionTypeID,
        rt.RestrictionTypeName,
        COUNT(*) AS Cnt
FROM    Trade.CopyTradeSettlementRestrictions r WITH (NOLOCK)
LEFT JOIN Dictionary.RestrictionType rt WITH (NOLOCK) ON r.RestrictionTypeID = rt.RestrictionTypeID
WHERE   r.SysEndTime = '9999-12-31 23:59:59.9999999'
GROUP BY r.RestrictionTypeID, rt.RestrictionTypeName
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| (None found) | Confluence | No direct Confluence pages found for CopyTradeSettlementRestrictions |

---

*Generated: 2026-03-14 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | Object: Trade.CopyTradeSettlementRestrictions | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CopyTradeSettlementRestrictions.sql*
