# History.MoveRecsFromHistorySyncTSLToPass_BCP

> TSL pipeline Stage 3 BCP transfer procedure - exports History.SyncTSLSwitch to a network file via BCP queryout, then bulk-imports into the Azure SyncTSL database using encrypted credentials, with row count verification and file cleanup on success.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - executes a complete BCP export+import cycle |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.MoveRecsFromHistorySyncTSLToPass_BCP` is the BCP-based Stage 3 transfer for eToro's TSL (Trailing Stop Loss) event pipeline. It is the alternative to `History.MoveRecsFromDagSyncTslToPass` (which uses linked server INSERT). After `ALTER TABLE History.SyncTSL SWITCH TO History.SyncTSLSwitch` populates the switch table, this procedure exports all rows from `History.SyncTSLSwitch` to a timestamped BCP file on the network backup share (`\\AZR-W-DBBCKUP-1\DB_Backup\BCP\`), then imports that file into the `History.SyncTSL` table on the Azure SQL database `synctsl.database.windows.net`.

The procedure uses `xp_cmdshell` to invoke the BCP command-line utility from within SQL Server. Destination credentials for the Azure SQL server are encrypted in the database using a Symmetric Key (`ArchiveConnectionPasswordsKey`) protected by a certificate (`CERT_EncryptArchiveConnectionPasswords`). The key is opened at runtime and the credentials are decrypted inline within the BCP command string.

After both BCP operations complete, the procedure verifies that the row counts match. If they match and are non-zero, it deletes the temporary BCP file and returns 1 (success). If the counts don't match or are zero/null, it returns 0 (failure) and the BCP file is retained for investigation.

---

## 2. Business Logic

### 2.1 Two-Phase BCP Transfer

**What**: Two sequential xp_cmdshell BCP commands: first export from SQL Server to file, then import from file to Azure SQL.

**Columns/Parameters Involved**: `@BCPPath`, `@strQuery`, `@Rows_BCP_Source`, `@Rows_BCP_Destination`

**Rules**:
- Phase 1 (queryout): `BCP "select A.ID, A.PositionID, A.StopLoss, A.SLManualVer, A.NextThresHold, A.IsBuy, A.DateInserted from History.SyncTSLSwitch A" queryout "@BCPPath" -S"@@SERVERNAME" -T -d"etoro" -n`
  - -T: Windows authentication (trusted connection)
  - -n: native format (binary BCP file)
  - File path: `\\AZR-W-DBBCKUP-1\DB_Backup\BCP\HistorySyncTSL_{yyyyMMdd_HHmmss}.bcp`
- Phase 2 (in): `BCP "History.SyncTSL" in "@BCPPath" -S"synctsl.database.windows.net" -U"{decrypted_user}" -P"{decrypted_password}" -d"SyncTsl" -n -b100000`
  - -b100000: batch size 100,000 rows per BCP batch
  - Username and password decrypted at runtime via CONVERT(varchar, DecryptByKey(...))
- Both phases capture output via #LogExport2File and #LogImport2File temp tables
- Row count extraction: `SELECT ... CAST(... replace(Log_Output,' rows copied.','') ...) AS INT)` from the BCP output line matching '% rows copied.'

### 2.2 Encrypted Credential Management

**What**: Azure SQL connection credentials are stored in encrypted form in the database and decrypted at runtime for the BCP command.

**Columns/Parameters Involved**: `@strQuery`, `ArchiveConnectionPasswordsKey`, `CERT_EncryptArchiveConnectionPasswords`

**Rules**:
- `OPEN SYMMETRIC KEY ArchiveConnectionPasswordsKey DECRYPTION BY CERTIFICATE CERT_EncryptArchiveConnectionPasswords` - opens the symmetric key using the certificate
- Username: `CONVERT(varchar(max), DecryptByKey(0x00BED14F...))` - decrypts the stored encrypted username blob
- Password: `CONVERT(varchar(max), DecryptByKey(0x00BED14F...))` - decrypts the stored encrypted password blob
- Key is not explicitly closed after use (session-scoped automatic cleanup)
- The decrypted credentials are embedded directly into the BCP command string via CONCAT

### 2.3 Row Count Verification and File Cleanup

**What**: After both BCP phases complete, row counts are compared to verify the transfer was complete and successful.

**Columns/Parameters Involved**: `@Rows_BCP_Source`, `@Rows_BCP_Destination`, `@ISBCPSuccessful`

**Rules**:
- IF @Rows_BCP_Source > 0 AND ISNULL(@Rows_BCP_Source, -1) = ISNULL(@Rows_BCP_Destination, -2):
  - Row counts match AND source is non-zero -> @ISBCPSuccessful = 1 (Success)
  - Delete the BCP file: `DEL "@BCPPath"` via xp_cmdshell
- ELSE: @ISBCPSuccessful = 0 (Fail) - file retained for investigation
- RETURN @ISBCPSuccessful - caller checks return code
- ISNULL(@Rows_BCP_Source, -1) = ISNULL(@Rows_BCP_Destination, -2) handles NULLs: if both are NULL they get -1 and -2 respectively, so they don't match (failure)

**Diagram**:
```
History.SyncTSLSwitch
  (populated by TABLE SWITCH from History.SyncTSL)
        |
        v
