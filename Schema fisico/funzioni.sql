--con CONDIVISIONE = FALSE, prendo tutte le gallerie private
--con PROPRIETARIO = AUTORE, vado a prendere tutte le foto presente nella galleria personale di quel utente
CREATE OR REPLACE FUNCTION elimina_foto_gal_pers_fn(foto_da_eliminare IN CHAR)
RETURNS TEXT
AS $$
BEGIN
	DELETE FROM galleria.CONTENUTA c
	WHERE EXISTS(
			SELECT 1
			FROM galleria.GALLERIA g 
			JOIN galleria.FOTO f ON g.IDGalleria = c.IDGalleria AND f.IDFoto = c.IDFoto
			WHERE g.condivisione = FALSE AND g.proprietario = f.autore AND f.IDFOTO = foto_da_eliminare
			);
	RETURN 'La foto è stata eliminata correttamente.';
END;
$$
LANGUAGE PLPGSQL


--creata per la creazione della galleria personale e generare un id passando come parametro la prima lettera
CREATE OR REPLACE FUNCTION galleria.genera_id(iniziale IN CHAR)
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


--creata per generare il nome di un galleria passando il nome utente.
CREATE OR REPLACE FUNCTION galleria.genera_nome_galleria(nome_utente IN VARCHAR)
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