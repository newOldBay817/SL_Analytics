-- Conversion by shop

SELECT L.shop_id,
CASE WHEN L.context_user_agent ~ '/Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/' THEN 'Mobile_Web'
                             ELSE 'Desktop_Web'
                             END AS platform,
count(DISTINCT L.visit_id) AS landing, 
count(DISTINCT M.visit_id) AS menu,
count(DISTINCT A.visit_id) AS add_item,
count(DISTINCT C.visit_id) AS cart,
count(DISTINCT O.visit_id) AS completed_order
FROM production.partner_landing_page_view L
LEFT JOIN production.viewed_menu M ON L.visit_id = M.visit_id
LEFT JOIN production.added_product A ON L.visit_id = A.visit_id
LEFT JOIN production.viewed_cart C ON L.visit_id = C.visit_id
LEFT JOIN production.completed_order O ON L.visit_id = O.visit_id
WHERE L.received_at >= CURRENT_DATE - 28
AND   L.context_user_agent NOT LIKE '%Health Check%'
AND   L.context_user_agent NOT LIKE '%crawler%'
AND   L.context_user_agent NOT LIKE '%Womply%'
AND   L.context_user_agent <> 'ia_archiver'
AND   L.context_user_agent NOT LIKE '%bot%'
GROUP BY 1,2
