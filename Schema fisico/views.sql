CREATE VIEW galleria.top_luoghi_w AS 
SELECT COUNT(*), F.Coordinate
FROM galleria.FOTO F JOIN galleria.LUOGO L ON F.Coordinate = L.Coordinate
GROUP BY F.Coordinate
ORDER BY COUNT (*) DESC 
LIMIT 3;
