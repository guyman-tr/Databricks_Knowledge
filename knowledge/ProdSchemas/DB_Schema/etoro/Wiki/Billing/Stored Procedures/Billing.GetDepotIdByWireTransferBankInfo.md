# Billing.GetDepotIdByWireTransferBankInfo

> Returns the DepotID (payment gateway) to use for a wire transfer given regulation, bank, funding type, and currency - a wire transfer routing lookup used by the wire transfer service to determine which depot should process the payment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar: DepotID (INT) for the wire transfer bank matching all four filter criteria |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepotIdByWireTransferBankInfo` is a wire transfer routing lookup. Given four routing dimensions (RegulationID, BankID, FundingTypeID, CurrencyID), it returns the DepotID - the payment gateway/processor - that should handle the wire transfer.

Wire transfers can be processed by different depots depending on the regulatory jurisdiction, the specific receiving bank, the currency, and the payment type (e.g., standard wire vs. a specific local payment scheme). This SP encodes the routing decision by querying the bank info and depot configuration tables.

Used by the `WireTransferUser` service account, which is the wire transfer processing service.

---

## 2. Business Logic

### 2.1 Wire Transfer Depot Routing

**What**: Resolves a combination of regulatory, bank, and currency parameters to a single payment depot.

**Columns/Parameters Involved**: `@RegulationID`, `@BankID`, `@FundingTypeID`, `@CurrencyID`, `DepotID (output)`

**Rules**:
- `FROM Billing.WireTransferBankInfo WHERE RegulationID=@RegulationID AND BankID=@BankID AND CurrencyID=@CurrencyID`
- `INNER JOIN Billing.WireTransferBanks ON BankID` - joins bank info to bank-depot mapping
- `INNER JOIN Billing.Depot ON DepotID WHERE FundingTypeID=@FundingTypeID` - further filters to depot of the specified funding type
- `SELECT TOP 1 wt.DepotID` - returns the first matching depot; INNER JOINs ensure all conditions must match; TOP 1 guards against duplicates

**Diagram**:
```
@RegulationID + @BankID + @CurrencyID
  |
  -> Billing.WireTransferBankInfo (RegulationID + BankID + CurrencyID)
     |
     INNER JOIN Billing.WireTransferBanks (DepotID mapping)
     |
     INNER JOIN Billing.Depot WHERE FundingTypeID = @FundingTypeID
     |
     v
     TOP 1 DepotID (the gateway to use)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegulationID | INT | NO | - | CODE-BACKED | Regulatory jurisdiction ID. Scopes the bank info lookup to a specific regulation (e.g., EU MiFID, ASIC, FCA). Matches Billing.WireTransferBankInfo.RegulationID. |
| 2 | @BankID | INT | NO | - | CODE-BACKED | Wire transfer bank identifier. Matches Billing.WireTransferBankInfo.BankID and Billing.WireTransferBanks.ID - the specific receiving bank. |
| 3 | @FundingTypeID | INT | NO | - | CODE-BACKED | Funding type filter applied to the depot. Matches Billing.Depot.FundingTypeID. Typically 2=WireTransfer, but may be a more specific type for local payment schemes. |
| 4 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency of the wire transfer. Matches Billing.WireTransferBankInfo.CurrencyID. Different currencies may route to different depots even for the same bank. |
| 5 | DepotID (output) | INT | YES | - | CODE-BACKED | Primary key of the depot to use for this wire transfer. From Billing.WireTransferBanks.DepotID. NULL if no matching bank configuration exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BankID + @RegulationID + @CurrencyID | Billing.WireTransferBankInfo | Lookup | Retrieves wire bank configuration |
| Billing.WireTransferBankInfo.BankID | Billing.WireTransferBanks.ID | INNER JOIN | Maps bank info to bank-depot mapping |
| Billing.WireTransferBanks.DepotID | Billing.Depot.DepotID | INNER JOIN | Verifies depot FundingTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WireTransferUser | GRANT EXECUTE | Permission | Wire transfer service uses for depot routing decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepotIdByWireTransferBankInfo (procedure)
├── Billing.WireTransferBankInfo (table)
├── Billing.WireTransferBanks (table)
└── Billing.Depot (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferBankInfo | Table | READ NOLOCK - primary filter by RegulationID + BankID + CurrencyID |
| Billing.WireTransferBanks | Table | READ NOLOCK - INNER JOIN to get DepotID from BankID |
| Billing.Depot | Table | READ NOLOCK - INNER JOIN to filter by FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WireTransferUser (wire transfer service) | DB User | Calls for depot routing during wire transfer initiation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN (not LEFT) | Design | All three joins are INNER - if any record is missing (no matching BankInfo, no WireTransferBanks row, or Depot has wrong FundingType), returns NULL/no rows |
| SELECT TOP 1 | Safety | Returns at most one DepotID; in normal operation each regulation-bank-currency-fundingtype combo maps to exactly one depot |
| WITH (NOLOCK) | Read hint | All three tables read dirty - acceptable for routing lookups (configuration data changes infrequently) |

---

## 8. Sample Queries

### 8.1 Get depot for a wire transfer routing scenario

```sql
EXEC Billing.GetDepotIdByWireTransferBankInfo
    @RegulationID = 1,    -- e.g., EU regulation
    @BankID = 42,
    @FundingTypeID = 2,   -- WireTransfer
    @CurrencyID = 1;      -- USD
```

### 8.2 Inline equivalent

```sql
SELECT TOP 1 wt.DepotID
FROM Billing.WireTransferBankInfo BI WITH (NOLOCK)
INNER JOIN Billing.WireTransferBanks wt WITH (NOLOCK) ON BI.BankID = wt.ID
INNER JOIN Billing.Depot d WITH (NOLOCK) ON wt.DepotID = d.DepotID
WHERE BI.RegulationID = 1
  AND BI.BankID = 42
  AND BI.CurrencyID = 1
  AND d.FundingTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Wire MIDs - LLD (Confluence) | Confluence | Low-level design document for wire MID configuration - likely covers how WireTransferBankInfo and depot routing are configured |
| Routing Tool - Guide (Confluence) | Confluence | Routing tool guide - likely covers how depot routing decisions are made for wire transfers |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 2 Confluence (search results - pages not fully read) + 0 Jira | Procedures: 0 SQL callers (WireTransferUser service) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepotIdByWireTransferBankInfo | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepotIdByWireTransferBankInfo.sql*
