# Billing.GetScheduledTaskMonitorProcessingEntitiesById

> Point-lookup version of the payment monitor enrichment: returns fully-enriched payment context for a single @DepositID without touching ScheduledTaskState. Returns same columns as batch version plus ApplicationIdentifier (hardcoded 'BillingService') and SessionId. Uses D.ProcessRegulationID instead of BackOffice.Customer.RegulationID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID (single-row lookup; no ScheduledTaskState claim) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskMonitorProcessingEntitiesById` is the point-lookup companion to `Billing.GetScheduledTaskMonitorProcessingEntities`. While the batch version claims a queue of pending deposits and marks them as In Progress, this procedure retrieves the same enriched payment context for a **specific** DepositID on demand - without any side effects on `ScheduledTaskState`.

Primary use cases:
- **Retry / manual re-send**: A payment monitoring consumer re-fetches context for a specific DepositID after a failed attempt (e.g., monitor service was down)
- **Debug / audit**: An operator or support tool looks up the full payment context for a specific deposit
- **Targeted re-processing**: The monitor pipeline re-processes a specific deposit that was missed or needs re-evaluation

The procedure returns 12 enriched columns (all human-readable labels) plus two additional fields not present in the batch version:
- `ApplicationIdentifier`: Always `'BillingService'` (hard-coded since PAYSOLB-1173, Jul 2022)
- `SessionId`: The session identifier from `Billing.Deposit.SessionID` (added PAYIL-5614, Dec 2022)

**Key difference from batch version**: Regulation is sourced from `D.ProcessRegulationID` (LEFT JOIN Dictionary.Regulation) on the Deposit row itself, rather than from `BackOffice.Customer.RegulationID`. This gives the regulation in effect at the time of deposit processing rather than the customer's current regulation.

**Evolution**:
- Dec 2020 (Oleg S., PAYUA-1440): Added ApplicationIdentifier via OUTER APPLY on STS_Audit_LoginHistory (resolved app that initiated the deposit session)
- Jul 2022 (Shay O., PAYSOLB-1173): Replaced the STS_Audit_LoginHistory lookup with hardcoded `'BillingService'` (simplified - all paths go through BillingService)
- Dec 2022 (Shay O., PAYIL-5614): Added `SessionID` to the result set for session tracking

---

## 2. Business Logic

### 2.1 Single-Row Point Lookup

**What**: Retrieves enriched payment context for exactly one deposit by primary key.

**Rules**:
- `WHERE D.DepositID = @DepositID` - direct PK lookup on Billing.Deposit
- No ScheduledTaskState interaction: no SELECT from ScheduledTaskState, no UPDATE of TaskState
- Returns exactly 0 or 1 rows (1 if deposit exists; 0 if DepositID not found)
- All JOINs are INNER except Regulation, RiskManagementStatus, and ProtocolMIDSettings (LEFT JOIN)

### 2.2 Full Context Enrichment (Same as Batch Version)

**What**: Returns human-readable labels for all key deposit dimensions.

**Rules**:
- `Country = Dictionary.Country.Name` via `Customer.CustomerStatic.CountryID`
- `FundingType = Dictionary.FundingType.Name` via `Billing.Funding.FundingTypeID`
- `Mid = Billing.ProtocolMIDSettings.Value` via `Billing.Deposit.ProtocolMIDSettingsID` (LEFT JOIN - NULL if none)
- `VerificationLevel = Dictionary.VerificationLevel.Name` via `BackOffice.Customer.VerificationLevelID`
- `Regulation = Dictionary.Regulation.Name` via `D.ProcessRegulationID` (LEFT JOIN - **deposit-level** regulation, not customer-level)
- `PaymentStatus = Dictionary.PaymentStatus.Name` via `Billing.Deposit.PaymentStatusID`
- `RiskManagementStatus = Dictionary.RiskManagementStatus.Name` via `Billing.Deposit.RiskManagementStatusID` (LEFT JOIN)
- `Depot = Billing.Depot.Name` via `Billing.Deposit.DepotID`
- `Currency = Dictionary.Currency.Abbreviation` via `Billing.Deposit.CurrencyID`
- `FTD = IIF(D.IsFTD=1, 'Yes', 'No')` as VARCHAR label

### 2.3 ApplicationIdentifier - Hardcoded (PAYSOLB-1173)

**What**: Returns a constant string identifying the application that processes deposits.

**Rules**:
- Returns `'BillingService'` as `ApplicationIdentifier` (hard-coded literal)
- Original design (PAYUA-1440): OUTER APPLY on `STS_Audit_LoginHistory` to look up the actual app that initiated the session - see commented-out code
- PAYSOLB-1173 (Jul 2022): Simplified to hardcoded `'BillingService'` since all billing deposits go through the BillingService application
- The original subquery used `D.SessionID` matched to `lh.SessionIdentifier` with `LOWER(lh.AccountType) = 'real'` filter

### 2.4 SessionId (PAYIL-5614)

**What**: Returns the session identifier from the deposit record.

**Rules**:
- `D.SessionID AS SessionId` - the session in which the deposit was made
- Used by the payment monitor service for session-level correlation (fraud detection, risk analysis)
- Not present in the original procedure; added Dec 2022

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The specific deposit to retrieve context for. PK of Billing.Deposit. No default - required parameter. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | (DepositID) | INT | NO | - | CODE-BACKED | The @DepositID parameter value echoed as first column (no alias). |
| 3 | Country | VARCHAR(100) | YES | - | CODE-BACKED | Customer's country name from `Dictionary.Country` via `Customer.CustomerStatic.CountryID`. |
| 4 | FundingType | VARCHAR(100) | YES | - | CODE-BACKED | Payment method name from `Dictionary.FundingType.Name` for this deposit's funding type. |
| 5 | Mid | VARCHAR(100) | YES | - | CODE-BACKED | Merchant ID value from `Billing.ProtocolMIDSettings.Value` via `Billing.Deposit.ProtocolMIDSettingsID`. NULL if no MID settings. |
| 6 | VerificationLevel | VARCHAR(100) | YES | - | CODE-BACKED | Customer's verification tier from `Dictionary.VerificationLevel.Name` via `BackOffice.Customer.VerificationLevelID`. |
| 7 | Regulation | VARCHAR(100) | YES | - | CODE-BACKED | Regulatory framework from `Dictionary.Regulation.Name` via `D.ProcessRegulationID` (deposit-level; may differ from customer's current regulation). NULL if not set. |
| 8 | PaymentStatus | VARCHAR(100) | YES | - | CODE-BACKED | Deposit payment status name from `Dictionary.PaymentStatus.Name` (e.g., "Approved", "Declined"). |
| 9 | RiskManagementStatus | VARCHAR(100) | YES | - | CODE-BACKED | Risk block status name from `Dictionary.RiskManagementStatus.Name`. NULL if no risk block applied. |
| 10 | Depot | VARCHAR(100) | YES | - | CODE-BACKED | Payment processing infrastructure name from `Billing.Depot.Name` via `Billing.Deposit.DepotID`. |
| 11 | Currency | VARCHAR(100) | YES | - | CODE-BACKED | Deposit currency abbreviation from `Dictionary.Currency.Abbreviation` (e.g., "USD", "EUR"). |
| 12 | FTD | VARCHAR(3) | NO | - | CODE-BACKED | First-time deposit label: "Yes" if `D.IsFTD=1`, "No" otherwise. |
| 13 | ApplicationIdentifier | VARCHAR(14) | NO | - | CODE-BACKED | Always `'BillingService'` (hardcoded since PAYSOLB-1173 Jul 2022). Identifies the application layer handling the deposit. |
| 14 | SessionId | INT/UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Session identifier from `Billing.Deposit.SessionID` (added PAYIL-5614 Dec 2022). Used for session-level correlation in fraud/monitor analysis. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | INNER JOIN (WHERE) | Core deposit data source |
| D.FundingID | Billing.Funding | INNER JOIN | FundingTypeID |
| F.FundingTypeID | Dictionary.FundingType | INNER JOIN | FundingType name |
| D.CID | Customer.CustomerStatic | INNER JOIN | CountryID |
| D.CID | BackOffice.Customer | INNER JOIN | VerificationLevelID |
| CS.CountryID | Dictionary.Country | INNER JOIN | Country name |
| CSf.VerificationLevelID | Dictionary.VerificationLevel | INNER JOIN | Verification level name |
| D.PaymentStatusID | Dictionary.PaymentStatus | INNER JOIN | Payment status name |
| D.DepotID | Billing.Depot | INNER JOIN | Depot name |
| D.CurrencyID | Dictionary.Currency | INNER JOIN | Currency abbreviation |
| D.ProcessRegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name (deposit-level) |
| D.RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Risk status name |
| D.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN | MID value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment monitor service (retry/manual) | @DepositID | EXEC | Point-lookup for re-processing or auditing a specific deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskMonitorProcessingEntitiesById (procedure)
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
| Billing.Deposit | Table | Core deposit data; WHERE DepositID=@DepositID; SessionID |
| Billing.Funding | Table | FundingTypeID |
| Billing.Depot | Table | Depot name |
| Billing.ProtocolMIDSettings | Table | MID value |
| Customer.CustomerStatic | Table | CountryID |
| BackOffice.Customer | Table | VerificationLevelID |
| Dictionary.FundingType | Table | FundingType name |
| Dictionary.Country | Table | Country name |
| Dictionary.VerificationLevel | Table | Verification level name |
| Dictionary.PaymentStatus | Table | Payment status name |
| Dictionary.Currency | Table | Currency abbreviation |
| Dictionary.Regulation | Table | Regulation name (via D.ProcessRegulationID) |
| Dictionary.RiskManagementStatus | Table | Risk management status name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment monitor alerting service | External | On-demand point lookup for retry/re-processing scenarios |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No ScheduledTaskState interaction | Design | Point lookup only; does NOT claim or update TaskState rows |
| ProcessRegulationID (not BackOffice) | Design | Uses D.ProcessRegulationID for regulation (deposit-level snapshot), not BackOffice.Customer.RegulationID (current customer regulation) |
| ApplicationIdentifier hardcoded | Simplification (PAYSOLB-1173) | Always 'BillingService'; original OUTER APPLY on STS_Audit_LoginHistory removed Jul 2022 |
| @DepositID required | Design | No default; must be provided; returns 0 rows for unknown DepositID |

---

## 8. Sample Queries

### 8.1 Get enriched monitor context for a specific deposit
```sql
EXEC Billing.GetScheduledTaskMonitorProcessingEntitiesById @DepositID = 123456789;
```

### 8.2 Compare batch vs point-lookup regulation source
```sql
-- Batch version uses BackOffice.Customer.RegulationID (current customer regulation)
-- Point-lookup version uses Billing.Deposit.ProcessRegulationID (regulation at deposit time)
-- These may differ if customer's regulation was changed after the deposit
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-1440 (referenced in DDL comment, Oleg S., 21/12/2020) | Jira | Initial addition of ApplicationIdentifier via STS_Audit_LoginHistory OUTER APPLY (Jira unavailable) |
| PAYSOLB-1173 (referenced in DDL comment, Shay O., 12/07/2022) | Jira | Simplified ApplicationIdentifier to hardcoded 'BillingService' (Jira unavailable) |
| PAYIL-5614 (referenced in DDL comment, Shay O., 27/12/2022) | Jira | Added SessionID to result set (Jira unavailable) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskMonitorProcessingEntitiesById | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskMonitorProcessingEntitiesById.sql*
