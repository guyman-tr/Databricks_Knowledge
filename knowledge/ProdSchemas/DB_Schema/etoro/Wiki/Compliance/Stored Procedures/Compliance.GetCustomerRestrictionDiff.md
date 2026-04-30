# Compliance.GetCustomerRestrictionDiff

> Detects discrepancies in customer trading restriction assignments between the ComplianceState database and the SettingsAzure database, returning only customers where the two systems disagree.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | GCID (output - customers with differing restrictions) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a reconciliation audit tool that surfaces discrepancies in customer trading restrictions across two systems that should always be in sync. eToro maintains customer restriction data (such as "Appropriate Test" results, CFD eligibility, and trading limitation flags) in two separate databases: ComplianceStateDB (the compliance engine's database) and SettingsAzureDB (the configuration/settings distribution database). When these systems drift out of sync, a customer may be incorrectly allowed or denied a trading action depending on which system the requesting service queries.

The procedure was created on 22/04/2019 by Geri Reshef as part of tickets RD-6118 and RD-6445, described as "Report for Appropriate Test Manual, Appropriate Test Auto and CFD status and reason." This is relevant to MiFID II appropriateness testing, where EU-regulated brokers must verify that retail clients understand the risks of complex instruments (CFDs, leveraged products). The SP returns a diff report for operations/compliance teams to investigate and correct mismatches.

If there are no discrepancies, the procedure returns no rows (the `IF @@RowCount > 0` guard ensures an empty result rather than an empty table). It is called as a monitoring/audit report, not a real-time operational procedure.

See also: `Compliance.GetCustomerRestrictionException` - a companion monitoring SP that detects customers who violated their restrictions by opening CFD positions while already restricted (i.e., after restriction was placed). Together, these two SPs cover the full CFD restriction monitoring picture: `GetCustomerRestrictionDiff` finds system drift, `GetCustomerRestrictionException` finds enforcement breaches.

---

## 2. Business Logic

### 2.1 Cross-System Restriction Diff Detection

**What**: FULL OUTER JOIN between the two systems to surface every GCID where restriction names differ or exist in only one system.

**Columns/Parameters Involved**: `GCID`, `RestrictionName_Compliance`, `RestrictionName_Settings`

**Rules**:
- Source A: `Compliance_CustomerRestriction_Compliance` synonym -> `[Compliance].[ComplianceStateDBStg].[Compliance].[CustomerRestriction_v]` (ComplianceState DB)
- Source B: `Compliance_CustomerRestriction_Settings` synonym -> `[SettingsAzure].[SettingsDB_Stg].[Compliance].[CustomerRestriction_v]` (SettingsAzure DB)
- FULL OUTER JOIN on `GCID` ensures customers only in one system are included
- Three discrepancy types returned:
  1. `C.RestrictionName IS NULL` - customer exists in Settings but not in Compliance DB
  2. `S.RestrictionName IS NULL` - customer exists in Compliance DB but not in Settings DB
  3. Names differ (collation-aware comparison) - same GCID but different restriction names
- Collation-aware comparison: `C.RestrictionName COLLATE Database_Default <> S.RestrictionName COLLATE Database_Default` handles encoding/collation mismatches between cross-database values
- Returns nothing if systems are fully in sync (no rows)

**Diagram**:
```
ComplianceStateDB                SettingsAzureDB
[CustomerRestriction_v]          [CustomerRestriction_v]
      GCID | RestrictionName           GCID | RestrictionName
      -----+-----------------          -----+-----------------
      101  | CFD_Restricted            101  | CFD_Restricted     <- MATCH (excluded)
      102  | AppropTest_Failed         102  | AppropTest_Passed  <- DIFF (included)
      103  | CFD_Restricted            (missing)                 <- MISSING in Settings (included)
      (missing)                        104  | AppropTest_Failed  <- MISSING in Compliance (included)

Result: GCIDs 102, 103, 104 with their respective RestrictionName columns
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Return Result Set** (returned only when discrepancies exist):

| # | Column | Type | Nullable | Default | Confidence | Description |
|---|--------|------|----------|---------|------------|-------------|
| R1 | GCID | INT/BIGINT | NO | - | CODE-BACKED | Global Customer ID - eToro's universal customer identifier. COALESCE(C.GCID, S.GCID) ensures the GCID is populated from whichever system has the record. |
| R2 | RestrictionName_Compliance | NVARCHAR | YES | - | CODE-BACKED | The restriction name for this customer as recorded in ComplianceStateDB. NULL when the customer exists in Settings but is missing from Compliance. Typical values include appropriateness test results and CFD eligibility flags (e.g., 'AppropTest_Failed', 'CFD_Restricted'). |
| R3 | RestrictionName_Settings | NVARCHAR | YES | - | CODE-BACKED | The restriction name for this customer as recorded in SettingsAzureDB. NULL when the customer exists in Compliance but is missing from Settings. Should match RestrictionName_Compliance when systems are in sync. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Compliance_CustomerRestriction_Compliance | [Compliance].[ComplianceStateDBStg].[Compliance].[CustomerRestriction_v] | Synonym -> Cross-DB View | Customer restriction state from the ComplianceState database (the compliance engine's source of truth) |
| Compliance_CustomerRestriction_Settings | [SettingsAzure].[SettingsDB_Stg].[Compliance].[CustomerRestriction_v] | Synonym -> Cross-DB View | Customer restriction state from the SettingsAzure database (the configuration distribution database) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in repo) | - | - | No stored procedures in the SSDT repo call this procedure. Called directly by compliance/operations teams for audit reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetCustomerRestrictionDiff (procedure)
├── Compliance_CustomerRestriction_Compliance (synonym)
│     └── [Compliance].[ComplianceStateDBStg].[Compliance].[CustomerRestriction_v] (cross-DB view)
└── Compliance_CustomerRestriction_Settings (synonym)
      └── [SettingsAzure].[SettingsDB_Stg].[Compliance].[CustomerRestriction_v] (cross-DB view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Compliance_CustomerRestriction_Compliance | Synonym | Left side of FULL OUTER JOIN - reads customer restrictions from ComplianceStateDB |
| Compliance_CustomerRestriction_Settings | Synonym | Right side of FULL OUTER JOIN - reads customer restrictions from SettingsAzureDB |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT repo) | - | Called by compliance/operations tooling for audit reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@RowCount guard | Application logic | Result only returned if temp table has rows - prevents empty result set noise when systems are in sync |
| Collation normalization | Application logic | `COLLATE Database_Default` on both sides prevents false positives from cross-database collation mismatches |

---

## 8. Sample Queries

### 8.1 Execute the diff report

```sql
-- Returns customers with mismatched restrictions (empty if systems are in sync)
EXEC [Compliance].[GetCustomerRestrictionDiff];
```

### 8.2 Check synonym targets directly

```sql
-- Verify what the synonyms point to
SELECT name, base_object_name
FROM sys.synonyms WITH (NOLOCK)
WHERE name IN ('Compliance_CustomerRestriction_Compliance', 'Compliance_CustomerRestriction_Settings');
```

### 8.3 Manual diff without temp table (for ad-hoc investigation)

```sql
SELECT COALESCE(C.GCID, S.GCID) AS GCID,
       C.RestrictionName AS RestrictionName_Compliance,
       S.RestrictionName AS RestrictionName_Settings
FROM Compliance_CustomerRestriction_Compliance C WITH (NOLOCK)
FULL OUTER JOIN Compliance_CustomerRestriction_Settings S
    ON C.GCID = S.GCID
WHERE C.RestrictionName IS NULL
   OR S.RestrictionName IS NULL
   OR C.RestrictionName COLLATE Database_Default <> S.RestrictionName COLLATE Database_Default;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comment identifies origin: tickets RD-6118, RD-6445 "Report for Appropriate Test Manual, Appropriate Test Auto and CFD status and reason" (2019-04-22, Geri Reshef).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetCustomerRestrictionDiff | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetCustomerRestrictionDiff.sql*
