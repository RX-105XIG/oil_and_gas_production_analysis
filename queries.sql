-- ============================================================
-- Reeves County Oil & Gas Production Analysis
-- Data source: Texas RRC Online System, General Production Query
-- Table: reeves_leases (5,962 leases, Jan 2020-Dec 2024 cumulative totals)
-- ============================================================

USE energy_project;

-- ------------------------------------------------------------
-- 1. Top 20 leases by total oil production
-- ------------------------------------------------------------
SELECT lease_name, lease_no, oil_bbl
FROM reeves_leases
ORDER BY oil_bbl DESC
LIMIT 20;

-- ------------------------------------------------------------
-- 2. Top 20 leases by total gas production (casinghead + gas well gas)
-- ------------------------------------------------------------
SELECT lease_name, lease_no,
       (casinghead_mcf + gw_gas_mcf) AS total_gas_mcf
FROM reeves_leases
ORDER BY total_gas_mcf DESC
LIMIT 20;

-- ------------------------------------------------------------
-- 3. Identify likely disposal/injection wells (zero production)
-- ------------------------------------------------------------
SELECT lease_name, lease_no, well_no
FROM reeves_leases
WHERE oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 AND condensate_bbl = 0;

-- Total count of zero-production leases
SELECT COUNT(*) AS total_zero_production
FROM reeves_leases
WHERE oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 AND condensate_bbl = 0;

-- How many of those have "SWD" or "BRINE" in the lease name
SELECT COUNT(*) AS zero_production_swd_brine
FROM reeves_leases
WHERE (oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 AND condensate_bbl = 0)
  AND (lease_name LIKE '%SWD%' OR lease_name LIKE '%BRINE%');

-- ------------------------------------------------------------
-- 4. Gas-to-oil ratio (GOR) - flag gas-dominant vs. oil-dominant leases
--    (oil_bbl > 100 filter avoids near-zero-denominator distortion)
-- ------------------------------------------------------------
SELECT lease_name, lease_no, oil_bbl,
       (casinghead_mcf + gw_gas_mcf) AS total_gas_mcf,
       ROUND((casinghead_mcf + gw_gas_mcf) / oil_bbl, 2) AS gas_oil_ratio
FROM reeves_leases
WHERE oil_bbl > 100
ORDER BY gas_oil_ratio DESC
LIMIT 20;

-- ------------------------------------------------------------
-- 5. Rank every lease within its district by total oil (window function)
-- ------------------------------------------------------------
SELECT lease_name, district_no, oil_bbl,
       RANK() OVER (PARTITION BY district_no ORDER BY oil_bbl DESC) AS district_rank
FROM reeves_leases;

-- ------------------------------------------------------------
-- 6. Summary statistics
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_leases,
    SUM(oil_bbl) AS total_oil,
    AVG(oil_bbl) AS avg_oil_per_lease,
    MAX(oil_bbl) AS max_oil_single_lease,
    SUM(CASE WHEN oil_bbl = 0 AND casinghead_mcf = 0 AND gw_gas_mcf = 0 THEN 1 ELSE 0 END) AS zero_production_leases
FROM reeves_leases;

-- Average oil among producing leases only (excludes zero-production leases)
SELECT AVG(oil_bbl) AS avg_oil_among_producing_leases
FROM reeves_leases
WHERE oil_bbl > 0;

-- ------------------------------------------------------------
-- 7. Production concentration: % of total oil from the top 10% of leases
-- ------------------------------------------------------------
WITH ranked AS (
    SELECT lease_name, oil_bbl,
           NTILE(10) OVER (ORDER BY oil_bbl DESC) AS decile
    FROM reeves_leases
)
SELECT
    (SELECT SUM(oil_bbl) FROM ranked WHERE decile = 1) /
    (SELECT SUM(oil_bbl) FROM reeves_leases) * 100 AS pct_from_top_decile;

-- ------------------------------------------------------------
-- 8. Multi-well leases vs. single-well leases (production comparison)
-- ------------------------------------------------------------
SELECT lease_no,
       COUNT(*) AS num_wells,
       SUM(oil_bbl) AS total_oil
FROM reeves_leases
GROUP BY lease_no
HAVING COUNT(*) > 1
ORDER BY total_oil DESC;
