# Billing.UpdateSecuredCard

> PCI key-rotation migration procedure that batch re-encrypts the SecuredCardDataAsString field in all pending Billing.Funding XML records with a new encryption key, processing 3500 rows per iteration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (operates on Billing.FundingDataMigration batch) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

eToro is a PCI DSS Level 1 merchant, obligated to rotate its encryption keys on a yearly basis. During key rotation, all credit card data encrypted with the old key must be re-encrypted with the new AES-256 key. `Billing.UpdateSecuredCard` is the DB-side engine for this re-encryption migration.

The procedure runs `WITH EXECUTE AS OWNER` (elevated permissions) and operates in a WHILE loop, processing batches of 3500 records at a time until all pending migration records are complete. For each batch: it reads the new encrypted card data from `Billing.FundingDataMigration` (pre-populated before migration starts), uses SQL Server XML `.modify()` to replace the `SecuredCardDataAsString` node inside `Billing.Funding.FundingData` XML, marks the processed records as done (MigrationStatus=3), and clears the batch tracking table before the next iteration.

The migration is run during a maintenance window with credit card operations suspended. The `PCI_Rotation` database role has execute permission on this procedure.

The `SecuredCardDataAsString` field inside `Billing.Funding.FundingData` XML stores the AES-256 encrypted card token. During PCI key rotation, the new encrypted value (re-encrypted with the new key) is pre-computed externally and loaded into `Billing.FundingDataMigration.SecuredCardData`, from which this procedure reads and applies the update.

---

## 2. Business Logic

### 2.1 Batch Re-encryption WHILE Loop

**What**: Processes all pending `FundingDataMigration` records in batches of 3500, replacing the XML-embedded encrypted card token with a new ciphertext.

**Columns/Parameters Involved**: `Billing.FundingDataMigration.MigrationStatus`, `Billing.FundingDataMigration.SecuredCardData`, `Billing.Funding.FundingData` (XML)

**Rules**:
- Loop condition: `EXISTS (SELECT 1 FROM Billing.FundingDataMigration WHERE MigrationStatus = 1)` - continues while there are pending records
- Step 1: Insert TOP 3500 FundingIDs with MigrationStatus=1 into `Billing.CurrentFundingDataMigrated` (batch scratch table)
- Step 2: UPDATE `Billing.Funding.FundingData` XML using `.modify('replace value of (/Funding/SecuredCardDataAsString/text())[1] with sql:column("T.SecuredCardData")')` for all FundingIDs in the batch
- Step 3: UPDATE `Billing.FundingDataMigration SET MigrationStatus=3` for processed IDs (marks as done)
- Step 4: `TRUNCATE TABLE Billing.CurrentFundingDataMigrated` - resets batch tracker for next iteration
- Repeat until loop condition is false

**Diagram**:
```
Pre-migration setup (done externally before calling this SP):
  FundingDataMigration populated with:
    (FundingID, SecuredCardData=<new_encrypted_value>, MigrationStatus=1)

WHILE EXISTS(MigrationStatus=1):
  Step 1: INSERT TOP 3500 into CurrentFundingDataMigrated
  Step 2: UPDATE Billing.Funding.FundingData XML
            SET /Funding/SecuredCardDataAsString = new encrypted value
  Step 3: UPDATE FundingDataMigration SET MigrationStatus=3
  Step 4: TRUNCATE CurrentFundingDataMigrated
  (repeat)
```

### 2.2 MigrationStatus State Machine

**What**: `Billing.FundingDataMigration.MigrationStatus` tracks the state of each record through the re-encryption process.

**Rules**:
- 1 = Pending migration (ready to process)
- 3 = Migration complete (set by this procedure after successful update)
- Other values (0, 2, etc.) may be used by supporting procedures (`RotateEncryptionKey`, `RollbackPCIRotation`) for different lifecycle states
- This procedure only reads MigrationStatus=1 and writes MigrationStatus=3

### 2.3 XML Modification Pattern

**What**: SQL Server's XML `.modify()` method is used to update a single XML node in-place without deserializing the entire XML document.

