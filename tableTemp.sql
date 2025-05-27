-- REMPLISSAGE DES TABLES attention a cp les fichier dans tmp

COPY Utilisateur 
FROM '/tmp/Utilisateur.csv' 
DELIMITER ',' CSV HEADER;

CREATE TEMPORARY TABLE temp_lieu (
    department INTEGER,
    nom TEXT,
    adresse_1 TEXT,
    adresse2 TEXT,
    adresse3 TEXT,
    code_postal TEXT,
    ville TEXT,
    email TEXT,
    telephone TEXT,
    fax TEXT,
    web TEXT,
    wgs84 TEXT
);

COPY temp_lieu(department, nom, adresse_1, adresse2, adresse3, code_postal, ville, email, telephone, fax, web, wgs84)
FROM '/tmp/les-lieux-de-diffusion-du-spectacle-vivant-en-ile-de-france.csv'
DELIMITER ';' CSV HEADER;

INSERT INTO Lieu (nom_lieu, adresse, ville)
SELECT 
    nom AS nom_lieu,
    adresse_1 AS adresse,
    ville
FROM temp_lieu
LIMIT 20;

DROP TABLE temp_lieu;

UPDATE Lieu
SET type_lieu = 'spectacle vivant'
WHERE id_lieu IN (
    SELECT id_lieu 
    FROM Lieu 
    ORDER BY id_lieu
    LIMIT 20
);

COPY Lieu(nom_lieu, adresse, ville, type_lieu)
FROM '/tmp/Lieu.csv' 
DELIMITER ',' CSV HEADER;

COPY Artiste(id_artiste, nom_artiste, genre_musical)
FROM '/tmp/Artiste.csv' 
DELIMITER ',' CSV HEADER;

COPY Musique(titre, id_artiste, duree, genre_musical, spotify_track_id) 
FROM '/tmp/Musique.csv' 
DELIMITER ',' CSV HEADER;

COPY Ecoute(id_utilisateur, id_musique) 
FROM '/tmp/ecoute.csv' 
DELIMITER ',' CSV HEADER;

COPY TicketMaster(id_utilisateur, nom_event, genre, date_participation) 
FROM '/tmp/ticketMaster.csv' 
DELIMITER ',' CSV HEADER;

COPY Evenement 
FROM '/tmp/Evenement.csv' 
DELIMITER ',' CSV HEADER;

COPY Concert(id_evenement, id_artiste) 
FROM '/tmp/Concert.csv' 
DELIMITER ',' CSV HEADER;

COPY Festival(id_evenement, nb_jours, avec_camping) 
FROM '/tmp/Festival.csv' 
DELIMITER ',' CSV HEADER;

COPY Festival_Artiste(id_evenement, id_artiste)
FROM '/tmp/Festival_artiste.csv' 
DELIMITER ',' CSV HEADER;

COPY Autre_Evenement(id_evenement, description) 
FROM '/tmp/autre_evenement.csv' 
DELIMITER ',' CSV HEADER;

COPY Participe 
FROM '/tmp/Participe.csv' 
DELIMITER ',' CSV HEADER;

COPY Interaction 
FROM '/tmp/Interaction.csv' 
DELIMITER ',' CSV HEADER;

COPY Recommandation(id_utilisateur, id_evenement, score_recommandation)
FROM '/tmp/Recommandation.csv' 
DELIMITER ',' CSV HEADER;

COPY Tag 
FROM '/tmp/Tag.csv' 
DELIMITER ',' CSV HEADER;

COPY Tag_artiste 
FROM '/tmp/Tag_artiste.csv' 
DELIMITER ',' CSV HEADER;

COPY Tag_evenement 
FROM '/tmp/Tag_evenement.csv' 
DELIMITER ',' CSV HEADER;

COPY Tag_lieu 
FROM '/tmp/Tag_lieu.csv' 
DELIMITER ',' CSV HEADER;

COPY Tag_musique 
FROM '/tmp/Tag_musique.csv' 
DELIMITER ',' CSV HEADER;

COPY Tag_user 
FROM '/tmp/tag_user.csv' 
DELIMITER ',' CSV HEADER;
