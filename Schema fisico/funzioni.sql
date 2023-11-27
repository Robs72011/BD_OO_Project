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

CREATE OR REPLACE FUNCTION galleria.elimina_foto_gal_priv_fn(foto_da_eliminare IN galleria.id_user_dt)
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
	END;

	DELETE FROM galleria.CONTENUTA
	WHERE idfoto = foto_da_eliminare AND idgalleria IN (
		SELECT idgalleria
		FROM galleria.GALLERIA
		WHERE Condivisione = FALSE
	);


END;
$$ LANGUAGE PLPGSQL;
