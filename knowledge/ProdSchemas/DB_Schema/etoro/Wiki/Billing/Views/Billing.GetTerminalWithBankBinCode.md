# Billing.GetTerminalWithBankBinCode

> Extended variant of GetDefaultTerminalForBank that adds BIN code lookup (Dictionary.BankBin) to the payment routing result, but applies only a single active-state filter (bank IsActive=1) rather than the four-layer filter of its counterpart. BinCode is NULL for all 272 rows in practice.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | (BankID, CardTypeID, CurrencyID, DepotID) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.GetTerminalWithBankBinCode` is an extended payment routing view that follows the same multi-hop join pattern as `Billing.GetDefaultTerminalForBank` (Bank -> CardTypeToBank -> BankToDepot -> Depot -> DepotToCurrency -> Protocol), but adds a LEFT JOIN to `Dictionary.BankBin` to expose the card BIN code associated with each bank.

The intended use case was BIN-level payment routing: given a customer's card BIN code, identify which payment depot should process the transaction. The `BinCode` column (a 6-digit card prefix) would allow routing decisions to be made at the card-issuer level rather than just at the bank level.

However, in practice, `Dictionary.BankBin` contains only 1 record (BankID=10, BinCode=462252), and BankID=10 is not present in the current bank-to-depot routing table. As a result, `BinCode` is NULL for all 272 rows returned by this view.

Additionally, compared to `Billing.GetDefaultTerminalForBank`, this view applies **only one** active-state filter (DBNK.IsActive=1) rather than four. It returns inactive depot-currency pairs and inactive card-type-to-bank mappings, making it less strict for routing decisions.

**No stored procedures** in the codebase reference this view - it appears to be an unused draft or legacy artifact.

---

## 2. Business Logic

### 2.1 Single Active-State Filter (vs Four in GetDefaultTerminalForBank)

**What**: Only the bank's IsActive status is checked; depot, currency, and card-type-to-bank active states are not filtered.

**Columns/Parameters Involved**: `DBNK.IsActive`, `DPTC.IsActive`, `IsActive` (output)

**Rules**:
- WHERE DBNK.IsActive = 1: Bank must be active (only filter applied)
- `DPTC.IsActive` is included in SELECT but NOT used in WHERE - inactive depot-currency pairs appear
- `CTBK.IsActive` is not filtered - inactive card-type-to-bank mappings appear
- `BDPT.IsActive` is not filtered - inactive/retired depots appear
- This produces 272 rows vs `GetDefaultTerminalForBank`'s more conservative result set
- Callers needing only fully-active routing paths should use `GetDefaultTerminalForBank` instead

### 2.2 BIN Code Extension via LEFT JOIN

**What**: Adds the card BIN code (6-digit card number prefix) for each bank via a LEFT JOIN to Dictionary.BankBin.

**Columns/Parameters Involved**: `BinCode`, `BankID`

**Rules**:
- LEFT JOIN Dictionary.BankBin BC2B ON BC2B.BankID = CTBK.BankID
- NULL for all rows where the bank has no BIN code entry in Dictionary.BankBin
- Currently NULL for 100% of rows (272/272) - Dictionary.BankBin has only 1 record for BankID=10, which is not in the current routing table
- BinCode = 462252 is the only value that could theoretically appear but does not in practice
- This feature appears to have been designed but never fully populated

### 2.3 Multi-Hop Routing Path (Same as GetDefaultTerminalForBank)

**What**: The routing traversal is identical to GetDefaultTerminalForBank: Bank -> CardTypeToBank -> BankToDepot -> Depot -> DepotToCurrency -> Protocol.

**Columns/Parameters Involved**: `BankID`, `CardTypeID`, `DepotID`, `ProtocolID`, `CurrencyID`, `Priority`

**Rules**:
- Step 1: Dictionary.Bank (DBNK) -> BankID (anchors the query, IsActive=1 filter)
- Step 2: Dictionary.CardTypeToBank (CTBK) -> links BankID to CardTypeID
- Step 3: Billing.BankToDepot (BKTD) -> maps BankID to DepotID with Priority
- Step 4: Billing.Depot (BDPT) -> gateway config (FundingTypeID, ProtocolID)
- Step 5: Billing.DepotToCurrency (DPTC) -> currencies supported by the depot
- Step 6: Dictionary.Protocol (DPRT) -> ClassKey for handler instantiation
- Step 7: Dictionary.BankBin (BC2B) -> LEFT JOIN BIN code per bank (currently all NULL)

---

## 3. Data Overview

| FundingTypeID | DepotID | Name | ProtocolID | CurrencyID | IsActive | Priority | BankID | CardTypeID | BinCode | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 18 | WireCard | 18 | 1 (USD) | true | 100 | 2 | 1 (Visa) | NULL | BankID=2, Visa -> WireCard depot for USD. Active. BIN not populated. |
| 1 | 18 | WireCard | 18 | 2 (EUR) | true | 100 | 2 | 1 (Visa) | NULL | Same bank+card -> WireCard EUR |
| 1 | 34 | Barclay SmartPay | 22 | 4 | false | 50 | 2 | 1 (Visa) | NULL | Inactive Barclays depot included (no IsActive filter on depot) |

**Row count**: 272 (all bank-card-depot-currency combinations where bank IsActive=1)

**BinCode**: NULL for all 272 rows - Dictionary.BankBin has only 1 record (BankID=10, BinCode=462252) which is not present in the current routing table.

**IsActive** (DPTC.IsActive): both true and false values appear (unlike GetDefaultTerminalForBank which only returns active=1).

**No stored procedure references** found in codebase.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type for this depot. From Billing.Depot. 1=CreditCard for all routing paths in this view. |
| 2 | ProtocolID | int | NO | - | CODE-BACKED | Payment protocol ID. From Billing.Depot. References Dictionary.Protocol. Identifies the payment gateway handler. |
| 3 | DepotID | int | NO | - | CODE-BACKED | Payment depot identifier. From Billing.Depot and Billing.BankToDepot. The routing target for this bank+card+currency combination. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Supported deposit currency. From Billing.DepotToCurrency. One row per (bank, card, depot, currency) combination. |
| 5 | IsActive | bit | NO | - | CODE-BACKED | Active status of the depot-currency pairing (DPTC.IsActive). From Billing.DepotToCurrency. NOTE: NOT filtered to 1 - both active and inactive depot-currency pairs are returned. Callers must filter if only active paths are needed. |
| 6 | Priority | int | NO | - | CODE-BACKED | Routing priority from Billing.BankToDepot. Higher value = preferred depot when multiple options exist. Values observed: 50, 100. |
| 7 | BankID | int | NO | - | CODE-BACKED | Issuing bank identifier. From Dictionary.Bank (anchor). The bank that issued the customer's card, identified via BIN lookup. View is anchored on active banks (IsActive=1). |
| 8 | ClassKey | nvarchar | YES | - | CODE-BACKED | Protocol class name from Dictionary.Protocol. String used to instantiate the correct payment handler DLL (e.g., "WireCardPaymentDll", "BarclayCardPaymentDll"). |
| 9 | Name | nvarchar | NO | - | CODE-BACKED | Protocol name from Dictionary.Protocol. Human-readable gateway identifier (e.g., "WireCard", "Barclay SmartPay"). Note: this is the Protocol Name, not the Depot Name (unlike GetDefaultTerminalForBank which exposes Depot Name). |
| 10 | CardTypeID | int | NO | - | CODE-BACKED | Card network type. From Dictionary.CardTypeToBank. 1=Visa, 2=Mastercard, etc. |
| 11 | BinCode | int | YES | - | CODE-BACKED | Card BIN code (6-digit card number prefix) from Dictionary.BankBin. LEFT JOIN - NULL for all rows in practice (Dictionary.BankBin has only 1 record, BankID=10, BinCode=462252, which is not in the current routing table). The column was designed to enable BIN-level routing but has never been fully populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID | Dictionary.Bank | Source (FROM anchor, IsActive=1 filter) | Active issuing bank definitions |
| BankID, CardTypeID | Dictionary.CardTypeToBank | Source (INNER JOIN) | Card-type-to-bank mappings (active and inactive) |
| BankID, DepotID, Priority | Billing.BankToDepot | Source (INNER JOIN) | Bank-to-depot routing rules |
| DepotID, FundingTypeID, ProtocolID | Billing.Depot | Source (INNER JOIN) | Depot configuration (active and inactive) |
| DepotID, CurrencyID, IsActive | Billing.DepotToCurrency | Source (INNER JOIN, no active filter) | Depot currency support (active and inactive) |
| ProtocolID, ClassKey, Name | Dictionary.Protocol | Source (INNER JOIN) | Payment protocol handler configuration |
| BankID, BinCode | Dictionary.BankBin | Source (LEFT JOIN) | Card BIN codes per bank - currently all NULL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures reference this view | - | - | Unused/legacy view |
| Billing.GetDefaultTerminalForBank | - | Related | The stricter four-filter routing counterpart |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetTerminalWithBankBinCode (view)
├── Dictionary.Bank (table, cross-schema)
├── Dictionary.CardTypeToBank (table, cross-schema)
├── Billing.BankToDepot (table)
├── Billing.Depot (table)
├── Billing.DepotToCurrency (table)
├── Dictionary.Protocol (table, cross-schema)
└── Dictionary.BankBin (table, cross-schema, LEFT JOIN - all NULL currently)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FROM anchor: BankID, IsActive=1 filter |
| Dictionary.CardTypeToBank | Table | INNER JOIN: BankID -> CardTypeID mapping |
| Billing.BankToDepot | Table | INNER JOIN: BankID -> DepotID with Priority |
| Billing.Depot | Table | INNER JOIN: depot config (FundingTypeID, ProtocolID) |
| Billing.DepotToCurrency | Table | INNER JOIN: depot currency support and IsActive status |
| Dictionary.Protocol | Table | INNER JOIN: ClassKey and Name for protocol handler |
| Dictionary.BankBin | Table | LEFT JOIN: BIN code per bank (all NULL currently) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | View appears unused in stored procedures |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. 272 rows - small result set with negligible performance impact. All joins use PK/FK columns indexed in base tables.

### 7.2 Constraints

N/A for view. Key differences from `Billing.GetDefaultTerminalForBank`:
- Only 1 active-state filter (bank only) vs 4 filters -> may return routing paths through inactive depots
- Protocol.Name exposed (not Depot.Name) -> callers get protocol name not depot name
- LEFT JOIN to Dictionary.BankBin -> BinCode always NULL in practice
- No stored procedure callers -> effectively unused

No SCHEMABINDING (cross-schema). WITH (NOLOCK) applied to all base tables in the view definition.

---

## 8. Sample Queries

### 8.1 Find routing for a bank and card type (all depot states)

```sql
SELECT FundingTypeID, DepotID, Name AS ProtocolName, ProtocolID, CurrencyID, Priority, BinCode
FROM Billing.GetTerminalWithBankBinCode WITH (NOLOCK)
WHERE BankID = @BankID
  AND CardTypeID = @CardTypeID
ORDER BY Priority DESC, CurrencyID
```

### 8.2 Find rows with BIN codes (currently none)

```sql
SELECT BankID, CardTypeID, BinCode, DepotID, Name
FROM Billing.GetTerminalWithBankBinCode WITH (NOLOCK)
WHERE BinCode IS NOT NULL
```

### 8.3 Compare with GetDefaultTerminalForBank (active-only routing)

```sql
-- Use GetDefaultTerminalForBank for production routing (4 active-state filters)
SELECT * FROM Billing.GetDefaultTerminalForBank WITH (NOLOCK) WHERE BankID = @BankID

-- Use GetTerminalWithBankBinCode for full picture including inactive paths
SELECT * FROM Billing.GetTerminalWithBankBinCode WITH (NOLOCK) WHERE BankID = @BankID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetTerminalWithBankBinCode | Type: View | Source: etoro/etoro/Billing/Views/Billing.GetTerminalWithBankBinCode.sql*
