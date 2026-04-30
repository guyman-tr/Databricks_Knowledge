# Compliance.GetCustomerRestrictionException

> Detects customers who opened CFD positions despite having an active compliance restriction, identifying potential regulatory violations for the past day (or a specified date range).

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate (input), CID (output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a compliance monitoring tool that detects customers who violated their trading restrictions by opening CFD positions after a restriction was placed on their account. Under MiFID II and similar regulatory frameworks, eToro must perform appropriateness tests for retail clients before allowing them to trade complex instruments (CFDs, leveraged products). When a customer fails an appropriateness test or is otherwise restricted, a restriction record with a `BeginTime` is created in ComplianceStateDB. If the customer then opens a CFD position after that `BeginTime`, it represents a potential breach.

Without this monitoring procedure, restriction violations could go undetected, exposing eToro to regulatory penalties for allowing restricted customers to trade prohibited instruments. The procedure was created on 24/04/2019 by Geri Reshef as part of tickets RD-6017 and RD-6528, described as "Monitoring of miss behavior for CFD restriction."

The procedure defaults to checking the past 24 hours when no date is provided, making it suitable for daily scheduled monitoring jobs. It returns the CIDs of violating customers only if exceptions are found, allowing operations or compliance teams to investigate and potentially reverse affected trades.

See also: `Compliance.GetCustomerRestrictionDiff` - a companion audit SP that checks whether restriction data is in sync between ComplianceStateDB and SettingsAzureDB. If `GetCustomerRestrictionDiff` shows no drift, the restriction data is reliable; if drift exists, some exceptions detected here may be artifacts of the data inconsistency rather than true violations.

---

## 2. Business Logic

### 2.1 CFD Restriction Violation Detection

**What**: Identifies customers who opened non-copy CFD positions while a compliance restriction was already active on their account.

**Columns/Parameters Involved**: `@FromDate`, `MirrorID`, `IsSettled`, `Occurred`, `BeginTime`

**Rules**:
- Scope: Only **manual** (non-copy) CFD positions: `MirrorID = 0` (no copy parent) AND `IsSettled = 0` (CFD, not real stock)
- Date window: Positions opened on or after `@FromDate` (defaults to yesterday UTC via `CAST(GETUTCDATE()-1 AS DATE)`)
- Violation condition: The customer's GCID has a restriction record in `Compliance_CustomerRestriction_v` where `BeginTime <= P.Occurred` - meaning the restriction was already active when the position was opened
- Cross-reference path: `Trade.Position.CID` -> `Customer.CustomerStatic.CID` -> `Customer.CustomerStatic.GCID` -> `Compliance_CustomerRestriction_v.GCID`
- Returns nothing if no violations found (`@@RowCount > 0` guard)
- Copy positions (`MirrorID != 0`) are excluded - restriction enforcement for copy trades may follow different rules

**Diagram**:
```
@FromDate (default: yesterday UTC)
        |
        v
Scan Trade.Position WHERE:
  MirrorID = 0        (manual position, not copy)
  IsSettled = 0       (CFD, not real stock)
  Occurred >= @FromDate
        |
        v
For each position, check:
  CustomerStatic[CID] -> get GCID
        |
        v
Does Compliance_CustomerRestriction_v have a record
  WHERE GCID = customer's GCID
    AND BeginTime <= position.Occurred?
  YES -> restriction was active when position opened = VIOLATION
  NO  -> customer had no active restriction = CLEAN
        |
        v
Return violating CIDs (if any)
```

### 2.2 Date Default Logic

**What**: Defaults to checking the prior calendar day when called without a date parameter.

**Columns/Parameters Involved**: `@FromDate`

**Rules**:
- `@FromDate = ISNULL(@FromDate, CAST(GETUTCDATE()-1 AS DATE))` converts to date (midnight), ensuring the full previous UTC day is scanned
- Passing an explicit date allows ad-hoc investigations over longer periods
- All timestamps compared are UTC-based (GETUTCDATE, Occurred field)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | GETUTCDATE()-1 (yesterday UTC midnight) | CODE-BACKED | Start of the date range to scan for restriction violations. Defaults to the beginning of yesterday (UTC). Pass a specific date for ad-hoc investigations over longer periods. |

**Return Result Set** (returned only when violations are found):

| # | Column | Type | Nullable | Default | Confidence | Description |
|---|--------|------|----------|---------|------------|-------------|
| R1 | CID | INT | NO | - | CODE-BACKED | Customer ID (eToro's per-entity integer ID) for customers who opened a CFD position while a compliance restriction was active on their account. Each CID represents a potential regulatory violation requiring investigation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / Occurred | Trade.Position | Lookup (SELECT) | Source of CFD positions to check - filtered to manual (non-copy) CFD positions in the date window |
| CID | Customer.CustomerStatic | JOIN | Resolves customer CID to GCID for cross-referencing with the restriction system |
| GCID / BeginTime | Compliance_CustomerRestriction_v (synonym -> ComplianceStateDB) | Lookup (EXISTS) | Source of active customer restrictions - checks whether the customer had an active restriction at the time of the position open |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in repo) | - | - | No stored procedures in the SSDT repo call this procedure. Likely called by a scheduled monitoring job or compliance operations tooling. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetCustomerRestrictionException (procedure)
├── Trade.Position (table)
├── Customer.CustomerStatic (table)
└── Compliance_CustomerRestriction_v (synonym)
      └── [Compliance].[ComplianceStateDBStg].[Compliance].[CustomerRestriction_v] (cross-DB view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Scanned for manual CFD positions (MirrorID=0, IsSettled=0) opened after @FromDate |
| Customer.CustomerStatic | Table | Joined on CID to retrieve GCID for restriction lookup |
| Compliance_CustomerRestriction_v | Synonym | EXISTS subquery - checks whether customer GCID has an active restriction (BeginTime <= position Occurred) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT repo) | - | Called by scheduled compliance monitoring jobs or operations tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CFD filter | Application logic | `IsSettled = 0` - restricts to derivative (CFD) positions only; real stock positions (IsSettled=1) are excluded |
| Manual trade filter | Application logic | `MirrorID = 0` - excludes copy-trading positions; only checks positions the customer opened themselves |
| @@RowCount guard | Application logic | Result only returned if violations exist - prevents empty result noise in monitoring pipelines |

---

## 8. Sample Queries

### 8.1 Run daily violation check (default: yesterday)

```sql
EXEC [Compliance].[GetCustomerRestrictionException];
```

### 8.2 Run for a specific historical date range

```sql
EXEC [Compliance].[GetCustomerRestrictionException] @FromDate = '2026-03-01';
```

### 8.3 Investigate a specific CID returned by the procedure

```sql
-- Check what restriction the customer had and when positions were opened
SELECT P.CID, P.Occurred, P.IsSettled, P.MirrorID,
       CS.GCID
FROM [Trade].[Position] P WITH (NOLOCK)
JOIN [Customer].[CustomerStatic] CS WITH (NOLOCK) ON CS.CID = P.CID
WHERE P.CID = @SuspectCID
  AND P.IsSettled = 0
  AND P.MirrorID = 0
ORDER BY P.Occurred;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Test Strategy - Appropriateness Test changes (CR space) | Confluence | Provides context that appropriateness test results drive customer restrictions for CFD eligibility |
| HLD COAIL-276: Appropriateness scoring mechanism (CR space) | Confluence | Background on the appropriateness scoring mechanism that populates restriction records |

DDL comment identifies origin: tickets RD-6017, RD-6528 "Monitoring of miss behavior for CFD restriction" (2019-04-24, Geri Reshef).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 2 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetCustomerRestrictionException | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetCustomerRestrictionException.sql*
