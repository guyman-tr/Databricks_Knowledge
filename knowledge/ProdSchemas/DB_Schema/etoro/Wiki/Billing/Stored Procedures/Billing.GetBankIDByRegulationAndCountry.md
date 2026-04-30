# Billing.GetBankIDByRegulationAndCountry

> Returns the wire transfer receiving bank ID(s) configured for a specific regulation, country, and optionally state, with a selection flag indicating the currently active bank when multiple are configured.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns BankID (WireTransferBanks row ID) + IsSelected flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetBankIDByRegulationAndCountry` retrieves the wire transfer receiving bank configuration for a specific combination of regulatory jurisdiction, customer country, and state. Unlike `Billing.GetBankIDByRegulation` which always picks `TOP 1`, this procedure can return multiple rows (when multiple banks are configured for the same jurisdiction, e.g., during a bank migration) and exposes the `IsSelected` flag so the caller can determine which bank is currently the active choice.

The `WireTransferBankCountryRegulationCountry` table it reads from is configuration data that maps each regulatory entity (RegulationID) to the eToro receiving bank. Most regulations have a single entry with CountryID=0 (global). The exception is RegulationID=8 which has a US-specific override (CountryID=219) in addition to the global entry, enabling US customers to be routed to a different bank than the rest of the world under that regulation.

The `@StateID` parameter (default=0) supports US-state-level routing granularity, though currently all rows have StateID=0.

---

## 2. Business Logic

### 2.1 Three-Tier Lookup: Regulation + Country + State

**What**: The three-parameter WHERE clause implements a precise lookup that can return a regulation's global bank, a country-specific override, or a state-specific override.

**Columns/Parameters Involved**: `@RegulationID`, `@CountryID`, `@StateID`

**Rules**:
- For most regulations: call with `@CountryID=0, @StateID=0` to get the global bank assignment
- For country-specific override lookup: call with the actual CountryID (e.g., 219 for USA) and `@StateID=0`
- The caller decides whether to first try CountryID=actual country, then fall back to CountryID=0 (global)
- `@StateID=0` is the only value in use; state-level routing is provisioned but not currently populated

### 2.2 IsSelected Flag and Multi-Bank Scenarios

**What**: When multiple banks are configured for the same regulation (e.g., during bank migration), IsSelected identifies the active bank.

**Columns/Parameters Involved**: `BankID`, `IsSelected`

**Rules**:
- `IsSelected=true`: this bank is the currently active receiving bank for this regulation/country
- `IsSelected=false`: alternative/inactive bank entry (legacy or future candidate)
- Example: RegulationID=1 has two rows — Deutsche Bank (IsSelected=true) and JPMorgan (IsSelected=false) — indicating an active migration where Deutsche Bank replaced JPMorgan but JPMorgan entry is retained
- 13 of 14 rows across all regulations have IsSelected=true; only 1 is false

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | int | - | (required) | CODE-BACKED | Regulatory jurisdiction filter. References Dictionary.Regulation.RegulationID. Determines which eToro regulatory entity's receiving bank is needed (e.g., CySEC, FCA, ASIC). |
| 2 | @CountryID | int | - | (required) | CODE-BACKED | Customer country filter. Use 0 for global (regulation-wide) bank assignment. Use specific CountryID for country overrides (e.g., 219=USA for RegulationID=8 which has US-specific routing). References Dictionary.Country.CountryID. |
| 3 | @StateID | int | - | 0 | CODE-BACKED | US-state-level routing granularity. Default=0 (no state-specific override). Currently all rows in WireTransferBankCountryRegulationCountry have StateID=0, making this parameter functionally unused today but provisioned for future state-level routing. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BankID | int | NO | - | VERIFIED | The wire transfer receiving bank ID. References Billing.WireTransferBanks.ID. The full bank details (IBAN, SWIFT, account coordinates, beneficiary name) are in Billing.WireTransferBankInfo joined on this BankID. |
| 2 | IsSelected | bit | NO | - | VERIFIED | Whether this bank is the currently active selection for this regulation/country: 1=active bank to use, 0=inactive/legacy entry. Callers should filter to IsSelected=1 for the active routing bank. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all data) | Billing.WireTransferBankCountryRegulationCountry | Read | Simple SELECT with three-column WHERE filter. Returns BankID and IsSelected. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser (role) | EXECUTE permission | Permission | Deposit setup service uses this to retrieve regulation-specific wire bank configuration. |
| WireTransferUser (role) | EXECUTE permission | Permission | Wire transfer service uses this for bank routing decisions per regulation and country. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetBankIDByRegulationAndCountry (procedure)
└── Billing.WireTransferBankCountryRegulationCountry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferBankCountryRegulationCountry | Table | SELECT BankID, IsSelected WHERE RegulationID=@RegulationID AND CountryID=@CountryID AND StateID=@StateID. The clustered index on (RegulationID, CountryID, StateID) makes this an efficient point lookup. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser (role) | Permission | Wire bank configuration retrieval |
| WireTransferUser (role) | Permission | Wire bank routing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get the global wire bank for CySEC regulation
```sql
EXEC Billing.GetBankIDByRegulationAndCountry @RegulationID = 1, @CountryID = 0
-- Returns Deutsche Bank (BankID=13, IsSelected=1) and JPMorgan (BankID=12, IsSelected=0)
```

### 8.2 Get the US-specific wire bank for regulation 8
```sql
EXEC Billing.GetBankIDByRegulationAndCountry @RegulationID = 8, @CountryID = 219
-- Returns the US-specific bank entry if it exists for RegulationID=8
```

### 8.3 Get active bank for a regulation (filter IsSelected)
```sql
SELECT BankID, IsSelected,
       wb.BankName, wbi.BeneficiaryName, wbi.SwiftCode
FROM Billing.WireTransferBankCountryRegulationCountry wtb WITH (NOLOCK)
JOIN Billing.WireTransferBanks wb WITH (NOLOCK) ON wb.ID = wtb.BankID
JOIN Billing.WireTransferBankInfo wbi WITH (NOLOCK) ON wbi.BankID = wtb.BankID
WHERE wtb.RegulationID = 2
  AND wtb.CountryID = 0
  AND wtb.StateID = 0
  AND wtb.IsSelected = 1  -- active bank only
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Wire MIDs - LLD](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13388513671/Wire+MIDs+-+LLD) | Confluence | Technical design for wire transfer MID and bank configuration per regulation. Confirms regulation-to-bank mapping is the core use case. MEDIUM confidence. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetBankIDByRegulationAndCountry | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetBankIDByRegulationAndCountry.sql*
