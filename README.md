# energy_project_oilgas

Reeves County Oil & Gas Production Analysis (MySQL)

Overview
This project analyzes 5 years of oil, gas, and condensate production data for leases in Reeves County, Texas from 2020-2024 using MySQL. The goal was to identify top producing leases, understand production concentration, and flag nonproducing (disposal/injection) wells within the dataset.

Data Source
Source: Texas Railroad Commission (RRC) Online System — General Production Query
Query criteria: Lease level view, Well Type: Both, County: Reeves, Date Range: Jan 2020 – Dec 2024
Rows: ~5,962 leases (each row is a 5 year cumulative total per lease)
Note on scope: this dataset reflects cumulative totals per lease rather than monthly production, and does not include an operator field. As a result, this analysis focuses on cross-sectional comparisons (rankings, ratios, concentration) rather than time-series trends.


Tools
MySQL / MySQL Workbench, Excel (data cleaning + charts)

Key Findings
1. Production is highly concentrated among a small number of leases
The top 10% of leases (by oil production) account for 76.71% of total oil production across the county.

2. Top single lease significantly outproduces the rest of the field
REV GF STATE T7 50 was the top-producing lease with 4440186 barrels of oil over the period — roughly 19.88x the county average of 223343 barrels per lease.

3. Zero-production leases are largely disposal/injection wells, not inactive producers
1275 leases (21.39% of the dataset) showed zero recorded oil, gas, and condensate production. Of these, 14.20% had lease names containing "SWD" or "BRINE," consistent with these being saltwater disposal or brine injection wells rather than producing wells that went inactive.

4. Gas-to-oil ratio varies widely across leases
The highest gas-to-oil ratio (GOR) lease was BIG GEORGE 180 at 56.26 mcf per barrel, suggesting a more gas-dominant reservoir compared to typical oil-weighted leases in the sample.
Note: leases with very low oil volumes were excluded from this ranking (oil_bbl > 100), since dividing by a near-zero denominator produces extreme ratios that don't reflect actual reservoir characteristics rather than a genuinely gas-rich lease.


Full Query File
See queries.sql for all 8 queries used in this analysis, including summary statistics and multi-well lease comparisons.
Limitations
Data is a 5-year cumulative total per lease, not monthly — no time-series/decline-rate analysis was possible with this pull.
No operator field was included in this query, so operator-level comparisons were not performed.
District-level ranking was included to demonstrate window function syntax (RANK() OVER (PARTITION BY ...)), but since the query was filtered to a single county, most leases fall under one district and the ranking is not a meaningful business insight on its own.
What I'd Do Next
Pull the same county's data using RRC's "Monthly Totals" view (scoped to top-producing leases) to add month-over-month decline analysis, and separately pull operator-level data to compare production efficiency across companies.


