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
BEFORE INSERT ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.a_check_luogo_fn();

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
BEFORE UPDATE ON galleria.FOTO
FOR EACH ROWEXECUTE FUNCTION galleria.check_data_eliminazione_fn();

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
BEFORE INSERT ON galleria.LUOGO
FOR EACH ROW EXECUTE FUNCTION galleria.check_valori_coordinate_fn();

--------------------------------------------------------------------------------------------------------------------------
--All'inserimento di un utente viene creata la sua galleria personale
CREATE OR REPLACE FUNCTION galleria.crea_gall_personale_fn()
RETURNS TRIGGER
AS $$
BEGIN    
    INSERT INTO galleria.GALLERIA VALUES (galleria.genera_id_fn('G'), galleria.genera_nome_galleria_fn(NEW.Nome), FALSE, NEW.IDUtente);
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER crea_gall_personale_tr
AFTER INSERT ON galleria.UTENTE
FOR EACH ROW EXECUTE FUNCTION galleria.crea_gall_personale_fn();

--------------------------------------------------------------------------------------------------------------------------
--trigger all'inserimento di una foto, nella tabella FOTO, essa viene inserita dirattamente nella galleria personale dell'autore
CREATE OR REPLACE FUNCTION galleria.insert_foto_gal_priv_fn()
RETURNS TRIGGER
AS $$
DECLARE
    galleria_target CHAR(10);
BEGIN
    SELECT IDGalleria INTO galleria_target
    FROM galleria.GALLERIA g
    WHERE g.condivisione = FALSE AND g.proprietario = NEW.autore;
    
    INSERT INTO galleria.CONTENUTA VALUES (galleria_target, NEW.IDFoto);
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER insert_foto_gal_priv_tr
AFTER INSERT ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.insert_foto_gal_priv_fn();

--------------------------------------------------------------------------------------------------------------------------
--trigger per la privatizzazione di una foto, impostando a false la visibilita' la foto viene rimossa da tutte le gallerie tranne quelli personali
CREATE OR REPLACE FUNCTION galleria.privatizzazione_foto_fn()
RETURNS TRIGGER
AS $$
BEGIN
    
    IF NEW.Visibilita = FALSE THEN

        DELETE FROM galleria.CONTENUTA C
        WHERE EXISTS(
            SELECT 1
            FROM galleria.GALLERIA g
            WHERE c.IDGalleria = g.IDGalleria AND g.condivisione = TRUE AND OLD.IDFoto = c.IDFoto
        );

    END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER privatizzazione_foto_tr
AFTER UPDATE ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.privatizzazione_foto_fn();

--------------------------------------------------------------------------------------------------------------------------
--trigger che evita l'inserimento di una foto 'non visibile' in una galleria privata
CREATE OR REPLACE FUNCTION galleria.stop_inserimento_foto_privata_fn()
RETURNS TRIGGER
AS $$
DECLARE
    check_visibilita BOOLEAN;
    check_gallery_type BOOLEAN;
BEGIN
    
    SELECT Visibilita INTO check_visibilita
    FROM galleria.FOTO
    WHERE IDFOTO = NEW.IDFoto;

    SELECT Condivisione INTO check_gallery_type
    FROM galleria.GALLERIA
    WHERE IDGalleria = NEW.IDGalleria;

    IF check_visibilita = FALSE AND check_gallery_type = TRUE THEN

        RAISE EXCEPTION 'La foto non può essere inserita in una galleria condivisa in quanto è stata resa invisibile';

    END IF;

    RETURN NULL;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER stop_inserimento_foto_privata_tr
BEFORE INSERT ON galleria.CONTENUTA
FOR EACH ROW EXECUTE FUNCTION galleria.stop_inserimento_foto_privata_fn();

--------------------------------------------------------------------------------------------------------------------------
--CREARE TRIGGER PER IL CONTROLLO DI ELIMINAZIONE DI FOTO/UTENTE

--CREARE TRIGGER PER ELIMINAZIONE DI UNA FOTO

--CREARE TRIGGER PER CONTROLLO DELL'OWNER DI UNA GALLERIA CONDIVISA PER CAMBIO DI OWNER

--CREARE TRIGGER PER PASSAGGIO DI OWNERSHIP DI UNA GALLERIA CONDIVISA E CONTROLLO SE PERSONALE O MENO