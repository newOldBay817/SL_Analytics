--- CUSTOM PHOTO PAGE CONVERSIONS


SELECT B.shop_id, A.experiment_name AS experiment, 
A.experiment_variant AS variant,  
CASE
    WHEN A.context_user_agent ~ '/Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/' THEN 'Mobile_Web'
    ELSE 'Desktop_Web' 
    END AS platform,
count(DISTINCT A.visit_id) AS landing_page,
count(DISTINCT C.visit_id) AS menu,
count(DISTINCT D.visit_id) AS add_product,
count(DISTINCT E.visit_id) AS view_cart,
count(DISTINCT F.visit_id) AS complete_order
FROM
(SELECT visit_id, experiment_name, experiment_variant, context_user_agent FROM production.experiment WHERE experiment_name = 'custom_photos') A
LEFT JOIN production.pages B ON A.visit_id = B.visit_id
LEFT JOIN production.viewed_menu C ON A.visit_id = C.visit_id
LEFT JOIN production.added_product D ON A.visit_id = D.visit_id
LEFT JOIN production.viewed_cart E ON A.visit_id = E.visit_id
LEFT JOIN production.completed_order F ON A.visit_id = F.visit_id
WHERE B.shop_id IN (1078,1520, 1594,1641, 2198, 2348, 3859, 4563, 563)
AND A.context_user_agent NOT LIKE '%Health Check%'
AND   A.context_user_agent NOT LIKE '%crawler%'
AND   A.context_user_agent NOT LIKE '%Womply%'
AND   A.context_user_agent <> 'ia_archiver'
AND   A.context_user_agent NOT LIKE '%bot%'
GROUP BY 1,2,3,4
