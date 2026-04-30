# Billing.FundingTypeToDepot

> Funding-type-to-depot assignment table. Each row maps one payment method type to one specific payment depot with an IsActive flag. 25 rows covering 14 non-credit-card funding types. Used to determine which depot handles a specific alternative payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (FundingTypeID, DepotID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 25 rows |
| **Partition** | N/A - filegroup PRIMARY; DATA_COMPRESSION = PAGE |
| **Indexes** | 1 CLUSTERED composite PK (FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.FundingTypeToDepot` provides a direct mapping from payment method type to the processing depot for non-credit-card, non-standard payment methods. While credit cards (FundingTypeID=1) use more complex routing via `Billing.ProtocolMIDSettings` and country/regulation rules, many alternative payment methods (wire transfer, ACH, iDEAL, etc.) have a fixed depot assignment recorded here.

A funding type may have multiple depot entries if it can route to different processors (e.g., FundingTypeID=2 wire transfer maps to 4 different bank depots), with IsActive controlling which are currently live.

**Active/Inactive**: 21 active (84%), 4 inactive (16%).

---

## 2. Live Data - Funding Type to Depot Assignments

| FundingTypeID | DepotID | IsActive |
|---|---|---|
| 2 (Wire) | 105 (Banking Circle) | Active |
| 2 (Wire) | 106 (JPMorgan) | Active |
| 2 (Wire) | 108 (Deutsche Bank) | Active |
| 2 (Wire) | 163 (Customers Bank) | Active |
| 22 | 46 | Inactive |
| 22 | 47 | Inactive |
| 22 | 58 | Active |
| 22 | 91 | Active |
| 25 | 55 | Active |
| 25 | 59 | Inactive |
| 26 | 56 | Inactive |
| 26 | 60 | Active |
| 28 | 69 | Active |
| 28 | 90 | Active |
| 29 | 71 | Active |
| 29 | 75 | Active |
| 32 | 86 | Active |
| 34 | 89 | Active |
| 35 | 93 | Active |
| 36 | 94 | Active |
| 37 | 103 | Active |
| 38 | 104 | Active |
| 39 | 109 | Active |
| 42 | 113 | Active |
| 43 | 165 | Active |

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **FundingTypeID** | int | NOT NULL | - | Dictionary.FundingType(FundingTypeID) [implicit] | [CODE-BACKED] Payment method type; part of composite PK. No explicit FK constraint. See live data table above for active types. |
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) | [CODE-BACKED] Payment depot assigned to handle this funding type; part of composite PK. Explicit FK. |
| **IsActive** | bit | NOT NULL | - | - | [CODE-BACKED] Whether this funding-type-to-depot mapping is currently active. 21 true (84%), 4 false. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_FundingTypeToDepot | CLUSTERED | (FundingTypeID ASC, DepotID ASC) | FILLFACTOR=90; DATA_COMPRESSION=PAGE. |

---

## 5. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | FundingTypeToDepot.DepotID = Depot.DepotID | Explicit FK. |
| Dictionary.FundingType | Many-to-one | FundingTypeToDepot.FundingTypeID = FundingType.FundingTypeID | Implicit (no FK). |

---

*Quality: 9.0/10 | 3 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,11*
