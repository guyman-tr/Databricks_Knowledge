# apex.EXT870_StockActivity

> Stock/security movement activity from Apex Clearing EXT870 extract: transfers, deliveries, and certificate movements per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily stock (security) movement activity from Apex Clearing's EXT870 extract. Each row represents a security-level movement event on a customer account -- share transfers, deliveries, receipts, certificate deposits, and DTC (Depository Trust Company) movements. This is distinct from trade activity (EXT872) as it captures non-trade security movements.

The EXT870 data supports reconciliation by providing visibility into all non-trade share movements that affect position balances. When a position discrepancy is found between Apex and eToro, this data helps identify the root cause -- such as transfers in/out, certificate deposits, or corporate action deliveries.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT870 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 SMA (Special Memorandum Account) Impact

**What**: Stock movements may affect the account's SMA balance.

**Columns Involved**: `SMAChangeAmount`, `SMAChangePrice`

**Rules**:
- SMAChangeAmount records the dollar impact on the SMA from the stock movement
- SMAChangePrice records the price used for SMA calculation
- SMA changes are relevant for Reg T margin compliance

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT870 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | CurrencyCode | varchar(3) | YES | - | CODE-BACKED | ISO currency code for the transaction. |
| 5 | AccountType | varchar(1) | YES | - | CODE-BACKED | Account type code (cash, margin, short). |
| 6 | EntryDate | date | YES | - | CODE-BACKED | Date the stock movement was entered in Apex's system. |
| 7 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security being moved. |
| 8 | SequenceNumber | int | YES | - | CODE-BACKED | Sequence number for ordering movements within a batch. |
| 9 | TradeDate | date | YES | - | CODE-BACKED | Trade date associated with the stock movement. |
| 10 | Tradenumber | varchar(5) | YES | - | CODE-BACKED | Trade number linking the movement to a specific trade. |
| 11 | SettleDate | date | YES | - | CODE-BACKED | Settlement date for the stock movement. |
| 12 | TradeSettleBasis | varchar(1) | YES | - | NAME-INFERRED | Trade settlement basis code (regular way, when-issued, etc.). |
| 13 | Trailer | varchar(25) | YES | - | NAME-INFERRED | Trailer text providing additional movement details. |
| 14 | Quantity | decimal(19,5) | YES | - | CODE-BACKED | Number of shares or units moved. Positive for receipts, negative for deliveries. |
| 15 | SecurityTypeCode | varchar(1) | YES | - | CODE-BACKED | Security type classification code (equity, bond, option, etc.). |
| 16 | EnteredDate | date | YES | - | CODE-BACKED | Date the entry was recorded. |
| 17 | SourceProgram | varchar(6) | YES | - | NAME-INFERRED | Apex source program that generated the movement. |
| 18 | EntryType | varchar(2) | YES | - | NAME-INFERRED | Entry type code classifying the stock movement. |
| 19 | TerminalID | varchar(15) | YES | - | CODE-BACKED | Terminal or workstation identifier where the entry originated. |
| 20 | UserID | varchar(8) | YES | - | CODE-BACKED | User ID of the operator who entered the movement. |
| 21 | IssueDate | datetime2(7) | YES | - | NAME-INFERRED | Issue date of the security or certificate. |
| 22 | CertificateShortDesc | varchar(25) | YES | - | NAME-INFERRED | Short description of the certificate being moved. |
| 23 | SMAChangeAmount | decimal(28,10) | YES | - | NAME-INFERRED | Dollar amount impact on the Special Memorandum Account (SMA). |
| 24 | SMAChangePrice | decimal(18,2) | YES | - | NAME-INFERRED | Price used for SMA change calculation. |
| 25 | ReInvestmentAmount | decimal(19,10) | YES | - | NAME-INFERRED | Reinvestment amount for dividend reinvestment or DRIP movements. |
| 26 | DTCNumberExp | varchar(4) | YES | - | NAME-INFERRED | DTC (Depository Trust Company) number or expiration code. |
| 27 | SequenceCusipNumber | varchar(9) | YES | - | NAME-INFERRED | Sequence CUSIP number for multi-leg movements. |
| 28 | SequenceEntryDate | date | YES | - | NAME-INFERRED | Entry date associated with the sequence CUSIP. |
| 29 | ProcessDate | date | YES | - | CODE-BACKED | Business date of the Apex extract file. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT870_StockActivity (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT870_StockActivity | CLUSTERED PK | Id | - | - | Active |
| IX_EXT870_StockActivity_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT870_StockActivity | PRIMARY KEY | Unique Id per row |
| FK_EXT870_StockActivity_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get stock movements for a specific import

```sql
SELECT AccountNumber, Cusip, Quantity, EntryType, TradeDate, SettleDate, ProcessDate
FROM apex.EXT870_StockActivity WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 870 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber, Cusip;
```

### 8.2 Find large share movements

```sql
SELECT AccountNumber, Cusip, Quantity, EntryType, SMAChangeAmount, TradeDate, ProcessDate
FROM apex.EXT870_StockActivity WITH (NOLOCK)
WHERE ABS(Quantity) > 10000
  AND ProcessDate >= '2026-04-01'
ORDER BY ABS(Quantity) DESC;
```

### 8.3 Summarize movements by entry type

```sql
SELECT EntryType, COUNT(*) AS MovementCount, SUM(Quantity) AS TotalQuantity
FROM apex.EXT870_StockActivity WITH (NOLOCK)
WHERE ProcessDate >= '2026-04-01'
GROUP BY EntryType
ORDER BY MovementCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 17 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT870_StockActivity | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT870_StockActivity.sql*
