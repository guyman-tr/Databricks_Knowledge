# BackOffice.RegulationChangeLog

> Audit log of every regulatory jurisdiction change applied to a customer account, recording the before/after regulation, unrealized P&L at the time of change, and related credit snapshot.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_RegulationChangeLogID: RegulationChangeID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.RegulationChangeLog` is a compliance and operational audit log that records every instance of a customer's regulatory jurisdiction being changed. eToro operates under multiple regulatory frameworks (CySEC, FCA, ASIC, BVI, eToroUS, etc.) and customers are assigned to a jurisdiction based on their country of residence and account type. When a customer's regulation changes - due to relocation, regulatory restructuring, or back-office correction - this table captures a timestamped record of the transition with context about the financial state at the time.

This table exists primarily for compliance, regulatory reporting, and operational integrity. It enables tracing: which customers moved between jurisdictions, when, what their unrealized P&L was at transition, and which credit event triggered or accompanied the change. Without this log, re-regulation events would be invisible from a compliance audit perspective.

Data is written by the `BackOffice.ChangeCustomerRegulation` stored procedure (inferred from the table name and context). The table is highly active - 7.7M+ records with new entries appearing continuously in real time. `UnrealizedPnl` and `CurrentCreditID` are nullable, suggesting they may only be captured for certain regulation change scenarios (e.g., when open positions need to be assessed).

---

## 2. Business Logic

### 2.1 Regulation Transition Tracking

**What**: Each row records one regulation change event for one customer.

**Columns/Parameters Involved**: `CID`, `Occurred`, `FromRegulationID`, `ToRegulationID`

**Rules**:
- A customer can have multiple regulation changes over time (multi-row history per CID).
- `FromRegulationID` -> `ToRegulationID` defines the transition direction.
- Live data shows frequent transitions FROM RegulationID=5 (BVI) TO 1 (CySEC) or 2 (FCA), suggesting BVI is a registration-time default that is quickly re-assigned to the appropriate regulatory entity.
- The `Occurred` timestamp is set at event time.

**Diagram**:
```
Customer journey example:
  Registration       -> Regulation 5 (BVI - default at signup)
  Profile verified   -> Regulation 2 (FCA - UK-based customer)  [logged here]
  Customer relocates -> Regulation 1 (CySEC - moved to EU)      [logged here]

