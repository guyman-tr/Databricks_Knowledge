# apex.EXT871_PositionActivity

> Daily position snapshot from Apex Clearing EXT871 extract: holdings per account with quantities, prices, and settlement status. **TRIGGERS RECONCILIATION** against eToro positions (Flow 2).

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 (1 PK + 3 NC) |

---

## 1. Business Meaning

This table stores the daily position snapshot from Apex Clearing's EXT871 extract. Each row represents a single security holding in a customer account, including the trade-date and settle-date quantities, closing price, and security descriptors. This is one of the two most critical extracts in the SOD pipeline because it **triggers the position reconciliation flow** (Flow 2).

**RECONCILIATION TRIGGER**: After a successful EXT871 import, the system automatically initiates the reconciliation process that compares every Apex position against eToro's internal position records. Discrepancies (mismatched quantities, missing positions, extra positions) are flagged for investigation. This is the primary mechanism for ensuring eToro's book of record matches the clearing firm's authoritative position data.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT871 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table. After successful import, a message is sent to Service Bus triggering the reconciliation flow. The table has a covering index optimized for reconciliation queries.

---

## 2. Business Logic

### 2.1 Trade vs. Settle Quantity

**What**: Each position has both trade-date and settle-date quantities.

**Columns Involved**: `TradeQuantity`, `SettleQuantity`

**Rules**:
- TradeQuantity reflects the position as of trade date (includes unsettled trades)
- SettleQuantity reflects the position as of settlement date (only settled shares)
- The difference between these indicates pending settlement activity
- Reconciliation primarily compares TradeQuantity against eToro's positions

### 2.2 Options Position Identification

**What**: Options positions include additional identifying fields beyond the CUSIP.

**Columns Involved**: `OptionSymbolRoot`, `OptionContractDate`, `StrikePrice`, `CallPut`, `ExpirationDeliveryDate`, `UnderlyingCusip`

**Rules**:
- These fields are populated only for options positions (SecurityTypeCode indicates option)
- Together they uniquely describe the option contract
- CallPut distinguishes calls from puts
- StrikePrice and ExpirationDeliveryDate define the contract terms

---

## 3. Data Overview

