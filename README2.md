# Reeves County Oil & Gas Production Analysis (SQL)

# Overview
This project analyzes 5 years (2020–2024) of oil, gas, and condensate production data for leases in Reeves County, Texas, using MySQL. The goal was to identify top-producing leases, production concentration, and note nonproducing (disposal/injection) wells within the dataset.

# Data Source
- Source: [Texas Railroad Commission (RRC) Online System](https://www.rrc.texas.gov/)
- Query criteria: Lease-level view, Well Type: Both, County: Reeves, Date Range: Jan 2020 – Dec 2024
- Rows: 5,962 leases (each row is a 5 year cumulative total per lease)

Note on scope: this dataset reflects cumulative totals per lease, not monthly production, and does not include an operator field. As such, this analysis focuses on cross section comparisons (rankings, ratios, concentration) rather than time trends.

# Schema
```sql
CREATE TABLE reeves_leases (
    lease_name VARCHAR(100),
    lease_no VARCHAR(20),
    district_no VARCHAR(5),
    well_no VARCHAR(20),
    oil_bbl INT,
    casinghead_mcf INT,
    gw_gas_mcf INT,
    condensate_bbl INT
);
```

# Tools
MySQL Workbench, Excel (data cleaning CSV)

# Key Findings

# 1. Production is highly concentrated among a small number of leases:
The top 10% of leases (by oil production) account for a disproportionate share of total oil production across the county.
```sql
WITH ranked AS (
    SELECT lease_name, oil_bbl,
           NTILE(10) OVER (ORDER BY oil_bbl DESC) AS decile
    FROM reeves_leases
)
SELECT
    (SELECT SUM(oil_bbl) FROM ranked WHERE decile = 1) /
    (SELECT SUM(oil_bbl) FROM reeves_leases) * 100 AS pct_from_top_decile;
```

### 2. Top single lease significantly outproduces the rest of the field
**REV GF STATE T7 50** was the top-producing lease with **4,440,186 barrels** of oil over the period — roughly **19.88x** the average of **223,343 barrels** among producing leases (leases with nonzero oil production).
```sql
SELECT lease_name, lease_no, oil_bbl
FROM reeves_leases
ORDER BY oil_bbl DESC
LIMIT 20;

SELECT AVG(oil_bbl) AS avg_oil_among_producing_leases
FROM reeves_leases
WHERE oil_bbl > 0;
```

### 3. Zero-production leases are largely disposal/injection wells, not inactive producers
**1,275** leases (**21.39%** of the dataset) showed zero recorded oil, gas, and condensate production. Of these, **181 (14.20%)** had lease names explicitly containing "SWD" or "BRINE," confirming that at least a portion of zero-production leases are disposal/injection wells rather than inactive producers. The remaining zero-production leases likely include a mix of disposal wells without that naming convention, plugged/abandoned wells, and leases that were permitted but never brought into production.
```sql
SELECT lease_name, lease_no, well_no
FROM reeves_leases
WHERE oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 AND condensate_bbl = 0;

SELECT COUNT(*) AS total_zero_production
FROM reeves_leases
WHERE oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 AND condensate_bbl = 0;

SELECT COUNT(*) AS zero_production_swd_brine
FROM reeves_leases
WHERE (oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 AND condensate_bbl = 0)
  AND (lease_name LIKE '%SWD%' OR lease_name LIKE '%BRINE%');
```

### 4. Gas-to-oil ratio varies widely across leases
The highest gas-to-oil ratio (GOR) lease was **BIG GEORGE 180** at **56.26 mcf per barrel** (14,399 barrels of oil, 810,069 mcf of gas), suggesting a more gas-dominant reservoir compared to typical oil-weighted leases in the sample.

*Note: leases with very low oil volumes were excluded from this ranking (`oil_bbl > 100`), since dividing by a near-zero denominator produces extreme ratios that don't reflect actual reservoir characteristics rather than a genuinely gas-rich lease.*
```sql
SELECT lease_name, lease_no, oil_bbl,
       (casinghead_mcf + gw_gas_mcf) AS total_gas_mcf,
       ROUND((casinghead_mcf + gw_gas_mcf) / oil_bbl, 2) AS gas_oil_ratio
FROM reeves_leases
WHERE oil_bbl > 100
ORDER BY gas_oil_ratio DESC
LIMIT 20;
```

## Full Query File
See [`queries.sql`](./queries.sql) for all 8 queries used in this analysis, including summary statistics and multi-well lease comparisons.

## Limitations
- Data is a 5-year cumulative total per lease, not monthly — no time-series/decline-rate analysis was possible with this pull.
- No operator field was included in this query, so operator-level comparisons were not performed.
- District-level ranking was included to demonstrate window function syntax (`RANK() OVER (PARTITION BY ...)`), but since the query was filtered to a single county, most leases fall under one district and the ranking is not a meaningful business insight on its own.

## What I'd Do Next
Pull the same county's data using RRC's "Monthly Totals" view (scoped to top-producing leases) to add month-over-month decline analysis, and separately pull operator-level data to compare production efficiency across companies.
