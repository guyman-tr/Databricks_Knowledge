# BackOffice.GetHistoryBackOfficeCustomer

> Returns the full change history of a BackOffice customer record for a given CID, combining account-attribute history with risk-status change history in two separate result sets.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer whose history is retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the complete audit trail for a BackOffice customer record. It answers: "How has this customer's BackOffice profile changed over time?" by surfacing two complementary histories: (1) the snapshot-by-snapshot change log from the temporal `History.BackOfficeCustomer` table, showing how account attributes such as manager assignment, verification level, and acceptance status evolved; (2) the chronological risk-status change log from `History.CustomerRisk` and `BackOffice.CustomerRisk`, showing every risk classification event with its combined status and event-status label.

The procedure exists because BackOffice agents performing compliance reviews, fraud investigations, or customer-service escalations need to reconstruct the full lifecycle of an account. Without it, agents would have to query two separate history tables (using different identity columns - CID vs GCID) and manually correlate the results.

Data flows into this procedure from two paths: the first result set is sourced from `History.BackOfficeCustomer`, which is populated by the temporal system-versioning mechanism whenever a row in the main BackOffice customer table changes. The second result set is sourced from `History.CustomerRisk` (the historical risk audit table) and `BackOffice.CustomerRisk` (the current live risk table), both joined via `Customer.CustomerStatic` to translate the GCID-keyed risk records back to the CID-keyed customer identity.

---

## 2. Business Logic

### 2.1 Two Result Sets with Different Histories

**What**: The procedure returns two independent result sets, not a UNION of all changes. Each result set uses a different time ordering and different column population strategy.

**Columns/Parameters Involved**: `@CID`, `ValidFrom`, `RiskStatus`, all BackOffice customer attribute columns

**Rules**:
- Result Set 1 (`History.BackOfficeCustomer`): Returns ALL attribute-change snapshots ordered by `CustomerHistoryID` ASC (chronological). Each row has the full attribute set; `RiskStatus` and `RiskStatusName` are NULL.
- Result Set 2 (UNION of `History.CustomerRisk` + `BackOffice.CustomerRisk`): Returns ONLY risk-status changes. All attribute columns are NULL; `RiskStatus` is populated as `CONCAT(RiskStatusName, ' - ', RiskEventStatusName)`. Ordered by `ValidFrom` DESC (most recent first).
- The UNION in Result Set 2 combines historical risk snapshots with the current active risk state (from `BackOffice.CustomerRisk`), ensuring the live status is included even if it has not yet been archived.

**Diagram**:
```
Input: @CID (integer customer identifier)

Result Set 1: BackOffice attribute history
  History.BackOfficeCustomer -> LEFT JOIN Dictionary.Regulation (-> Regulation name)
                              -> LEFT JOIN Dictionary.MifidCategorization (-> MifidCategorization name)
  WHERE CID = @CID
  ORDER BY CustomerHistoryID ASC

Result Set 2: Risk status change history
  History.CustomerRisk (archived)  -> INNER JOIN Dictionary.RiskStatus
  UNION                            -> INNER JOIN Dictionary.RiskEventStatus
  BackOffice.CustomerRisk (live)   -> INNER JOIN Customer.CustomerStatic (GCID->CID bridge)
  WHERE CustomerStatic.CID = @CID
  ORDER BY ValidFrom DESC
```

### 2.2 CID-to-GCID Bridge for Risk History

**What**: Risk tables (`History.CustomerRisk`, `BackOffice.CustomerRisk`) use GCID as their primary identity key, while the caller provides a CID. The procedure bridges this gap through `Customer.CustomerStatic`.

**Columns/Parameters Involved**: `@CID`, `Customer.CustomerStatic.CID`, `Customer.CustomerStatic.GCID`, `History.CustomerRisk.GCID`

**Rules**:
- `Customer.CustomerStatic` maps `CID` (etoro internal ID) to `GCID` (global customer ID).
- The JOIN `CCS.GCID = HCR.GCID` followed by `WHERE CCS.CID = @CID` is the translation mechanism.
- This pattern is required because the risk system uses the global identity while BackOffice historically uses the internal CID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Input parameter. The internal customer identifier (CID) for which the full BackOffice and risk change history is retrieved. Drives the WHERE filter in both result sets. |

