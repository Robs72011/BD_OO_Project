CREATE TABLE IF NOT EXISTS galleria.UTENTE(
    IDUtente galleria.id_user_dt NOT NULL,
    Nome VARCHAR(30) NOT NULL,
    IsAdmin BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT utente_pk PRIMARY KEY (IDUtente)
);

CREATE TABLE IF NOT EXISTS galleria.LUOGO(
    Coordinate  galleria.coo_dt NOT NULL,
    Toponimo VARCHAR(30) UNIQUE,

    CONSTRAINT luogo_pk PRIMARY KEY (Coordinate)
);

CREATE TABLE IF NOT EXISTS galleria.FOTO(
    IDFoto galleria.id_object_dt NOT NULL,
    Dispositivo VARCHAR(30) NOT NULL DEFAULT 'Nameless', --il dispositivo non e' specificato nel caso l'utente non lo inserisce
    DataDiScatto DATE NOT NULL,
    DataEliminazione DATE DEFAULT NULL,
    Visibilita BOOLEAN NOT NULL DEFAULT TRUE,
    InVideo BOOLEAN NOT NULL DEFAULT FALSE,
    Coordinate galleria.coo_dt, 
    Autore galleria.id_user_dt NOT NULL,

    CONSTRAINT foto_pk PRIMARY KEY (IDFoto),
    
    CHECK(DataDiScatto < DataEliminazione),
    CHECK(IDFoto ~ '^F'),

    CONSTRAINT coordinate_fk FOREIGN KEY (Coordinate) REFERENCES galleria.LUOGO(Coordinate) 
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT autore_fk FOREIGN KEY (Autore) REFERENCES galleria.UTENTE(IDUtente)
        ON UPDATE CASCADE ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS galleria.SOGGETTO(
    Foto galleria.id_object_dt NOT NULL,
    NomeSoggetto VARCHAR(30) NOT NULL UNIQUE,
    Categoria VARCHAR(30) NOT NULL,

    CONSTRAINT soggetto_pk PRIMARY KEY (Foto, NomeSoggetto),

    CONSTRAINT foto_raffigurante_fk FOREIGN KEY (Foto) REFERENCES galleria.FOTO(IDFoto) 
        ON UPDATE CASCADE ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS galleria.VIDEO(
    IDVideo galleria.id_object_dt NOT NULL,
    TitoloVideo VARCHAR(30) NOT NULL,
    Descrizione TEXT,

    CHECK(IDVideo ~ '^V'),

    CONSTRAINT video_pk PRIMARY KEY (IDVideo)
);

CREATE TABLE IF NOT EXISTS galleria.GALLERIA(

    IDGalleria galleria.id_object_dt  NOT NULL,
    NomeGalelria VARCHAR(30)  NOT NULL,
    Condivisione BOOLEAN DEFAULT FALSE,
    Proprietario galleria.id_user_dt  NOT NULL,

    CONSTRAINT galleria_pk PRIMARY KEY (IDGalleria),

    CHECK(IDGalleria ~ '^G'),

    CONSTRAINT proprietario_fk FOREIGN KEY (Proprietario) REFERENCES galleria.UTENTE(IDUtente)
        ON UPDATE CASCADE ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS galleria.COMPONE(

    IDVideo galleria.id_object_dt  NOT NULL,
    IDFoto galleria.id_object_dt  NOT NULL,

    CONSTRAINT compone_pk PRIMARY KEY (IDVideo, IDFoto),

    CONSTRAINT video_fk FOREIGN KEY (IDVideo) REFERENCES galleria.VIDEO(IDVideo)
        ON UPDATE CASCADE ON DELETE NO ACTION,
    CONSTRAINT foto_fk FOREIGN KEY (IDFoto) REFERENCES galleria.FOTO(IDFoto)
        ON UPDATE CASCADE ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS galleria.CONTENUTA(

    IDGalleria galleria.id_object_dt  NOT NULL,
    IDFoto galleria.id_object_dt  NOT NULL,

    CONSTRAINT contenuta_pk PRIMARY KEY (IDGalleria, IDFoto),

    CONSTRAINT galleria_contenitrice_fk FOREIGN KEY (IDGalleria) REFERENCES galleria.GALLERIA(IDGalleria)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT foto_contenuta_fk FOREIGN KEY (IDFoto) REFERENCES galleria.FOTO(IDFoto)   
        ON UPDATE CASCADE ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS galleria.PARTECIPA(

    IDGalleria galleria.id_object_dt  NOT NULL,
    IDUtente galleria.id_user_dt  NOT NULL,

    CONSTRAINT partecipa_pk PRIMARY KEY (IDGalleria, IDUtente),

    CONSTRAINT galleria_fk FOREIGN KEY (IDGalleria) REFERENCES galleria.GALLERIA(IDGalleria)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT utente_partecipante_fk FOREIGN KEY (IDUtente) REFERENCES galleria.UTENTE(IDUtente)
        ON UPDATE CASCADE ON DELETE CASCADE
);