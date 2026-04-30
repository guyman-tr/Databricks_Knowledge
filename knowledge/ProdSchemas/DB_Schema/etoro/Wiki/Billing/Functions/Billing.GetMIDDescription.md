# Billing.GetMIDDescription

> Multi-statement table-valued function that resolves the merchant identifier (MID) and human-readable description for a deposit or cashout transaction, using a priority-ordered decision tree based on funding type, regulation, and payment channel configuration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Multi-Statement Table-Valued Function (MSTVF) |
| **Key Identifier** | Returns TABLE(MID, Description) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMIDDescription` answers the question: "For this specific payment action, which merchant account was used and what should we display for it?" It takes the internal transaction ID and payment direction (deposit vs. cashout) and returns a standardized MID code plus a back-office-readable description. The MID (Merchant ID) is the identifier that links a transaction to a payment provider channel - used in reconciliation, chargebacks, and BI reporting.

The function exists because MID resolution is non-trivial: the same funding type (e.g., Skrill) may route through different merchant accounts depending on regulation, currency, and whether the transaction has an explicit merchant account assigned. Without this function, every BI report and back-office tool would need to replicate the same multi-branch resolution logic independently.

Data flows into the function via the ActionID: for deposits it reads `Billing.Deposit`, for cashouts it reads `Billing.WithdrawToFunding`. The function then walks a decision tree based on the resolved `FundingTypeID` and available MID configuration, ultimately returning a single row with MID and Description. It is consumed exclusively by BI reporting stored procedures for state reports and PIPS (Payments Intelligence) reports.

---

## 2. Business Logic

### 2.1 Payment Direction Lookup

**What**: The function serves both deposit and cashout flows using a single parameter.

**Columns/Parameters Involved**: `@PaymentType`, `@ActionID`

**Rules**:
- When `@PaymentType = 1` (Deposit): resolves transactional data from `Billing.Deposit` using `@ActionID` as `DepositID`. Reads CID, ProtocolMIDSettingsID, MerchantAccountID, DepotID, CurrencyID, ProcessRegulationID, FundingTypeID.
- When `@PaymentType = 2` (Cashout): resolves from `Billing.WithdrawToFunding` using `@ActionID` as `BWTF.ID`. Reads the same fields, but RegulationID comes from `BackOffice.Customer` (not the transaction record).

**Diagram**:
```
@PaymentType = 1 (Deposit)
  -> Billing.Deposit JOIN Billing.Funding JOIN Dictionary.Regulation JOIN Billing.Depot
  -> extracts: CID, FundingTypeID, ProtocolMIDSettingsID, MerchantAccountID, DepotID, CurrencyID, RegulationID

@PaymentType = 2 (Cashout)
  -> Billing.WithdrawToFunding JOIN Billing.Withdraw JOIN Billing.Funding
     JOIN BackOffice.Customer JOIN Dictionary.Regulation JOIN Billing.Depot
  -> extracts same fields (RegulationID from Customer record, not transaction)
