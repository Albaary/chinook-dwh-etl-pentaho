SELECT d.year,
       c.country,
       t.genre_name,
       ROUND(SUM(f.amount)::numeric, 2)   AS total_revenue,
       SUM(f.quantity)                    AS total_units_sold,
       COUNT(DISTINCT f.sk_customer)      AS customer_count,
       ROUND((100.0 * SUM(f.amount)
             / SUM(SUM(f.amount)) OVER (PARTITION BY d.year, c.country))::numeric, 2) AS pct_of_country_revenue,
       RANK() OVER (PARTITION BY d.year, c.country
                    ORDER BY SUM(f.amount) DESC)                                      AS revenue_rank
FROM   fact_table.fact_sales f
JOIN   dimension.dim_date     d ON d.sk_date     = f.sk_date
JOIN   dimension.dim_customer c ON c.sk_customer = f.sk_customer
JOIN   dimension.dim_track    t ON t.sk_track    = f.sk_track
GROUP  BY d.year, c.country, t.genre_name
ORDER  BY d.year, c.country, revenue_rank