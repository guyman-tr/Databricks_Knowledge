# History.ProtocolMIDSettings

> Audit log capturing historical snapshots of Merchant ID (MID) parameter settings per payment depot, regulation, and currency - recording configuration changes to the payment processing infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, no clustered PK declared) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 0 |

---

## 1. Business Meaning

`History.ProtocolMIDSettings` is a standalone audit/change log that captures historical parameter settings for Merchant IDs (MIDs) in the payment processing system. A Merchant ID is an identifier assigned by a payment acquirer/processor to a merchant account - in eToro's context, each MID represents a configured payment processing channel (depot) used for handling deposits and withdrawals.

This table stores snapshots of MID parameter changes: when a payment depot's settings are reconfigured (e.g., a regulatory parameter changes, a currency assignment is updated, or an operational mode changes), a record is written here. Each row represents one parameter value at a point in time, identified by its ParameterID and associated depot/regulation/currency context.

Unlike temporal tables that are maintained automatically by SQL Server, this table is written by the application (Billing procedures) when explicit audit logging is required. With 0 rows in the current environment, it may be a legacy or rarely-triggered audit log.

The table is referenced by PCI-version billing procedures (Billing.GetDepositsCustomerCardPCIVersion, BackOffice.GetProcessedWithdrawPCIVersion, etc.) which need to reconstruct historical MID configurations for payment compliance reporting.

---

## 2. Business Logic

### 2.1 MID Parameter Audit Trail

**What**: Each row captures the value of one MID configuration parameter at the time of a change.

**Columns/Parameters Involved**: `ParameterID`, `DepotID`, `DepotModeID`, `Value`, `RegulationID`, `CurrencyID`, `InsertDate`

**Rules**:
- `ParameterID` identifies which MID configuration parameter changed
- `DepotID` links to the payment depot (payment channel/acquirer account) being configured
- `DepotModeID` (tinyint) identifies the operational mode of the depot (e.g., live vs. test, different routing modes)
- `Value` stores the parameter's value as nvarchar(250) - may contain numeric or string settings
- `RegulationID` captures the regulatory context (different regulations may require different MID configurations)
- `CurrencyID` is nullable - some parameters are currency-specific, others apply across currencies
- `InsertDate` defaults to `getutcdate()` at INSERT time - provides the audit timestamp
- `Description` provides a human-readable label for what the parameter represents

### 2.2 No PK / Append-Only Log

**What**: This table has no primary key constraint and no indexes, indicating it is a pure append-only audit log.

**Rules**:
- The IDENTITY `ID` column provides row ordering but no constraint prevents duplicate entries
- No clustered index means rows are stored in heap order (insertion order)
- This structure is appropriate for write-heavy audit logs where query performance is secondary

---

## 3. Data Overview

0 rows in current environment. This may be a legacy table from an older billing audit process or a rarely-triggered log that only fires under specific configuration change events.

| ID | ParameterID | DepotID | DepotModeID | Value | RegulationID | CurrencyID | InsertDate | Description |
|---|---|---|---|---|---|---|---|---|
| (no rows) | | | | | | | | |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | auto | VERIFIED | Auto-incrementing row identifier. Provides insertion-order sequencing. No PK constraint declared. |
| 2 | ParameterID | int | NO | - | NAME-INFERRED | Identifies which MID configuration parameter this row records. Implicit FK to a parameter definition lookup. Different ParameterIDs represent different aspects of MID configuration (routing rules, fee settings, processing limits, etc.). |
| 3 | DepotID | int | NO | - | CODE-BACKED | The payment depot (payment processing channel/acquirer account) whose MID parameter is being logged. Corresponds to DepotID in Billing.Deposit and other billing tables. Each depot represents one configured payment processing relationship. |
| 4 | DepotModeID | tinyint | NO | - | NAME-INFERRED | Operational mode of the depot at the time of this setting. Tinyint suggests a small enumeration (e.g., 1=Live, 2=Test, 3=Sandbox or similar operational modes). |
| 5 | Value | nvarchar(250) | YES | - | VERIFIED | The actual parameter value. Wide type (nvarchar 250) accommodates both numeric and string-based parameter values. Stores the MID setting value at the time of the audit record. |
| 6 | RegulationID | int | NO | - | NAME-INFERRED | Regulatory context for this MID parameter. Different regulations (e.g., GDPR, PSD2, country-specific financial regulations) may require different MID configurations. |
| 7 | CurrencyID | int | YES | - | CODE-BACKED | Currency for which this parameter applies. Nullable - some parameters are currency-agnostic. When set, restricts the parameter's scope to a specific currency's processing rules. |
| 8 | InsertDate | datetime | YES | getutcdate() | VERIFIED | UTC timestamp when this audit record was created. Defaults to getutcdate() at INSERT. Provides the audit trail timestamp. |
| 9 | Description | nvarchar(250) | YES | - | VERIFIED | Human-readable description of what this parameter represents or what changed. Aids in interpreting the Value without needing to join to a parameter lookup table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepotID | Billing.Deposit (DepotID) | Implicit | The payment depot being configured |
| CurrencyID | Dictionary.Currency | Implicit | Currency scope for this parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDepositsCustomerCardPCIVersion | SELECT | READER | PCI compliance reporting for customer card deposits |
| BackOffice.GetProcessedWithdrawPCIVersion | SELECT | READER | PCI compliance reporting for processed withdrawals |
| BackOffice.GetRiskExposureReportPCIVersion | SELECT | READER | PCI compliance risk exposure report |
| BackOffice.InProcessPaymentsToSendPCIVersion | SELECT | READER | In-process payments PCI reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProtocolMIDSettings (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | READER - PCI version reporting |
| BackOffice.GetProcessedWithdrawPCIVersion | Stored Procedure | READER - PCI compliance reporting |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | READER - risk exposure PCI reporting |

---

## 7. Technical Details

### 7.1 Indexes

None. Heap table - no clustered or nonclustered indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryProtocolMIDSettings_InsertDate | DEFAULT | `getutcdate()` on InsertDate |

---

## 8. Sample Queries

### 8.1 All MID settings for a specific depot

```sql
SELECT ParameterID, DepotModeID, Value, RegulationID, CurrencyID, InsertDate, Description
FROM History.ProtocolMIDSettings WITH (NOLOCK)
WHERE DepotID = @DepotID
ORDER BY InsertDate DESC
```

### 8.2 Parameter history for a specific regulation

```sql
SELECT ParameterID, DepotID, DepotModeID, Value, CurrencyID, InsertDate, Description
FROM History.ProtocolMIDSettings WITH (NOLOCK)
WHERE RegulationID = @RegulationID
ORDER BY InsertDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 7.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProtocolMIDSettings | Type: Table | Source: etoro/etoro/History/Tables/History.ProtocolMIDSettings.sql*