**Result Set 1 Output Columns** (from `History.BackOfficeCustomer`):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ValidFrom | DATETIME | YES | - | CODE-BACKED | Timestamp when this snapshot became active - i.e., when the BackOffice customer record was last changed before this version. From `History.BackOfficeCustomer.ValidFrom` (system-versioning start column). |
| 2 | SalesStatusID | INT | YES | - | NAME-INFERRED | Identifier of the customer's sales status at this point in time. Lookup: BackOffice.SalesStatus or similar dictionary table. |
| 3 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager assigned to this customer at this snapshot. References BackOffice.Manager. |
| 4 | IsAffiliate | BIT | YES | - | NAME-INFERRED | Flag indicating whether the customer was classified as an affiliate at this point in time. |
| 5 | Cleared | BIT | YES | - | NAME-INFERRED | Flag indicating the cleared status of the customer at this snapshot. Business meaning depends on compliance workflow context. |
| 6 | Verified | BIT | YES | - | NAME-INFERRED | Flag indicating whether the customer was verified at this snapshot. Related to KYC/AML verification status. |
| 7 | PreviousManagerID | INT | YES | - | CODE-BACKED | ID of the manager who previously held this customer before the current assignment recorded in ManagerID. References BackOffice.Manager. |
| 8 | FXEligibilityDate | DATETIME | YES | - | NAME-INFERRED | Date from which the customer became eligible for FX trading at this snapshot. |
| 9 | AffiliateManagerID | INT | YES | - | NAME-INFERRED | ID of the affiliate manager associated with this customer at this snapshot. |
| 10 | CashoutFeeGroupID | INT | YES | - | NAME-INFERRED | Identifier of the cashout fee group applied to this customer at this snapshot. |
| 11 | AccountTypeID | INT | YES | - | NAME-INFERRED | Account type classification at this snapshot. Determines trading permissions and regulatory treatment. |
| 12 | MasterAccountCID | INT | YES | - | NAME-INFERRED | CID of the master/parent account if this is a sub-account, at this snapshot. |
| 13 | ManagerPermitID | INT | YES | - | NAME-INFERRED | Identifier of the manager permit level assigned at this snapshot. |
| 14 | ThirdPartyManagerComment | NVARCHAR | YES | - | NAME-INFERRED | Free-text comment recorded by a third-party manager at this snapshot. |
| 15 | GuruStatusID | INT | YES | - | NAME-INFERRED | Guru/Popular Investor status identifier at this snapshot. |
| 16 | RiskClassificationID | INT | YES | - | NAME-INFERRED | Risk classification assigned to the customer at this snapshot (e.g., Retail, Professional). |
| 17 | VerificationLevelID | INT | YES | - | NAME-INFERRED | KYC verification tier achieved at this snapshot (e.g., basic, full). |
| 18 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Name of the regulatory framework applied to this customer at this snapshot. Resolved via LEFT JOIN to `Dictionary.Regulation` on `RegulationID`. |
| 19 | RiskStatus | NVARCHAR | YES | - | CODE-BACKED | NULL in Result Set 1. In Result Set 2, this is the combined risk label: CONCAT(RiskStatus.Name, ' - ', RiskEventStatus.Name). |
| 20 | AcceptanceStatusID | INT | YES | - | NAME-INFERRED | Compliance acceptance status at this snapshot (e.g., accepted, pending, rejected). |
| 21 | DocumentStatusID | INT | YES | - | NAME-INFERRED | Document verification status at this snapshot. |
| 22 | PhoneVerifiedID | INT | YES | - | NAME-INFERRED | Phone verification status identifier at this snapshot. |
| 23 | EvMatchStatusID | INT | YES | - | CODE-BACKED | Electronic verification (EV) match status at this snapshot. Source column is `EvMatchStatus` aliased as `EvMatchStatusID`. |
| 24 | AcceptanceStatusChanginManagerID | INT | YES | - | NAME-INFERRED | ID of the manager who last changed the acceptance status at this snapshot. |
| 25 | GDCCheckID | INT | YES | - | NAME-INFERRED | Global Due Diligence Check status identifier at this snapshot. |
| 26 | MifidCategorization | NVARCHAR | YES | - | CODE-BACKED | MiFID II client categorization name at this snapshot (e.g., Retail Client, Professional Client). Resolved via LEFT JOIN to `Dictionary.MifidCategorization`. |
| 27 | RiskStatusName | NVARCHAR | YES | - | CODE-BACKED | NULL in Result Set 1 (always). Reserved column position for Result Set 2 compatibility. |