```

### 2.2 MID Resolution Decision Tree

**What**: A priority-ordered decision tree that resolves the MID and Description based on funding type and available configuration.

**Columns/Parameters Involved**: `@FundingTypeID`, `@ProtocolMIDSettingsID`, `@MerchantAccountID`, `@RegulationID`, `@CurrencyID`

**Rules**:
- **WireTransfer (FundingTypeID=2)** AND ProtocolMIDSettingsID is set: read MID/Description directly from `Billing.ProtocolMIDSettings`. Most deterministic branch.
- **Redeem (FundingTypeID=27)**: returns `'N/A'` for both MID and Description. Redeem transactions have no merchant channel.
- **Giropay (FundingTypeID=11)**: reads `Dictionary.MerchantAccount WHERE MerchantID=10`. Code comment flags "Missing Data [MerchantAccountID]" - the MerchantAccountID is not available on the transaction, so a hardcoded MerchantID=10 is used.
- **Skrill (FundingTypeID=8) AND Cashout AND no MerchantAccountID**: uses a fallback chain:
  1. Look up most recent successful deposit (PaymentStatusID=2) for the same DepotID to borrow its ProtocolMIDSettings.
  2. If found: COALESCE(DMA.Name, BPMS.Description, BMMC.MID, BPMS.Value, RegulationName).
  3. If not found: resolve by RegulationID: CYSEC(1)=SkrillEU, FCA(2)=SkrillUK, ASIC(4) or ASICGAML(10)=SkrillAU, else SkrillUK.
- **eToroMoney (FundingTypeID=33)** AND no MerchantAccount AND no ProtocolMID: resolve by RegulationID/CurrencyID: FCA or CurrencyID=3 -> eToroMoneyUK, else -> eToroMoneyEU.
- **No ProtocolMIDSettingsID AND has MerchantAccountID**: direct lookup in `Dictionary.MerchantAccount` by MerchantAccountID.
- **Default fallback**: if ProtocolMIDSettingsID is set, COALESCE(DMA.Name, BPMS.Description, BMMC.MID, BPMS.Value, RegulationName); else use DepotName. Final: COALESCE(@MIDID, @DepotName), COALESCE(@Description, @RegulationName, @DepotName).

**Diagram**:
```
FundingTypeID = WireTransfer(2) AND ProtocolMIDSettingsID set
  -> Billing.ProtocolMIDSettings: Value=MID, Description=Description

FundingTypeID = Redeem(27)
  -> MID='N/A', Description='N/A'

FundingTypeID = Giropay(11)
  -> Dictionary.MerchantAccount WHERE MerchantID=10 (hardcoded, known data gap)

FundingTypeID = Skrill(8) AND Cashout AND no MerchantAccountID
  -> Find recent deposit for DepotID (PaymentStatusID=2)
     -> Found: COALESCE(DMA.Name, BPMS.Description, BMMC.MID, BPMS.Value, RegulationName)
     -> Not found: RegulationID lookup
                   CYSEC(1) -> SkrillEU
                   FCA(2)   -> SkrillUK
                   ASIC(4)  -> SkrillAU
                   ASICGAML(10) -> SkrillAU
                   else     -> SkrillUK

FundingTypeID = eToroMoney(33) AND no MerchantAccount AND no ProtocolMID
  -> FCA or CurrencyID=3 -> eToroMoneyUK
  -> else               -> eToroMoneyEU

No ProtocolMIDSettingsID AND MerchantAccountID set
  -> Dictionary.MerchantAccount by MerchantAccountID

Fallback
  -> ProtocolMIDSettingsID set: COALESCE(DMA.Name, BPMS.Description, BMMC.MID, BPMS.Value, RegulationName)
  -> else: DepotName
  -> Final: COALESCE(@MIDID, @DepotName), COALESCE(@Description, @RegulationName, @DepotName)
