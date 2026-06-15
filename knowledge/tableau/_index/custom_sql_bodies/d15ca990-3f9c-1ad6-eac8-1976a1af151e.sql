SELECT

    -- All Datasources
    d.id                                        AS "Datasource ID" ,
    d.luid                                      AS "Datasource LUID" ,
    d.name                                      AS "Datasource Name" ,
    d.repository_url                            AS "Datasource Repository URL" ,
    d.owner_id                                  AS "Datasource Owner ID" ,
    d_pc.project_id                             AS "Datasource Project ID" ,
    d.site_id                                   AS "Datasource Site ID" ,
    d.created_at                                AS "Datasource Created At" ,
    d.updated_at                                AS "Datasource Updated At" ,
    d.is_hierarchical                           AS "Datasource Is Hierarchical" ,
    d.is_certified                              AS "Datasource Is Certified" ,
    COALESCE(e_dc.has_extract,
        d.data_engine_extracts)                 AS "Datasource Has Extract" ,
    d.incrementable_extracts                    AS "Datasource Incrementable Extracts" ,
    d.refreshable_extracts                      AS "Datasource Refreshable Extracts" ,
    d.data_engine_extracts                      AS "Datasource Data Engine Extracts" ,
    d.extracts_refreshed_at                     AS "Datasource Extracts Refreshed At" ,
    d.db_class                                  AS "Datasource DB Class" ,
    d.db_name                                   AS "Datasource DB Name" ,
    d.table_name                                AS "Datasource Table Name" ,
    CASE d.connectable
    WHEN true THEN false
    ELSE true
    END                                         AS "Is Embedded in Workbook" ,
    CASE 
        WHEN p_dc.dbclass = 'sqlproxy' THEN true
        ELSE false
    END                                         AS "References Published Data Source" ,
    d.parent_workbook_id                        AS "Parent Workbook ID" ,


    -- "Underlying" Data Sources (e.g., if the data source in a Workbook points to a Tableau Server published datasource)
    
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.id
        ELSE d.id
    END                                         AS "Datasource ID (underlying)" , -- represents the underlying datasource id. If a workbook connects to a published datasource, use that ID rather than the datasource id referenced by the workbook.

    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.data_engine_extracts
        ELSE d.data_engine_extracts
    END                                         AS "Datasource Data Engine Extracts (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.refreshable_extracts
        ELSE d.refreshable_extracts
    END                                         AS "Datasource Refreshable Extracts (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.incrementable_extracts
        ELSE d.incrementable_extracts
    END                                         AS "Datasource Incrementable Extracts (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.extracts_refreshed_at
        ELSE d.extracts_refreshed_at
    END                                         AS "Datasource Extracts Refreshed At (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.extracts_incremented_at
        ELSE d.extracts_incremented_at
    END                                         AS "Datasource Extracts Incremented At (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.name
        ELSE d.name
    END                                         AS "Datasource Name (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.owner_id
        ELSE d.owner_id
    END                                         AS "Datasource Owner ID (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds_pc.project_id
        ELSE d_pc.project_id
    END                                         AS "Datasource Project ID (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.db_class
        ELSE d.db_class
    END                                         AS "Datasource DB Class (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.db_name
        ELSE d.db_name
    END                                         AS "Datasource DB Name (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.table_name
        ELSE d.table_name
    END                                         AS "Datasource Table Name (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.is_hierarchical
        ELSE d.is_hierarchical
    END                                         AS "Datasource Is Hierarchical (underlying)" ,
    CASE p_dc.dbclass
        WHEN 'sqlproxy' THEN p_ds.is_certified
        ELSE d.is_certified
    END                                         AS "Datasource Is Certified (underlying)" ,
    p_ds.repository_url                         AS "Datasource Repository URL (underlying)"

FROM datasources d  -- all datasources, published and embedded
    LEFT JOIN projects_contents d_pc
        ON d.id = d_pc.content_id
            AND d.site_id = d_pc.site_id
            AND d_pc.content_type = 'datasource'
    LEFT JOIN 
        (
         SELECT
             datasource_id ,
             has_extract
         FROM data_connections  -- used to obtain extract information on first-level datasources (e_dc = embedded data connections)
         GROUP BY
             datasource_id ,
             has_extract
        ) as e_dc
            ON d.id = e_dc.datasource_id
    LEFT JOIN data_connections p_dc  -- used to obtain information on what datasources (in a workbook) are connecting to what published datasources
        ON d.id = p_dc.datasource_id
            AND p_dc.dbclass = 'sqlproxy'
    LEFT JOIN datasources p_ds  -- just the published "conectable" datasources for supplemental information
        ON p_dc.dbname = p_ds.repository_url
            AND p_dc.site_id = p_ds.site_id
            AND p_ds.connectable = true
    LEFT JOIN projects_contents p_ds_pc
        ON p_ds.id = p_ds_pc.content_id
            AND p_ds.site_id = p_ds_pc.site_id
            AND p_ds_pc.content_type = 'datasource'