Each arrow = one row in RegulationChangeLog
```

### 2.2 Financial Snapshot at Transition

**What**: Open position context is captured at the moment of regulation change.

**Columns/Parameters Involved**: `UnrealizedPnl`, `CurrentCreditID`, `DateID`

**Rules**:
- `UnrealizedPnl` records the total open position P&L at the time of the regulation change (NULL if no open positions or not calculated).
- `CurrentCreditID` is a BIGINT referencing the credit/account balance record at the time of the change.
- `DateID` is an integer date key (likely YYYYMMDD format) for data warehouse / date dimension joins.
- These fields allow retroactive analysis of the financial impact of regulation changes on open positions.

---

## 3. Data Overview

| RegulationChangeID | CID | Occurred | FromRegulationID | ToRegulationID | Meaning |
|-------------------|-----|----------|-----------------|----------------|---------|
| 7754604 | 25463843 | 2026-03-17 12:43 | 5 (BVI) | 2 (FCA) | New UK customer: registration default (BVI) reassigned to FCA jurisdiction |
| 7754603 | 25463842 | 2026-03-17 12:42 | 5 (BVI) | 1 (CySEC) | New EU customer: registration default (BVI) reassigned to CySEC jurisdiction |
| 7754602 | 25463841 | 2026-03-17 12:42 | 5 (BVI) | 1 (CySEC) | New EU customer: same BVI->CySEC pattern during account activation |
| 7754601 | 25463840 | 2026-03-17 12:42 | 5 (BVI) | 1 (CySEC) | New EU customer activation - very high event frequency indicates automated process |
| 7754600 | 25463839 | 2026-03-17 12:41 | 5 (BVI) | 1 (CySEC) | Continuous stream of new account regulation assignments |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationChangeID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each regulation change event. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID whose regulation was changed. References Customer.Customer.CID. Multiple rows per CID if customer has changed regulation multiple times. |
| 3 | Occurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the regulation change was executed. Set at the time the ChangeCustomerRegulation procedure runs. |
| 4 | FromRegulationID | int | NO | - | CODE-BACKED | The regulation the customer was in before the change. FK to Dictionary.Regulation.ID. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 9=FSA Seychelles, 11=FSRA, 13=MAS. |
| 5 | ToRegulationID | int | NO | - | CODE-BACKED | The regulation the customer was moved to. FK to Dictionary.Regulation.ID. Same value set as FromRegulationID. |
| 6 | UnrealizedPnl | money | YES | - | NAME-INFERRED | Total unrealized profit/loss across open positions at the moment of regulation change. NULL if customer had no open positions or if this data was not captured for this event type. |
| 7 | CurrentCreditID | bigint | YES | - | NAME-INFERRED | Reference to the customer's credit/account balance record at the time of the regulation change. Links to the History or Credit schema. NULL if not applicable. |
| 8 | DateID | int | YES | - | NAME-INFERRED | Integer date key for data warehouse joins, likely in YYYYMMDD format. Corresponds to the date portion of Occurred. NULL if not populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer.CID | Implicit | The customer whose regulation changed |
| FromRegulationID | Dictionary.Regulation.ID | Implicit | Source regulatory jurisdiction |
| ToRegulationID | Dictionary.Regulation.ID | Implicit | Target regulatory jurisdiction |
| CurrentCreditID | History.Credit.CreditID (inferred) | Implicit | Balance snapshot at time of change |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in BackOffice schema procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegulationChangeLogID | CLUSTERED PK | RegulationChangeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RegulationChangeID NOT FOR REPLICATION | Identity | Identity not replicated to subscribers |

---

## 8. Sample Queries

### 8.1 Regulation change history for a specific customer

```sql
SELECT
    rcl.RegulationChangeID, rcl.CID, rcl.Occurred,
    fr.Name AS FromRegulation, tr.Name AS ToRegulation,
    rcl.UnrealizedPnl
FROM BackOffice.RegulationChangeLog rcl WITH (NOLOCK)
JOIN Dictionary.Regulation fr WITH (NOLOCK) ON fr.ID = rcl.FromRegulationID
JOIN Dictionary.Regulation tr WITH (NOLOCK) ON tr.ID = rcl.ToRegulationID
WHERE rcl.CID = 99999
ORDER BY rcl.Occurred;
```

### 8.2 Count of regulation changes by transition type today

```sql
SELECT
    fr.Name AS FromRegulation, tr.Name AS ToRegulation, COUNT(*) AS Changes
FROM BackOffice.RegulationChangeLog rcl WITH (NOLOCK)
JOIN Dictionary.Regulation fr WITH (NOLOCK) ON fr.ID = rcl.FromRegulationID
JOIN Dictionary.Regulation tr WITH (NOLOCK) ON tr.ID = rcl.ToRegulationID
WHERE rcl.Occurred >= CAST(GETUTCDATE() AS DATE)
GROUP BY fr.Name, tr.Name
ORDER BY Changes DESC;
```

### 8.3 Find customers who changed regulation with open positions (non-null UnrealizedPnl)

```sql
SELECT TOP 20
    rcl.CID, rcl.Occurred, rcl.FromRegulationID, rcl.ToRegulationID, rcl.UnrealizedPnl
FROM BackOffice.RegulationChangeLog rcl WITH (NOLOCK)
WHERE rcl.UnrealizedPnl IS NOT NULL
ORDER BY ABS(rcl.UnrealizedPnl) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 8.75/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 4/11 (DDL, Live Data, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RegulationChangeLog | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.RegulationChangeLog.sql*
