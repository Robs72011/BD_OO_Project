CREATE OR REPLACE VIEW galleria.top_luoghi_w AS 
SELECT COUNT(*), L.Coordinate, L.toponimo
FROM galleria.FOTO F JOIN galleria.LUOGO L ON F.Coordinate = L.Coordinate
GROUP BY L.Coordinate
ORDER BY COUNT (*) DESC 
LIMIT 3;
