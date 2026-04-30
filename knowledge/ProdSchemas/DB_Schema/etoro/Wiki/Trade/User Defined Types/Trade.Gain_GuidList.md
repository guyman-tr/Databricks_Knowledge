# Trade.Gain_GuidList

> Single-column TVP carrying a list of anonymized customer GUIDs. Used by the Gain integration to look up internal CIDs from external anonymized identifiers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (uniqueidentifier) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.Gain_GuidList is a table-valued parameter used by the Gain integration to pass a list of anonymized customer IDs (GUIDs). The Gain_ prefix indicates this belongs to the external cashflow/payment provider integration. The type allows callers to request internal customer IDs (CIDs) from external anonymized identifiers - a common pattern when integrating with third-party systems that use different identity schemes.

Trade.Gain_GetCustomersCIDsByAnonID accepts this TVP via the @customerIds parameter and returns the corresponding internal CIDs. This enables the Gain integration layer to reconcile external anonymized identities with eToro's internal customer identifiers.

---

## 2. Business Logic

### 2.1 Anonymized ID to Internal CID Lookup

**What**: Maps external anonymized customer GUIDs to internal CIDs for Gain integration processing.

**Columns/Parameters Involved**: ID (uniqueidentifier).

**Rules**: ID is NOT NULL. Each row holds one anonymized customer GUID. Trade.Gain_GetCustomersCIDsByAnonID uses the list to perform lookups and return internal CIDs. No duplicates assumed; caller responsibility to deduplicate if needed.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | uniqueidentifier | NOT NULL | - | High | Anonymized customer ID (GUID). External identifier used by Gain to reference customers; procedure maps to internal CID. |

---

## 5. Relationships

### 5.1 References To

This object points to an anonymized identity store or mapping table used by Gain_GetCustomersCIDsByAnonID (implementation-dependent).

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Gain_GetCustomersCIDsByAnonID | @customerIds | Parameter (TVP) | Passes anonymized GUIDs for CID lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Trade.Gain_GetCustomersCIDsByAnonID

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Lookup CIDs for Single Anonymized ID

```sql
DECLARE @customerIds Trade.Gain_GuidList;
INSERT INTO @customerIds (ID) VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890');
EXEC Trade.Gain_GetCustomersCIDsByAnonID @customerIds = @customerIds;
```

### 8.2 Lookup CIDs for Multiple Anonymized IDs

```sql
DECLARE @customerIds Trade.Gain_GuidList;
INSERT INTO @customerIds (ID)
VALUES ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890'),
       ('B2C3D4E5-F6A7-8901-BCDE-F12345678901');
EXEC Trade.Gain_GetCustomersCIDsByAnonID @customerIds = @customerIds;
```

### 8.3 Populate from Staging Table

```sql
DECLARE @customerIds Trade.Gain_GuidList;
INSERT INTO @customerIds (ID) SELECT DISTINCT AnonCustomerID FROM #StagingGainData;
EXEC Trade.Gain_GetCustomersCIDsByAnonID @customerIds = @customerIds;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GuidList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Gain_GuidList.sql*
