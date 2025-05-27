# Projet de L3 semestre 6

## Présentation du projet:

big match lié à la musique, base de donnée d'une application de rencontre.

_Le projet fonctionne en Postgresql._

### fichiers : 

- la creation de la base avec les create table (base.sql)

- le fichier de remplissage des tables (tableTemp.sql)

- les .csv pour remplir les tables dans le dossier CSV

- le fichier de requête sql (requete2.sql)

- l'algorithme de matching (reco_Algo.sql)


#### Pour remplir la base dans cet ordre

- Il faut créé la base avant de lancer les commandes dans postgresql si celle-ci n'existe pas encore.

créer les tables:
```
\i /chemin/base.sql
```

remplir la base:
```
\i /chemin/tableTemp.sql
```


**Projet réalisé en duo dans le cadre du cours Base de Données à l'université Paris Cité.**

_Année 2024-2025_