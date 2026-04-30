# apex.EXT872_TradeActivity

> Trade execution details from Apex Clearing EXT872 extract: buys, sells, quantities, prices, commissions, and fees. **TRIGGERS RECONCILIATION** against eToro trades (Flow 2).

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 PK + 2 NC) |

---

## 1. Business Meaning

This table stores daily trade execution data from Apex Clearing's EXT872 extract. Each row represents a single trade execution -- buy or sell -- with full details including quantity, price, commissions, fees, settlement date, and market routing information. This is one of the two most critical extracts in the SOD pipeline because it **triggers the trade reconciliation flow** (Flow 2).

**RECONCILIATION TRIGGER**: After a successful EXT872 import, the system automatically initiates the reconciliation process that compares every Apex trade against eToro's internal trade records. Discrepancies (missing trades, price mismatches, quantity differences) are flagged for investigation. This is the primary mechanism for ensuring trade-level agreement between eToro and its clearing firm.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT872 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table. After successful import, a message is sent to Service Bus triggering the reconciliation flow. The table has a covering index optimized for reconciliation queries including AccountNumber, BuySellCode, TradeDate, TradeNumber, Cusip, Symbol, Quantity, Price, and OrderId.

---

## 2. Business Logic

### 2.1 Trade Economics

**What**: Multiple fields combine to define the full economics of a trade.

**Columns Involved**: `Quantity`, `Price`, `PrincipalAmount`, `NetAmount`, `CommissionGrossCalculated`, `CommissionGrossEntered`, `CommissionEntered`, `FeeSec`, `FeeMisc`, `Fee1`-`Fee5`

**Rules**:
- PrincipalAmount = Quantity * Price (gross trade value)
- NetAmount = PrincipalAmount +/- commissions and fees (what the customer actually pays/receives)
- Multiple fee fields (FeeSec, FeeMisc, Fee1-Fee5) capture SEC fees, miscellaneous fees, and other regulatory/exchange fees
- Commission fields track both calculated and entered commission amounts

### 2.2 Trade Identification for Reconciliation

**What**: Trades are matched between Apex and eToro using a composite key.

**Columns Involved**: `AccountNumber`, `BuySellCode`, `TradeDate`, `TradeNumber`, `Cusip`, `Symbol`, `Quantity`, `Price`, `OrderId`

**Rules**:
- The covering index includes all fields needed for reconciliation matching
- OrderId links back to the original order in eToro's system
- TradeNumber is Apex's unique trade identifier
- BuySellCode indicates the direction (buy vs sell)

---

## 3. Data Overview

