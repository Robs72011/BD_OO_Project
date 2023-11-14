--Eliminazione di una foto da una galleria personale, DA RIVEDERE
--con CONDIVISIONE = FALSE, prendo tutte le gallerie private
--con PROPRIETARIO = AUTORE, vado a prendere tutte le foto presente nella galleria personale di quel utente
CREATE OR REPLACE FUNCTION galleria.elimina_foto_gal_pers_fn(foto_da_eliminare IN CHAR)
RETURNS TEXT
AS $$
BEGIN
	--Vado ad eliminare la foto da "CONTENUTA"
	DELETE FROM galleria.CONTENUTA c
	WHERE EXISTS(
			SELECT 1
			FROM galleria.GALLERIA g 
			JOIN galleria.FOTO f ON g.IDGalleria = c.IDGalleria AND f.IDFoto = c.IDFoto
			WHERE g.condivisione = FALSE AND g.proprietario = f.autore AND f.IDFOTO = foto_da_eliminare
			);

	--Aggiorno la data di eliminazione, della foto appena eliminata da un galleria personale, alla data corrente
	UPDATE galleria.FOTO 
	SET DataEliminazione = current_date
	WHERE IDFOTO = foto_da_eliminare;

	UPDATE galleria.FOTO 
	SET Autore = 'ADMN1' --modificare con l'effettivo id dell'admin
	WHERE IDFOTO = foto_da_eliminare;

	RETURN 'La foto è stata eliminata correttamente.';
END;
$$
LANGUAGE PLPGSQL;


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