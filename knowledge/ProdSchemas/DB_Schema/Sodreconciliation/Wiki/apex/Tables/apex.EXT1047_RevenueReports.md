# apex.EXT1047_RevenueReports

> Revenue/PFOF reports from Apex Clearing EXT1047 extract: order routing venue, execution rates, and customer payment for order flow.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily revenue report data from Apex Clearing's EXT1047 extract. Each row represents a trade-level revenue record showing order routing details -- which venue executed the order, the execution rate, and any payment for order flow (PFOF) or rebate amounts. PFOF is a practice where broker-dealers receive compensation from market makers for directing order flow to their venues.

The EXT1047 data is important for SEC Rule 606 compliance (order routing disclosure), revenue tracking, and best execution analysis. It enables eToro to verify PFOF payments received from Apex, analyze execution quality by venue, and generate required quarterly order routing disclosures.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1047 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Order Routing and Revenue

**What**: Each trade is associated with a routing venue and execution economics.

**Columns Involved**: `GatewayRouteRequested`, `Venue`, `ExecutionRate`, `CustomerPFOFPayback`, `Side`

**Rules**:
- GatewayRouteRequested is the routing instruction
- Venue identifies the market center that executed the order
- ExecutionRate is the rate at which the order was executed
- CustomerPFOFPayback is the PFOF or rebate amount paid for the order
- Side indicates buy or sell direction

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1047 file import. CASCADE DELETE. |
| 3 | BillingPeriod | nvarchar(max) | YES | - | CODE-BACKED | Billing period for the revenue record. |
| 4 | TradeMonth | nvarchar(max) | YES | - | CODE-BACKED | Month in which the trade occurred. |
| 5 | TradeDate | smalldatetime | YES | - | CODE-BACKED | Date the trade was executed. |
| 6 | GatewayRouteRequested | nvarchar(max) | YES | - | CODE-BACKED | Routing instruction or gateway requested for the order. |
| 7 | InstrumentType | nvarchar(max) | YES | - | CODE-BACKED | Type of instrument traded (equity, option, etc.). |
| 8 | Side | varchar(1) | YES | - | CODE-BACKED | Trade side indicator (B=Buy, S=Sell). |
| 9 | ExecutionRate | decimal(19,10) | YES | - | CODE-BACKED | Execution rate or price for the trade. |
| 10 | TerminalID | nvarchar(max) | YES | - | CODE-BACKED | Terminal or workstation identifier. |
| 11 | Client | nvarchar(max) | YES | - | CODE-BACKED | Client identifier or name. |
| 12 | Venue | nvarchar(max) | YES | - | CODE-BACKED | Market center/venue that executed the order. |
| 13 | BillingKey | nvarchar(max) | YES | - | NAME-INFERRED | Billing key for revenue allocation. |
| 14 | Symbol | nvarchar(max) | YES | - | CODE-BACKED | Trading symbol of the security. |
| 15 | Description | nvarchar(max) | YES | - | CODE-BACKED | Description of the trade or security. |
| 16 | OrderID | nvarchar(max) | YES | - | CODE-BACKED | Order identifier. |
| 17 | ClearingAccount | varchar(12) | YES | - | CODE-BACKED | Clearing account number. MASKED (PII). |
| 18 | PriceFiller | decimal(19,10) | YES | - | NAME-INFERRED | Price or filler field (may be execution price or placeholder). |
| 19 | OrderID2 | nvarchar(max) | YES | - | NAME-INFERRED | Secondary order identifier. |
| 20 | TotalQuantity | decimal(19,10) | YES | - | CODE-BACKED | Total quantity of shares traded. |
| 21 | CustomerPFOFPayback | decimal(19,10) | YES | - | CODE-BACKED | Payment for order flow or rebate amount for the trade. |

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
apex.EXT1047_RevenueReports (table)
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
| PK_EXT1047_RevenueReports | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1047_RevenueReports_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1047_RevenueReports | PRIMARY KEY | Unique Id per row |
| FK_EXT1047_RevenueReports_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get revenue data from the latest import

```sql
SELECT TradeDate, Symbol, Side, TotalQuantity, ExecutionRate, Venue,
       CustomerPFOFPayback, ClearingAccount
FROM apex.EXT1047_RevenueReports WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1047 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY TradeDate, Symbol;
```

### 8.2 Summarize PFOF by venue

```sql
SELECT Venue, COUNT(*) AS TradeCount, SUM(TotalQuantity) AS TotalShares,
       SUM(CustomerPFOFPayback) AS TotalPFOF
FROM apex.EXT1047_RevenueReports WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1047 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY Venue
ORDER BY TotalPFOF DESC;
```

### 8.3 Analyze order routing by instrument type

```sql
SELECT InstrumentType, Side, Venue, COUNT(*) AS OrderCount,
       SUM(TotalQuantity) AS TotalShares
FROM apex.EXT1047_RevenueReports WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1047 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY InstrumentType, Side, Venue
ORDER BY InstrumentType, OrderCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1047_RevenueReports | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1047_RevenueReports.sql*
