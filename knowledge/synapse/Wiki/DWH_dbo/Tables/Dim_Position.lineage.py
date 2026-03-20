"""
Dim_Position — UC External Lineage Injection
=============================================
Injects Synapse DWH lineage into Unity Catalog for DWH_dbo.Dim_Position.

Resolves ALL bronze table names dynamically from the Generic Pipeline
mapping view — never infers from naming conventions.  Verifies every UC
object exists before creating lineage.  On any error: logs, skips the
failed item, and continues.  Produces a summary report at the end.

Prerequisites:
  pip install databricks-sdk
  databricks auth login --profile guyman   (if token expired)

Privileges required:
  CREATE EXTERNAL METADATA  on metastore
  MODIFY                    on main.dwh.dim_position
  SELECT                    on bronze source tables
  SELECT                    on main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables

Usage:
  python Dim_Position.lineage.py              # dry run (default)
  python Dim_Position.lineage.py --execute    # actually write to UC
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
log = logging.getLogger("lineage-dim-position")

# ── Configuration ─────────────────────────────────────────────────────

HOST = "https://adb-5142916747090026.6.azuredatabricks.net"
WAREHOUSE_ID = "208214768b0e0308"
PROFILE = "guyman"
WAIT_TIMEOUT = "50s"

UC_GOLD_TABLE = "main.dwh.dim_position"
SYNAPSE_SCHEMA = "DWH_dbo"
SYNAPSE_TABLE = "Dim_Position"

MAPPING_VIEW = "main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables"

# Production sources that feed Dim_Position through the main ETL SP.
# Schema.Table as they appear in the production (etoro) database.
# The script resolves each to a UC bronze table via the mapping view.
PRODUCTION_SOURCES = [
    {"database": "etoro", "schema": "Trade",      "table": "PositionTbl"},
    {"database": "etoro", "schema": "Trade",      "table": "PositionTreeInfo"},
    {"database": "etoro", "schema": "Trade",      "table": "OpenPositionEndOfDay"},
    {"database": "etoro", "schema": "Trade",      "table": "PositionAirdropLog"},
    {"database": "etoro", "schema": "BackOffice", "table": "Customer"},
    {"database": "etoro", "schema": "Trade",      "table": "HBCExecutionLog"},
    {"database": "etoro", "schema": "History",    "table": "Cost"},
    # PriceLog is a partitioned/sharded log — may not have a single
    # mapping entry.  The script will try to resolve it; if it can't,
    # it skips with a warning.
    {"database": "etoro", "schema": "Trade",      "table": "PriceLog"},
]

# ETL stored procedures
SYNAPSE_SPS = [
    {
        "name": "synapse__dwh_dbo__sp_dim_position_populate",
        "entity_type": "Stored Procedure",
        "description": (
            "Main ETL procedure for DWH_dbo.Dim_Position. "
            "Loads from Trade.PositionTbl via CopyFromLake staging, "
            "joins PositionTreeInfo, PriceLog snapshots, HBCExecutionLog, "
            "BackOffice.Customer, and History.Cost. Incremental by PositionID."
        ),
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Dim_Position_Populate",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "incremental",
        },
    },
    {
        "name": "synapse__dwh_dbo__sp_dim_position_reopen",
        "entity_type": "Stored Procedure",
        "description": (
            "Post-load SP: adjusts CommissionOnClose and "
            "FullCommissionOnClose for reopened positions."
        ),
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Dim_Position_ReOpen",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "post-load adjustment",
        },
    },
    {
        "name": "synapse__dwh_dbo__sp_dim_position_partialclosechild",
        "entity_type": "Stored Procedure",
        "description": (
            "Post-load SP: handles partial-close child positions. "
            "Pro-rates Amount, AmountInUnitsDecimal, LotCountDecimal."
        ),
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Dim_Position_PartialCloseChild",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "post-load adjustment",
        },
    },
    {
        "name": "synapse__dwh_dbo__sp_dim_position_ispartialcloseparent",
        "entity_type": "Stored Procedure",
        "description": "Post-load SP: flags positions with partial-close children.",
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Dim_Position_IsPartialCloseParent",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "post-load adjustment",
        },
    },
    {
        "name": "synapse__dwh_dbo__sp_dim_position_iscopyfundposition",
        "entity_type": "Stored Procedure",
        "description": "Post-load SP: determines if position belongs to a CopyFund.",
        "properties": {
            "synapse_schema": "DWH_dbo",
            "synapse_object": "SP_Dim_Position_IsCopyFundPosition",
            "object_type": "SQL_STORED_PROCEDURE",
            "etl_pattern": "post-load adjustment",
        },
    },
]

MAIN_SP = "synapse__dwh_dbo__sp_dim_position_populate"

# Column-level lineage: production source column → DWH column.
# Keyed by "Schema.Table".
COLUMN_MAPPINGS_BY_SOURCE = {
    "Trade.PositionTbl": [
        ("PositionID", "PositionID"),
        ("CID", "CID"),
        ("CurrencyID", "CurrencyID"),
        ("ProviderID", "ProviderID"),
        ("InstrumentID", "InstrumentID"),
        ("HedgeID", "HedgeID"),
        ("HedgeServerID", "HedgeServerID"),
        ("Leverage", "Leverage"),
        ("Amount", "Amount"),
        ("AmountInUnitsDecimal", "AmountInUnitsDecimal"),
        ("LotCountDecimal", "LotCountDecimal"),
        ("UnitMargin", "UnitMargin"),
        ("InitForexRate", "InitForexRate"),
        ("NetProfit", "NetProfit"),
        ("SpreadedPipBid", "SpreadedPipBid"),
        ("SpreadedPipAsk", "SpreadedPipAsk"),
        ("IsBuy", "IsBuy"),
        ("EndOfWeekFee", "EndOfWeekFee"),
        ("Commission", "Commission"),
        ("CommissionOnClose", "CommissionOnClose"),
        ("Occurred", "OpenOccurred"),
        ("CloseOccurred", "CloseOccurred"),
        ("ParentPositionID", "ParentPositionID"),
        ("OrigParentPositionID", "OrigParentPositionID"),
        ("MirrorID", "MirrorID"),
        ("IsOpenOpen", "IsOpenOpen"),
        ("PlatformTypeID", "PlatformTypeID"),
        ("PositionSegment", "PositionSegment"),
        ("OpenInd", "OpenInd"),
        ("SpreadedCommission", "SpreadedCommission"),
        ("EndForexRate", "EndForexRate"),
        ("LastOpConversionRate", "LastOpConversionRate"),
        ("ClosePositionReasonID", "ClosePositionReasonID"),
        ("TreeID", "TreeID"),
        ("FullCommission", "FullCommission"),
        ("FullCommissionOnClose", "FullCommissionOnClose"),
        ("IsComputeForHedge", "IsComputeForHedge"),
        ("InitialAmountCents", "InitialAmountCents"),
        ("RedeemStatus", "RedeemStatus"),
        ("RedeemID", "RedeemID"),
        ("InitialUnits", "InitialUnits"),
        ("IsSettled", "IsSettled"),
        ("LastOpPriceRateID", "LastOpPriceRateID"),
        ("InitForexPriceRateID", "InitForexPriceRateID"),
        ("EndForexPriceRateID", "EndForexPriceRateID"),
        ("InitExecutionID", "InitExecutionID"),
        ("EndExecutionID", "EndExecutionID"),
        ("InitConversionRate", "InitConversionRate"),
        ("InitConversionRateID", "InitConversionRateID"),
        ("CloseMarketPriceRateID", "CloseMarketPriceRateID"),
        ("OrderID", "OrderID"),
        ("ExitOrderID", "ExitOrderID"),
        ("IsSettledOnOpen", "IsSettledOnOpen"),
        ("LastOpPriceRate", "LastOpPriceRate"),
        ("SettlementTypeID", "SettlementTypeID"),
        ("OpenMarketPriceRateID", "OpenMarketPriceRateID"),
        ("RequestOccurred", "RequestOpenOccurred"),
        ("RequestCloseOccurred", "RequestCloseOccurred"),
        ("OrderType", "OrderType"),
        ("PnLVersion", "PnLVersion"),
        ("CloseMarkupOnOpen", "CloseMarkupOnOpen"),
        ("OpenMarkup", "OpenMarkup"),
        ("CloseMarkup", "CloseMarkup"),
        ("DLTOpen", "DLTOpen"),
        ("DLTClose", "DLTClose"),
        ("CommissionVersion", "CommissionVersion"),
        ("ExitOrderType", "ExitOrderType"),
        ("OpenActionType", "OpenPositionReasonID"),
        ("OpenTotalTaxes", "OpenTotalTaxes"),
        ("CloseTotalTaxes", "CloseTotalTaxes"),
        ("EstimateCloseFeeOnOpen", "EstimateCloseFeeOnOpen"),
    ],
    "Trade.PositionTreeInfo": [
        ("CloseOnEndOfWeek", "CloseOnEndOfWeek"),
        ("LimitRate", "LimitRate"),
        ("StopRate", "StopRate"),
        ("IsDiscounted", "IsDiscounted"),
        ("StopRate", "StopRateOnOpen"),
        ("LimitRate", "LimitRateOnOpen"),
    ],
    "Trade.OpenPositionEndOfDay": [
        ("PnLInDollars", "PnLInDollars"),
        ("EstimateCloseFeeForCFD", "EstimateCloseFeeForCFD"),
        ("Close_PnLInDollars", "Close_PnLInDollars"),
        ("Close_CalculationRate", "Close_CalculationRate"),
        ("Close_ConversionRate", "Close_ConversionRate"),
        ("Close_PriceType", "Close_PriceType"),
        ("CurrentCalculationRate", "CurrentCalculationRate"),
        ("CurrentConversionRate", "CurrentConversionRate"),
    ],
    "BackOffice.Customer": [
        ("RegulationID", "RegulationIDOnOpen"),
    ],
    "Trade.HBCExecutionLog": [],
    "Trade.PositionAirdropLog": [],
    "History.Cost": [],
    "Trade.PriceLog": [],
}

# Post-load SPs and the specific columns they modify
POST_LOAD_SP_COLUMNS = {
    "synapse__dwh_dbo__sp_dim_position_reopen": [
        "CommissionOnClose", "FullCommissionOnClose", "IsReOpen",
        "ReopenForPositionID", "CommissionOnCloseOrig",
        "FullCommissionOnCloseOrig", "IsPartialCloseChildFromReOpen",
    ],
    "synapse__dwh_dbo__sp_dim_position_partialclosechild": [
        "Amount", "AmountInUnitsDecimal", "LotCountDecimal",
        "OriginalPositionID", "IsPartialCloseChild",
    ],
    "synapse__dwh_dbo__sp_dim_position_ispartialcloseparent": [
        "IsPartialCloseParent",
    ],
    "synapse__dwh_dbo__sp_dim_position_iscopyfundposition": [
        "IsCopyFundPosition",
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
        log.info("LINEAGE INJECTION REPORT — Dim_Position")
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


# ── Resolution functions ──────────────────────────────────────────────

def resolve_bronze_table(
    w: WorkspaceClient,
    database: str,
    schema: str,
    table: str,
    report: Report,
) -> Optional[str]:
    """Query the Generic Pipeline mapping view to find the UC bronze table.
    Returns the fully qualified UC table name or None."""

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
        report.skipped.append(f"{label} — mapping view query failed")
        return None

    if len(rows) == 0:
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
        report.skipped.append(f"{label} — mapping row missing UnityCatalogTableName or BusinessGroup")
        return None

    uc_fqn = f"main.{business_group}.{uc_table_name}"

    # Verify the table actually exists in UC
    verify = run_sql(w, f"DESCRIBE TABLE {uc_fqn}")
    if verify is None:
        report.skipped.append(f"{label} — resolved to {uc_fqn} but DESCRIBE failed (table may not exist or no access)")
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
        description="Inject Dim_Position lineage into Unity Catalog"
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

    # A3: Resolve bronze tables from the Generic Pipeline mapping view
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
        "name": "synapse__dwh_dbo__dim_position",
        "entity_type": "Table",
        "description": (
            "Synapse DWH table: DWH_dbo.Dim_Position. "
            "Central position dimension with full lifecycle attributes."
        ),
        "columns": gold_columns,
        "properties": {
            "synapse_schema": SYNAPSE_SCHEMA,
            "synapse_object": SYNAPSE_TABLE,
            "synapse_server": "sql_dp_prod_we",
            "object_type": "USER_TABLE",
            "refresh": "daily",
            "distribution": "HASH(PositionID)",
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
                "SP_Dim_Position_Populate writes to main.dwh.dim_position "
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
