--trigger che permette di caricare luoghi tramite foto
CREATE OR REPLACE FUNCTION galleria.a_check_luogo_fn()
RETURNS TRIGGER
AS $$
DECLARE 
    presenza INTEGER; --una variabile di tipo intero che conterra' 0, se il luogo non e' presente, e != 0 se lo e'.
BEGIN
    SELECT COUNT(*) INTO presenza
    FROM galleria.LUOGO
    WHERE galleria.LUOGO.Coordinate = NEW.Coordinate;
    
    IF presenza = 0 THEN 
        IF NEW.Coordinate IS NOT NULL THEN
            INSERT INTO galleria.LUOGO(coordinate) VALUES (NEW.Coordinate);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER a_check_luogo_tr
BEFORE INSERT ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.a_check_luogo_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger che non permette l'aggiornamento della data di eliminazione
CREATE OR REPLACE FUNCTION galleria.check_data_eliminazione_fn()
RETURNS TRIGGER
AS $$
BEGIN    
    --La data di eliminazione non puo' essere aggiornata, dato che la foto e' gia' stata eliminata
    --La data di eliminazione non puo' essere messa a NULL una volta che e' ne stata inserita una
    IF NEW.DataEliminazione <> OLD.DataEliminazione THEN
        RAISE EXCEPTION 'La data di eliminazione non è aggiornabile, in quanto la foto è già stata eliminata';
    END IF;
    
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_data_eliminazione_tr
BEFORE UPDATE ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.check_data_eliminazione_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger che controlla che -90 <= longitudine <= 90 &&  -180 <= latitudine <= 180
CREATE OR REPLACE FUNCTION galleria.check_valori_coordinate_fn()
RETURNS TRIGGER
AS $$
DECLARE
    check_coordinate CHAR(14) := NEW.coordinate;
    longitudine float;
    latitudine float;
BEGIN
    longitudine := SUBSTRING(check_coordinate FROM 2 FOR 5)::float;
    latitudine := SUBSTRING(check_coordinate FROM 9 FOR 6)::float;--controlla il 5 
    
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

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--All'inserimento di un utente viene creata la sua galleria personale
CREATE OR REPLACE FUNCTION galleria.crea_gall_personale_fn()
RETURNS TRIGGER
AS $$
DECLARE
    id_galleria CHAR(10);
BEGIN
    SELECT galleria.genera_id_fn('G') INTO id_galleria;
    INSERT INTO galleria.GALLERIA VALUES (id_galleria, galleria.genera_nome_galleria_fn(NEW.Nome), FALSE, NEW.IDUtente);
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER crea_gall_personale_tr
AFTER INSERT ON galleria.UTENTE
FOR EACH ROW EXECUTE FUNCTION galleria.crea_gall_personale_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger per la privatizzazione di una foto, impostando a false la visibilita' la foto viene rimossa da tutte le gallerie tranne quelli personale
CREATE OR REPLACE FUNCTION galleria.privatizzazione_foto_fn()
RETURNS TRIGGER
AS $$
BEGIN
    
    IF NEW.Visibilita = FALSE THEN

        DELETE FROM galleria.CONTENUTA c
        WHERE EXISTS(
            SELECT 1
            FROM galleria.GALLERIA g
            WHERE c.IDGalleria = g.IDGalleria AND g.condivisione = TRUE AND OLD.IDFoto = c.IDFoto
        );

    END IF;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER privatizzazione_foto_tr
AFTER UPDATE ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.privatizzazione_foto_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger che evita l'inserimento di una foto 'non visibile' in una galleria privata
CREATE OR REPLACE FUNCTION galleria.stop_inserimento_foto_privata_fn()
RETURNS TRIGGER
AS $$
DECLARE
    check_visibilita BOOLEAN;
    check_gallery_type BOOLEAN;
BEGIN
    
    --controllo la visibilta' della foto
    SELECT Visibilita INTO check_visibilita
    FROM galleria.FOTO
    WHERE IDFOTO = NEW.IDFoto;

    --controllo se la galleria e' condivisa o meno
    SELECT Condivisione INTO check_gallery_type
    FROM galleria.GALLERIA
    WHERE IDGalleria = NEW.IDGalleria;

    --se la foto e' 'invisibile' e la galleria condivisa, impedisco l'inserimento
    IF check_visibilita = FALSE AND check_gallery_type = TRUE THEN

        RAISE EXCEPTION 'La foto non può essere inserita in una galleria condivisa dato che è stata resa invisibile';

    END IF;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER stop_inserimento_foto_privata_tr
BEFORE INSERT ON galleria.CONTENUTA
FOR EACH ROW EXECUTE FUNCTION galleria.stop_inserimento_foto_privata_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger che non permette ad InVideo di passare da true a false
CREATE OR REPLACE FUNCTION galleria.stop_update_invideo_fn()
RETURNS TRIGGER
AS $$
BEGIN
    IF OLD.InVideo = TRUE AND NEW.InVideo = FALSE THEN
        RAISE EXCEPTION 'La foto, anche se eliminata dopo essere stata messa in video, deve essere tracciata lo stesso';
    ELSE
        RETURN NEW;
    END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER stop_update_invideo_tr
BEFORE UPDATE ON galleria.FOTO
FOR EACH ROW EXECUTE FUNCTION galleria.stop_update_invideo_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Trigger che controlla che ogni utente abbia al massimo una sola galleria personale con un inserimento diretto su galleria.galleria
CREATE OR REPLACE FUNCTION galleria.check_num_gall_pers_fn()
RETURNS TRIGGER
AS $$
DECLARE
    n_gall INTEGER;
BEGIN
    SELECT COUNT(*) INTO n_gall
    FROM galleria.GALLERIA
    WHERE Condivisione = FALSE AND Proprietario = NEW.Proprietario;
    
    IF n_gall = 1 AND NEW.Condivisione = FALSE THEN
        RAISE EXCEPTION 'Un utente può avere al massimo una galleria privata.';
    ELSE
        RETURN NEW;
    END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER check_num_gall_pers_tr
BEFORE INSERT ON galleria.GALLERIA
FOR EACH ROW EXECUTE FUNCTION galleria.check_num_gall_pers_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger che inserisce in galleria.partecipa la coppia composta dal'id proprietario della galleria e l'id della galleria appena 'creata'
CREATE OR REPLACE FUNCTION galleria.insert_partecipa_proprietario_gall_fn()
RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO galleria.PARTECIPA VALUES (NEW.IDGalleria, NEW.Proprietario);
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER insert_partecipa_proprietario_gall_tr
AFTER INSERT ON galleria.GALLERIA
FOR EACH ROW EXECUTE FUNCTION galleria.insert_partecipa_proprietario_gall_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger che evita l'eliminazione dell'utente admin
CREATE OR REPLACE FUNCTION galleria.stop_eliminazione_admin_fn()
RETURNS TRIGGER
AS $$
BEGIN
    IF OLD.IsAdmin = TRUE THEN
        RAISE EXCEPTION 'L''admin non può essere eliminato.';
    ELSE
        RETURN NEW;
    END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER stop_eliminazione_admin_tr
BEFORE DELETE ON galleria.UTENTE
FOR EACH ROW EXECUTE FUNCTION galleria.stop_eliminazione_admin_tr();


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--update che impedisce ad un utente di diventare admin e il contrario.
CREATE OR REPLACE FUNCTION galleria.stop_update_isadmin_fn()
RETURNS TRIGGER
AS $$
BEGIN
    IF (OLD.IsAdmin = TRUE AND NEW.IsAdmin = FALSE) THEN
        RAISE EXCEPTION 'Un admin non può diventare un utente';
    ELSIF (OLD.IsAdmin = FALSE AND NEW.IsAdmin = TRUE) THEN 
        RAISE EXCEPTION 'Un utente non può diventare un admin';
    ELSE
        RETURN NEW;
    END IF;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER stop_update_isadmin_tr
BEFORE UPDATE ON galleria.UTENTE
FOR EACH ROW EXECUTE FUNCTION galleria.stop_update_isadmin_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--trigger dedito all'inserimento del soggetto e la giusta gestione di utenti della base di dati come soggetti di una foto
CREATE OR REPLACE FUNCTION galleria.controllo_soggetto_fn()
RETURNS TRIGGER
AS $$
DECLARE
    buff galleria.string;
    buff_2 galleria.string;
    controllo_lunghezza INT;
    presenza INT;
    newtext galleria.id_user_dt;
BEGIN

    IF SUBSTRING(NEW.NomeSoggetto FROM 1 FOR 1) = '@' THEN 
        buff_2 := SUBSTRING(NEW.NomeSoggetto FROM 2);
        buff := UPPER(buff_2);
        controllo_lunghezza := LENGTH(buff);
        IF controllo_lunghezza = 5 THEN 
            newtext := buff::galleria.id_user_dt;
            SELECT COUNT(*) INTO presenza
            FROM galleria.UTENTE
            WHERE galleria.UTENTE.IDUtente = newtext;

            IF presenza = 0 THEN 
                RAISE EXCEPTION 'Non pui inserire questo utente in quanto non esiste';
            ELSE 
                NEW.NomeSoggetto := buff; 
            END IF;

        ELSE 

            RAISE EXCEPTION 'Un id utente ha precisamente 5 caratteri';

        END IF;
    ELSE 
        buff := LOWER(NEW.NomeSoggetto);
        NEW.NomeSoggetto := buff; 
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER controllo_soggetto_tr
BEFORE INSERT ON galleria.SOGGETTO
FOR EACH ROW EXECUTE FUNCTION galleria.controllo_soggetto_fn();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREARE TRIGGER PER ELIMINAZIONE DI UNA FOTO (attualmente e' stato fatto in forma di funzione: elimina_foto_gal_pers_fn(foto_da_eliminare IN CHAR))

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREARE TRIGGER PER CONTROLLO DELL'OWNER DI UNA GALLERIA CONDIVISA PER CAMBIO DI OWNER

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREARE TRIGGER CHE CONTROLLA CHE SE UNA FOTO E' PRESENTE IN UNA GALLERIA PERSONALE E' PRESENTE ANCHE IL SUO AUTORE COME PARTECIPANTE ALLA GALLERIA

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREARE TRIGGER CHE GESTISCE ELIMNAZIONE FOTO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREARE TRIGGER PER L'ELIMINAZIONE DI UTENTE DA PARTE DI UN ADMIN CON TUTTE LE DINAMICHE RELATIVE ALLA ELIMINAZIONE DI UNA FOTO
CREATE OR REPLACE FUNCTION galleria.eliminazione_utente_admin_fn()
RETURNS TRIGGER
AS $$
BEGIN
    
    

END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER eliminazione_utente_admin_tr
BEFORE INSERT ON galleria.SOGGETTO
FOR EACH ROW EXECUTE FUNCTION galleria.eliminazione_utente_admin_fn();




delete from galleria.foto where galleria.foto.idfoto = ( 
select c.idfoto
from GALLERIA.contenuta c join galleria.galleria g on c.idgalleria = g.idgalleria
where g.proprietario = 'AB123' AND g.condivisione = false 
except
select c.idfoto
from GALLERIA.contenuta c join galleria.galleria g on c.idgalleria = g.idgalleria
where g.proprietario = 'AB123' AND g.condivisione = true)