~12.8 million rows. Daily trade executions from Apex. This is one of the two tables that triggers the reconciliation flow (Flow 2) against eToro's internal trade data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT872 file import. CASCADE DELETE. |
| 3 | AccountNumber | nvarchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | ProcessDate | datetime2(7) | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 5 | Firm | nvarchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 6 | CorrespondentID | int | YES | - | CODE-BACKED | Correspondent firm identifier. |
| 7 | CorrespondentOfficeID | int | YES | - | CODE-BACKED | Correspondent firm office identifier. |
| 8 | CorrespondentCode | nvarchar(23) | YES | - | CODE-BACKED | Correspondent firm code. |
| 9 | OfficeCode | nvarchar(11) | YES | - | CODE-BACKED | Apex office/branch code. |
| 10 | RegisteredRepCode | nvarchar(19) | YES | - | CODE-BACKED | Registered representative code assigned to the account. |
| 11 | AccountType | nvarchar(13) | YES | - | CODE-BACKED | Account type code. MASKED (PII). |
| 12 | BuySellCode | nvarchar(13) | YES | - | CODE-BACKED | Buy/sell direction indicator for the trade. |
| 13 | TradeDate | datetime2(7) | YES | - | CODE-BACKED | Date the trade was executed. |
| 14 | TradeNumber | nvarchar(15) | YES | - | CODE-BACKED | Apex's unique trade number identifier. |
| 15 | ExecutionTime | nvarchar(15) | YES | - | CODE-BACKED | Time the trade was executed. |
| 16 | Cusip | nvarchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the traded security. |
| 17 | Symbol | nvarchar(35) | YES | - | CODE-BACKED | Trading symbol of the security. |
| 18 | Quantity | decimal(28,10) | YES | - | CODE-BACKED | Number of shares/units traded. |
| 19 | Price | decimal(28,10) | YES | - | CODE-BACKED | Execution price per share/unit. |
| 20 | MarketCode | nvarchar(12) | YES | - | CODE-BACKED | Market/exchange code where the trade was executed. |
| 21 | CapacityCode | nvarchar(14) | YES | - | NAME-INFERRED | Trade capacity code (principal, agency, riskless principal). |
| 22 | CommissionGrossCalculated | decimal(18,2) | YES | - | CODE-BACKED | Commission amount calculated by the system. |
| 23 | CommissionGrossEntered | decimal(18,2) | YES | - | CODE-BACKED | Commission amount entered manually or by the order entry system. |
| 24 | SettlementDate | datetime2(7) | YES | - | CODE-BACKED | Settlement date for the trade (T+1 for equities). |
| 25 | CurrencyCode | nvarchar(14) | YES | - | CODE-BACKED | ISO currency code for the trade. |
| 26 | PrincipalAmount | decimal(28,10) | YES | - | CODE-BACKED | Gross trade value (Quantity * Price). |
| 27 | NetAmount | decimal(18,2) | YES | - | CODE-BACKED | Net settlement amount after commissions and fees. |
| 28 | FeeSec | decimal(18,2) | YES | - | CODE-BACKED | SEC transaction fee (Section 31 fee). |
| 29 | FeeMisc | decimal(18,2) | YES | - | CODE-BACKED | Miscellaneous fee amount. |
| 30 | Fee1 | decimal(18,2) | YES | - | CODE-BACKED | Additional fee amount (exchange, regulatory, etc.). |
| 31 | Fee2 | decimal(18,2) | YES | - | CODE-BACKED | Additional fee amount. |
| 32 | Fee3 | decimal(18,2) | YES | - | CODE-BACKED | Additional fee amount. |
| 33 | Fee4 | decimal(18,2) | YES | - | CODE-BACKED | Additional fee amount. |
| 34 | Fee5 | decimal(18,2) | YES | - | CODE-BACKED | Additional fee amount. |
| 35 | EntryDate | datetime2(7) | YES | - | CODE-BACKED | Date the trade was entered into Apex's system. |
| 36 | ShortDescription | nvarchar(18) | YES | - | CODE-BACKED | Short description of the traded security. |
| 37 | TrailerCode | nvarchar(13) | YES | - | NAME-INFERRED | Trailer code providing additional trade classification. |
| 38 | TradeIntrest | nvarchar(20) | YES | - | NAME-INFERRED | Accrued interest amount for bond trades. Note: column name has typo ("Intrest"). |
| 39 | ExecutingBrokerBack | nvarchar(21) | YES | - | NAME-INFERRED | Back-office executing broker identifier. |
| 40 | SecurityTypeCode | nvarchar(18) | YES | - | CODE-BACKED | Security type classification code. |
| 41 | CommissionRRCategory | nvarchar(22) | YES | - | NAME-INFERRED | Commission category for registered representative payout calculation. |
| 42 | Reallowance | nvarchar(20) | YES | - | NAME-INFERRED | Reallowance amount (portion of underwriting concession). |
| 43 | CommissionEntered | decimal(18,2) | YES | - | CODE-BACKED | Commission amount as entered. |
| 44 | ShortName | nvarchar(11) | YES | - | CODE-BACKED | Short name of the account holder. |
| 45 | Factor | decimal(18,2) | YES | - | NAME-INFERRED | Factor for bond or MBS trades (face value multiplier). |
| 46 | CommissionNet | nvarchar(20) | YES | - | NAME-INFERRED | Net commission after any splits or concessions. |
| 47 | Trailer | nvarchar(35) | YES | - | NAME-INFERRED | Trailer text providing additional trade details. |
| 48 | ExecutingBrokerFront | nvarchar(22) | YES | - | NAME-INFERRED | Front-office executing broker identifier. |
| 49 | FeeMF | nvarchar(20) | YES | - | NAME-INFERRED | Mutual fund fee amount. |
| 50 | ClearingSymbol | nvarchar(35) | YES | - | CODE-BACKED | Clearing-level symbol (may differ from trading symbol). |
| 51 | Repo | nvarchar(20) | YES | - | NAME-INFERRED | Repo (repurchase agreement) related information. |
| 52 | Description1 | nvarchar(30) | YES | - | CODE-BACKED | Primary security description. |
| 53 | SecuritySubType | nvarchar(17) | YES | - | CODE-BACKED | Security sub-type classification. |
| 54 | InstructionsTradeLegendCode | nvarchar(29) | YES | - | NAME-INFERRED | Trade legend code for special instructions on confirmations. |
| 55 | Country | nvarchar(70) | YES | - | CODE-BACKED | Country associated with the security or trade. |
| 56 | ISIN | nvarchar(35) | YES | - | CODE-BACKED | International Securities Identification Number. |
| 57 | LanguageID | nvarchar(12) | YES | - | NAME-INFERRED | Language identifier for trade confirmation generation. |
| 58 | InstructionsSpecial1 | nvarchar(22) | YES | - | NAME-INFERRED | Special instruction line 1 for the trade. |
| 59 | InstructionsSpecial2 | nvarchar(22) | YES | - | NAME-INFERRED | Special instruction line 2 for the trade. |
| 60 | OriginalTradeNumber | nvarchar(21) | YES | - | CODE-BACKED | Original trade number for corrections or amendments. |
| 61 | TradeLegendCode | nvarchar(29) | YES | - | NAME-INFERRED | Trade legend code for confirmation printing. |
| 62 | OptionSymbolRoot | nvarchar(18) | YES | - | CODE-BACKED | Root symbol for option trades. |
| 63 | DisplaySymbol | nvarchar(50) | YES | - | CODE-BACKED | Display symbol for the security (human-readable format). |
| 64 | StrikePrice | decimal(18,2) | YES | - | CODE-BACKED | Strike price for option trades. |
| 65 | CallPut | nvarchar(9) | YES | - | CODE-BACKED | Call or Put indicator for option trades. |
| 66 | ExpirationDeliveryDate | datetime2(7) | YES | - | CODE-BACKED | Expiration or delivery date for option/futures trades. |
| 67 | OptionContractDate | datetime2(7) | YES | - | CODE-BACKED | Option contract origination date. |
| 68 | OrderId | nvarchar(35) | YES | - | CODE-BACKED | Order ID linking back to the originating order in eToro's system. Key field for reconciliation matching. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SOD Reconciliation Flow (Flow 2) | SodFileId | Application logic | Trade reconciliation is triggered after successful EXT872 import. Compares Apex trades against eToro trades. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT872_TradeActivity (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SOD Reconciliation Flow (Flow 2) | Application | Triggered after successful import; compares Apex trades vs eToro trades |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT872_TradeActivity | CLUSTERED PK | Id | - | - | Active |
| IX_EXT872_TradeActivity_SodFileId | NC | SodFileId | - | - | Active |
| IX_EXT872_TradeActivity_SodFileId_CoveringIndex | NC (Covering) | SodFileId | AccountNumber, BuySellCode, TradeDate, TradeNumber, Cusip, Symbol, Quantity, Price, OrderId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT872_TradeActivity | PRIMARY KEY | Unique Id per row |
| FK_EXT872_TradeActivity_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get all trades from the latest import

