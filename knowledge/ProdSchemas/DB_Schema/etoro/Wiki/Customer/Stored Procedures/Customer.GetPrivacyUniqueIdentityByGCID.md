# Customer.GetPrivacyUniqueIdentityByGCID

> Returns all social network connections (platform IDs and OAuth tokens) for a customer by GCID, the cross-product identity variant of GetPrivacyUniqueIdentityByCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID; returns PrivacyRecipientID, Token for all connections |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivacyUniqueIdentityByGCID is the GCID-based variant of GetPrivacyUniqueIdentityByCID. It retrieves all social network connections for a customer using their GCID (Group Customer ID), returning the platform identifier and OAuth token for every linked account.

Like the CID variant, it returns all connections without IsAuthorized or TokenExpiry filtering - suitable for administrative operations, GDPR data exports, and full audit views. The GCID lookup uses the NC index IX_CustomerPrivacyUniqueIdentity_GCID for performance.

---

## 2. Business Logic

### 2.1 Unfiltered GCID-Based Connection Retrieval

**What**: Returns ALL social connections for a GCID, including inactive ones.

**Columns/Parameters Involved**: `@GCID`, `PrivacyRecipientID`, `Token`

**Rules**:
- No IsAuthorized filter: returns active and revoked connections
- No TokenExpiry filter: returns all regardless of expiry
- Uses GCID index for the lookup (IX_CustomerPrivacyUniqueIdentity_GCID)
- GCID may match multiple CIDs (though rare) - returns all associated connections

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Input: Group Customer ID. Used to filter Customer.PrivacyUniqueIdentity.GCID. Lookup uses IX_CustomerPrivacyUniqueIdentity_GCID. |
| 2 | PrivacyRecipientID | int (output) | NO | - | VERIFIED | Social platform: 1=Community, 2=Facebook, 3=Twitter, 4=LinkedIn, 5=Google, 6=Yahoo, 7=Live. |
| 3 | Token | varchar(255) (output) | YES | - | VERIFIED | OAuth access token. May be NULL, expired, or revoked - no filtering applied. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.PrivacyUniqueIdentity | FROM + WHERE filter | Source of social connection data, filtered by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivacyUniqueIdentityByGCID (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | FROM + WHERE GCID = @GCID (no authorization filter) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all social connections for a GCID
```sql
EXEC Customer.GetPrivacyUniqueIdentityByGCID @GCID = 1983785;
```

### 8.2 Direct query equivalent
```sql
SELECT PrivacyRecipientID, Token
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE GCID = 1983785;
```

### 8.3 Compare CID vs GCID connection views
```sql
-- By CID:
EXEC Customer.GetPrivacyUniqueIdentityByCID @CID = 245;

-- By GCID (same customer):
EXEC Customer.GetPrivacyUniqueIdentityByGCID @GCID = 1983785;
-- Should return same rows if CID=245 maps to GCID=1983785
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related SP compared | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetPrivacyUniqueIdentityByGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetPrivacyUniqueIdentityByGCID.sql*
