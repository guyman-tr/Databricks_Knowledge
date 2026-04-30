# Billing.GetScheduledTaskMonitorProcessingEntities

> Post-deposit scheduler fetch for TaskID=8 (payment monitor alerting): claims pending deposits of a specified FundingTypeID, returns fully-enriched payment context (country, MID, verification level, regulation, payment status, risk status, depot, currency, FTD), marks claimed rows as TaskState=3.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch + @FundingTypeID filter; returns one row per claimed deposit via OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskMonitorProcessingEntities` is the batch-fetch step for the payment monitoring/alerting pipeline (TaskID=8). This scheduler sends deposit events to a payment monitoring system that tracks anomalies, fraud indicators, and KPIs by funding type. Unlike other deposit schedulers that send raw identifiers, this procedure returns fully resolved human-readable context: country name, payment method name, MID value, verification level, regulation, payment status, risk management status, depot name, currency abbreviation, and FTD label.

Two versions exist:
- This procedure: batch scheduler version - claims multiple pending deposits and marks them as in-progress
- `Billing.GetScheduledTaskMonitorProcessingEntitiesById`: point-lookup version - returns data for a specific DepositID without touching ScheduledTaskState

Created 26 Jul 2020 (Shay Oren, PAYUA-665). Updated 23 Aug 2020 (Shay Oren, PAYUA-804) to take RegulationID from `BackOffice.Customer` rather than `Billing.Deposit`.

---

## 2. Business Logic

### 2.1 FundingType-Scoped Batch (Two-Stage)

**What**: The procedure first pre-filters eligible DepositIDs using a CTE, then joins with funding type filter in a second stage.

**Rules**:
- Stage 1 CTE: `SELECT DepositID FROM ScheduledTaskState INNER JOIN Deposit WITH(FORCESEEK) WHERE TaskState=0 AND TaskID=8`
  - `FORCESEEK` hint on Deposit JOIN forces index seek for performance
- Stage 2: JOIN DepositIDList with Funding WHERE `F.FundingTypeID = @FundingTypeID` (default=1, credit card)
  - This allows the scheduler to be called separately per funding type (each call processes one payment method)
- Stage 3: Main SELECT with full enrichment from 9+ tables -> INSERT #PostDepositTask OUTPUT
- Stage 4: `UPDATE ScheduledTaskState SET TaskState=3` from #PostDepositTask

### 2.2 Full Context Enrichment

**What**: Returns human-readable labels for all key deposit dimensions.

**Rules**:
- `Country = Dictionary.Country.Name` via `Customer.CustomerStatic.CountryID`
- `FundingType = Dictionary.FundingType.Name` for the @FundingTypeID parameter value
- `Mid = Billing.ProtocolMIDSettings.Value` via `Billing.Deposit.ProtocolMIDSettingsID`
- `VerificationLevel = Dictionary.VerificationLevel.Name` via `BackOffice.Customer.VerificationLevelID`
- `Regulation = Dictionary.Regulation.Name` via `BackOffice.Customer.RegulationID` (PAYUA-804: moved from Deposit to BackOffice.Customer)
- `PaymentStatus = Dictionary.PaymentStatus.Name` via `Billing.Deposit.PaymentStatusID`
- `RiskManagementStatus = Dictionary.RiskManagementStatus.Name` via `Billing.Deposit.RiskManagementStatusID` (LEFT JOIN - NULL if no risk block)
- `Depot = Billing.Depot.Name` via `Billing.Deposit.DepotID`
- `Currency = Dictionary.Currency.Abbreviation` via `Billing.Deposit.CurrencyID`
- `FTD = IIF(D.IsFTD=1, 'Yes', 'No')` as VARCHAR label

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Maximum batch size. -1 = no limit. Typically loaded from ScheduledTaskConfig.MaxEntitiesToFetch for TaskID=8 (1 - processes one deposit at a time). |
| 2 | @FundingTypeID | INT | YES | 1 | CODE-BACKED | Payment method type to filter on. Default=1 (credit card). Allows the monitor scheduler to run separately per funding type. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | DepositID | INT | NO | - | CODE-BACKED | PK of the claimed deposit. |
| 4 | Country | VARCHAR(100) | YES | - | CODE-BACKED | Customer's country name from `Dictionary.Country` via `Customer.CustomerStatic.CountryID`. |
| 5 | FundingType | VARCHAR(100) | YES | - | CODE-BACKED | Payment method name from `Dictionary.FundingType.Name` for @FundingTypeID. |
| 6 | Mid | VARCHAR(100) | YES | - | CODE-BACKED | Merchant ID value from `Billing.ProtocolMIDSettings.Value` via `Billing.Deposit.ProtocolMIDSettingsID`. NULL if no MID settings. |
| 7 | VerificationLevel | VARCHAR(100) | YES | - | CODE-BACKED | Customer's verification tier from `Dictionary.VerificationLevel.Name` via `BackOffice.Customer.VerificationLevelID`. |
| 8 | Regulation | VARCHAR(100) | YES | - | CODE-BACKED | Regulatory framework from `Dictionary.Regulation.Name` via `BackOffice.Customer.RegulationID`. NULL if unregulated. |
| 9 | PaymentStatus | VARCHAR(100) | YES | - | CODE-BACKED | Deposit payment status name from `Dictionary.PaymentStatus.Name` (e.g., "Approved", "Declined"). |
| 10 | RiskManagementStatus | VARCHAR(100) | YES | - | CODE-BACKED | Risk block status name from `Dictionary.RiskManagementStatus.Name`. NULL if no risk block applied. |
| 11 | Depot | VARCHAR(100) | YES | - | CODE-BACKED | Payment processing infrastructure name from `Billing.Depot.Name` via `Billing.Deposit.DepotID`. |
| 12 | Currency | VARCHAR(100) | YES | - | CODE-BACKED | Deposit currency abbreviation from `Dictionary.Currency.Abbreviation` (e.g., "USD", "EUR"). |
| 13 | FTD | VARCHAR(3) | NO | - | CODE-BACKED | First-time deposit label: "Yes" if `D.IsFTD=1`, "No" otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.ScheduledTaskState | SELECT + UPDATE | Claim TaskID=8 rows; mark TaskState=3 |
| DepositID | Billing.Deposit | INNER JOIN (FORCESEEK) | Deposit data source |
| D.FundingID | Billing.Funding | INNER JOIN | FundingTypeID filter |
| @FundingTypeID | Dictionary.FundingType | INNER JOIN | FundingType name |
| D.CID | Customer.CustomerStatic | INNER JOIN | CountryID |
| D.CID | BackOffice.Customer | INNER JOIN (x2) | RegulationID, VerificationLevelID |
| CS.CountryID | Dictionary.Country | INNER JOIN | Country name |
| CSf.VerificationLevelID | Dictionary.VerificationLevel | INNER JOIN | Verification level name |
| D.PaymentStatusID | Dictionary.PaymentStatus | INNER JOIN | Payment status name |
| D.DepotID | Billing.Depot | INNER JOIN | Depot name |
| D.CurrencyID | Dictionary.Currency | INNER JOIN | Currency abbreviation |
| BC.RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name |
| D.RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Risk status name |
| D.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN | MID value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment monitor scheduler (TaskID=8) | @MaxEntitiesToFetch, @FundingTypeID | EXEC | Enriched deposit batch fetch for monitor alerting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskMonitorProcessingEntities (procedure)
+-- Billing.ScheduledTaskState (table)
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- Billing.Depot (table)
+-- Billing.ProtocolMIDSettings (table)
+-- Customer.CustomerStatic (table, cross-schema)
+-- BackOffice.Customer (table, cross-schema)
+-- Dictionary.FundingType (table)
+-- Dictionary.Country (table)
+-- Dictionary.VerificationLevel (table)
+-- Dictionary.PaymentStatus (table)
+-- Dictionary.Currency (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.RiskManagementStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Claim pending TaskID=8 rows; mark TaskState=3 |
| Billing.Deposit | Table | Core deposit data (FORCESEEK hint) |
| Billing.Funding | Table | FundingTypeID for @FundingTypeID filter |
| Billing.Depot | Table | Depot name |
| Billing.ProtocolMIDSettings | Table | MID value |
| Customer.CustomerStatic | Table | CountryID |
| BackOffice.Customer | Table | RegulationID, VerificationLevelID |
| Dictionary.FundingType | Table | FundingType name |
| Dictionary.Country | Table | Country name |
| Dictionary.VerificationLevel | Table | Verification level name |
| Dictionary.PaymentStatus | Table | Payment status name |
| Dictionary.Currency | Table | Currency abbreviation |
| Dictionary.Regulation | Table | Regulation name |
| Dictionary.RiskManagementStatus | Table | Risk management status name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment monitor alerting scheduler | External | Enriched deposit batch processing for monitoring dashboards/alerts |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FORCESEEK on Deposit | Performance | Forces index seek in CTE stage; avoids table scan when joining ScheduledTaskState to Deposit |
| @FundingTypeID default=1 | Design | Defaults to credit card; allows multi-invocation pattern (one call per funding type) |
| Regulation from BackOffice.Customer | Business rule (PAYUA-804) | Moved from Deposit.RegulationID to BackOffice.Customer.RegulationID in Aug 2020 |
| Two-stage filtering | Performance | CTE + table variable pre-filter before enrichment JOIN reduces cardinality in main SELECT |
| INSERT...OUTPUT | Design | Returns results via OUTPUT clause |

---

## 8. Sample Queries

### 8.1 Fetch monitor processing batch for credit cards
```sql
EXEC Billing.GetScheduledTaskMonitorProcessingEntities
    @MaxEntitiesToFetch = 1,
    @FundingTypeID = 1;  -- Credit Card (default)
```

### 8.2 Fetch monitor batch for ACH deposits
```sql
EXEC Billing.GetScheduledTaskMonitorProcessingEntities
    @MaxEntitiesToFetch = 10,
    @FundingTypeID = 29;  -- ACH
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-665 (referenced in DDL comment, Shay Oren, 26/07/2020) | Jira | Initial version of monitor processing scheduler (Jira unavailable for full details) |
| PAYUA-804 (referenced in DDL comment, Shay Oren, 23/08/2020) | Jira | Changed RegulationID source from Billing.Deposit to BackOffice.Customer (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskMonitorProcessingEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskMonitorProcessingEntities.sql*
