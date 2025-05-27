-- DROP QD ON RELANCE

DROP TABLE IF EXISTS Tag_evenement CASCADE;
DROP TABLE IF EXISTS Tag_artiste CASCADE;
DROP TABLE IF EXISTS Tag_musique CASCADE;
DROP TABLE IF EXISTS Tag_lieu CASCADE;
DROP TABLE IF EXISTS Tag_user CASCADE;

DROP TABLE IF EXISTS Recommandation CASCADE;
DROP TABLE IF EXISTS Ecoute CASCADE;
DROP TABLE IF EXISTS Participe CASCADE;
DROP TABLE IF EXISTS Interaction CASCADE;

DROP TABLE IF EXISTS Festival_Artiste CASCADE;
DROP TABLE IF EXISTS Festival CASCADE;
DROP TABLE IF EXISTS Concert CASCADE;
DROP TABLE IF EXISTS Autre_Evenement CASCADE;
DROP TABLE IF EXISTS Evenement CASCADE;
DROP TABLE IF EXISTS Lieu CASCADE;
DROP TABLE IF EXISTS TicketMaster CASCADE;
DROP TABLE IF EXISTS Musique CASCADE;
DROP TABLE IF EXISTS Artiste CASCADE;
DROP TABLE IF EXISTS Tag CASCADE;
DROP TABLE IF EXISTS Utilisateur CASCADE;
DROP TYPE IF EXISTS genre_enum;
DROP TYPE IF EXISTS orientation_enum;
DROP TYPE IF EXISTS interaction_enum;

-- CREATION DES TABLES

CREATE TYPE genre_enum AS ENUM ('homme', 'femme', 'non-binaire', 'autre');
CREATE TYPE orientation_enum AS ENUM ('hetero', 'bi', 'gay', 'pan');
CREATE TYPE interaction_enum AS ENUM ('like', 'nope', 'match', 'message');


CREATE TABLE Utilisateur (
    id_utilisateur SERIAL PRIMARY KEY,
    pseudo VARCHAR(50) UNIQUE NOT NULL,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(100) NOT NULL,
    date_naissance DATE CHECK (date_naissance <= CURRENT_DATE - INTERVAL '18 years'),
    ville VARCHAR(50),
    pays VARCHAR(50),
    genre genre_enum,
    orientation_sexuelle orientation_enum,
    abonnement BOOLEAN DEFAULT FALSE,
    spotify_id VARCHAR(100),
    ticketmaster_id VARCHAR(100),
    type_utilisateur VARCHAR(20) CHECK (type_utilisateur IN ('organisateur', 'participant')),
    CHECK (
        spotify_id IS NOT NULL
        OR ticketmaster_id IS NOT NULL
    )
);

CREATE TABLE Lieu (
    id_lieu SERIAL PRIMARY KEY,
    nom_lieu VARCHAR(100),
    adresse TEXT,
    ville VARCHAR(50),
    type_lieu VARCHAR(50)
);


CREATE TABLE Artiste (
    id_artiste SERIAL PRIMARY KEY,
    nom_artiste VARCHAR(100),
    genre_musical VARCHAR(50)
);

CREATE TABLE Musique (
    id_musique SERIAL PRIMARY KEY,
    titre VARCHAR(100),
    id_artiste INTEGER,
    duree INTEGER,
    genre_musical VARCHAR(50),
    spotify_track_id VARCHAR(100),
    FOREIGN KEY (id_artiste) REFERENCES Artiste(id_artiste)
);

-- table asso
CREATE TABLE Ecoute (
    id_ecoute SERIAL,
    id_utilisateur INTEGER,
    id_musique INTEGER,
    PRIMARY KEY (id_ecoute, id_utilisateur, id_musique),
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateur(id_utilisateur) ON DELETE CASCADE,
    FOREIGN KEY (id_musique) REFERENCES Musique(id_musique) ON DELETE CASCADE
);

CREATE TABLE TicketMaster (
    id_ticketmaster SERIAL,
    id_utilisateur INTEGER,
    nom_event VARCHAR(50),
    genre VARCHAR(50),
    date_participation DATE,
    PRIMARY KEY (id_ticketmaster, id_utilisateur),
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateur(id_utilisateur)
);

