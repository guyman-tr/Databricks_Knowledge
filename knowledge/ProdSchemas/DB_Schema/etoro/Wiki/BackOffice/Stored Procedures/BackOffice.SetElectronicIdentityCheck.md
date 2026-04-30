# BackOffice.SetElectronicIdentityCheck

> Upserts a customer's electronic identity verification (eIDV) record - inserting if no record exists or updating if one already exists - recording the verification provider, outcome, and transaction reference.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - one record per customer in BackOffice.ElectronicIdentityCheck |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetElectronicIdentityCheck records or updates the result of an automated electronic identity verification (eIDV) check for a customer. eIDV checks customer-provided personal details (name, date of birth, address) against third-party data bureaus and public records - providing evidence of identity without requiring the customer to submit physical documents.

The procedure creates or updates the one-row-per-customer record in BackOffice.ElectronicIdentityCheck. Two external providers have been used: GDC (Global Data Corporation) and GB (GBGroup/GBG). The check outcome (ElectronicIdentityCheckID) indicates whether the customer's identity was matched against zero, one, or two independent data sources.

Historical data shows this feature was active from November 2013 to May 2014, after which it appears to have been superseded by document-based KYC (passports, utility bills). However, the procedure remains in place for any future eIDV workflow.

---

## 2. Business Logic

### 2.1 UPSERT by CID (One Record Per Customer)

**What**: Each customer has at most one eIDV record. The procedure uses an existence check to decide INSERT vs UPDATE.

**Columns/Parameters Involved**: `@CID`, `@ElectronicIdentityCheckID`, `@ElectronicIdentityProviderID`, `@TransactionID`, `@TransactionDate`

**Rules**:
- EXISTS check: `SELECT @CID FROM BackOffice.ElectronicIdentityCheck WITH (NOLOCK) WHERE CID=@CID`
- If found: UPDATE all fields (ElectronicIdentityCheckID, ElectronicIdentityProviderID, TransactionID, TransactionDate) WHERE CID=@CID. If @@ROWCOUNT != 1 after UPDATE: RAISERROR(60000, 16, 1)
- If not found: INSERT all fields including CID
- No transaction wrapper - the two operations are separate; failure of the UPDATE check raises an error
- @ElectronicIdentityCheckID defaults to 0 (None check result)
- @TransactionID and @TransactionDate are optional: GDC provider does not supply transaction references (NULL); GB provider supplies both

### 2.2 Check Outcome Values

**What**: ElectronicIdentityCheckID encodes the strength of the identity match.

**Columns/Parameters Involved**: `@ElectronicIdentityCheckID`

**Rules**:
- 0 = None: No check performed or result not available
- 1 = One Source: Identity matched against one data bureau - partial verification
- 2 = Two Sources: Identity matched against two independent data bureaus - full eIDV pass (strongest outcome)
- 3 = No Match: No matching data found - eIDV failed, customer identity not electronically confirmable
- Distribution in data: 2=Two Sources (50.2%), 3=No Match (25.4%), 1=One Source (24.4%)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer whose eIDV record is being created or updated. PK of BackOffice.ElectronicIdentityCheck - one record per customer. |
| 2 | @ElectronicIdentityCheckID | INT | YES | 0 | VERIFIED | The eIDV outcome: 0=None, 1=One Source (partial match), 2=Two Sources (full match), 3=No Match. FK semantics to Dictionary.ElectronicIdentityCheck (enforced by application, not DDL). Defaults to 0 if not supplied. |
| 3 | @ElectronicIdentityProviderID | INT | NO | - | VERIFIED | The identity verification bureau used: 1=GDC (Global Data Corporation), 2=GB (GBGroup), 3=Au10tix (defined but 0 records in data). FK semantics to Dictionary.ElectronicIdentityProvider (application-enforced). |
| 4 | @TransactionID | VARCHAR(50) | YES | NULL | VERIFIED | Provider-supplied transaction reference for this check. NULL for GDC (not provided). Populated for GB (all 15,005 GB rows have TransactionID). Enables audit trail back to the provider's records. |
| 5 | @TransactionDate | DATETIME | YES | NULL | VERIFIED | Timestamp of the check as reported by the provider. NULL for GDC. Populated for GB records. May differ from the DB insertion time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.ElectronicIdentityCheck | WRITER/MODIFIER (UPSERT) | Creates new or updates existing eIDV record for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| eIDV Service / BackOffice API | - | Caller | Called by identity verification integrations when a provider returns a result |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetElectronicIdentityCheck (procedure)
└── BackOffice.ElectronicIdentityCheck (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ElectronicIdentityCheck | Table | EXISTS check + UPDATE or INSERT based on CID presence |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eIDV integration service | External | Calls after receiving provider result to persist the verification outcome |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Record a successful two-source eIDV match (GBGroup)
```sql
EXEC BackOffice.SetElectronicIdentityCheck
    @CID                        = 12345678,
    @ElectronicIdentityCheckID  = 2,        -- Two Sources (full match)
    @ElectronicIdentityProviderID = 2,      -- GBGroup
    @TransactionID              = 'GB-TX-987654321',
    @TransactionDate            = '2024-03-15 10:30:00'
```

### 8.2 Record a no-match result (GDC, no transaction reference)
```sql
EXEC BackOffice.SetElectronicIdentityCheck
    @CID                        = 12345678,
    @ElectronicIdentityCheckID  = 3,        -- No Match
    @ElectronicIdentityProviderID = 1,      -- GDC
    @TransactionID              = NULL,
    @TransactionDate            = NULL
```

### 8.3 View eIDV results by provider and outcome
```sql
SELECT
    eic.ElectronicIdentityCheckID,
    eic.ElectronicIdentityProviderID,
    COUNT(*) AS CustomerCount
FROM BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
GROUP BY eic.ElectronicIdentityCheckID, eic.ElectronicIdentityProviderID
ORDER BY eic.ElectronicIdentityProviderID, eic.ElectronicIdentityCheckID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetElectronicIdentityCheck | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetElectronicIdentityCheck.sql*