~82 million rows. Daily position snapshots from Apex for all accounts. This is one of the two tables that triggers the reconciliation flow (Flow 2) against eToro's internal position data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT871 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | ProcessDate | datetime2(7) | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 5 | Firm | nchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 6 | CorrespondentID | int | YES | - | CODE-BACKED | Correspondent firm identifier. |
| 7 | CorrespondentOfficeID | int | YES | - | CODE-BACKED | Correspondent firm office identifier. |
| 8 | OfficeCode | nchar(3) | YES | - | CODE-BACKED | Apex office/branch code associated with the account. |
| 9 | RegisteredRepCode | nvarchar(3) | YES | - | CODE-BACKED | Registered representative code assigned to the account. |
| 10 | AccountType | nvarchar(1) | YES | - | CODE-BACKED | Account type code (cash, margin, short). |
| 11 | Symbol | varchar(35) | YES | - | CODE-BACKED | Trading symbol of the security. |
| 12 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security. |
| 13 | TradeQuantity | decimal(28,10) | YES | - | CODE-BACKED | Position quantity as of trade date (includes unsettled trades). Used in reconciliation. |
| 14 | SettleQuantity | decimal(28,10) | YES | - | CODE-BACKED | Position quantity as of settlement date (settled shares only). |
| 15 | CurrencyCode | nvarchar(3) | YES | - | CODE-BACKED | ISO currency code for the position valuation. |
| 16 | SecurityTypeCode | nvarchar(1) | YES | - | CODE-BACKED | Security type classification code (equity, bond, option, etc.). |
| 17 | Description | nvarchar(40) | YES | - | CODE-BACKED | Security description text. |
| 18 | MarginEligibleCode | nvarchar(1) | YES | - | NAME-INFERRED | Code indicating if the security is eligible for margin. |
| 19 | ClosingPrice | decimal(28,10) | YES | - | CODE-BACKED | Closing/market price of the security. Used for position valuation and reconciliation. |
| 20 | LastActivityDate | nvarchar(10) | YES | - | NAME-INFERRED | Date of the last activity on this position (stored as string). |
| 21 | LocLocation | nvarchar(1) | YES | - | NAME-INFERRED | Location code indicating where the shares are held (street name, transfer agent, etc.). |
| 22 | LocMemo | nvarchar(1) | YES | - | NAME-INFERRED | Location memo indicator. |
| 23 | OptionAmount | decimal(18,2) | YES | - | NAME-INFERRED | Option contract notional amount or premium. |
| 24 | ConversionFactor | decimal(18,2) | YES | - | NAME-INFERRED | Conversion factor for convertible securities or options. |
| 25 | UnderlyingCusip | nvarchar(12) | YES | - | CODE-BACKED | CUSIP of the underlying security for options/derivatives. |
| 26 | OptionSymbolRoot | varchar(18) | YES | - | CODE-BACKED | Root symbol for option contracts. |
| 27 | OptionContractDate | datetime2(7) | YES | - | CODE-BACKED | Option contract origination date. |
| 28 | StrikePrice | decimal(18,2) | YES | - | CODE-BACKED | Strike price for option contracts. |
| 29 | CallPut | varchar(9) | YES | - | CODE-BACKED | Call or Put indicator for option contracts. |
| 30 | ExpirationDeliveryDate | datetime2(7) | YES | - | CODE-BACKED | Expiration or delivery date for options/futures contracts. |
| 31 | InsertDate | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the row was inserted into this table. Used for tracking import timing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SOD Reconciliation Flow (Flow 2) | SodFileId | Application logic | Position reconciliation is triggered after successful EXT871 import. Compares Apex positions against eToro positions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT871_PositionActivity (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SOD Reconciliation Flow (Flow 2) | Application | Triggered after successful import; compares Apex positions vs eToro positions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT871_PositionActivity | CLUSTERED PK | Id | - | - | Active |
| CIInsertDate | NC | InsertDate | - | - | Active |
| IX_EXT871_PositionActivity_SodFileId | NC | SodFileId | - | - | Active |
| IX_EXT871_PositionActivity_SodFileId_CoveringIndexNew | NC (Covering) | SodFileId | AccountNumber, Symbol, Cusip, TradeQuantity, ClosingPrice, RegisteredRepCode | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT871_PositionActivity | PRIMARY KEY | Unique Id per row |
| FK_EXT871_PositionActivity_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |
| DF_InsertDate | DEFAULT | getutcdate() for InsertDate |

---

## 8. Sample Queries

### 8.1 Get all positions from the latest import

```sql
SELECT AccountNumber, Symbol, Cusip, TradeQuantity, SettleQuantity, ClosingPrice, SecurityTypeCode
FROM apex.EXT871_PositionActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 871 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber, Symbol;
```

### 8.2 Find positions with trade/settle quantity mismatch

```sql
SELECT AccountNumber, Symbol, Cusip, TradeQuantity, SettleQuantity,
       (TradeQuantity - SettleQuantity) AS UnsettledQuantity, ProcessDate
FROM apex.EXT871_PositionActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 871 AND Status = 2 ORDER BY ProcessDate DESC)
  AND TradeQuantity <> SettleQuantity
ORDER BY ABS(TradeQuantity - SettleQuantity) DESC;
```

### 8.3 Summarize option positions by call/put

```sql
SELECT CallPut, COUNT(*) AS PositionCount, SUM(TradeQuantity) AS TotalQuantity
FROM apex.EXT871_PositionActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 871 AND Status = 2 ORDER BY ProcessDate DESC)
  AND CallPut IS NOT NULL
GROUP BY CallPut;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture. EXT871 import triggers position reconciliation flow (Flow 2) comparing Apex vs eToro positions. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 9 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT871_PositionActivity | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT871_PositionActivity.sql*
