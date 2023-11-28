--creata per la creazione della galleria personale e generare un id passando come parametro la prima lettera
CREATE OR REPLACE FUNCTION galleria.genera_id_fn(iniziale IN CHAR)
RETURNS CHAR(10)
AS $$
DECLARE
    nuovo_id CHAR(10);
BEGIN
    SELECT iniziale || array_to_string(array(select substr('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',((random()*(36-1)+1)::integer),1) from generate_series(1,9)),'') INTO nuovo_id;
    RETURN nuovo_id;
END;
$$
LANGUAGE PLPGSQL;


--Generazione del nome di un galleria passando il nome utente.
CREATE OR REPLACE FUNCTION galleria.genera_nome_galleria_fn(nome_utente IN VARCHAR)
RETURNS VARCHAR
AS $$
DECLARE
	nome_galleria VARCHAR;
BEGIN
	nome_galleria := 'Galleria di ' || nome_utente;
    RETURN nome_galleria;
END;
$$
LANGUAGE PLPGSQL;

--Recupero di tutte le foto dato un determinato soggetto.
CREATE OR REPLACE FUNCTION galleria.recupero_soggetti_fn(cercare IN VARCHAR(50))
RETURNS TABLE(fotografia galleria.id_object_dt)
AS $$
BEGIN

	RETURN QUERY 
	SELECT foto
	FROM galleria.SOGGETTO S
	WHERE S.NomeSoggetto = cercare;
    
END;
$$
LANGUAGE PLPGSQL;

--Recupero di tutte le foto data una coppia di coordinate
CREATE OR REPLACE FUNCTION galleria.recupero_foto_luoghi_fn(cercare galleria.coo_dt)
RETURNS TABLE(fotografia galleria.id_object_dt)
AS $$
BEGIN

 RETURN QUERY 
 SELECT IDFoto
 FROM galleria.FOTO F
 WHERE F.coordinate = cercare;
    
END;
$$
LANGUAGE PLPGSQL;

-Funzione che elimina una foto da una galleruia privana nel modo adeguato 

CREATE OR REPLACE FUNCTION galleria.elimina_foto_gal_priv_fn(foto_da_eliminare IN galleria.id_object_dt)
RETURNS VOID
AS $$
DECLARE
	check_foto INT;
BEGIN

	SELECT COUNT(*) INTO check_foto
	FROM galleria.FOTO
	WHERE idfoto = foto_da_eliminare;

	IF check_foto = 0 THEN
		RAISE EXCEPTION 'La foto non esiste.';
	END IF;

	DELETE FROM galleria.CONTENUTA
	WHERE idfoto = foto_da_eliminare AND idgalleria IN (
		SELECT idgalleria
		FROM galleria.GALLERIA
		WHERE Condivisione = FALSE
	);
	
	SELECT COUNT(*) INTO check_foto
	FROM galleria.CONTENUTA
	WHERE idfoto = foto_da_eliminare;
	
	IF check_foto = 0 THEN
		UPDATE galleria.FOTO SET dataeliminazione = current_date WHERE idfoto = foto_da_eliminare AND invideo = true;
		DELETE FROM galleria.FOTO WHERE idfoto = foto_da_eliminare AND invideo = false;
	END IF;
	
END;
$$ LANGUAGE PLPGSQL;
-- Funzione che genera un video  

CREATE OR REPLACE FUNCTION galleria.creazione_video_fn(idgall IN galleria.id_object_dt, foto IN TEXT, descrizione IN TEXT, titolo IN galleria.string)
RETURNS VOID
AS $$
DECLARE 
 verifica INT;
 singola_foto galleria.id_object_dt;
 idv_tmp galleria.id_object_dt;
 text_tmp TEXT;
 
BEGIN 
 SELECT COUNT(*) INTO verifica
 FROM galleria.GALLERIA
 WHERE idgalleria = idgall and condivisione  = false;
 
 IF verifica = 0 THEN 
  RAISE EXCEPTION 'La galleria che mi hai dato non esiste';
 END IF;
 
 idv_tmp := galleria.genera_id_fn('V');
 
 INSERT INTO galleria.VIDEO VALUES (idv_tmp, titolo, descrizione, idgall);
 
 
 WHILE LENGTH(foto) <> 0 LOOP
  singola_foto := SUBSTRING(foto from 1 for 10);
 
  SELECT COUNT(*) INTO verifica
  FROM galleria.CONTENUTA
  WHERE idgalleria = idgall and idfoto = singola_foto;
 
  IF verifica <> 0 THEN
   INSERT INTO galleria.COMPONE VALUES (idv_tmp, singola_foto);
   UPDATE galleria.foto SET invideo = true WHERE idfoto = singola_foto;
  END IF;
  
  text_tmp := SUBSTRING(foto from 12);
  foto :=text_tmp;
  
 END LOOP;
 
 
END;
$$ 
LANGUAGE PLPGSQL;
