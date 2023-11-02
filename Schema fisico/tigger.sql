CREATE OR REPLACE FUNCTION check_luogo_fn()
RETURNS TRIGGER
AS $$
DECLARE 
    presence INTEGER; --una variabile di tipo intero che conterra' 1, se il luogo e' presente, e 0 se non lo e'.
BEGIN
    SELECT COUNT(*) into presence
    FROM LUOGO
    WHERE LUOGO.Coordinate = NEW.Coordinate;
    
    IF presence = 0 then
        INSERT INTO LUOGO(coordinate, tiponome) VALUES (NEW.Coordinate, NULL);

    ELSE
        RAISE EXCEPTION 'Non è possibile inserire le coordinate (%) dato che sono già presenti.', NEW.Coordinate;
    END IF;
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_luogo_tr
BEFORE INSERT 
ON FOTO
FOR EACH ROW
EXECUTE FUNCTION check_luogo_fn();


--CREARE TRIGGER PER CONTROLLARE CHE GLI INTERI DELLE COORDINATE VADANO DA 0 A 90 E DA 0 A 180

--CREARE VINCOLO PER CONTROLLARE CHE LA DATA DI ELIMINAZIONE SIA TEMPORALMENTE DOPO LA DATA DI SCATTO

--CREARE TRIGGER PER CONTROLLARE CHE L'INZIALE DELL'ID UNA FOTO SIA F, UN VIDEO V E UNA GALLERIA G