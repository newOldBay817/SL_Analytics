-- page conversions (not shop specific)
SELECT a.experiment_name AS experiments,
       a.experiment_variant AS variant,
       CASE
         WHEN a.context_user_agent ~ '/Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/' THEN 'Mobile_Web'
         ELSE 'Desktop_Web'
       END AS platform,
       COUNT(DISTINCT (a.visit_id)) AS landing_page,
       COUNT(DISTINCT (c.visit_id)) AS pages_landing_page,
       COUNT(DISTINCT (b.visit_id)) AS menu,
       COUNT(DISTINCT (d.visit_id)) AS completed_order,
       (1.0 *COUNT(DISTINCT (b.visit_id))) / COUNT(DISTINCT (a.visit_id))*100 AS CVR,
       (1.0 *COUNT(DISTINCT (d.visit_id))) / COUNT(DISTINCT (a.visit_id))*100 AS completed_order_cvr
FROM production.experiment a
  JOIN (SELECT visit_id
        FROM production.pages
        WHERE name = 'amp-landing'
        UNION
        SELECT visit_id
        FROM production.partner_landing_page_view) c ON a.visit_id = c.visit_id
  LEFT JOIN production.viewed_menu b ON a.visit_id = b.visit_id
  LEFT JOIN production.completed_order d ON a.visit_id = d.visit_id
AND   a.context_user_agent NOT LIKE '%Health Check%'
AND   a.context_user_agent NOT LIKE '%crawler%'
AND   a.context_user_agent NOT LIKE '%Womply%'
AND   a.context_user_agent <> 'ia_archiver'
AND   a.context_user_agent NOT LIKE '%bot%'
GROUP BY 1,
         2,
         3