Phase 1: BCP queryout -> \\AZR-W-DBBCKUP-1\...\HistorySyncTSL_yyyyMMdd.bcp
  Capture @Rows_BCP_Source from "N rows copied." output
        |
        v
Open Symmetric Key -> Decrypt credentials
        |
        v
Phase 2: BCP in -> synctsl.database.windows.net/SyncTsl/History.SyncTSL
  Capture @Rows_BCP_Destination from "N rows copied." output
        |
        v
IF @Rows_BCP_Source > 0 AND source_count == dest_count:
  DEL BCP file -> RETURN 1 (Success)
ELSE:
  Keep BCP file -> RETURN 0 (Failure)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters (the commented-out `@ISBCPSuccessful int output` was removed).

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No input parameters. Returns 1 (success) or 0 (failure) via RETURN code. Also outputs diagnostic SELECT statements showing @BCPPath, the constructed BCP command string, and the @Rows_BCP_Source / @Rows_BCP_Destination counts.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.SyncTSLSwitch | Reads | BCP queryout source - all rows exported to file; accessed via xp_cmdshell BCP command |
| (body) | synctsl.database.windows.net/SyncTsl/History.SyncTSL | Writes (BCP in via xp_cmdshell) | Azure SQL destination for the TSL event records |
| (body) | ArchiveConnectionPasswordsKey | Symmetric Key | Opened to decrypt Azure SQL credentials |
| (body) | CERT_EncryptArchiveConnectionPasswords | Certificate | Used to decrypt the ArchiveConnectionPasswordsKey |
| (body) | \\AZR-W-DBBCKUP-1\DB_Backup\BCP\ | File Share | Intermediate storage for the BCP file between export and import |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TSL pipeline coordinator (SQL Agent job) | - | Caller | Executed as a Stage 3 job step after the TABLE SWITCH; no callers found in SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MoveRecsFromHistorySyncTSLToPass_BCP (procedure)
+-- History.SyncTSLSwitch (table - BCP export source)
+-- ArchiveConnectionPasswordsKey (symmetric key - credential decryption)
+-- CERT_EncryptArchiveConnectionPasswords (certificate - key protection)
+-- \\AZR-W-DBBCKUP-1\... (network file share - BCP intermediate file)
+-- synctsl.database.windows.net (Azure SQL - BCP import target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SyncTSLSwitch | Table | BCP queryout source (via xp_cmdshell) |
| ArchiveConnectionPasswordsKey | Symmetric Key | Opened to decrypt Azure SQL credentials at runtime |
| CERT_EncryptArchiveConnectionPasswords | Certificate | Provides decryption key for the symmetric key |

### 6.2 Objects That Depend On This

No callers found in the etoro SSDT repository. Called by the TSL pipeline coordinator.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Commented-out parameter: `--(@ISBCPSuccessful int output)` - at some point the return value was going to be an OUTPUT parameter but was changed to RETURN
- Diagnostic SELECTs: `Select @BCPPath`, `SELECT @strQuery` are inline diagnostic statements that return the file path and the BCP command string as result sets to the caller - useful for debugging but returned unconditionally
- xp_cmdshell is required and must be enabled on the SQL Server instance for this procedure to function
- BCP file naming: `HistorySyncTSL_{yyyyMMdd_HHmmss}.bcp` - timestamped to prevent collisions and enable investigation of failed transfers by file date
- Row count NULL handling: the ISNULL pattern guards against BCP output not containing the "N rows copied." line (produces NULL counts)
- No explicit transaction - each xp_cmdshell call is independent; partial failure leaves the BCP file on disk for retry
- Alternative: History.MoveRecsFromDagSyncTslToPass uses linked server INSERT for the same data transfer (no BCP, no external file system dependency)

---

## 8. Sample Queries

### 8.1 Execute the BCP transfer and check the return code

```sql
DECLARE @result INT
EXEC @result = History.MoveRecsFromHistorySyncTSLToPass_BCP
SELECT @result AS BCPSuccessful  -- 1=Success, 0=Failure
```

### 8.2 Check SyncTSLSwitch before triggering the BCP procedure

```sql
-- Verify the TABLE SWITCH has populated SyncTSLSwitch
SELECT
    COUNT(*) AS RowCount,
    MIN(ID) AS MinID,
    MAX(ID) AS MaxID,
    MIN(DateInserted) AS EarliestEvent,
    MAX(DateInserted) AS LatestEvent
FROM History.SyncTSLSwitch WITH (NOLOCK)
```

### 8.3 View the source data that will be BCP'd

```sql
SELECT TOP 10
    ID,
    PositionID,
    StopLoss,
    SLManualVer,
    NextThresHold,
    IsBuy,
    DateInserted
FROM History.SyncTSLSwitch WITH (NOLOCK)
ORDER BY ID ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.MoveRecsFromHistorySyncTSLToPass_BCP | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.MoveRecsFromHistorySyncTSLToPass_BCP.sql*
