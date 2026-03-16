"""
Fact_BillingDeposit — UC External Lineage Injection
====================================================
Generated: 2026-03-15
Injects Synapse DWH lineage into Unity Catalog for DWH_dbo.Fact_BillingDeposit.

Resolves ALL bronze table names dynamically from the Generic Pipeline
mapping view — falls back to FALLBACK_BRONZE when mapping returns invalid
values (e.g. "internal-sources").  Verifies every UC object exists before
creating lineage.  On any error: logs, skips the failed item, and continues.
Produces a summary report at the end.

Prerequisites:
  pip install databricks-sdk
  databricks auth login --profile guyman   (if token expired)

Privileges required:
  CREATE EXTERNAL METADATA  on metastore
  MODIFY                    on main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
  SELECT                    on bronze source tables
  SELECT                    on main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables

Usage:
  python Fact_BillingDeposit.lineage.py              # dry run (default)
  python Fact_BillingDeposit.lineage.py --execute   # actually write to UC
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from dataclasses import dataclass, field
from typing import Optional

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.catalog import (
    ColumnRelationship,
    CreateRequestExternalLineage,
    ExternalLineageExternalMetadata,
    ExternalLineageObject,
    ExternalLineageTable,
    ExternalMetadata,
    SystemType,
)
from databricks.sdk.service.sql import StatementState

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("lineage-fact-billingdeposit")

# ── Configuration ─────────────────────────────────────────────────────

HOST = "https://adb-5142916747090026.6.azuredatabricks.net"
WAREHOUSE_ID = "208214768b0e0308"
PROFILE = "guyman"
WAIT_TIMEOUT = "50s"

UC_GOLD_TABLE = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit"
SYNAPSE_SCHEMA = "DWH_dbo"
SYNAPSE_TABLE = "Fact_BillingDeposit"

MAPPING_VIEW = "main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables"

# Production sources that feed Fact_BillingDeposit through the main ETL SP.
# Schema.Table as they appear in the production (etoro) database.
# The script resolves each to a UC bronze table via the mapping view.
PRODUCTION_SOURCES = [
    {"database": "etoro", "schema": "Billing", "table": "Deposit"},
    {"database": "etoro", "schema": "Billing", "table": "Funding_DataFactory"},
]

# Fallback when mapping view returns invalid UnityCatalogTableName (e.g. "internal-sources")
FALLBACK_BRONZE = {
    "Billing.Deposit": "main.billing.bronze_etoro_billing_deposit",
    "Billing.Funding_DataFactory": "main.billing.bronze_etoro_billing_funding_datafactory",
}

# ETL stored procedures
SYNAPSE_SPS = [
    {
        "name": "synapse__dwh_dbo__sp_fact_billingdeposit_dl_to_synapse",
        "entity_type": "Stored Procedure",
        "description": (
            "Main ETL procedure for DWH_dbo.Fact_BillingDeposit. "
            "Loads from Billing.Deposit and Billing.Funding via DWH_staging, "
            "extracts ~70 columns from XML blobs (PaymentData, FundingData) "
            "using ExtractXMLValue function. Computes AmountUSD, ExpirationDateID, "
            "ModificationDateID. Writes to Ext_FBD_Fact_BillingDeposit staging buffer."
        ),
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Fact_BillingDeposit_DL_To_Synapse",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "incremental",
        },
    },
    {
        "name": "synapse__dwh_dbo__sp_fact_billingdeposit",
        "entity_type": "Stored Procedure",
        "description": (
            "Post-processing SP for DWH_dbo.Fact_BillingDeposit. "
            "Enriches MOPCountry (from Dim_Country), BankName and CardCategory "
            "(from Dim_CountryBin), PlatformID (from Fact_CustomerAction), "
            "and IsRecurring (from Billing.RecurringDeposit)."
        ),
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Fact_BillingDeposit",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "post-load enrichment",
        },
    },
]

MAIN_SP = "synapse__dwh_dbo__sp_fact_billingdeposit_dl_to_synapse"

# Column-level lineage: production source column → DWH column.
# Keyed by "Schema.Table".
COLUMN_MAPPINGS_BY_SOURCE = {
    "Billing.Deposit": [
        ("CID", "CID"),
        ("CurrencyID", "CurrencyID"),
        ("Commission", "Commission"),
        ("Approved", "Approved"),
        ("ModificationDate", "ModificationDate"),
        ("FundingID", "FundingID"),
        ("ExchangeRate", "ExchangeRate"),
        ("DepositID", "DepositID"),
        ("ProcessorValueDate", "ProcessorValueDate"),
        ("DepotID", "DepotID"),
        ("PaymentStatusID", "PaymentStatusID"),
        ("ManagerID", "ManagerID"),
        ("RiskManagementStatusID", "RiskManagementStatusID"),
        ("Amount", "Amount"),
        ("PaymentDate", "PaymentDate"),
        ("IPAddress", "IPAddress"),
        ("ClearingHouseEffectiveDate", "ClearingHouseEffectiveDate"),
        ("IsFTD", "IsFTD"),
        ("RefundVerificationCode", "RefundVerificationCode"),
        ("MatchStatusID", "MatchStatusID"),
        ("BonusStatusID", "BonusStatusID"),
        ("BonusAmount", "BonusAmount"),
        ("BonusErrorCode", "BonusErrorCode"),
        ("ExTransactionID", "ExTransactionID"),
        ("FundingTypeID", "FundingTypeID"),
        ("IsRefundExcluded", "IsRefundExcluded"),
        ("DocumentRequired", "DocumentRequired"),
        ("BaseExchangeRate", "BaseExchangeRate"),
        ("ExchangeFee", "ExchangeFee"),
        ("ProtocolMIDSettingsID", "ProtocolMIDSettingsID"),
        ("FunnelID", "FunnelID"),
        ("SessionID", "SessionID"),
        ("PaymentGeneration", "PaymentGeneration"),
        ("ProcessRegulationID", "ProcessRegulationID"),
        ("MerchantAccountID", "MerchantAccountID"),
        ("IsSetBalanceCompleted", "IsSetBalanceCompleted"),
        ("RoutingReasonID", "RoutingReasonID"),
        ("FlowID", "FlowID"),
        ("IsAftSupportedAsBool", "IsAftSupportedAsBool"),
        ("IsAftEligibleAsBool", "IsAftEligibleAsBool"),
        ("IsAftProcessedAsBool", "IsAftProcessedAsBool"),
    ],
    "Billing.Funding_DataFactory": [],
}

# Post-load SP columns (the columns modified by SP_Fact_BillingDeposit)
POST_LOAD_SP_COLUMNS = {
    "synapse__dwh_dbo__sp_fact_billingdeposit": [
        "MOPCountry", "BankName", "CardCategory", "PlatformID", "IsRecurring",
    ],
}


# ── Report tracking ──────────────────────────────────────────────────

@dataclass
class Report:
    resolved: list[str] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)
    created: list[str] = field(default_factory=list)
    existed: list[str] = field(default_factory=list)
    failed: list[str] = field(default_factory=list)

    def print_summary(self):
        log.info("=" * 60)
        log.info("LINEAGE INJECTION REPORT — Fact_BillingDeposit")
        log.info("=" * 60)
        log.info("Resolved:  %d", len(self.resolved))
        for r in self.resolved:
            log.info("  OK  %s", r)
        if self.skipped:
            log.warning("Skipped:   %d", len(self.skipped))
            for s in self.skipped:
                log.warning("  SKIP  %s", s)
        log.info("Created:   %d", len(self.created))
        for c in self.created:
            log.info("  NEW  %s", c)
        if self.existed:
            log.info("Existed:   %d", len(self.existed))
        if self.failed:
            log.error("Failed:    %d", len(self.failed))
            for f in self.failed:
                log.error("  FAIL  %s", f)
        log.info("=" * 60)


# ── SQL execution via Statement Execution API ─────────────────────────

def run_sql(w: WorkspaceClient, query: str) -> Optional[list[dict]]:
    """Execute SQL and return rows as list of dicts.  Returns None on error."""
    try:
        response = w.statement_execution.execute_statement(
            warehouse_id=WAREHOUSE_ID,
            statement=query,
            wait_timeout=WAIT_TIMEOUT,
        )
    except Exception as e:
        log.error("SQL execution error: %s\n  Query: %s", e, query[:200])
        return None

    if response.status.state == StatementState.SUCCEEDED:
        if response.result is None or response.manifest is None:
            return []
        columns = [col.name for col in response.manifest.schema.columns]
        rows = response.result.data_array or []
        return [dict(zip(columns, row)) for row in rows]

    if response.status.state == StatementState.FAILED:
        err = response.status.error
        msg = err.message if err else "Unknown"
        log.error("SQL failed: %s\n  Query: %s", msg, query[:200])
        return None

    log.error("SQL unexpected state: %s", response.status.state)
    return None


def _is_invalid_uc_table_name(name: str) -> bool:
    """Check if UnityCatalogTableName from mapping view is invalid (e.g. internal-sources)."""
    if not name or not str(name).strip():
        return True
    n = str(name).strip().lower()
    if n in ("internal-sources", "internal", ""):
        return True
    if n.startswith("internal-") or n.startswith("internal_"):
        return True
    if "." in n or " " in n:
        return True
    return False


def _try_fallback_bronze(
    w: WorkspaceClient,
    schema: str,
    table: str,
    label: str,
    report: Report,
) -> Optional[str]:
    """Try FALLBACK_BRONZE when mapping view fails or returns invalid values."""
    key = f"{schema}.{table}"
    fallback_uc = FALLBACK_BRONZE.get(key)
    if not fallback_uc:
        return None
    verify = run_sql(w, f"DESCRIBE TABLE {fallback_uc}")
    if verify is None:
        return None
    report.resolved.append(f"{label} → {fallback_uc} (fallback)")
    return fallback_uc


# ── Resolution functions ──────────────────────────────────────────────

def resolve_bronze_table(
    w: WorkspaceClient,
    database: str,
    schema: str,
    table: str,
    report: Report,
) -> Optional[str]:
    """Query the Generic Pipeline mapping view to find the UC bronze table.
    Falls back to FALLBACK_BRONZE when mapping returns invalid values
    (e.g. 'internal-sources'). Returns the fully qualified UC table name or None."""

    label = f"{schema}.{table} ({database})"
    query = (
        f"SELECT UnityCatalogTableName, BusinessGroup "
        f"FROM {MAPPING_VIEW} "
        f"WHERE TableName = '{table}' "
        f"  AND SchemaName = '{schema}' "
        f"  AND DatabaseName = '{database}'"
    )
    rows = run_sql(w, query)

    if rows is None:
        uc_fqn = _try_fallback_bronze(w, schema, table, label, report)
        if uc_fqn:
            return uc_fqn
        report.skipped.append(f"{label} — mapping view query failed")
        return None

    if len(rows) == 0:
        uc_fqn = _try_fallback_bronze(w, schema, table, label, report)
        if uc_fqn:
            return uc_fqn
        report.skipped.append(f"{label} — no mapping found in Generic Pipeline")
        return None

    if len(rows) > 1:
        log.warning(
            "Multiple mappings for %s — using first: %s",
            label,
            json.dumps(rows, default=str),
        )

    row = rows[0]
    uc_table_name = row.get("UnityCatalogTableName")
    business_group = row.get("BusinessGroup")

    if not uc_table_name or not business_group:
        uc_fqn = _try_fallback_bronze(w, schema, table, label, report)
        if uc_fqn:
            return uc_fqn
        report.skipped.append(f"{label} — mapping row missing UnityCatalogTableName or BusinessGroup")
        return None

    if _is_invalid_uc_table_name(uc_table_name):
        uc_fqn = _try_fallback_bronze(w, schema, table, label, report)
        if uc_fqn:
            return uc_fqn
        report.skipped.append(
            f"{label} — mapping returned invalid UnityCatalogTableName: {uc_table_name}"
        )
        return None

    uc_fqn = f"main.{business_group}.{uc_table_name}"

    # Verify the table actually exists in UC
    verify = run_sql(w, f"DESCRIBE TABLE {uc_fqn}")
    if verify is None:
        uc_fqn = _try_fallback_bronze(w, schema, table, label, report)
        if uc_fqn:
            return uc_fqn
        report.skipped.append(
            f"{label} — resolved to {uc_fqn} but DESCRIBE failed (table may not exist or no access)"
        )
        return None

    report.resolved.append(f"{label} → {uc_fqn}")
    return uc_fqn


def resolve_gold_table(w: WorkspaceClient, report: Report) -> Optional[str]:
    """Verify the gold UC table exists."""
    verify = run_sql(w, f"DESCRIBE TABLE {UC_GOLD_TABLE}")
    if verify is None:
        report.failed.append(f"Gold table {UC_GOLD_TABLE} — DESCRIBE failed")
        return None
    report.resolved.append(f"Gold table: {UC_GOLD_TABLE}")
    return UC_GOLD_TABLE


def get_gold_columns(w: WorkspaceClient) -> list[str]:
    """Get the actual column list from the gold table."""
    rows = run_sql(w, f"DESCRIBE TABLE {UC_GOLD_TABLE}")
    if rows is None:
        return []
    cols = []
    for row in rows:
        col_name = row.get("col_name", "")
        if col_name and not col_name.startswith("#") and col_name not in ("", " "):
            data_type = row.get("data_type", "")
            if data_type and data_type not in ("", " "):
                cols.append(col_name)
    return cols


# ── External metadata helpers ─────────────────────────────────────────

def ext_meta_exists(w: WorkspaceClient, name: str) -> bool:
    try:
        w.external_metadata.get_external_metadata(name)
        return True
    except Exception:
        return False


def create_or_skip_metadata(
    w: WorkspaceClient,
    meta: dict,
    dry_run: bool,
    report: Report,
):
    name = meta["name"]

    if ext_meta_exists(w, name):
        report.existed.append(f"ext-meta: {name}")
        log.info("EXISTS  external metadata: %s", name)
        return True

    obj = ExternalMetadata(
        name=name,
        system_type=SystemType.AZURE_SYNAPSE,
        entity_type=meta["entity_type"],
        description=meta.get("description"),
        properties=meta.get("properties"),
        columns=meta.get("columns"),
    )

    if dry_run:
        report.created.append(f"ext-meta: {name} (dry run)")
        log.info("DRY RUN  would create: %s", name)
        return True

    try:
        result = w.external_metadata.create_external_metadata(obj)
        report.created.append(f"ext-meta: {name} (id={result.id})")
        log.info("CREATED  %s (id=%s)", name, result.id)
        return True
    except Exception as e:
        report.failed.append(f"ext-meta: {name} — {e}")
        log.error("FAILED  creating %s: %s", name, e)
        return False


def create_or_skip_lineage(
    w: WorkspaceClient,
    source: ExternalLineageObject,
    target: ExternalLineageObject,
    columns: list[ColumnRelationship],
    props: dict[str, str],
    label: str,
    dry_run: bool,
    report: Report,
):
    n_cols = len(columns) if columns else 0

    if dry_run:
        report.created.append(f"lineage: {label} ({n_cols} cols, dry run)")
        log.info("DRY RUN  would create lineage: %s (%d col mappings)", label, n_cols)
        return True

    req = CreateRequestExternalLineage(
        source=source,
        target=target,
        columns=columns if columns else None,
        properties=props,
    )

    try:
        result = w.external_lineage.create_external_lineage_relationship(req)
        report.created.append(f"lineage: {label} ({n_cols} cols, id={result.id})")
        log.info("CREATED  lineage: %s (%d cols, id=%s)", label, n_cols, result.id)
        return True
    except Exception as e:
        err_str = str(e)
        if "ALREADY_EXISTS" in err_str:
            report.existed.append(f"lineage: {label}")
            log.info("EXISTS   lineage: %s", label)
            return True
        report.failed.append(f"lineage: {label} — {e}")
        log.error("FAILED   lineage: %s — %s", label, e)
        return False


# ============================== main =======================================

def main():
    parser = argparse.ArgumentParser(
        description="Inject Fact_BillingDeposit lineage into Unity Catalog"
    )
    parser.add_argument(
        "--execute", action="store_true",
        help="Actually write to UC (default: dry run)",
    )
    args = parser.parse_args()
    dry_run = not args.execute
    report = Report()

    banner = "DRY RUN MODE — no changes will be written" if dry_run else "EXECUTE MODE — writing to Unity Catalog"
    log.info("=== %s ===", banner)

    w = WorkspaceClient(host=HOST, profile=PROFILE)
    log.info("Connected to %s (profile=%s)", HOST, PROFILE)

    # ==================================================================
    # Phase A: Resolution — query UC to resolve all objects
    # ==================================================================
    log.info("--- Phase A: Resolving UC objects ---")

    # A1: Verify gold table
    gold = resolve_gold_table(w, report)
    if gold is None:
        log.error("FATAL: Gold table %s not accessible. Aborting.", UC_GOLD_TABLE)
        report.print_summary()
        sys.exit(1)

    # A2: Get actual column list from gold table
    gold_columns = get_gold_columns(w)
    if not gold_columns:
        log.error("FATAL: Could not read columns from %s. Aborting.", UC_GOLD_TABLE)
        report.print_summary()
        sys.exit(1)
    log.info("Gold table has %d columns", len(gold_columns))

    # A3: Resolve bronze tables from the Generic Pipeline mapping view (with fallback)
    bronze_resolved: dict[str, str] = {}  # "Schema.Table" → UC FQN
    for src in PRODUCTION_SOURCES:
        key = f"{src['schema']}.{src['table']}"
        uc_fqn = resolve_bronze_table(
            w, src["database"], src["schema"], src["table"], report
        )
        if uc_fqn:
            bronze_resolved[key] = uc_fqn

    log.info(
        "Resolved %d/%d bronze sources",
        len(bronze_resolved), len(PRODUCTION_SOURCES),
    )

    # ==================================================================
    # Phase B: Create external metadata objects
    # ==================================================================
    log.info("--- Phase B: External metadata objects ---")

    # B1: Synapse table
    synapse_table_meta = {
        "name": "synapse__dwh_dbo__fact_billingdeposit",
        "entity_type": "Table",
        "description": (
            "Synapse DWH table: DWH_dbo.Fact_BillingDeposit. "
            "Central deposit fact table recording every monetary deposit attempt. "
            "136 columns including ~70 XML-extracted payment provider fields."
        ),
        "columns": gold_columns,
        "properties": {
            "synapse_schema": SYNAPSE_SCHEMA,
            "synapse_object": SYNAPSE_TABLE,
            "synapse_server": "sql_dp_prod_we",
            "object_type": "USER_TABLE",
            "refresh": "daily",
            "distribution": "HASH(DepositID)",
            "documented_by": "dwh-semantic-doc pipeline",
        },
    }
    create_or_skip_metadata(w, synapse_table_meta, dry_run, report)

    # B2: ETL stored procedures
    for sp in SYNAPSE_SPS:
        create_or_skip_metadata(w, sp, dry_run, report)

    # ==================================================================
    # Phase C: Lineage — Bronze → Main SP
    # ==================================================================
    log.info("--- Phase C: Lineage — Bronze → Synapse SP ---")

    sp_target = ExternalLineageObject(
        external_metadata=ExternalLineageExternalMetadata(name=MAIN_SP)
    )

    for source_key, uc_bronze in bronze_resolved.items():
        col_tuples = COLUMN_MAPPINGS_BY_SOURCE.get(source_key, [])
        columns = [
            ColumnRelationship(source=src, target=tgt)
            for src, tgt in col_tuples
        ]
        source_obj = ExternalLineageObject(
            table=ExternalLineageTable(name=uc_bronze)
        )
        label = f"{uc_bronze} → {MAIN_SP}"

        create_or_skip_lineage(
            w, source_obj, sp_target, columns,
            props={
                "relationship_type": "etl_source",
                "source_production_table": source_key,
            },
            label=label,
            dry_run=dry_run,
            report=report,
        )

    # ==================================================================
    # Phase D: Lineage — Main SP → Gold table
    # ==================================================================
    log.info("--- Phase D: Lineage — Synapse SP → Gold table ---")

    sp_source = ExternalLineageObject(
        external_metadata=ExternalLineageExternalMetadata(name=MAIN_SP)
    )
    gold_target = ExternalLineageObject(
        table=ExternalLineageTable(name=UC_GOLD_TABLE)
    )
    sp_to_gold_cols = [
        ColumnRelationship(source=c, target=c) for c in gold_columns
    ]

    create_or_skip_lineage(
        w, sp_source, gold_target, sp_to_gold_cols,
        props={
            "relationship_type": "etl_target",
            "description": (
                "SP_Fact_BillingDeposit_DL_To_Synapse writes to "
                "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit "
                "via Generic Pipeline delta export"
            ),
        },
        label=f"{MAIN_SP} → {UC_GOLD_TABLE}",
        dry_run=dry_run,
        report=report,
    )

    # ==================================================================
    # Phase E: Lineage — Post-load SPs → Gold table
    # ==================================================================
    log.info("--- Phase E: Lineage — Post-load SPs → Gold table ---")

    for sp_name, cols in POST_LOAD_SP_COLUMNS.items():
        # Only include columns that actually exist in the gold table
        valid_cols = [c for c in cols if c in gold_columns]
        if not valid_cols:
            report.skipped.append(f"post-load lineage: {sp_name} — no matching columns in gold table")
            continue

        skipped_cols = set(cols) - set(valid_cols)
        if skipped_cols:
            log.warning(
                "%s: %d columns not found in gold table: %s",
                sp_name, len(skipped_cols), sorted(skipped_cols),
            )

        sp_src = ExternalLineageObject(
            external_metadata=ExternalLineageExternalMetadata(name=sp_name)
        )
        col_rels = [ColumnRelationship(source=c, target=c) for c in valid_cols]
        label = f"{sp_name} → {UC_GOLD_TABLE}"

        create_or_skip_lineage(
            w, sp_src, gold_target, col_rels,
            props={
                "relationship_type": "post_load_adjustment",
                "columns_modified": str(len(valid_cols)),
            },
            label=label,
            dry_run=dry_run,
            report=report,
        )

    # ==================================================================
    # Report
    # ==================================================================
    report.print_summary()

    if report.failed and not dry_run:
        sys.exit(1)


if __name__ == "__main__":
    main()
