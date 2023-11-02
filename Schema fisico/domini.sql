
DROP SCHEMA IF EXISTS galleria CASCADE;
CREATE SCHEMA galleria AUTHORIZATION postgres;

--dominio dedicato agli identificativi degli utenti. dt sta per "data type"
CREATE DOMAIN galleria.id_user_dt CHAR(5)
    CONSTRAINT id_user_dt_alnum CHECK (VALUE ~ '^[A-Z0-9]+$');


--dominio dedicato agli identificati degli oggetti, per oggetti s'intende foto, video gallerie, etc.
CREATE DOMAIN galleria.id_object_dt CHAR(10)
    CONSTRAINT id_object_dt_alnum CHECK (VALUE ~ '^[A-Z0-9]+$');


--dominio dedicato alle coordinate, espresse in modo decimale, con una precisione fino a 2 decimali.
CREATE DOMAIN galleria.coo_dt CHAR(14)
    CONSTRAINT coordinate_format CHECK (VALUE ~ '^[+-][0-9]{2}\.[0-9]{2},[+-][0-9]{3}\.[0-9]{2}$');

CREATE TABLE IF NOT EXISTS galleria.UTENTE(
    IDUtente galleria.id_user_dt NOT NULL,
    Nome VARCHAR(30) UNIQUE  NOT NULL,
    IsAdmin BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT utente_pk PRIMARY KEY (IDUtente)
);

CREATE TABLE IF NOT EXISTS galleria.LUOGO(
    Coordinate  galleria.coo_dt NOT NULL,
    Toponimo VARCHAR(30) UNIQUE NOT NULL,

    CONSTRAINT luogo_pk PRIMARY KEY (Coordinate)
);