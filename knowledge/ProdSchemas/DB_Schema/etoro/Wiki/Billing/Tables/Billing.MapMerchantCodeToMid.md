# Billing.MapMerchantCodeToMid

> Lookup table mapping payment provider merchant codes (as they appear in transaction records) to human-readable Merchant ID (MID) labels, scoped by regulatory entity and account currency.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: (RegulationID, CurrencyID, MerchantCode) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered on RegulationID+CurrencyID+MerchantCode + NC on CurrencyID) |

---

## 1. Business Meaning

Billing.MapMerchantCodeToMid resolves the raw merchant codes that payment providers (Skrill, Neteller) embed in transaction records into the human-readable MID labels used in the BackOffice and reporting tools. When compliance teams or operations staff look at a payment in the BackOffice, they see names like "SkrillEU" or "NetellerUK" instead of opaque provider codes like "5075493" or "AAABbn2n6r56x4Qe".

This table exists because the same payment provider may operate through multiple merchant accounts differentiated by regulatory entity (CySEC, FCA, ASIC, FSA Seychelles) and currency. A GBP Skrill payment under FCA regulation routes through a different merchant account than a EUR Skrill payment under CySEC, and each has a different raw MerchantCode. This table normalizes those provider-specific codes into the eToro's internal MID naming scheme.

The table is used by Billing.GetMIDDescription (and its V2 variant) to produce MID labels for deposit and cashout records in BackOffice views and payment reporting. The function joins Billing.ProtocolMIDSettings to this table via MerchantCode to resolve the final display label.

---

## 2. Business Logic

### 2.1 Three-Way Scoping of Merchant Code Resolution

**What**: A MerchantCode may be valid for multiple (Regulation, Currency) combinations, each mapping to the same or different MID. The three-way PK (RegulationID, CurrencyID, MerchantCode) allows different labels for the same code in different regulatory contexts.

**Columns/Parameters Involved**: `RegulationID`, `CurrencyID`, `MerchantCode`, `MID`

**Rules**:
- **RegulationID** scopes the resolution: CySEC (EU entity) maps to SkrillEU/NetellerEU; FCA (UK entity) maps to SkrillUK/NetellerUK; ASIC (AU entity) maps to SkrillAU.
- **CurrencyID** further scopes: the same Skrill MerchantCode maps to different numeric MID values per currency (e.g., Skrill 5075493 -> "SkrillEU" for USD, EUR, GBP - but each with a different eToro MID number).
- **MerchantCode types**:
  - Numeric provider codes (e.g., "5075493") = Skrill merchant account codes sent by Skrill in transaction callbacks.
  - Alpha codes (e.g., "AAABbn2n6r56x4Qe") = Neteller merchant account codes.
  - eToro internal codes (e.g., "ETOROEUOCTPT", "ETOROEUSALES") = eToro's own merchant account IDs used for credit card processing (19-character numeric MID values like "18986763").
- **MID values**: Either a human-readable label (SkrillEU, NetellerFCA, SkrillUK) or a numeric eToro merchant account number (18986763, 18989693, etc.).

### 2.2 Regulatory Distribution

**What**: Rows are distributed across 4 regulatory entities, one per eToro legal entity that processes payments.

**Columns/Parameters Involved**: `RegulationID`

**Rules**:
- **CySEC (1)**: 21 rows - EU entity (Cyprus), covering USD/EUR/GBP/JPY and more.
- **FCA (2)**: 20 rows - UK entity, covering same currencies under FCA regulation.
- **ASIC (4)**: 14 rows - Australian entity, AUD-focused.
- **FSA Seychelles (9)**: 8 rows - offshore entity.

---

## 3. Data Overview

| RegulationID | Regulation | CurrencyID | Currency | MerchantCode | MID | Meaning |
|---|---|---|---|---|---|---|
| 1 | CySEC | 1 | USD | 5075493 | SkrillEU | Skrill's EU merchant account code for USD transactions under CySEC regulation. Resolves to the label "SkrillEU" in BackOffice. |
| 1 | CySEC | 1 | USD | AAABbn2n6r56x4Qe | NetellerEU | Neteller's alpha merchant code for USD/CySEC. Resolves to "NetellerEU" label. |
| 1 | CySEC | 1 | USD | ETOROEUOCTPT | 18986763 | eToro's internal credit card MID code for EU entity (Oct PT campaign). Resolves to numeric MID used for card processing reports. |
| 1 | CySEC | 2 | EUR | ETOROEUSALES | 18957833 | eToro EU Sales merchant account for EUR. Different numeric MID from USD version of the same code. |
| 4 | ASIC | - | AUD | - | SkrillAU | ASIC-regulated Skrill transactions resolve to SkrillAU label instead of SkrillEU. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | int | NO | - | VERIFIED | eToro regulatory entity under which the transaction was processed. 1=CySEC (EU), 2=FCA (UK), 4=ASIC (Australia), 9=FSA Seychelles. Forms part of the composite PK. Explicit FK to Dictionary.Regulation(ID). Used in Billing.GetMIDDescription to scope the MID lookup by the deposit's ProcessRegulationID or the customer's RegulationID. |
| 2 | CurrencyID | int | NO | - | VERIFIED | Account denomination currency of the transaction. Explicit FK to Dictionary.Currency. Combined with RegulationID to narrow the merchant code lookup. The same MerchantCode often has different underlying MID values per currency (different numeric merchant accounts per currency). |
| 3 | MerchantCode | varchar(50) | NO | - | VERIFIED | The raw merchant identifier as provided by the payment provider or used in eToro's own systems. Three formats: (1) Numeric string = Skrill merchant account code (e.g., "5075493"); (2) Alphanumeric string = Neteller merchant account code (e.g., "AAABbn2n6r56x4Qe"); (3) eToro internal code = eToro's own merchant account identifier (e.g., "ETOROEUOCTPT", "ETOROEUSALES"). Joined against Billing.ProtocolMIDSettings.Value in Billing.GetMIDDescription. |
| 4 | MID | varchar(100) | NO | - | VERIFIED | Human-readable Merchant ID label or numeric merchant account number. Two forms: (1) Label = friendly name used in BackOffice UI (SkrillEU, SkrillUK, SkrillAU, NetellerEU, NetellerFCA); (2) Numeric = eToro's actual merchant account number at the payment gateway (e.g., 18986763). Returned by Billing.GetMIDDescription and displayed in payment investigation views. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK (explicit) | References the instrument/currency registry for the account denomination currency. |
| RegulationID | Dictionary.Regulation | FK (explicit) | References the regulatory entity under which the payment was processed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetMIDDescription | MerchantCode | LEFT JOIN via ProtocolMIDSettings.Value | Primary consumer. Resolves MerchantCode to MID for display in deposit/cashout BackOffice views. |
| Billing.GetMIDDescriptionV2 | MerchantCode | LEFT JOIN | Updated version of the MID description function. |
| Billing.GetDepositsCustomerCardPCIVersion | - | JOIN/Reader | Deposit reporting query that includes MID resolution. |
| Billing.GetRollbackedPaymentOrdersReport | - | JOIN/Reader | Rollback payment report that includes MID labels. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MapMerchantCodeToMid (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Explicit FK target for CurrencyID column |
| Dictionary.Regulation | Table | Explicit FK target for RegulationID column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetMIDDescription | Function | LEFT JOIN on MerchantCode - primary consumer |
| Billing.GetMIDDescriptionV2 | Function | LEFT JOIN on MerchantCode |
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | Reader for deposit reporting |
| Billing.GetRollbackedPaymentOrdersReport | Stored Procedure | Reader for rollback reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingMapMerchantCodeToMid | CLUSTERED PK | RegulationID ASC, CurrencyID ASC, MerchantCode ASC | - | - | Active (FILLFACTOR=95) |
| i_CureenyID | NC | CurrencyID ASC | - | - | Active - supports currency-based lookups (note: typo in index name "Cureeny") |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingMapMerchantCodeToMid | PRIMARY KEY | (RegulationID, CurrencyID, MerchantCode) - ensures unique MID per regulation+currency+code combination |
| FK_BillingMapMerchantCodToMid_DictionaryCurrency | FK | CurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_BillingMapMerchantCodToMid_DictionaryRegulation | FK | RegulationID -> Dictionary.Regulation(ID) |

---

## 8. Sample Queries

### 8.1 Get all MID mappings with human-readable names

```sql
SELECT
    r.Name AS Regulation,
    c.Abbreviation AS Currency,
    m.MerchantCode,
    m.MID
FROM Billing.MapMerchantCodeToMid m WITH (NOLOCK)
JOIN Dictionary.Regulation r WITH (NOLOCK) ON m.RegulationID = r.ID
JOIN Dictionary.Currency c WITH (NOLOCK) ON m.CurrencyID = c.CurrencyID
ORDER BY r.Name, c.Abbreviation, m.MerchantCode
```

### 8.2 Resolve a MerchantCode to its MID label

```sql
SELECT m.MID
FROM Billing.MapMerchantCodeToMid m WITH (NOLOCK)
WHERE m.MerchantCode = '5075493'
  AND m.RegulationID = 1   -- CySEC
  AND m.CurrencyID = 1     -- USD
```

### 8.3 Find all mappings for a specific regulation entity

```sql
SELECT
    c.Abbreviation AS Currency,
    m.MerchantCode,
    m.MID
FROM Billing.MapMerchantCodeToMid m WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON m.CurrencyID = c.CurrencyID
WHERE m.RegulationID = 2  -- FCA (UK entity)
ORDER BY c.Abbreviation, m.MerchantCode
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (GetMIDDescription) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.MapMerchantCodeToMid | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.MapMerchantCodeToMid.sql*
