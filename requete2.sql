-- 1. les événements à venir pour lesquels un utilisateur partage au moins 2 tags ? (au moins 3 tables)
SELECT e.id_evenement, e.nom_evenement, COUNT(*) AS nb_tags_communs
FROM Tag_user tu
JOIN Tag_evenement te ON tu.id_tag = te.id_tag
JOIN Evenement e ON e.id_evenement = te.id_evenement
WHERE tu.id_utilisateur = 1 AND e.date > NOW()
GROUP BY e.id_evenement, e.nom_evenement
HAVING COUNT(*) >= 2;
-- concert nflying 2 tags : rock et fun

-- 2. auto-jointure : trouver les utilisateurs habitant la même ville
SELECT u1.pseudo AS user1, u2.pseudo AS user2, u1.ville
FROM Utilisateur u1
JOIN Utilisateur u2 ON u1.ville = u2.ville AND u1.id_utilisateur < u2.id_utilisateur
ORDER BY u1.ville, u1.pseudo, u2.pseudo;
-- 79 lignes donc on peut limit si on en veut pas trop

-- 3. Sous-requête corrélée : événements auxquels participent tous les like d’un utilisateur
SELECT e.id_evenement, e.nom_evenement
FROM Evenement e
WHERE NOT EXISTS (
    SELECT 1
    FROM Interaction i
    WHERE (i.id_utilisateur_1 = 1 OR i.id_utilisateur_2 = 1)
      AND i.type_interaction = 'like'
      AND NOT EXISTS (
          SELECT 1 FROM Participe p
          WHERE p.id_evenement = e.id_evenement
            AND (p.id_utilisateur = i.id_utilisateur_1 OR p.id_utilisateur = i.id_utilisateur_2)
            AND p.id_utilisateur != 1
      )
);
-- pour le user 1 c'est le concert de the weeknd

-- par rapport a la 3 si on avait aucune interraction alors tout était vrai a cause du not exist
SELECT e.id_evenement, e.nom_evenement
FROM Evenement e
WHERE EXISTS (
    SELECT 1
    FROM Interaction i
    WHERE (i.id_utilisateur_1 = 41 OR i.id_utilisateur_2 = 41)
      AND i.type_interaction = 'like'
)
AND NOT EXISTS (
    SELECT 1
    FROM Interaction i
    WHERE (i.id_utilisateur_1 = 41 OR i.id_utilisateur_2 = 41)
      AND i.type_interaction = 'like'
      AND NOT EXISTS (
          SELECT 1 FROM Participe p
          WHERE p.id_evenement = e.id_evenement
            AND (p.id_utilisateur = i.id_utilisateur_1 OR p.id_utilisateur = i.id_utilisateur_2)
            AND p.id_utilisateur != 41
      )
);

-- 4. Sous-requête dans le FROM : top 5 artistes les plus écoutés
SELECT a.nom_artiste, ec.nb_ecoutes
FROM (
    SELECT m.id_artiste, COUNT(*) AS nb_ecoutes
    FROM Ecoute e
    JOIN Musique m ON e.id_musique = m.id_musique
    GROUP BY m.id_artiste
) ec
JOIN Artiste a ON a.id_artiste = ec.id_artiste
ORDER BY ec.nb_ecoutes DESC
LIMIT 10;
-- nflying at the top iktr

-- 5. Sous-requête dans le WHERE : utilisateurs ayant écouté une chanson d’un artiste précis
SELECT DISTINCT u.pseudo
FROM Utilisateur u
WHERE u.id_utilisateur IN (
    SELECT e.id_utilisateur
    FROM Ecoute e
    JOIN Musique m ON m.id_musique = e.id_musique
    WHERE m.id_artiste = 3
);
-- 3 c'est yoasobi et 4 listeners
-- 8 pour nflying et 5 listeners

-- 6. GROUP BY et HAVING : événements ayant plus de 3 participants
SELECT e.nom_evenement, COUNT(p.id_utilisateur) AS nb_participants
FROM Evenement e
JOIN Participe p ON p.id_evenement = e.id_evenement
GROUP BY e.id_evenement, e.nom_evenement
HAVING COUNT(p.id_utilisateur) > 3;
-- BTS avec 4 participants 

-- 7. GROUP BY et HAVING : artistes avec plus de 5 musiques écoutées ordre du plus au moins écouté
SELECT a.nom_artiste, COUNT(e.id_musique) AS total
FROM Ecoute e
JOIN Musique m ON e.id_musique = m.id_musique
JOIN Artiste a ON a.id_artiste = m.id_artiste
GROUP BY a.id_artiste, a.nom_artiste
HAVING COUNT(e.id_musique) > 5
ORDER BY total DESC;
-- 19 lignes 

-- 8. Moyenne des maximums d'écoutes d'artistes par utilisateur
SELECT AVG(max_ecoutes_par_utilisateur) AS moyenne_max_par_utilisateur
FROM (
    SELECT id_utilisateur, MAX(nb_ecoutes) AS max_ecoutes_par_utilisateur
    FROM (
        SELECT ec.id_utilisateur, m.id_artiste, COUNT(*) AS nb_ecoutes
        FROM Ecoute ec
        JOIN Musique m ON ec.id_musique = m.id_musique
        GROUP BY ec.id_utilisateur, m.id_artiste
    ) stats
    GROUP BY id_utilisateur
) max_stats;
-- environ 3 ecoute par user

-- 9. Jointure externe (LEFT JOIN) : événements et leurs lieux, même si le lieu est inconnu
SELECT e.nom_evenement, l.nom_lieu
FROM Evenement e
LEFT JOIN Lieu l ON e.lieu = l.id_lieu;
-- 41 ligne et nflying on a pas de lieu mais affiche qd meme

-- 10. Condition de totalité avec sous-requête corrélée : utilisateurs ayant participé à tous les event autre
SELECT u.id_utilisateur, u.pseudo
FROM Utilisateur u
WHERE NOT EXISTS (
    SELECT 1 FROM Evenement e
    WHERE e.type_evenement = 'autre'
    AND NOT EXISTS (
        SELECT 1 FROM Participe p
        WHERE p.id_utilisateur = u.id_utilisateur AND p.id_evenement = e.id_evenement
    )
);
-- user id : 3

-- 11. Condition de totalité avec agrégation : même requête via GROUP BY
SELECT p.id_utilisateur
FROM Participe p
JOIN Evenement e ON p.id_evenement = e.id_evenement
WHERE e.type_evenement = 'autre'
GROUP BY p.id_utilisateur
HAVING COUNT(DISTINCT p.id_evenement) = (SELECT COUNT(*) FROM Evenement WHERE type_evenement = 'autre');
-- tjrs user 3

-- 12. requêtes lié a NULL
-- A. Liste des utilisateurs n’ayant pas de ticketmaster_id (NULL)
SELECT pseudo FROM Utilisateur WHERE ticketmaster_id IS NULL;
-- B. Même requête avec "<>" renverra différents résultats si des NULL sont présents
SELECT pseudo FROM Utilisateur WHERE ticketmaster_id <> 'ticketmaster_alice';
-- Correction : inclure explicitement les NULL
SELECT pseudo FROM Utilisateur WHERE ticketmaster_id <> 'ticketmaster_alice' OR ticketmaster_id IS NULL;

-- 13. Requête récursive : prochaines dates libres pour un lieu après aujourd’hui
WITH RECURSIVE Dates_Disponibles(date_libre) AS (
    SELECT CURRENT_DATE
    UNION ALL
    SELECT (date_libre + INTERVAL '1 day')::date
    FROM Dates_Disponibles
    WHERE (date_libre + INTERVAL '1 day') < CURRENT_DATE + INTERVAL '30 days'
)
SELECT dd.date_libre
FROM Dates_Disponibles dd
WHERE NOT EXISTS (
    SELECT 1 FROM Evenement e
    WHERE e.lieu = 1 AND DATE(e.date) = dd.date_libre
)
LIMIT 10;
-- les 10 prochains jours pour l'instant 

