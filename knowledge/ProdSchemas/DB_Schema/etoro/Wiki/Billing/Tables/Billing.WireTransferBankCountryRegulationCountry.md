# Billing.WireTransferBankCountryRegulationCountry

> Configuration table mapping wire transfer regulatory jurisdictions to the receiving bank that should handle deposits, with optional country-level overrides and an IsSelected flag to designate the active bank per regulation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED INDEX on (RegulationID, CountryID, StateID) |
| **Partition** | No ([DICTIONARY] filegroup) |
| **Indexes** | 1 (CLUSTERED only, no PK) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.WireTransferBankCountryRegulationCountry defines which eToro receiving bank account should process wire transfer deposits for each regulatory jurisdiction (RegulationID). This is configuration data - the [DICTIONARY] filegroup placement confirms it changes rarely and supports read-heavy access.

The table solves the problem that eToro operates under multiple regulatory entities (CySEC, FCA, ASIC, etc.), each of which has a designated receiving bank. For most regulations, there is a single global bank entry (CountryID=0 and StateID=0 meaning "any country/state"). The IsSelected flag designates the active bank when multiple options exist for the same regulation (e.g., when migrating from one bank to another).

**14 rows** across **12 distinct RegulationIDs**:
- Most regulations: 1 row, CountryID=0, StateID=0, IsSelected=1
- RegulationID=1: 2 rows (BankID=13 Deutsche Bank selected, BankID=12 JPMorgan not selected) - bank transition or alternative routing
- RegulationID=8: 2 rows (CountryID=0 global + CountryID=219 for USA-specific routing)
- 13 of 14 rows IsSelected=true; 1 IsSelected=false

---

## 2. Business Logic

### 2.1 Bank Selection by Regulation and Country

**Read by**: `Billing.GetBankIDByRegulationAndCountry`

```sql
-- From Billing.GetBankIDByRegulationAndCountry
SELECT BankID, IsSelected
FROM [Billing].[WireTransferBankCountryRegulationCountry]
WHERE RegulationID = @RegulationID
AND CountryID = @CountryID
AND StateID = @StateID  -- default @StateID=0
```

The caller receives both BankID and IsSelected - it is the caller's responsibility to decide whether to use the bank if IsSelected=false (alternative/inactive bank row).

---

## 3. Data Overview

| RegulationID | CountryID | StateID | BankID | IsSelected | Notes |
|-------------|-----------|---------|--------|------------|-------|
| 1 | 0 | 0 | 13 (Deutsche Bank) | true | Active bank for Reg 1 |
| 1 | 0 | 0 | 12 (JPMorgan) | false | Inactive alternative for Reg 1 |
| 2 | 0 | 0 | 12 (JPMorgan) | true | |
| 4 | 0 | 0 | 12 (JPMorgan) | true | |
| 5 | 0 | 0 | 7 (Coutts) | true | |
| 6 | 0 | 0 | 9 (Silvergate) | true | |
| 7 | 0 | 0 | 9 (Silvergate) | true | |
| 8 | 0 | 0 | 12 (JPMorgan) | true | Global default for Reg 8 |
| 8 | 219 | 0 | 12 (JPMorgan) | true | USA-specific (CountryID=219) |
| 9 | 0 | 0 | 12 (JPMorgan) | true | |
| 10 | 0 | 0 | 12 (JPMorgan) | true | |
| 11 | 0 | 0 | 12 (JPMorgan) | true | |
| 13 | 0 | 0 | 12 (JPMorgan) | true | |
| 14 | 0 | 0 | 12 (JPMorgan) | true | |

JPMorgan (BankID=12) is the dominant receiving bank, handling 10 of 14 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | INT | NO | - | CODE-BACKED | Regulatory jurisdiction identifier. Implicit FK to Billing.WireTransferBanks or a regulation configuration table. Identifies the eToro legal entity (CySEC, FCA, ASIC, etc.) under which the customer is onboarded. 12 distinct values: 1, 2, 4-11, 13, 14. |
| 2 | CountryID | INT | NO | - | CODE-BACKED | Customer's country. Implicit FK to Dictionary.Country(CountryID). 0 = global default (applies to all countries unless a specific country row exists). CountryID=219 (USA) is the only non-zero value currently. |
| 3 | StateID | INT | NO | - | CODE-BACKED | Customer's state/province within a country. 0 = any state (global default). Supports US state-level routing overrides (not currently used - all rows are StateID=0). |
| 4 | BankID | INT | NO | - | CODE-BACKED | The receiving bank for this regulation/country/state combination. Implicit FK to Billing.WireTransferBanks(ID). BankID=12 (JPMorgan) handles most regulations; BankID=13 (Deutsche Bank) for Reg 1; BankID=7 (Coutts) for Reg 5; BankID=9 (Silvergate) for Regs 6-7. |
| 5 | IsSelected | BIT | NO | - | CODE-BACKED | Whether this bank is the currently active choice for this regulation. When multiple rows exist for the same RegulationID+CountryID+StateID, only IsSelected=1 rows represent the active routing. |

---

## 5. Relationships

### 5.1 References To (Implicit - No FK Constraints Defined)

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| BankID | Billing.WireTransferBanks | Implicit FK (no DDL constraint) |
| CountryID | Dictionary.Country | Implicit FK (no DDL constraint) |

### 5.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.GetBankIDByRegulationAndCountry | READER - primary consumer, filters by RegulationID + CountryID + StateID |

---

## 6. Technical Details

### 6.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| IX_WireTransferBankCountryRegulationCountry | CLUSTERED | RegulationID ASC, CountryID ASC, StateID ASC | Active |

No PK is defined - the clustered index serves as the physical sort and lookup key. Multiple rows can have the same (RegulationID, CountryID, StateID) combination (as seen with RegulationID=1 having 2 rows).

---

*Generated: 2026-03-17 | Quality: 8.2/10 | Phases: 8/11 | CODE-BACKED: 5 | Sources: 0*
*Object: Billing.WireTransferBankCountryRegulationCountry | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WireTransferBankCountryRegulationCountry.sql*
