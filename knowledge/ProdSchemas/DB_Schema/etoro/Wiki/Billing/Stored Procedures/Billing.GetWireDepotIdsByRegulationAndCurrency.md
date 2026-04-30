# Billing.GetWireDepotIdsByRegulationAndCurrency

> Returns the distinct DepotIDs (payment terminals) that support wire transfer deposits for a given regulatory jurisdiction and currency: joins WireTransferBankInfo (regulation+currency config) to WireTransferBanks (depot mapping) for wire transfer routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RegulationID + @CurrencyID; returns one row per eligible DepotID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWireDepotIdsByRegulationAndCurrency resolves which payment processing depots (terminals/merchant IDs) are configured to accept wire transfer deposits for a specific regulatory jurisdiction and currency combination. This is a routing lookup: given a customer's regulatory context and the currency they wish to deposit in, the billing service uses the returned DepotIDs to determine which wire transfer endpoint to route the deposit to.

The two-table join reflects the wire transfer configuration architecture:
- `Billing.WireTransferBankInfo`: Configuration records mapping RegulationID + CurrencyID to a BankID (which bank accepts wire transfers under that regulation in that currency)
- `Billing.WireTransferBanks`: Maps BankID to DepotID (the payment terminal/MID through which the bank processes wire deposits)

Referenced in "Wire Transfer Re-Architecture Proposal" and "Wire MIDs - LLD" (Confluence MG/NOC1) - part of the wire transfer routing architecture.

---

## 2. Business Logic

### 2.1 Regulation + Currency to Depot Routing

**What**: Finds all DepotIDs where wire transfers can be processed under a given regulation and currency.

**Columns/Parameters Involved**: `@RegulationID`, `@CurrencyID`, `Billing.WireTransferBankInfo.RegulationID`, `Billing.WireTransferBankInfo.CurrencyID`, `Billing.WireTransferBankInfo.BankID`, `Billing.WireTransferBanks.ID`, `Billing.WireTransferBanks.DepotID`

**Rules**:
- `WHERE BI.RegulationID = @RegulationID AND BI.CurrencyID = @CurrencyID` - filters to matching bank configurations
- `INNER JOIN WireTransferBanks wt ON BI.BankID = wt.ID` - resolves bank to depot
- `SELECT DISTINCT wt.DepotID` - deduplicates; multiple bank configurations may map to the same depot

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | INT | NO | - | CODE-BACKED | Regulatory jurisdiction identifier. Filters WireTransferBankInfo to configurations applicable for this regulation (e.g., CySEC, ASIC, FCA). |
| 2 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency identifier. Filters WireTransferBankInfo to configurations for this currency (e.g., USD, EUR, GBP). |
| - | DepotID | INT | YES | - | CODE-BACKED | Payment terminal / MID that accepts wire transfers under the given regulation and currency. From Billing.WireTransferBanks.DepotID. DISTINCT - one row per unique depot even if multiple bank configs point to it. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID, CurrencyID, BankID | Billing.WireTransferBankInfo | SELECT | Configuration mapping regulation+currency to BankID |
| BankID -> DepotID | Billing.WireTransferBanks | INNER JOIN | Resolves BankID to DepotID for routing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wire transfer deposit routing service | @RegulationID, @CurrencyID | EXEC | Terminal selection for wire deposit routing (Wire Transfer Re-Architecture, Confluence MG/NOC1) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWireDepotIdsByRegulationAndCurrency (procedure)
+-- Billing.WireTransferBankInfo (table) [regulation+currency -> BankID config]
+-- Billing.WireTransferBanks (table) [BankID -> DepotID mapping]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferBankInfo | Table | Filters by RegulationID + CurrencyID; provides BankID |
| Billing.WireTransferBanks | Table | INNER JOIN on BankID -> returns DepotID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wire transfer routing service | External | Identifies valid depots for wire deposit routing by regulation and currency |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DISTINCT DepotID | Design | Deduplicates result; multiple bank configs (different BankIDs) may map to the same DepotID |
| NOLOCK throughout | Concurrency | Both tables read with NOLOCK - configuration data read; acceptable for routing lookups |
| Empty result | Behavior | No rows returned if no WireTransferBankInfo record matches RegulationID + CurrencyID; wire transfer not available for that combination |

---

## 8. Sample Queries

### 8.1 Find depots for CySEC regulation in EUR

```sql
EXEC [Billing].[GetWireDepotIdsByRegulationAndCurrency]
    @RegulationID = 1,   -- CySEC
    @CurrencyID = 2      -- EUR
-- Returns: DepotID list for EUR wire transfers under CySEC
```

### 8.2 Equivalent direct query

```sql
SELECT DISTINCT wt.DepotID
FROM [Billing].[WireTransferBankInfo] bi WITH (NOLOCK)
INNER JOIN [Billing].[WireTransferBanks] wt WITH (NOLOCK) ON bi.BankID = wt.ID
WHERE bi.RegulationID = 1
  AND bi.CurrencyID = 2
```

### 8.3 Check available regulation+currency combinations

```sql
SELECT DISTINCT bi.RegulationID, bi.CurrencyID, COUNT(DISTINCT wt.DepotID) AS DepotCount
FROM [Billing].[WireTransferBankInfo] bi WITH (NOLOCK)
INNER JOIN [Billing].[WireTransferBanks] wt WITH (NOLOCK) ON bi.BankID = wt.ID
GROUP BY bi.RegulationID, bi.CurrencyID
ORDER BY bi.RegulationID, bi.CurrencyID
```

---

## 9. Atlassian Knowledge Sources

**Confluence**:
- "Wire Transfer Re-Architecture Proposal" (/spaces/NOC1 and /spaces/MG) - wire transfer routing architecture that this procedure is part of
- "Wire MIDs - LLD" (/spaces/MG) - low-level design for wire transfer merchant IDs (DepotIDs) and routing configuration
- "Payments Configuration Tool (PCT) Roles & Access" (/spaces/MG) - PCT manages WireTransferBankInfo configuration data

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 9.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 3 Confluence (Wire Transfer Re-Architecture, Wire MIDs LLD, PCT Roles) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWireDepotIdsByRegulationAndCurrency | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWireDepotIdsByRegulationAndCurrency.sql*
