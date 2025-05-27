-- Algo de matching pour recommander des evenements

WITH 
-- 1. Tags communs entre utilisateur et événements
User_Tags AS (
    SELECT id_tag
    FROM Tag_user
    WHERE id_utilisateur = 41
),
Event_Tags AS (
    SELECT e_tag.id_evenement, COUNT(*) AS nb_tags_communs
    FROM Tag_evenement e_tag
    JOIN User_Tags ut ON ut.id_tag = e_tag.id_tag
    JOIN Evenement e ON e.id_evenement = e_tag.id_evenement
    WHERE e.date > NOW()
    GROUP BY e_tag.id_evenement
),

-- 2. Artistes écoutés par l'utilisateur
Artistes_Ecoutes AS (
    SELECT DISTINCT m.id_artiste
    FROM Ecoute ec
    JOIN Musique m ON ec.id_musique = m.id_musique
    WHERE ec.id_utilisateur = 41
),

-- 3. Concerts avec artistes écoutés
Concerts_Connus AS (
    SELECT c.id_evenement, 1 AS artiste_match
    FROM Concert c
    JOIN Artistes_Ecoutes ae ON ae.id_artiste = c.id_artiste
),

-- 4. Proximité géographique : on utilise la ville de l'utilisateur
Ville_User AS (
    SELECT ville FROM Utilisateur WHERE id_utilisateur = 41
),
Concerts_Proches AS (
    SELECT e.id_evenement, 1 AS ville_match
    FROM Evenement e
    JOIN Lieu l ON e.lieu = l.id_lieu
    JOIN Ville_User vu ON l.ville = vu.ville
    WHERE e.date > NOW()
),

-- 5. Interactions sociales positives (like/match avec des gens allant à l’événement)
Social_Match AS (
    SELECT p.id_evenement, COUNT(*) AS nb_interactions
    FROM Participe p
    JOIN Interaction i 
      ON ((i.id_utilisateur_1 = 41 AND i.id_utilisateur_2 = p.id_utilisateur)
       OR (i.id_utilisateur_2 = 41 AND i.id_utilisateur_1 = p.id_utilisateur))
    WHERE i.type_interaction IN ('like', 'match') AND p.id_utilisateur != 41
    GROUP BY p.id_evenement
)

-- 6. Score final combiné
SELECT 
    e.id_evenement,
    e.nom_evenement,
    e.date,
    COALESCE(et.nb_tags_communs, 0) * 2 + 
    COALESCE(cc.artiste_match, 0) * 4 + 
    COALESCE(cp.ville_match, 0) * 1.5 + 
    COALESCE(sm.nb_interactions, 0) * 3 AS score_recommandation
FROM Evenement e
LEFT JOIN Concerts_Connus cc ON e.id_evenement = cc.id_evenement
LEFT JOIN Event_Tags et ON e.id_evenement = et.id_evenement
LEFT JOIN Concerts_Proches cp ON e.id_evenement = cp.id_evenement
LEFT JOIN Social_Match sm ON e.id_evenement = sm.id_evenement
WHERE e.date > NOW() AND e.type_evenement = 'concert'
ORDER BY score_recommandation DESC
LIMIT 10;


-- Algo de matching pour recommander des personnes
WITH 
-- 1. Tags de l'utilisateur courant
User_Tags AS (
    SELECT id_tag
    FROM Tag_user
    WHERE id_utilisateur = 41
),

-- 2. Autres utilisateurs partageant au moins un tag
Common_Tags AS (
    SELECT tu.id_utilisateur, COUNT(*) AS nb_tags_communs
    FROM Tag_user tu
    JOIN User_Tags ut ON tu.id_tag = ut.id_tag
    WHERE tu.id_utilisateur != 41
    GROUP BY tu.id_utilisateur
),

-- 3. Artistes écoutés par l'utilisateur courant
Artistes_Ecoutes AS (
    SELECT DISTINCT m.id_artiste
    FROM Ecoute ec
    JOIN Musique m ON ec.id_musique = m.id_musique
    WHERE ec.id_utilisateur = 41
),

-- 4. Utilisateurs ayant écouté les mêmes artistes
Common_Artists AS (
    SELECT ec.id_utilisateur, 1 AS artiste_match
    FROM Ecoute ec
    JOIN Musique m ON ec.id_musique = m.id_musique
    JOIN Artistes_Ecoutes ae ON ae.id_artiste = m.id_artiste
    WHERE ec.id_utilisateur != 41
    GROUP BY ec.id_utilisateur
),

-- 5. Utilisateurs habitant dans la même ville
Same_City AS (
    SELECT u2.id_utilisateur, 1 AS ville_match
    FROM Utilisateur u1
    JOIN Utilisateur u2 
      ON u1.ville = u2.ville
    WHERE u1.id_utilisateur = 41 AND u2.id_utilisateur != 41
),

-- 6. Interactions sociales déjà positives avec ces utilisateurs
Social_Score AS (
    SELECT 
        CASE 
            WHEN i.id_utilisateur_1 = 41 THEN i.id_utilisateur_2
            ELSE i.id_utilisateur_1
        END AS id_utilisateur,
        COUNT(*) AS nb_interactions
    FROM Interaction i
    WHERE (i.id_utilisateur_1 = 41 OR i.id_utilisateur_2 = 41)
      AND i.type_interaction IN ('like', 'match')
      AND i.id_utilisateur_1 != i.id_utilisateur_2
    GROUP BY id_utilisateur
)

-- Score final combiné
SELECT 
    u.id_utilisateur,
    u.pseudo,
    COALESCE(ct.nb_tags_communs, 0) * 2 + 
    COALESCE(ca.artiste_match, 0) * 4 + 
    COALESCE(sc.ville_match, 0) * 1.5 + 
    COALESCE(ss.nb_interactions, 0) * 3 AS score_affinite
FROM Utilisateur u
LEFT JOIN Common_Tags ct ON u.id_utilisateur = ct.id_utilisateur
LEFT JOIN Common_Artists ca ON u.id_utilisateur = ca.id_utilisateur
LEFT JOIN Same_City sc ON u.id_utilisateur = sc.id_utilisateur
LEFT JOIN Social_Score ss ON u.id_utilisateur = ss.id_utilisateur
WHERE u.id_utilisateur != 41
ORDER BY score_affinite DESC
LIMIT 10;
