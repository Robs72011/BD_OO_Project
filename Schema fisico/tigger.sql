--trigger che permette di caricare luoghi solo tramite foto
CREATE OR REPLACE FUNCTION galleria.check_luogo_fn()
RETURNS TRIGGER
AS $$
DECLARE 
    presenza INTEGER; --una variabile di tipo intero che conterra' 1, se il luogo e' presente, e 0 se non lo e'.
BEGIN
    SELECT COUNT(*) into presenza
    FROM galleria.LUOGO
    WHERE galleria.LUOGO.Coordinate = NEW.Coordinate;
    
    IF presenza = 0 THEN
        INSERT INTO galleria.LUOGO(coordinate, tiponome) VALUES (NEW.Coordinate, NULL);
    ELSE
        RAISE EXCEPTION 'Non è possibile inserire le coordinate (%) dato che sono già presenti.', NEW.Coordinate;
    END IF;
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_luogo_tr
BEFORE INSERT 
ON galleria.FOTO
FOR EACH ROW
EXECUTE FUNCTION galleria.check_luogo_fn();

--------------------------------------------------------------------------------------------------------------------------

--trigger che non permette l'aggiornamento della data di eliminazione se gia c'e', oopure la messa a null 
CREATE OR REPLACE FUNCTION galleria.check_data_eliminazione_fn()
RETURNS TRIGGER
AS $$
BEGIN    
    --La data di eliminazione non puo' essere aggiornata, dato che la foto e' gia' stata eliminata
    --La data di eliminazione non puo' essere messa a NULL una volta che e' ne stata inserita una
    IF NEW.DataEliminazione <> OLD.DataEliminazione OR NEW.DataEliminazione IS NULL THEN
        RAISE EXCEPTION 'La data di eliminazione non è aggiornabile, in quanto la foto è già stata eliminata';
    END IF;
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_data_eliminazione_tr
BEFORE UPDATE 
ON galleria.FOTO
FOR EACH ROW
EXECUTE FUNCTION galleria.check_data_eliminazione_fn();

--------------------------------------------------------------------------------------------------------------------------

--CREARE TRIGGER PER CONTROLLARE CHE L'INZIALE DELL'ID UNA FOTO SIA F, UN VIDEO V E UNA GALLERIA G

--CREARE TRIGGER PER CONTROLLARE CHE GLI INTERI DELLE COORDINATE VADANO DA 0 A 90 E DA 0 A 180
CREATE OR REPLACE FUNCTION galleria.check_valori_coordinate_fn()
RETURNS TRIGGER
AS $$
BEGIN

END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_valori_coordinate_tr
BEFORE UPDATE 
ON galleria.FOTO
FOR EACH ROW
EXECUTE FUNCTION galleria.check_valori_coordinate_fn();