-- 14. Fenêtrage : top 3 utilisateurs qui ont le plus envoyé de messages par mois
SELECT pseudo, mois, nb_likes
FROM (
    SELECT u.pseudo, 
           DATE_TRUNC('month', i.date_interaction) AS mois,
           COUNT(*) AS nb_likes,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', i.date_interaction) ORDER BY COUNT(*) DESC) AS rang
    FROM Interaction i
    JOIN Utilisateur u ON u.id_utilisateur = i.id_utilisateur_2
    WHERE i.type_interaction = 'message'
    GROUP BY u.pseudo, DATE_TRUNC('month', i.date_interaction)
) classement
WHERE rang <= 3;
-- 6 lignes 

-- 15. Musiques jamais écoutées
SELECT m.id_musique, m.titre
FROM Musique m
LEFT JOIN Ecoute e ON m.id_musique = e.id_musique
WHERE e.id_musique IS NULL;
-- 17 lignes dont tout oor #tristesse

-- 16. Nombre moyen d’événements par utilisateur
SELECT AVG(nb_events) AS moyenne_evenements
FROM (
    SELECT id_utilisateur, COUNT(*) AS nb_events
    FROM Participe
    GROUP BY id_utilisateur
) stats;
-- un peu plus de 1

-- 17. les 5 artistes dont les musiques sont les plus écoutées en moyenne
SELECT a.nom_artiste, AVG(ec.nb) AS moyenne
FROM (
    SELECT m.id_artiste, COUNT(*) AS nb
    FROM Ecoute e
    JOIN Musique m ON e.id_musique = m.id_musique
    GROUP BY m.id_artiste
) ec
JOIN Artiste a ON ec.id_artiste = a.id_artiste
GROUP BY a.nom_artiste
ORDER BY moyenne DESC
LIMIT 5;
-- nflying no1

-- 18. Lieux utilisés pour au moins 4 événements différents
SELECT l.nom_lieu, COUNT(*) AS total
FROM Lieu l
JOIN Evenement e ON l.id_lieu = e.lieu
GROUP BY l.id_lieu, l.nom_lieu
HAVING COUNT(*) >= 4;
-- BTS taylor angèle coldplay et drake

-- 19. Événements avec utilisateurs venant de villes différentes
SELECT e.id_evenement, e.nom_evenement
FROM Evenement e
JOIN Participe p1 ON e.id_evenement = p1.id_evenement
JOIN Utilisateur u1 ON p1.id_utilisateur = u1.id_utilisateur
JOIN Participe p2 ON e.id_evenement = p2.id_evenement AND p1.id_utilisateur <> p2.id_utilisateur
JOIN Utilisateur u2 ON p2.id_utilisateur = u2.id_utilisateur
WHERE u1.ville <> u2.ville
GROUP BY e.id_evenement, e.nom_evenement;
-- 11 lignes

-- 20. Les évenement où deux personnes qui ont match sont deja allé en même temps via ticketmaster
WITH Crush AS (
    SELECT CASE 
             WHEN id_utilisateur_1 = 5 THEN id_utilisateur_2
             ELSE id_utilisateur_1 
           END AS crush
    FROM Interaction
    WHERE (id_utilisateur_1 = 5 OR id_utilisateur_2 = 5)
      AND type_interaction = 'match'
),
Evenements_Communs AS (
    SELECT t1.nom_event
    FROM TicketMaster t1
    JOIN TicketMaster t2 ON t1.nom_event = t2.nom_event
    JOIN Crush c ON t2.id_utilisateur = c.crush
    WHERE t1.id_utilisateur = 5 AND t2.id_utilisateur != 5
)
SELECT nom_event
FROM Evenements_Communs
GROUP BY nom_event;
-- le crush qui devient le id_user dans le select case qui n'est pas 5
-- 3 ligne pour les user 1 et 5

-- 21. recommandation de personne a rencontrer dans un evenement deja recommandé
WITH Evenements_Recommandes AS (
    SELECT id_evenement
    FROM Recommandation
    WHERE id_utilisateur = 41
),
Utilisateurs_Recommandes AS (
    SELECT DISTINCT p.id_utilisateur
    FROM Participe p
    JOIN Evenements_Recommandes er ON er.id_evenement = p.id_evenement
    WHERE p.id_utilisateur != 41
)
SELECT u.id_utilisateur, u.pseudo
FROM Utilisateurs_Recommandes ur
JOIN Utilisateur u ON u.id_utilisateur = ur.id_utilisateur;
-- les personnes pour le user 41 : 4 lignes