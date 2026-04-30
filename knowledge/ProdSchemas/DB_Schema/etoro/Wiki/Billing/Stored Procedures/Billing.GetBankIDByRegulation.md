# Billing.GetBankIDByRegulation

> Selects the best wire transfer receiving bank for a given regulatory jurisdiction, preferring regulation-specific entries over universal fallbacks, and filtering to only active depots with visible banks.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wb.ID (WireTransferBanks row ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetBankIDByRegulation` answers one specific question: "For this customer's regulatory jurisdiction, which is the single best eToro receiving bank to present for a wire transfer deposit?" It returns `TOP 1` bank ID, selected via a deterministic ordering that prefers regulation-specific bank entries over universal fallbacks, then respects an explicit `Rank` ordering, and finally falls back to the highest ID.

eToro operates under multiple regulatory entities (CySEC, FCA, ASIC, etc.) and each has a designated receiving bank account. The procedure handles the case where some banks are configured for a specific regulation only, while others serve as universal fallbacks (`RegulationID=0` entries) — the `IN (@RegulationID, 0)` clause in the WHERE captures both, and `ORDER BY RegulationID DESC` ensures the specific-regulation entry wins over the universal fallback.

This procedure was introduced in August 2021 (PAYUS-3432) and extended in November 2021 (PAYUSOLA-4154) to add the `Rank` column ordering for deterministic bank selection when multiple banks are configured for the same regulation.

---

## 2. Business Logic

### 2.1 Regulation-Specific vs. Universal Fallback Selection

**What**: The procedure uses `IN (@RegulationID, 0)` with `ORDER BY RegulationID DESC` to implement a two-tier selection: specific entries take priority over universal entries.

**Columns/Parameters Involved**: `@RegulationID`, `WireTransferBankInfo.RegulationID`

**Rules**:
- `RegulationID = @RegulationID` rows in WireTransferBankInfo are regulation-specific entries (higher priority)
- `RegulationID = 0` rows are universal fallbacks (apply to any regulation)
- `ORDER BY RegulationID DESC` ensures specific entry (nonzero) outranks universal entry (0) when both exist
- `ORDER BY Rank` applies within the same RegulationID - lower rank number = higher priority
- `ORDER BY ID DESC` is the final tiebreaker — highest-ID bank wins if rank and regulation are equal

**Diagram:**
```
Candidates for @RegulationID = 2:
  BankID=12 (JPMorgan), RegulationID=2, Rank=1  <- WINS (specific, rank 1)
  BankID=7  (Coutts),   RegulationID=0, Rank=1  <- LOSES (universal fallback)

If no specific entry exists for @RegulationID:
  BankID=7  (Coutts), RegulationID=0 <- only candidate, becomes winner
```

### 2.2 Dual Visibility Filters

**What**: Only banks that are both depot-active and customer-visible are eligible.

**Columns/Parameters Involved**: `Depot.IsActive`, `WireTransferBanks.IsVisible`

**Rules**:
- `d.IsActive = 1`: the bank's payment depot must be active in the routing system
- `wb.IsVisible = 1`: the bank must be visible to customers (7 of 16 banks are IsVisible=true)
- Both conditions must be true — an active depot with a hidden bank or a visible bank with an inactive depot are both excluded
- Banks currently eligible: Sberbank (3), Coutts (7), National Australia Bank (8), Silvergate (9), Banking Circle (10), JPMorgan (12), Deutsche Bank (13), Customers Bank (14), Marsheq (15), DBS Singapore (16)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | int | - | (required) | CODE-BACKED | The customer's regulatory jurisdiction identifier. References Dictionary.Regulation.RegulationID implicitly. The procedure also includes RegulationID=0 (universal fallback entries) in the search. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | The selected bank's ID from Billing.WireTransferBanks. This is the TOP 1 result — the single best bank for the given regulation. Returned as a scalar for the caller to use in subsequent wire transfer bank detail lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegulationID | Billing.WireTransferBankInfo (RegulationID) | Lookup | Filters bank info records to those matching the requested regulation or the universal fallback (0). |
| wb.ID | Billing.WireTransferBanks | Read | Main bank registry. Returns the ID of the best-matching bank. |
| d.DepotID | Billing.Depot | JOIN | Validates the bank's depot is active (IsActive=1). |
| wbi.BankID | Billing.WireTransferBankInfo | JOIN | Links the bank to its regulation-specific info record. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser (role) | EXECUTE permission | Permission | Deposit setup service calls this to determine the correct receiving bank for wire transfer configuration. |
| WireTransferUser (role) | EXECUTE permission | Permission | Wire transfer processing service uses this to select the receiving bank for a customer's deposit. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetBankIDByRegulation (procedure)
├── Billing.WireTransferBanks (table)
├── Billing.Depot (table)
└── Billing.WireTransferBankInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferBanks | Table | Main FROM table. Filtered by IsVisible=1. Returns wb.ID. |
| Billing.Depot | Table | JOINed on DepotID. Filter: d.IsActive=1. Ensures only active routing depots are considered. |
| Billing.WireTransferBankInfo | Table | JOINed on BankID. Filter: RegulationID IN (@RegulationID, 0). Links banks to regulation-specific banking details. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser (role) | Permission | Deposit setup consumption |
| WireTransferUser (role) | Permission | Wire transfer bank selection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get the best bank ID for CySEC regulation (RegulationID=1)
```sql
EXEC Billing.GetBankIDByRegulation @RegulationID = 1
-- Returns ID from WireTransferBanks where regulation-specific entry exists (Deutsche Bank=13)
```

### 8.2 Direct query replicating the SP logic (for debugging)
```sql
SELECT TOP 1 wb.ID, wb.BankName, wbi.RegulationID, wb.Rank, d.IsActive, wb.IsVisible
FROM Billing.WireTransferBanks wb WITH (NOLOCK)
JOIN Billing.Depot d WITH (NOLOCK) ON d.DepotID = wb.DepotID
JOIN Billing.WireTransferBankInfo wbi WITH (NOLOCK) ON wbi.BankID = wb.ID
WHERE wbi.RegulationID IN (1, 0)  -- replace 1 with desired RegulationID
  AND d.IsActive = 1
  AND wb.IsVisible = 1
ORDER BY wbi.RegulationID DESC, wb.Rank, wb.ID DESC
```

### 8.3 Get all eligible candidates by regulation before TOP 1 filtering
```sql
SELECT wb.ID, wb.BankName, wbi.RegulationID, wb.Rank, d.DepotID
FROM Billing.WireTransferBanks wb WITH (NOLOCK)
JOIN Billing.Depot d WITH (NOLOCK) ON d.DepotID = wb.DepotID
JOIN Billing.WireTransferBankInfo wbi WITH (NOLOCK) ON wbi.BankID = wb.ID
WHERE wbi.RegulationID IN (2, 0)
  AND d.IsActive = 1
  AND wb.IsVisible = 1
ORDER BY wbi.RegulationID DESC, wb.Rank, wb.ID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Wire MIDs - LLD](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13388513671/Wire+MIDs+-+LLD) | Confluence | Technical design for wire transfer bank and MID configuration. Context for regulation-based bank routing. MEDIUM confidence. |
| [How to Add new bank support](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12287901714/How+to+Add+new+bank+support) | Confluence | Describes the process of adding new wire banks to the system. Confirms IsVisible, Rank, and RegulationID are the key configuration fields for bank selection. MEDIUM confidence. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetBankIDByRegulation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetBankIDByRegulation.sql*