**Rules**:
- XPath target: `/Funding/SecuredCardDataAsString/text()[1]` - the first text node of SecuredCardDataAsString
- Source: `sql:column("T.SecuredCardData")` - pulls the new encrypted value from the joined FundingDataMigration row
- This is an in-place XML update - the rest of `FundingData` XML structure is untouched
- `SecuredCardDataAsString` = the AES-256 encrypted card token; contains the encrypted PAN after key rotation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It operates on predefined tables.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. The procedure reads from `Billing.FundingDataMigration` (MigrationStatus=1) and updates `Billing.Funding.FundingData` XML. All inputs are pre-staged in the migration tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | Billing.FundingDataMigration | READ + UPDATE | Reads pending records (MigrationStatus=1); marks processed records as MigrationStatus=3 |
| (internal) | Billing.Funding | UPDATE (XML) | Replaces SecuredCardDataAsString XML node with new encrypted value |
| (internal) | Billing.CurrentFundingDataMigrated | INSERT + TRUNCATE | Batch scratch table: holds current batch of FundingIDs being processed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PCI_Rotation role (permission grant) | - | GRANT EXECUTE | PCI rotation process calls this during annual key rotation maintenance window |
| PROD_BIadmins role (permission grant) | - | GRANT EXECUTE | BI admins can also run this |
| PROD_SQL_Billing role (permission grant) | - | GRANT EXECUTE | Billing SQL role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateSecuredCard (procedure)
├── Billing.FundingDataMigration (table) [READ + UPDATE]
├── Billing.Funding (table) [UPDATE XML]
└── Billing.CurrentFundingDataMigrated (table) [INSERT + TRUNCATE - batch scratch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingDataMigration | Table | Source of new encrypted card data; MigrationStatus=1 rows are processed, set to 3 when done |
| Billing.Funding | Table | Target of XML update: FundingData.SecuredCardDataAsString is replaced with new encrypted value |
| Billing.CurrentFundingDataMigrated | Table | Batch scratch table: holds the current 3500-row batch being processed; TRUNCATED each iteration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PCI key rotation process | Operations | Called once per year during PCI maintenance window to complete the card data re-encryption |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Security | Runs with elevated permissions to access PCI-sensitive tables and perform XML modification |
| Batch size | Logic | TOP 3500 per iteration - controls memory and lock duration during migration |
| No transaction wrapper | Design | Each batch is committed independently (no outer transaction); partial completion is recoverable - re-running restarts from the next MigrationStatus=1 batch |

---

## 8. Sample Queries

### 8.1 Check migration progress
```sql
SELECT
    MigrationStatus,
    COUNT(*) AS RecordCount
FROM Billing.FundingDataMigration WITH (NOLOCK)
GROUP BY MigrationStatus
ORDER BY MigrationStatus;
-- 1 = Pending, 3 = Complete
```

### 8.2 Verify current batch tracker is empty (safe to run)
```sql
SELECT COUNT(*) AS BatchTrackerRows
FROM Billing.CurrentFundingDataMigrated WITH (NOLOCK);
-- Should be 0 before starting migration
```

### 8.3 Check a sample of the post-migration XML to verify re-encryption
```sql
SELECT TOP 5
    f.FundingID,
    f.FundingData.value('(Funding/SecuredCardDataAsString)[1]', 'VARCHAR(500)') AS SecuredCardDataAsString,
    fdm.MigrationStatus
FROM Billing.Funding f WITH (NOLOCK)
JOIN Billing.FundingDataMigration fdm WITH (NOLOCK)
    ON fdm.FundingID = f.FundingID
WHERE fdm.MigrationStatus = 3;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PCI Key Rotation](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/11955536253/PCI+Key+Rotation) | Confluence | eToro is PCI Level 1; annual key rotation required; SecuredCardDataAsString stores AES-256 encrypted card token in FundingData XML; rotation runs during maintenance mode with CC operations suspended |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 9.0/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateSecuredCard | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateSecuredCard.sql*