```sql
SELECT AccountNumber, BuySellCode, Symbol, Cusip, Quantity, Price, NetAmount, TradeDate, SettlementDate, OrderId
FROM apex.EXT872_TradeActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 872 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber, TradeDate, TradeNumber;
```

### 8.2 Summarize daily trade volume and value

```sql
SELECT BuySellCode, COUNT(*) AS TradeCount, SUM(Quantity) AS TotalShares, SUM(PrincipalAmount) AS TotalValue
FROM apex.EXT872_TradeActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 872 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY BuySellCode;
```

### 8.3 Find trades with high commission or fee amounts

```sql
SELECT AccountNumber, Symbol, Quantity, Price, PrincipalAmount, NetAmount,
       CommissionGrossCalculated, FeeSec, FeeMisc, Fee1, OrderId
FROM apex.EXT872_TradeActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 872 AND Status = 2 ORDER BY ProcessDate DESC)
  AND (CommissionGrossCalculated > 50 OR FeeSec > 10)
ORDER BY CommissionGrossCalculated DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture. EXT872 import triggers trade reconciliation flow (Flow 2) comparing Apex vs eToro trades. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 50 CODE-BACKED, 0 ATLASSIAN-ONLY, 18 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT872_TradeActivity | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT872_TradeActivity.sql*