**Result Set 2 Output Columns** (from `History.CustomerRisk` UNION `BackOffice.CustomerRisk`): Same column names as Result Set 1, but only `ValidFrom` and `RiskStatus` are populated; all others are NULL.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | History.BackOfficeCustomer | Lookup (READ) | Primary source of attribute-change history for Result Set 1 |
| (internal) | History.CustomerRisk | Lookup (READ) | Archived risk-status change records for Result Set 2 |
| (internal) | BackOffice.CustomerRisk | Lookup (READ) | Current/live risk records included in Result Set 2 via UNION |
| (internal) | Dictionary.Regulation | Lookup | Resolves RegulationID to regulatory framework name |
| (internal) | Dictionary.RiskStatus | Lookup | Resolves RiskStatusID to risk status label (both result sets) |
| (internal) | Dictionary.RiskEventStatus | Lookup | Resolves RiskEventStatusID to event type label (Result Set 2) |
| (internal) | Dictionary.MifidCategorization | Lookup | Resolves MifidCategorizationID to MiFID category name |
| (internal) | Customer.CustomerStatic | Bridge | Maps @CID to GCID for joining against risk tables (cross-schema) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No SQL callers found; this SP is invoked directly from the BackOffice application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetHistoryBackOfficeCustomer (procedure)
├── History.BackOfficeCustomer (table)
├── Dictionary.Regulation (table)
├── Dictionary.RiskStatus (table)
├── Dictionary.MifidCategorization (table)
├── History.CustomerRisk (table)
├── Dictionary.RiskEventStatus (table)
├── BackOffice.CustomerRisk (table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.BackOfficeCustomer | Table | FROM clause of Result Set 1; source of all attribute-change snapshots |
| Dictionary.Regulation | Table | LEFT JOIN to resolve RegulationID to name |
| Dictionary.RiskStatus | Table | LEFT JOIN (Result Set 1) and INNER JOIN (Result Set 2) to resolve RiskStatusID |
| Dictionary.MifidCategorization | Table | LEFT JOIN to resolve MifidCategorizationID to name |
| History.CustomerRisk | Table | FROM clause of Result Set 2 first branch; archived risk events |
| Dictionary.RiskEventStatus | Table | INNER JOIN in Result Set 2 to resolve RiskEventStatusID |
| BackOffice.CustomerRisk | Table | FROM clause of Result Set 2 second branch (UNION); current risk state |
| Customer.CustomerStatic | Table | INNER JOIN to translate @CID input to GCID for risk table joins |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called directly to power the customer history audit view in the BackOffice portal |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages for the calling application |
| WITH (NOLOCK) on all tables | Query hint | All joins use NOLOCK to avoid blocking under high-read scenarios |

---

## 8. Sample Queries

### 8.1 Retrieve full BackOffice history for a customer

```sql
EXEC BackOffice.GetHistoryBackOfficeCustomer @CID = 12345
```

### 8.2 Get Result Set 1 (attribute history) directly from the source table

```sql
SELECT c.ValidFrom,
       c.SalesStatusID,
       c.ManagerID,
       c.VerificationLevelID,
       c.AcceptanceStatusID,
       dr.Name AS Regulation,
       dmc.Name AS MifidCategorization
FROM History.BackOfficeCustomer c WITH (NOLOCK)
LEFT JOIN Dictionary.Regulation dr WITH (NOLOCK) ON c.RegulationID = dr.ID
LEFT JOIN Dictionary.MifidCategorization dmc WITH (NOLOCK) ON c.MifidCategorizationID = dmc.MifidCategorizationID
WHERE c.CID = 12345
ORDER BY c.CustomerHistoryID;
```

### 8.3 Get Result Set 2 (risk status changes) directly

```sql
SELECT HCR.ModifiedDate AS ValidFrom,
       CONCAT(DRS.Name, ' - ', DRES.Name) AS RiskStatus
FROM History.CustomerRisk HCR WITH (NOLOCK)
INNER JOIN Dictionary.RiskStatus DRS WITH (NOLOCK) ON HCR.RiskStatusID = DRS.RiskStatusID
INNER JOIN Dictionary.RiskEventStatus DRES WITH (NOLOCK) ON DRES.RiskEventStatusID = HCR.RiskEventStatusID
INNER JOIN Customer.CustomerStatic CCS WITH (NOLOCK) ON CCS.GCID = HCR.GCID
WHERE CCS.CID = 12345
UNION
SELECT HCR2.ModifiedDate,
       CONCAT(DRS2.Name, ' - ', DRES2.Name)
FROM BackOffice.CustomerRisk HCR2 WITH (NOLOCK)
INNER JOIN Dictionary.RiskStatus DRS2 WITH (NOLOCK) ON HCR2.RiskStatusID = DRS2.RiskStatusID
INNER JOIN Dictionary.RiskEventStatus DRES2 WITH (NOLOCK) ON DRES2.RiskEventStatusID = HCR2.RiskEventStatusID
INNER JOIN Customer.CustomerStatic CCS2 WITH (NOLOCK) ON CCS2.GCID = HCR2.GCID
WHERE CCS2.CID = 12345
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 7.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 13 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetHistoryBackOfficeCustomer | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetHistoryBackOfficeCustomer.sql*
