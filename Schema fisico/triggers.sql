--trigger che permette di caricare luoghi solo tramite foto
CREATE OR REPLACE FUNCTION galleria.a_check_luogo_fn()
RETURNS TRIGGER
AS $$
DECLARE 
    presenza INTEGER; --una variabile di tipo intero che conterra' 0, se il luogo non e' presente, e != 0 se lo e'.
BEGIN
    SELECT COUNT(*) INTO presenza
    FROM LUOGO
    WHERE LUOGO.Coordinate = NEW.Coordinate;
    
    IF presenza = 0 THEN 
        IF NEW.Coordinate IS NOT NULL THEN
            INSERT INTO LUOGO(coordinate) VALUES (NEW.Coordinate);
        END IF;
    ELSE
        RAISE EXCEPTION 'Non è possibile inserire le coordinate (%) dato che sono già presenti.', NEW.Coordinate;
    END IF;
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER a_check_luogo_tr
BEFORE INSERT 
ON FOTO
FOR EACH ROW
EXECUTE FUNCTION galleria.a_check_luogo_fn();

--------------------------------------------------------------------------------------------------------------------------

--trigger che non permette l'aggiornamento della data di eliminazione a null 
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
ON FOTO
FOR EACH ROW
EXECUTE FUNCTION galleria.check_data_eliminazione_fn();

--------------------------------------------------------------------------------------------------------------------------

--trigger che controlla che -90 <= longitudine <= 90 &&  -180 <= latitudine <= 180
CREATE OR REPLACE FUNCTION galleria.check_valori_coordinate_fn()
RETURNS TRIGGER
AS $$
DECLARE
    check_coordinate CHAR(14) := NEW.coordinate;
    longitudine float;
    latitudine float;
BEGIN
    longitudine := SUBSTRING(check_coordinate FROM 2 FOR 5 )::float;
    latitudine := SUBSTRING(check_coordinate FROM 9 FOR 5 )::float;
    
    IF longitudine > 90.00 OR latitudine > 180.00 THEN
        RAISE EXCEPTION 'Il valore di logintudine, oppure di latitudine, vanno oltre l''insieme di valori ammessi.';
    END IF;
    
    RETURN NEW;

END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_valori_coordinate_tr
BEFORE INSERT 
ON galleria.LUOGO
FOR EACH ROW
EXECUTE FUNCTION galleria.check_valori_coordinate_fn();

--------------------------------------------------------------------------------------------------------------------------

--CREARE TRIGGER PER IL CONTROLLO DI ELIMINAZIONE DI FOTO/UTENTE

--CREARE TRIGGER DEL CONTROLLO PER ELIMINAZIONE DI UNA FOTO

--CREARE TRIGGER PER CONTROLLO DELL'OWNER DI UNA GALLERIA CONDIVISA CAMBIA L'OWNER

--CREARE TRIGGER PER PASSAGGIO DI OWNERSHIP DI UNA GALLERIA CONDIVISA E CONTROLLO SE PERSONALE O MENO