```

### 2.3 Regulation-Based Skrill Channel Mapping

**What**: For Skrill cashouts without an assigned merchant account, the function uses the customer's regulatory jurisdiction to determine which Skrill channel to report.

**Columns/Parameters Involved**: `@RegulationID`, `@CurrencyID`

**Rules**:
- RegulationID=1 (CYSEC, Cyprus regulation): channel = `SkrillEU`
- RegulationID=2 (FCA, UK regulation): channel = `SkrillUK`
- CurrencyID=4 (ASIC) or CurrencyID=10 (ASICGAML, Australia): channel = `SkrillAU`
- All other regulations: default to `SkrillUK`

---

## 3. Data Overview

N/A for Multi-Statement Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionID | INT | NO | - | CODE-BACKED | The transaction identifier. Interpreted as DepositID when @PaymentType=1, or as WithdrawToFunding.ID when @PaymentType=2. Drives the JOIN to retrieve all transaction context needed for MID resolution. |
| 2 | @PaymentType | INT | NO | - | CODE-BACKED | Payment direction: 1=Deposit (reads Billing.Deposit), 2=Cashout (reads Billing.WithdrawToFunding). Determines which transaction table is queried and which regulation source is used (deposit: ProcessRegulationID on transaction; cashout: RegulationID from BackOffice.Customer). |
| 3 | MID (return) | varchar(100) | NO | - | CODE-BACKED | The resolved merchant identifier code. Examples: 'SkrillEU', 'SkrillUK', 'SkrillAU', 'eToroMoneyUK', 'eToroMoneyEU', 'N/A' (for Redeem), Giropay merchant name, or ProtocolMIDSettings.Value for wire transfers. Used for reconciliation and BI reporting. COALESCE(@MIDID, @DepotName) as final fallback. |
| 4 | Description (return) | nvarchar(250) | NO | - | CODE-BACKED | The back-office-readable description of the merchant channel. For protocol-based channels: ProtocolMIDSettings.Description or MerchantAccount.BODescription. For regulation-based channels: the regulation name. Final fallback: COALESCE(@Description, @RegulationName, @DepotName). Always non-null due to DepotName ultimate fallback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ActionID (Deposit path) | Billing.Deposit | Lookup | Reads CID, ProtocolMIDSettingsID, MerchantAccountID, DepotID, CurrencyID, ProcessRegulationID for deposit transactions |
| @ActionID (Deposit path) | Billing.Funding | Lookup | JOINed to Billing.Deposit to resolve FundingTypeID |
| @ActionID (Deposit path) | Billing.Depot | Lookup | JOINed to Billing.Deposit to resolve depot name |
| @ActionID (Deposit path) | Dictionary.Regulation | Lookup | LEFT JOINed to Billing.Deposit.ProcessRegulationID to resolve regulation name |
| @ActionID (Cashout path) | Billing.WithdrawToFunding | Lookup | Reads ProtocolMIDSettingsID, MerchantAccountID, DepotID, ProcessCurrencyID for cashout transactions |
| @ActionID (Cashout path) | Billing.Withdraw | Lookup | JOINed to get CID from cashout transaction |
| @ActionID (Cashout path) | BackOffice.Customer | Lookup | JOINed to get RegulationID for cashout (regulation stored on customer, not on transaction) |
| MID resolution | Billing.ProtocolMIDSettings | Lookup | Primary MID source for WireTransfer and fallback paths; returns Value and Description |
| MID resolution | Billing.MapMerchantCodeToMid | Lookup | LEFT JOINed to ProtocolMIDSettings to resolve BMMC.MID from merchant code |
| MID resolution | Dictionary.MerchantAccount | Lookup | Used for Giropay (MerchantID=10 hardcoded) and direct MerchantAccountID lookups; returns Name and BODescription |
| Skrill fallback | Billing.Deposit | Lookup | Secondary query: finds most recent successful deposit (PaymentStatusID=2) for same DepotID to borrow ProtocolMIDSettings for Skrill cashouts without MerchantAccountID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_State_Report | CROSS APPLY | Calls | BI deposit state report uses this function to resolve MID/description for each deposit row |
| Billing.BI_Cashout_State_Report | CROSS APPLY | Calls | BI cashout state report uses this function to resolve MID/description for each cashout row |
| Billing.BI_Deposit_PIPS_Report | CROSS APPLY | Calls | PIPS (Payments Intelligence) deposit report uses this function |
| Billing.BI_DepositRollback_PIPS_Report | CROSS APPLY | Calls | PIPS deposit rollback report uses this function |
| Billing.BI_Withdraw_PIPS_Report | CROSS APPLY | Calls | PIPS withdrawal report uses this function |
| Billing.BI_WithdrawRollback_PIPS_Report | CROSS APPLY | Calls | PIPS withdrawal rollback report uses this function |
| Billing.GetMIDDescriptionV2 | Related | Reference | V2 variant of this function (documented separately); references similar logic but is a distinct implementation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMIDDescription (function)
|- Billing.Deposit (table) [deposit path - leaf]
|- Billing.Funding (table) [deposit and cashout paths - leaf]
|- Billing.Depot (table) [depot name fallback - leaf]
|- Dictionary.Regulation (table) [regulation name resolution - leaf]
|- Billing.WithdrawToFunding (table) [cashout path - leaf]
|- Billing.Withdraw (table) [cashout path - leaf]
|- BackOffice.Customer (table) [cashout path regulation source - leaf]
|- Billing.ProtocolMIDSettings (table) [MID source - leaf]
|- Billing.MapMerchantCodeToMid (table) [MID code mapping - leaf]
|- Dictionary.MerchantAccount (table) [Giropay and MerchantAccountID lookup - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM/JOIN in deposit path: resolves CID, ProtocolMIDSettingsID, MerchantAccountID, DepotID, CurrencyID, ProcessRegulationID; also secondary query for Skrill cashout fallback |
| Billing.Funding | Table | JOINed to Billing.Deposit and Billing.WithdrawToFunding to resolve FundingTypeID |
| Billing.Depot | Table | JOINed to resolve depot name (used as ultimate fallback for MID and Description) |
| Dictionary.Regulation | Table | LEFT JOINed to resolve regulation name from RegulationID |
| Billing.WithdrawToFunding | Table | FROM/JOIN in cashout path: resolves ProtocolMIDSettingsID, MerchantAccountID, DepotID, ProcessCurrencyID |
| Billing.Withdraw | Table | JOINed to Billing.WithdrawToFunding to get CID in cashout path |
| BackOffice.Customer | Table | JOINed in cashout path to get RegulationID (stored on customer record, not on transaction) |
| Billing.ProtocolMIDSettings | Table | Queried for MID Value and Description in WireTransfer and fallback branches |
| Billing.MapMerchantCodeToMid | Table | LEFT JOINed to ProtocolMIDSettings to resolve BMMC.MID from merchant code |
| Dictionary.MerchantAccount | Table | Queried for Name and BODescription for Giropay (MerchantID=10) and direct MerchantAccountID paths |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_State_Report | Stored Procedure | Calls via CROSS APPLY to resolve MID/description for each deposit |
| Billing.BI_Cashout_State_Report | Stored Procedure | Calls via CROSS APPLY to resolve MID/description for each cashout |
| Billing.BI_Deposit_PIPS_Report | Stored Procedure | Calls via CROSS APPLY for PIPS deposit reporting |
| Billing.BI_DepositRollback_PIPS_Report | Stored Procedure | Calls via CROSS APPLY for PIPS deposit rollback reporting |
| Billing.BI_Withdraw_PIPS_Report | Stored Procedure | Calls via CROSS APPLY for PIPS withdrawal reporting |
| Billing.BI_WithdrawRollback_PIPS_Report | Stored Procedure | Calls via CROSS APPLY for PIPS withdrawal rollback reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Multi-Statement Table-Valued Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MID NOT NULL | Return column | MID is declared NOT NULL in the return table definition; the COALESCE chain ensures a value is always present |
| Description NOT NULL | Return column | Description is declared NOT NULL; fallback chain guarantees a value via DepotName |

**Known data quality note**: The Giropay branch (FundingTypeID=11) uses a hardcoded `MerchantID=10` lookup because MerchantAccountID is not available on the transaction. The code comment explicitly flags: "Missing Data [MerchantAccountID]".

---

## 8. Sample Queries

### 8.1 Resolve MID for a specific deposit

```sql
SELECT m.MID, m.Description
FROM Billing.Deposit WITH (NOLOCK) AS d
CROSS APPLY Billing.GetMIDDescription(d.DepositID, 1) AS m
WHERE d.DepositID = 123456
```

### 8.2 Get MID for all deposits in a date range (BI pattern)

```sql
SELECT
    d.DepositID,
    d.CID,
    d.DepositDate,
    m.MID,
    m.Description
FROM Billing.Deposit WITH (NOLOCK) AS d
CROSS APPLY Billing.GetMIDDescription(d.DepositID, 1) AS m
WHERE d.DepositDate >= '2026-01-01'
  AND d.DepositDate < '2026-02-01'
```

### 8.3 Get MID for a cashout transaction

```sql
SELECT
    wtf.ID AS WithdrawToFundingID,
    w.WithdrawID,
    m.MID,
    m.Description
FROM Billing.WithdrawToFunding WITH (NOLOCK) AS wtf
INNER JOIN Billing.Withdraw WITH (NOLOCK) AS w ON w.WithdrawID = wtf.WithdrawID
CROSS APPLY Billing.GetMIDDescription(wtf.ID, 2) AS m
WHERE wtf.ID = 789012
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMIDDescription | Type: Multi-Statement Table-Valued Function | Source: etoro/etoro/Billing/Functions/Billing.GetMIDDescription.sql*