CREATE TABLE Evenement (
    id_evenement SERIAL PRIMARY KEY,
    nom_evenement VARCHAR(100),
    date TIMESTAMP,
    lieu INTEGER,
    prix NUMERIC(6,2),
    id_organisateur INTEGER,
    type_evenement VARCHAR(20) CHECK (type_evenement IN ('concert', 'festival', 'autre')),
    ticketmaster_id VARCHAR(100),
    FOREIGN KEY (id_organisateur) REFERENCES Utilisateur(id_utilisateur),
    FOREIGN KEY (lieu) REFERENCES Lieu(id_lieu)
);

-- table asso
CREATE TABLE Participe (
    id_utilisateur INTEGER,
    id_evenement INTEGER,
    statut VARCHAR(20) CHECK (statut IN ('intéressé', 'participant')),
    PRIMARY KEY (id_utilisateur,id_evenement),
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateur(id_utilisateur) ON DELETE CASCADE,
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement) ON DELETE CASCADE
);

-- herit event
CREATE TABLE Concert (
    id_evenement INTEGER PRIMARY KEY,
    id_artiste INTEGER,
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement) ON DELETE CASCADE,
    FOREIGN KEY (id_artiste) REFERENCES Artiste(id_artiste)
);

-- herit event
CREATE TABLE Festival (
    id_evenement INTEGER PRIMARY KEY,
    nb_jours INTEGER CHECK (nb_jours > 0),
    avec_camping BOOLEAN,
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement) ON DELETE CASCADE
);

-- table d'association
CREATE TABLE Festival_Artiste (
    id_evenement INTEGER,
    id_artiste INTEGER,
    PRIMARY KEY (id_evenement, id_artiste),
    FOREIGN KEY (id_evenement) REFERENCES Festival(id_evenement) ON DELETE CASCADE,
    FOREIGN KEY (id_artiste) REFERENCES Artiste(id_artiste)
);


-- herit event
CREATE TABLE Autre_Evenement (
    id_evenement INTEGER PRIMARY KEY,
    description TEXT,
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement) ON DELETE CASCADE
);

-- entit faible
CREATE TABLE Interaction (
    id_utilisateur_1 INTEGER,--envoie si pas match
    id_utilisateur_2 INTEGER,--reçoie si pas match
    type_interaction interaction_enum,
    date_interaction TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id_utilisateur_1, id_utilisateur_2, date_interaction),
    FOREIGN KEY (id_utilisateur_1) REFERENCES Utilisateur(id_utilisateur),
    FOREIGN KEY (id_utilisateur_2) REFERENCES Utilisateur(id_utilisateur),
    CHECK (id_utilisateur_1 <> id_utilisateur_2)
);


CREATE TABLE Recommandation (
    id_recommandation SERIAL PRIMARY KEY,
    id_utilisateur INTEGER,
    id_evenement INTEGER,
    score_recommandation FLOAT,
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateur(id_utilisateur),
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement)
);

-- pour les tag
CREATE TABLE Tag (
    id_tag SERIAL PRIMARY KEY,
    nom_tag VARCHAR(50) UNIQUE NOT NULL
);

-- tables d'asso
CREATE TABLE Tag_lieu (
    id_tag INTEGER,
    id_lieu INTEGER,
    PRIMARY KEY (id_tag, id_lieu),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag),
    FOREIGN KEY (id_lieu) REFERENCES Lieu(id_lieu)
);

CREATE TABLE Tag_user (
    id_tag INTEGER,
    id_utilisateur INTEGER,
    PRIMARY KEY (id_tag, id_utilisateur),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag),
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateur(id_utilisateur)
);

CREATE TABLE Tag_musique (
    id_tag INTEGER,
    id_musique INTEGER,
    PRIMARY KEY (id_tag, id_musique),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag),
    FOREIGN KEY (id_musique) REFERENCES Musique(id_musique)
);

CREATE TABLE Tag_artiste (
    id_tag INTEGER,
    id_artiste INTEGER,
    PRIMARY KEY (id_tag, id_artiste),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag),
    FOREIGN KEY (id_artiste) REFERENCES Artiste(id_artiste)
);

CREATE TABLE Tag_evenement (
    id_tag INTEGER,
    id_evenement INTEGER,
    PRIMARY KEY (id_tag, id_evenement),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag),
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement)
);
