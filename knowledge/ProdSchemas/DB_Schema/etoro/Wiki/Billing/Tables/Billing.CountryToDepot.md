# Billing.CountryToDepot

> Country-and-card-type-to-depot routing table. Each row defines which payment depot and currency to use for a combination of customer country, card type, and depot. Currently empty (0 rows) - designed for country/card-type-based payment routing but not populated in production.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, CardTypeID, DepotID, CurrencyID) - PRIMARY KEY CLUSTERED |
| **Row Count** | 0 rows (empty) |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 CLUSTERED composite PK (FILLFACTOR=90) |

---

## 1. Business Meaning

`Billing.CountryToDepot` was designed to route credit card deposits to specific depots and currencies based on the customer's country and card type. The composite key of (CountryID, CardTypeID, DepotID, CurrencyID) suggests it would enable fine-grained routing rules: "for customers in country X, using card type Y, route to depot Z in currency C".

This routing is instead handled by more complex logic in `Billing.GetCCProcessingBundle`, `Billing.ProtocolMIDSettings`, and the CC processing procedures that consider regulation, BIN country, and other factors.

**Current state**: 0 rows. The routing table was designed but never populated, with routing logic implemented procedurally instead.

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **CountryID** | int | NOT NULL | - | Dictionary.Country(CountryID) | [CODE-BACKED] Customer's country; part of composite PK. Explicit FK. |
| **CardTypeID** | int | NOT NULL | - | Dictionary.CardType(CardTypeID) | [CODE-BACKED] Card type (Visa, MasterCard, Amex, etc.); part of composite PK. Explicit FK. |
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) | [CODE-BACKED] Target payment depot; part of composite PK. Explicit FK. |
| **CurrencyID** | int | NOT NULL | (0) | Dictionary.Currency(CurrencyID) [implicit] | [CODE-BACKED] Target currency; part of composite PK. Default 0 (any). No explicit FK constraint. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_BCTD | CLUSTERED | (CountryID, CardTypeID, DepotID, CurrencyID) ASC | FILLFACTOR=90. |

---

## 4. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Dictionary.Country | Many-to-one | CountryToDepot.CountryID = Country.CountryID | Explicit FK. |
| Dictionary.CardType | Many-to-one | CountryToDepot.CardTypeID = CardType.CardTypeID | Explicit FK. |
| Billing.Depot | Many-to-one | CountryToDepot.DepotID = Depot.DepotID | Explicit FK. |

---

*Quality: 8.6/10 | 4 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,11 | Empty table in production*
