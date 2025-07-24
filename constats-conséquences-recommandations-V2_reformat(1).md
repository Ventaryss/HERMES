# 🛡️ Aide à la Rédaction du Rapport Technique

### État-major des Armées  
**Commandement de la cyberdéfense**  
**Groupement de cyberdéfense des Armées**  
**Centre d’audit de sécurité des systèmes d’informations**  

📍 *Rennes, le 23 juillet 2025*

---

État-major des Armées
Commandement de la cyberdéfense
Groupement de cyberdéfense des Armées

Centre d’audit de sécurité des systèmes d’informations

Rennes, le 23 juillet 2025

AIDE A LA REDACTION Du RAPPORT TECHNIQUE

## 🧭 1.1. Principe d’architecture

L’audit d’architecture consiste en la vérification de la conformité des pratiques de sécurité relatives au choix, au positionnement et à la mise en œuvre des dispositifs matériels et logiciels déployés dans un SI, à l’état de l’art et aux exigences et règles internes de l’audité. L’audit peut être étendu aux interconnexions avec des réseaux tiers, et notamment internet.

Il n’est pas possible de sécuriser de manière efficace un SI sans connaître les biens essentiels, les besoins de sécurité et les risques redoutés de celui-ci.

Résultats liés à l’élaboration du SI

Choix des dispositifs matériels et logiciels

Failles de sécurité

Du matériel obsolète ou non sécurisé (ex : routeurs, IoT, caméras...) peut introduire des vulnérabilités non corrigeables.

Des logiciels non maintenus ou non compatibles avec les mises à jour de sécurité.

Absence de chiffrement matériel (ex : TPM, HSM) compromet les données sensibles.

Surface d’attaque étendue

L'ajout de composants inutiles ou mal intégrés apporte plus de points d’entrée aux attaquants.

Les logiciels ou systèmes avec des ports/services non nécessaires ouverts augmentent les vecteurs d’attaque.

Diminution des performances de sécurité

Un antivirus ou un pare-feu mal adapté au matériel peut causer une dégradation de performance ou ne pas fonctionner correctement.

Dispositifs non conçus pour gérer une charge spécifique peuvent saturer ou tomber en panne, rendant les protections inefficaces.

Non-conformité réglementaire

Certains logiciels ou matériels peuvent ne pas répondre aux exigences des normes (ex : RGPD, ISO 27001, PCI-DSS...) et cela peut entraîner des sanctions légales.

Coûts accrus

Le mauvais choix engendre un besoin de remplacement prématuré ou des coûts supplémentaires en support et en mise à jour.

Le risque accru de cyberattaque entraînera des coûts de remédiation, une perte de données et surtout une atteinte à l’image du Minarm.

Difficulté de mise à jour ou d’évolution

Architecture rigide ou propriétaire rend difficile :

La correction rapide des failles.

L’intégration de nouvelles protections (EDR, SIEM, MFA...).

Choix de composants non compatibles entre eux peut empêcher le bon fonctionnement des solutions de sécurité.

Une mauvaise intégration engendre des vides dans la chaîne de défense (ex : logs non centralisables, cloisonnement réseau inefficace, etc. ...).

Positionnement des dispositifs matériels

Protection inefficace

Si un pare-feu est mal placé (ex : en aval au lieu d'en amont), le trafic malveillant peut atteindre des ressources critiques sans filtrage.

Un WAF mal positionné ne protège pas correctement les serveurs web.

Exemple : un WAF placé après un load balancer → il ne voit pas les vraies requêtes entrantes.

Création de zones non protégées ou zones grises

Des zones du réseau peuvent ne pas être surveillées ou filtrées si les dispositifs ne couvrent pas tous les segments.

Cela introduit des failles dans la défense mise en place, exploitables par un attaquant interne ou un malware.

Contournement possible des contrôles

Un dispositif mal positionné pourra être contourné par un routage alternatif ou une mauvaise segmentation.

L’absence de filtrage inter-VLAN permet à des machines non autorisées d’accéder à des ressources sensibles.

Visibilité limitée sur les événements

Une sonde de détection (IDS/IPS) mal placée (ex : sur un lien non stratégique) ne verra pas le trafic critique. Cela réduit la détection des attaques ou fuites de données.

Impact sur les performances

Dispositif placé dans un goulot d’étranglement ou mal dimensionné peut créer des indisponibilités ou une dégradation du service, et affecter la disponibilité du SI.

Violation du cloisonnement (segmentation)

Une mauvaise position des dispositifs de sécurité empêche une segmentation efficace (DMZ, LAN, admin, IoT…).

Cela facilite la propagation latérale en cas de compromission (ex : ransomware qui se répand sans obstacle).

Surcoût et complexité

Mal positionner un dispositif peut forcer à reconfigurer toute l’architecture, acheter du matériel supplémentaire, ou ajouter des règles complexes pour compenser.

Mise en œuvre des dispositifs matériels et logiciels

Failles de sécurité ouvertes malgré les dispositifs

Un pare-feu correctement placé mais mal configuré laisse passer des ports non autorisés.

Une matrice des flux qui n’est pas respectée implique que des flux interdits soient fonctionnels (accès entre zones sensibles et utilisateurs non autorisés).

Absence de cloisonnement réel

Le schéma d’architecture prévoit une segmentation forte (DMZ, admin, utilisateurs...), mais les ACLs/VLANs ne sont pas implémentés ou mal appliqués. Un attaquant ayant compromis un serveur ou un poste utilisateur peut remonter jusqu’à des systèmes critiques.

Visibilité et surveillance inefficaces

Une sonde IDS/IPS bien placée mais non connectée à un port miroir ou non reliée au SIEM ne détecte rien.

Des logs qui ne sont pas centralisés, ou les alertes qui ne remontent pas entraînent un temps de réaction allongé.

Non-conformité avec les exigences de sécurité

Le plan d’architecture validé en comité de sécurité n’est pas appliqué tel quel.

Des règles de filtrages prévus dans la matrice des flux sont ignorés entraîneront un risque technique, un risque juridique ou contractuel.

Comportement réseau imprévisible

Une mauvaise gestion des flux peut entraîner des boucles réseau, collisions, ou fuites de données.

Exemple : une erreur NAT ou routage peut exposer un serveur interne sur Internet.

Baisse des performances ou déni de service

Une erreur dans la mise en œuvre peut faire passer trop de trafic par un équipement non dimensionné ce qui entraînera la saturation de cet équipement.

Mais bloquer à tort des flux légitimes provoquera une interruption de service.

Erreurs humaines persistantes

Absence de documentation ou de schéma clair engendrera une configuration et une administration hasardeuse, un contournement des règles ou l’utilisation de mauvaises pratiques.

Contraintes et exigences de l’audité

Besoin en Disponibilité, Intégrité, Confidentialité, Imputabilité

Obligations légales

Budget alloué au projet

Contraintes opérationnelles

Quelques définitions

Une DMZ

Une DMZ (Demilitarized Zone) est une zone tampon entre deux réseaux de niveau de confiance/confidentialité différents dans lesquels on placera uniquement des serveurs ou relais exposés aux deux réseaux (et leurs dépendances).

Une DMZ commence et se finit forcément par un pare-feu, ou une diode ET un guichet. Une DMZ à l’état de l’art constitue une passerelle d’interconnexion sécurisée à partir du moment où tous les flux entre deux réseaux de niveau de confiance différent y transitent obligatoirement.

La zone ADMIN

Simplement le réseau d’administration permettant aux administrateurs de s’assurer du bon fonctionnement du SI.

On distingue les administrateurs système, réseau, de sécurité et de supervision (SOC).

La zone INFRA

Les services d’infrastructure sont les services gérés par les administrateurs, qui permettent au(x) SI de fonctionner sans rapport avec l’exploitation.

La zone SERVER / MÉTIER

Les services internes (LAN SERVER) contiennent les services qui sont exploités par les clients afin de répondre au(x) besoin(s) du SI et qui ne sont pas directement exposés à internet.

La zone CLIENT

L’exploitant est le client d’une application ou d’un SI. Il consomme et/ou renseigne les données. On parlera plutôt d’exploitant pour une personne, et de client pour une machine (host) ou une application.

Voici quelques principes d’une architecture sécurisée :

Un pare-feu doit toujours être en coupure du réseau sans possibilité de le contourner.

Les différentes zones doivent être séparées par un ou plusieurs pare-feu assurant le filtrage.

Une interconnexion (SI différent, internet, etc.) est à minima protégée par un pare-feu frontal.

En cas d’exposition à internet, la DMZ est un passage obligatoire pour toute action vers ou venant de l’extérieur. (Relais, Proxy, Web, etc.)

Les MCO-MCS et Antivirus doivent être définis et à jour.

Les biens essentiels du SI doivent être définis et sécurisés.

Résultats liés aux thèmes CASSI

Authentification & Droits

Conséquences d’une absence de centralisation de la gestion des comptes

Multiplication des identifiants entraîne une gestion difficile des comptes.

Si chaque équipement ou application gère ses propres comptes locaux. Cela entraîne :

Des incohérences (mots de passe différents, droits non uniformes),

Des comptes oubliés ou jamais supprimés,

Des risques de shadow IT (applications non connues du SI gérant des comptes utilisateurs non validés).

Impossible de savoir qui s’est connecté, quand, et où.

Augmentation du temps de gestion

Aucune automatisation n’est possible pour :

Créer / modifier / révoquer un accès,

Appliquer des politiques de mot de passe,

Surveiller les connexions.

L’équipe IT doit intervenir manuellement sur chaque système, ce qui est lent, source d’erreurs, et peu fiable.

Failles d’accès lors du départ d’un collaborateur

Si un employé quitte l’entreprise, son compte peut rester actif sur certains systèmes car il n’existe pas de point unique pour désactiver tous ses accès.

Conséquence : risque de réutilisation malveillante de ses identifiants (interne ou externe).

Traçabilité faible / journalisation fragmentée

L’absence d’annuaire empêche de :

Centraliser les logs d’authentification,

Identifier qui a accédé à quoi, quand et comment.

La détection des comportements anormaux ou des intrusions.

Pas de traçabilité ni d’audit fiable.

Non-respect des politiques de sécurité

Impossibilité d’appliquer de manière homogène :

Les exigences de mot de passe fort,

Le MFA (authentification multi facteur),

Le principe du moindre privilège,

Les groupes de droits basés sur les rôles.

Non-conformité réglementaire

De nombreuses normes exigent une gestion centralisée des identités et des accès (ISO 27001, RGPD, PCI-DSS…).

Sans annuaire, aucune preuve de contrôle cohérent ne peut être apportée → audit non conforme.

Propagation facilitée d'une attaque

Si un attaquant compromet un compte local avec droits d’administration, il peut :

Se déplacer latéralement,

Créer d'autres comptes manuellement,

Et rester invisible, faute de centralisation.

Conséquences de l'absence d'authentification des équipements via RADIUS

Accès administrateur non contrôlé / dispersé

Impossibilité de gestion des droits par rôle

Sans RADIUS ou TACACS+, tous les administrateurs ont les mêmes droits complets, souvent en partageant un même mot de passe.

Aucune distinction possible entre :

Administrateurs complets,

Techniciens réseau,

Prestataires tiers.

Persistance des accès après un départ

Si un administrateur quitte l’entreprise, son compte local reste actif sur tous les équipements sauf si on le supprime manuellement sur chaque équipement.

Risque critique : accès non autorisé par un ancien employé ou un attaquant ayant récupéré des identifiants.

Risque d’oubli : accès persistants non autorisés.

Journalisation quasi inexistante

Sans RADIUS ou TACACS+, il est impossible de savoir précisément :

Qui a exécuté telle ou telle commande,

Sur quel équipement,

À quelle date/heure.

Cela rend les enquêtes post-incident (forensic) quasiment impossibles.

Accès non sécurisé et non centralisé

Chaque équipement dispose de comptes locaux indépendants avec le risque d’un mot de passe faible ou inchangé qui pourrait faciliter la prise de contrôle par un attaquant.

Pas de traçabilité des connexions

Impossibilité de savoir qui s’est connecté, quand, et sur quel équipement.

Aucune visibilité sur les commandes exécutées (pas de journalisation des actions).

Rend les enquêtes post-incident difficiles, voire impossibles.

Mauvaise gestion des comptes administrateurs

Lors du départ d’un administrateur, il faut désactiver manuellement les comptes sur chaque équipement. Cela entraîne un risque d’oubli et donc des accès persistants non autorisés.

Non-respect des politiques de sécurité

Impossible d’appliquer des politiques de sécurité homogènes :

Complexité des mots de passe,

Rotation des mots de passe,

Accès conditionnels (heures, IP...).

Non-conformité réglementaire

Les normes ISO 27001, ANSSI, PCI-DSS, NIS2 exigent :

Une authentification forte,

Une gestion centralisée des accès,

Une traçabilité complète.

Surface d’attaque élargie

Si un attaquant compromet un compte local (souvent partagé ou connu), il peut :

Modifier la configuration du réseau (routes, VLANs, ACL...),

Capter ou rediriger le trafic réseau,

Créer une porte dérobée ou perturber le fonctionnement global.

Écart entre architecture théorique et réalité

Les décisions d’architecture (schéma réseau, matrice des flux, politique d’accès) prévoient un contrôle centralisé. L'absence de RADIUS provoque un non-respect de ces décisions, ce qui crée :

Des angles morts dans le système d’administration,

Une perte de cohérence de la sécurité entre les équipements.

Conséquences principales d’une mauvaise gestion de l’authentification dans les zones sensibles :

Accès non autorisé à des ressources critiques

Des comptes mal protégés (mots de passe faibles, comptes partagés, sans MFA) permettent à un attaquant de :

Accéder aux serveurs exposés (web, mail, API...),

Pivoter vers le réseau interne depuis la DMZ,

Atteindre des systèmes à haute valeur (base de données, AD...).

Absence de contrôle d’identité fiable

Sans authentification forte ou centralisée :

Impossible de vérifier l’identité des utilisateurs ou des services,

Accès anonymes ou génériques possibles (ex : admin / admin),

Usurpation d’identité facilitée.

Facilitation des attaques par rebond / mouvement latéral

Un attaquant qui compromet une machine en DMZ (souvent exposée à Internet) peut :

Profiter d’une authentification faible pour atteindre d'autres zones,

Utiliser des comptes avec privilèges excessifs ou mal cloisonnés,

Se déplacer vers le réseau interne ou les zones d’administration.

Traçabilité dégradée et détection des incidents difficile

Sans authentification individuelle et nominative :

Impossible d’identifier qui a accédé et à quelles ressources,

Pas de logs fiables pour enquêter après un incident,

Délai de détection prolongé en cas de compromission.

Élévation de privilèges facilitée

Des erreurs d’authentification peuvent donner des droits trop larges dans des zones critiques.

Exemple : un simple utilisateur peut accéder à un système de production.

L’absence de séparation des comptes (admin / standard) aggrave les risques.

Non-respect des décisions d’architecture et de la matrice des flux

Les zones sensibles sont censées être strictement contrôlées en termes d’accès. Une mauvaise gestion de l’authentification viole ces règles :

Accès directs depuis l’extérieur sans contrôle,

Contournement de la DMZ,

Connexion depuis des postes non autorisés.

Non-conformité aux normes de sécurité

Les bonnes pratiques (ANSSI, ISO 27001, PCI-DSS...) exigent :

Une authentification forte dans les zones sensibles,

Un contrôle d’accès basé sur les rôles,

Une gestion centralisée des identités.

Conséquences principales d'une mauvaise gestion des mécanismes et supports d'authentification

Accès non autorisé ou compromission d'identité

Des mots de passe faibles, partagés, ou non renouvelés facilitent la prise de contrôle par un attaquant (brute-force, hameçonnage, credential stuffing).

Des certificats ou tokens mal gérés engendre une possibilité d’usurpation d'identité numérique (ex. : accès à des APIs, VPN, SSO…).

Échec de la protection des accès sensibles

MFA mal implémenté ou absent → protection uni factorielle insuffisante.

Types d’authentification mal adaptés à la criticité du service (ex. : accès administrateur avec simple mot de passe local).

Fuite ou vol d’éléments d’authentification

La mauvaise conservation du type stockage en clair dans des fichiers, mails, captures d’écran, post-it… entraîne un vol possible par :

Malware ou keylogger,

Intrus sur un système mal protégé,

Empreint d’un token/certificat exportable (ex : .pfx, .pem),

Une récupération par ingénierie sociale.

Impossibilité d'audit et de traçabilité

Comptes partagés, fonctionnels ou locaux rend difficile voire impossible de savoir qui s’est authentifié réellement. L’imputation d’une action devient compliquée.

Des authentifications non centralisées génèrent souvent une journalisation imprécise.

Mauvaise révocation des accès

En cas de départ d’un utilisateur ou d’un prestataire :

Les certificats restent valides,

Les tokens ou mots de passe ne sont pas révoqués,

L’accès reste actif → porte dérobée potentielle.

Non-respect des politiques de sécurité / d’architecture

Des éléments critiques (certificats, tokens, secrets) circulent ou sont stockés en dehors des canaux ou zones prévues.

L’authentification ne respecte pas les exigences prévues dans le modèle d’architecture, la matrice des risques ou les niveaux de sécurité par zone.

Non-conformité aux normes de sécurité

Normes comme ISO 27001, NIS2, PCI-DSS, RGPD exigent :

Protection des données d’authentification,

MFA pour certains accès,

Traçabilité et révocation rapide.

Une mauvaise gestion constituera des non-conformités et des sanctions potentielles.

Conséquences d’une mauvaise gestion du nomadisme en architecture de sécurité

Exposition accrue aux attaques externes

Les utilisateurs nomades se connectent souvent via des réseaux publics ou non sécurisés (Wi-Fi cafés, hôtels, etc.).

Sans protections adaptées (VPN, MFA), leurs connexions peuvent être interceptées (attaque MITM, sniffing).

Il y a un risque d’injection de malwares ou de compromission des identifiants.

Faible contrôle d’accès et authentification

La mauvaise gestion peut entraîner l’absence d’authentification forte (MFA) pour les accès distants.

Utilisation d’identifiants faibles ou réutilisés.

Accès aux ressources sensibles sans restrictions adaptées à la situation (ex : zone géographique, type d’appareil).

Fuite de données et compromission des équipements

Utilisation d’appareils personnels non sécurisés (BYOD) ou mal configurés.

Des données sensibles peuvent être stockées localement sans chiffrement.

Risque de perte ou vol d’appareils avec accès aux ressources critiques.

Difficultés dans la surveillance et la détection

Multiplicité des points d’entrée rend la détection d’activités anormales plus complexe.

Logs éclatés sur plusieurs systèmes, pas toujours corrélés.

Retard dans la réponse aux incidents.

Non-respect des politiques et architecture réseau

Accès nomades non filtrés ou non segmentés.

Non-application des règles définies dans la matrice des flux (zones, VLAN, firewall).

Risque d’accès direct à des zones sensibles sans passer par les contrôles requis.

Non-conformité réglementaire

Normes (RGPD, ISO 27001, PCI-DSS, NIS2…) exigent la gestion des accès distants.

Manque de contrôle sur les sessions nomades → sanctions possibles.

MCO - MCS

Vulnérabilités non corrigées

Sans mises à jour régulières (système, logiciels, firmware), des failles connues restent exploitables. Il y a une augmentation de la surface d’attaque et un risque de compromission via :

Des exploits publiés,

Des rançongiciels,

Une escalade de privilèges.

Exemple : l’exploitation de la faille Log4Shell sur des serveurs non patchés.

Diffusion non maîtrisée des correctifs

Des mises à jour mal testées ou déployées sans contrôle peuvent :

Casser des services critiques (ex : changement de version de dépendances),

Provoquer des pannes dans les environnements de production,

Créer une Instabilité ou une indisponibilité du système.

Absence de résilience

Si le SI ne dispose pas de :

Redondance matérielle/logicielle,

Plans de reprise (PRA) ou de continuité (PCA),

Sauvegardes testées régulièrement,

Défaillance prolongée en cas d’incident :  toute attaque ou panne peut entraîner une interruption durable des services.

Utilisation de sources de mise à jour non fiables

Le téléchargement de correctifs depuis des sources non vérifiées ou compromises risque d’introduire du code malveillant (supply chain attack).

Exemple : attaque de SolarWinds ou compromission de référentiels NPM/PyPI.

Retard de détection des menaces

Les systèmes obsolètes ou pas à jour manquent de :

Fonctionnalités de sécurité récentes (par exemple, protections kernel ou sandbox),

Mécanismes de journalisation ou de détection (IDS, EDR à jour...).

Non-conformité réglementaire

De nombreuses normes imposent :

Un cycle de gestion des correctifs (patch management),

Une résilience minimale (ISO 27001, NIS2, RGPD, ANSSI).

Le non-respect peut entraîner des sanctions en cas d’audit ou de fuite.

Échec du cycle MCO/MCS

Une mauvaise orchestration des correctifs compromet :

La vision globale de l’état de sécurité du SI,

La coordination entre équipes architecture / exploitation / sécurité,

La capacité de réaction rapide face à une alerte ou un 0-day.

Antivirus

Introduction de malwares dans des zones sensibles

En l'absence de station blanche à jour, les supports amovibles (clés USB, disques durs, etc.) peuvent contenir :

Malware,

Ransomware,

Outils de prise de contrôle à distance (RAT),

Scripts de compromission automatique (autorun, macros…).

Ces menaces peuvent atteindre :

La zone bureautique (SI utilisateur),

Mais surtout des zones critiques (DMZ, OT/ICS, serveurs isolés).

Échec de détection d’attaques connues

Si l’antivirus n’est pas à jour :

Il ne détectera pas les nouvelles signatures (virus, chevaux de Troie, fichiers dropper, etc.).

Il sera inefficace face aux menaces actuelles (même simples ou déjà publiées).

Cela permet à des attaques pourtant connues de passer inaperçues.

Propagation rapide au sein du SI

Une menace non détectée via support amovible peut se propager latéralement via :

Partages réseau,

Mails internes,

Serveurs d’applications ou fichiers,

Postes utilisateurs.

Il y a un risque de propagation silencieuse dans l’ensemble du SI avant détection.

Compromission des zones déconnectées ou à accès restreint

Les réseaux isolés (ex : réseaux industriels, SCADA, infrastructures critiques) sont vulnérables si :

Les mises à jour antivirus sont manuelles ou rares,

Les insertions de données ne sont pas maîtrisées (USB utilisées sans contrôle préalable),

Risque de compromission persistante et non détectée.

Non-conformité aux politiques de sécurité ou aux référentiels (ANSSI, ISO27001, etc.)

L’absence de station blanche ou d’un mécanisme de filtrage de supports est incompatible avec les référentiels de sécurité pour environnements sensibles.

De même, les mises à jour antivirus sont un prérequis essentiel à toute posture défensive de base.

Journalisation

Détection d'incidents impossible ou fortement dégradée

Sans trace des activités réseau ou système rend impossible ou difficile de détecter :

Tentatives d’intrusion,

Mouvement latéral,

Escalade de privilèges,

Déploiement de malwares,

Ouverture de ports ou connexions inhabituelles.

Les SIEM, SOC ou outils EDR deviennent inefficaces sans logs pertinents.

Absence de reconstitution d’incident ou d’analyse post-mortem

En cas d’attaque ou de compromission :

Impossible de tracer l’origine, les vecteurs ou l’ampleur des dommages.

Difficulté à prouver la chronologie et à identifier les comptes/actions impliqués.

Impact direct sur la capacité à répondre aux incidents.

Problèmes liés à la gestion du temps (NTP)

Si les horodatages sont incohérents ou mal synchronisés :

Impossibilité de corréler les logs entre systèmes,

Analyses faussées,

Détection retardée ou erronée.

Cela impacte fortement les outils d’analyse automatique.

Non-conformité réglementaire ou contractuelle

La journalisation est une exigence fondamentale dans de nombreux référentiels :

ISO 27001, RGPD, NIS2, LPM, PCI-DSS, ANSSI…

En cas d’audit ou de contrôle post-incident :

Sanctions potentielles (amendes, blâme, perte de certification),

Incapacité à prouver la conformité (accountability).

Perte de preuve en cas de litige ou de contentieux

Des Logs insuffisants ou falsifiables entraine une impossibilité de produire une preuve technique :

Pour justifier une décision ou une mesure disciplinaire,

Pour identifier un utilisateur fautif,

Pour se défendre juridiquement après une fuite de données.

Risques sur l’intégrité et la confidentialité des logs

Des Logs non protégés (en lecture/écriture ou sans contrôle d’accès) :

Peuvent être modifiés ou effacés par un attaquant pour dissimuler ses traces.

Risque de fuite d’informations sensibles (identifiants, IP internes, données applicatives).

Absence de journalisation des accès aux logs eux-mêmes.

Non-centralisation des journaux

La non-centralisation des journaux fournie une vision fragmentée et inefficace

Logs éparpillés sur les machines → pas de vision globale.

Multitude de formats, absence de corrélation.

L’analyste sécurité ou le SOC travaille "à l’aveugle".

Surcharge des systèmes ou perte de données

Sans politique de rétention claire ou de rotation :

Risque de saturation des disques,

Perte de journaux anciens mais critiques,

Difficulté à savoir quoi conserver, combien de temps, et pour quelle finalité.

Sauvegarde

Perte de données irréversible

Sans sauvegarde effective ou fiable, toute panne, effacement accidentel ou attaque (ex : ransomware) peut entraîner :

La perte totale ou partielle des données métier,

L’arrêt durable d’activités critiques (ERP, GED, messagerie, bases de données…).

Non-disponibilité du matériel de sauvegarde au moment critique

Sans dimensionnement correct (stockage, bande passante, cycles de rétention) :

Les sauvegardes peuvent échouer,

Les données critiques ne sont pas couvertes,

Le système est faiblement sécurisé.

Procédures inexistantes ou non maîtrisées → échec en cas de crise

Sans procédures documentées, connues et testées :

Les équipes ne savent pas quoi restaurer, comment, ni dans quel ordre,

La perte de temps entraîne un allongement critique de l’indisponibilité,

Peut compromettre le PRA/PCA.

Aucune garantie que les sauvegardes sont exploitables

Si les restaurations ne sont jamais testées :

Les fichiers peuvent être corrompus, incomplets ou inutilisables,

Les sauvegardes automatiques peuvent avoir échoué sans alerte (scripts cassés, disque plein…).

Sauvegardes stockées sur le même site induit une vulnérabilité aux sinistres

En cas d’incendie, inondation, vol ou sabotage, l’ensemble du SI et ses sauvegardes peuvent disparaître en même temps.

Les rançongiciels chiffrent parfois aussi les sauvegardes locales s’il n’y a pas de segmentation ou d’isolement (airgap).

Absence de protection entraîne un risque de compromission ou d’altération

Si les sauvegardes ne sont pas chiffrées, ni isolées :

Un attaquant peut les voler (exfiltration de données sensibles),

Les altérer ou supprimer pour empêcher la reprise,

Les utiliser pour contourner les dispositifs de sécurité (injection de porte dérobée dans une image restaurée).

Non-conformité réglementaire

Le RGPD, ISO 27001, NIS2, ANSSI et d'autres normes imposent :

Des sauvegardes régulières et testées,

Des mécanismes de protection (chiffrement, contrôle d'accès, traçabilité),

Une capacité à restaurer rapidement les données en cas d’incident.

Sécurisation réseau

Absence de cloisonnement (segmentation/routage/ACL/VLAN/VRF)

Propagation rapide des attaques (vers, ransomware, scan latéral),

Aucun confinement possible en cas de compromission,

Visibilité excessive entre zones (ex : utilisateurs peuvent scanner la DMZ ou les bases de données),

Non-conformité aux principes de l’ANSSI (zones de sensibilité, flux maîtrisés, Zoning).

Mauvais choix de connexions et accès (ex : accès internet depuis postes d'administration)

Des postes d’administration exposés à internet :

Risque de compromission directe (phishing, malwares, drive-by download),

Élément pivot pour un attaquant avec privilèges élevés,

Contourne le principe de chaîne de confiance (admin via bastion, flux tracés, filtrés et contrôlés).

Exemple : Un administrateur ouvre un lien piégé sur son poste ce qui entraîne une prise de contrôle du SI via ses droits étendus.

Mauvais choix des protocoles d'administration et d'applications

L’utilisation de protocoles non chiffrés (Telnet, HTTP, SMBv1…) :

Capture de mots de passe en clair sur le réseau (sniffing),

Attaques Man-in-the-Middle facilitées.

L’utilisation de protocoles obsolètes ou vulnérables entraîne l’exposition de portes d’entrée faciles pour les attaquants.

Manque de standardisation rend le durcissement difficile.

Exemple : L’administration d’un routeur via Telnet → interception des identifiants, puis reconfiguration réseau malveillante.

Mauvais positionnement des équipements de sécurité et d’infrastructure

Bastions mal placés ou absents :

Impossible de centraliser et tracer l’administration,

Difficulté à appliquer le moindre privilège, les accès deviennent diffus.

IDS/IPS mal positionnés :

Trafic critique non surveillé,

Détection d’intrusion inefficace,

Aucune alerte sur les flux internes latéraux.

auvais positionnement des ESX / virtualisation :

Absence de séparation entre les flux d’administration, VM et stockage,

Risque de compromission croisée entre VMs (escape VM),

Gestion centralisée non cloisonnée → prise de contrôle globale via vCenter ou équivalent.

Exemple : Un hyperviseur exposé sur le réseau utilisateur → élévation de privilèges contrôle de toutes les VMs.

RÉSULTATS DE L’AUDIT DE CONFIGURATION

Authentification & Droits

Dans ce thème on identifie 4 grandes non-conformités globales :

Absence d’authentification

Implémentation d’une politique de mot de passe

Mauvaise gestion des privilèges (utilisateurs/administrateurs)

Mauvaise gestion des droits sur les données.

Cas particulier des systèmes temps réel (systèmes de combats, etc …)

Absence d’authentification

L'absence d'authentification dans un système informatique ou une application représente une faille critique qui peut compromettre la confidentialité, l'intégrité et la disponibilité des données et services. Voici les principaux risques associés :

Accès non autorisé

Sans authentification, n'importe quel utilisateur, légitime ou non, peut accéder aux systèmes, applications ou données, ce qui expose :

Les informations sensibles.

Les ressources critiques, comme les bases de données ou les systèmes d'administration.

Exploitation facile par des attaquants

Absence de barrière de sécurité : L'authentification est la première ligne de défense. Sans elle, un attaquant peut interagir directement avec le système ou l'application, facilitant :

Les attaques par injection (SQL, commandes système).

L'installation de logiciels malveillants.

L'exfiltration de données ou la modification de configurations critiques.

Menaces internes

Les utilisateurs internes (employés, sous-traitants) peuvent accéder à des ressources ou des données auxquelles ils ne devraient pas avoir accès, en l'absence d'un mécanisme pour vérifier leur identité.

Impossibilité de limiter ou contrôler les accès

Absence de gestion des rôles et permissions : Sans authentification, il est impossible de :

Distinguer les utilisateurs entre différents rôles (par exemple, administrateur vs utilisateur standard).

Restreindre l'accès à certains services ou données en fonction des privilèges.

Cela peut conduire à des abus et à une perte de contrôle sur les ressources.

Perte de traçabilité et d'audit

Sans authentification, il est impossible d’identifier qui a accédé à quoi ou d’attribuer des actions à des utilisateurs spécifiques, rendant :

Les enquêtes en cas d’incident extrêmement difficiles.

L'organisation vulnérable aux abus internes et externes sans preuve concrète.

Facilitation des attaques automatisées

Les systèmes sans authentification sont une cible facile pour les robots malveillants et les attaques automatisées, telles que :

Les balayages de port et de services non protégés.

Les attaques par force brute (dans le cas où une authentification partielle est présente mais mal configurée).

Accès à des fonctions ou services critiques

Si des fonctions sensibles (comme l’administration d’un système, la gestion des utilisateurs, ou des transactions financières) ne sont pas protégées par une authentification, cela permet :

L’altération ou la suppression de configurations.

L’usurpation d’identité et des actions non autorisées.

Augmentation des risques liés aux attaques de type "homme du milieu"

Sans authentification, les communications entre un utilisateur et le système ne sont pas sécurisées, ce qui facilite :

L'interception et la manipulation des données échangées.

L'usurpation de session pour accéder à des ressources sans légitimité.

Politique de mot de passe :

Une mauvaise politique de mot de passe expose le SI à de nombreux risques de sécurité, qui peuvent avoir des impacts graves sur la confidentialité, l'intégrité et la disponibilité des données et systèmes. On peut identifier les risques suivants :

Risque de compromission des comptes

Mot de passe faible ou prévisible : Si les mots de passe sont trop simples (ex. : "123456", "motdepasse"), ils peuvent être facilement devinés par des attaques par force brute ou des scripts automatisés.

Réutilisation des mots de passe : Si un utilisateur réutilise son mot de passe sur plusieurs services, une fuite sur une autre plateforme peut compromettre l’accès aux systèmes internes de l’organisation (attaque par réutilisation de mots de passe).

Absence de complexité : Des mots de passe sans complexité (majuscule, chiffres, symboles) sont plus faciles à casser via des attaques par dictionnaire.

Vulnérabilité face aux attaques

Attaques par force brute : Si les mots de passe sont courts ou simples, un attaquant peut les deviner rapidement.

Attaques par hameçonnage : Une mauvaise politique (par exemple, des mots de passe statiques sans expiration) peut prolonger la validité d’un mot de passe volé via une campagne d’hameçonnage.

Attaques internes : Les utilisateurs malveillants ou négligents peuvent accéder à des comptes sensibles si les politiques de mot de passe ne respectent pas les recommandations.

Perte de confidentialité et fuite de données

Une mauvaise politique peut faciliter l'accès non autorisé aux données sensibles, notamment dans les cas suivants :

Les mots de passe par défaut des équipements ou logiciels ne sont pas modifiés.

Les systèmes critiques sont protégés par des mots de passe faibles.

Les comptes administrateurs ou de services sont compromis à cause de mots de passe mal gérés.

Augmentation des erreurs humaines

Politiques trop laxistes : Les utilisateurs choisissent des mots de passe facilement mémorables, donc plus vulnérables.

Politiques trop strictes : Si les exigences sont trop complexes, les utilisateurs peuvent adopter des comportements risqués, comme :

Noter les mots de passe sur des post-it.

Utiliser des modèles répétitifs faciles à deviner.

Se tourner vers des mots de passe similaires (ex. : "Motdepasse1!", "Motdepasse2!").

Risque de compromission des accès privilégiés

Si les comptes administrateurs ou autres comptes privilégiés utilisent des mots de passe faibles ou statiques, un attaquant peut obtenir un accès total aux systèmes de l’organisation.

Impact opérationnel

Coûts liés à un incident : Une compromission causée par un mot de passe faible peut entraîner des interruptions de service.

Perte de réputation : Une fuite de données due à une mauvaise politique de mot de passe peut nuire à l'image de l'organisation.

Mauvaise gestion des privilèges (utilisateurs/administrateurs)

Une mauvaise gestion des privilèges expose une organisation à des risques majeurs qui peuvent compromettre la sécurité des systèmes, des données et des opérations. Voici les principaux risques :

Escalade de privilèges

Si les privilèges sont mal gérés, un utilisateur (ou un attaquant) disposant de droits limités peut exploiter des failles pour obtenir des accès plus élevés, comme des privilèges administratifs.

Cela permet un contrôle étendu sur les systèmes, facilitant les actions malveillantes telles que l'installation de maliciels), le vol de données ou l'altération de configurations critiques.

Accès non autorisé aux ressources sensibles

Droits excessifs : Lorsqu'un utilisateur ou un compte a plus de privilèges que nécessaire (par exemple, un employé ayant un accès administrateur sans en avoir besoin), il y a un risque accru d'accès non autorisé à des données critiques.

Exposition accrue des données : Des informations confidentielles (données clients, secrets commerciaux, etc.) peuvent être compromises si des utilisateurs non autorisés y accèdent accidentellement ou intentionnellement.

Compromission des comptes à privilèges

Risque accru de cyberattaques : Les comptes ayant des droits élevés (administrateurs, super utilisateurs) sont des cibles privilégiées pour les attaquants. Si ces comptes sont compromis, l'attaquant peut :

Accéder à l'ensemble des systèmes.

Désactiver les mesures de sécurité.

Propager des attaques sur tout le réseau.

Manque de protection des comptes privilégiés : Si les comptes à privilèges ne sont pas sécurisés par des mécanismes tels que des mots de passe robustes ou une authentification multifactorielle (MFA), ils deviennent une porte d'entrée facile pour les attaquants.

Risques liés aux attaques internes

Menaces internes : Les employés disposant de privilèges excessifs peuvent abuser de leurs droits pour :

Saboter des systèmes.

Voler ou divulguer des données sensibles.

Erreurs humaines : Des actions involontaires (comme la suppression accidentelle de données ou la modification incorrecte de configurations) peuvent avoir des impacts majeurs si les utilisateurs disposent de droits élevés.

Propagation de maliciels ou rançongiciels

Si un compte à privilèges est compromis, un logiciel malveillant ou rançongiciel peut se propager rapidement sur l'ensemble des systèmes en utilisant ces droits élevés, rendant les efforts de confinement inefficaces.

Perte de visibilité et de contrôle

Manque d’audit : Si les privilèges ne sont pas bien gérés ou surveillés, il devient difficile de tracer qui a accès à quoi. Cela complique les enquêtes en cas d'incident et rend l'organisation plus vulnérable aux abus.

Non-respect du principe du moindre privilège : Laisser des comptes ou des utilisateurs disposer de droits qui dépassent leurs besoins opérationnels crée un risque inutile.

Non-conformité réglementaire

Les réglementations et normes de sécurité (ex. : RGPD, PCI-DSS, ISO 27001, etc.) imposent souvent une gestion stricte des privilèges. Une mauvaise gestion peut entraîner :

Des sanctions financières.

Une atteinte à la réputation de l'organisation.

La perte de certifications nécessaires à certaines activités.

Réduction de la résilience en cas d’attaque

En cas d’attaque, des privilèges mal gérés peuvent :

Empêcher une réponse rapide (par exemple, si les équipes d’intervention ne disposent pas des droits nécessaires pour contenir une attaque).

Aggraver les dommages (par exemple, si des privilèges excessifs permettent à un attaquant d’effacer des journaux ou de désactiver des systèmes de sécurité).

Mauvaise gestion des droits sur les données et dossiers.

Une mauvaise gestion des droits d'accès présente de nombreux risques pour la sécurité des systèmes, des données et des opérations. Elle accroît la vulnérabilité des systèmes et expose le système d’information à des risques de compromission, de fuite de données. Voici les principaux dangers liés à cette faiblesse :

Accès non autorisé aux données sensibles

Droits excessifs : Si des utilisateurs ou comptes ont un accès non justifié à des données sensibles, cela peut entraîner :

Des violations de la confidentialité (par exemple, fuite de données personnelles ou stratégiques).

Une exploitation ou un vol de données critiques par des employés malveillants ou des attaquants.

Absence de cloisonnement : Sans une gestion précise des droits, des utilisateurs non concernés peuvent accéder à des informations qui devraient être restreintes.

Escalade de privilèges

Droits mal configurés : Un attaquant ou un utilisateur peut exploiter des permissions mal définies pour obtenir un accès à des systèmes ou données qu’il ne devrait pas avoir. Cela facilite l'escalade des privilèges, permettant un contrôle étendu et compromettant davantage de systèmes.

Menaces internes (insiders)

Des employés ou prestataires disposant de droits non nécessaires peuvent, intentionnellement ou accidentellement :

Saboter des systèmes ou supprimer des données.

Voler ou divulguer des informations confidentielles.

Causer des erreurs humaines qui impactent la sécurité ou la disponibilité des systèmes.

Augmentation de la surface d’attaque

Comptes inutilisés ou obsolètes : Si des droits ne sont pas révoqués pour des utilisateurs inactifs (anciens employés, partenaires), ces comptes peuvent devenir des vecteurs d'attaque faciles à exploiter.

Mauvaise segmentation des droits : L'absence de restrictions granulaires peut laisser des accès à des systèmes non nécessaires, augmentant les opportunités d'exploitation.

Exposition aux attaques automatisées

Si les droits sont trop larges ou mal configurés :

Les attaquants peuvent utiliser des scripts automatisés pour cibler des systèmes vulnérables (ex. : serveurs exposés, partages réseau non sécurisés).

La compromission d'un compte utilisateur avec des droits élevés peut permettre à un logiciels malveillants ou rançongiciel de se propager plus facilement.

Perte de contrôle et de traçabilité

Manque de visibilité : Une gestion inadéquate des droits rend difficile l’identification de qui a accès à quoi, et pourquoi.

Impossibilité d'auditer : En cas d'incident, il devient compliqué de retracer les actions effectuées et d'identifier les failles.

Actions non justifiées : Sans gestion rigoureuse, des utilisateurs peuvent accéder à des systèmes pour lesquels ils n’ont pas de légitimité.

Impact opérationnel et financier

Interruption des services : Des droits mal configurés peuvent entraîner des modifications accidentelles ou malveillantes sur des systèmes critiques, provoquant des interruptions de service.

Coûts liés aux incidents : Une mauvaise gestion des droits peut entraîner des violations de données, des amendes réglementaires ou des coûts de remédiation importants.

Perte de réputation : Une fuite ou un incident causé par une mauvaise gestion des droits peut nuire à l’image de l’organisation auprès des clients et partenaires.

Risques liés aux comptes administrateurs

Si les droits d'administration sont attribués à trop d'utilisateurs ou mal protégés, cela crée :

Un risque de compromission massive.

Une possibilité de sabotage ou de désactivation des systèmes de sécurité.

Cas particulier des systèmes temps réel (systèmes de combats, etc …)

En cas d'absence d'authentification des utilisateurs sur un système temps réel, la sécurité doit être renforcée par des mesures compensatoires et des contrôles supplémentaires pour limiter les risques. Voici les actions principales à mettre en place :

Limitation des accès physiques et réseau

Restreindre l'accès physique au système :

Verrouiller les salles des serveurs ou dispositifs connectés.

Utiliser des dispositifs de sécurité physique comme des badges, clés ou biométrie.

Contrôle des accès réseau :

Cloisonner le réseau via des VLANs ou des zones dédiées aux systèmes temps réel.

Limiter les connexions à des adresses IP spécifiques via des listes de contrôle d’accès (ACL).

Utiliser des pare-feu pour bloquer tout trafic non autorisé ou non nécessaire.

Mise en place de mécanismes de contrôle d'accès indirect

Accès via une passerelle sécurisée :

Exiger que tout accès au système temps réel passe par une passerelle ou un bastion, même sans authentification native.

La passerelle peut intégrer des mécanismes d'authentification (ex. : un serveur VPN ou proxy).

Filtrage par adresse MAC : Restreindre l'accès aux seuls périphériques autorisés via un contrôle des adresses MAC.

Contrôle basé sur les rôles (RBAC) : Mettre en œuvre des permissions granulaires basées sur les rôles assignés aux utilisateurs (indirectement via la configuration système).

Mise en œuvre d’un audit et d’une journalisation rigoureuse

Surveillance active des accès : configurer le système pour enregistrer toutes les actions effectuées, y compris les connexions réseau, les modifications et les interactions des utilisateurs.

Alertes en temps réel : activer des alertes en cas d’accès ou de comportement inhabituel sur le système (par exemple, un volume inhabituel de commandes ou des accès non attendus).

Analyse régulière des journaux : Identifier toute activité suspecte ou non conforme en étudiant les journaux d’événements.

Mise en place de contrôles au niveau applicatif

Limitation des actions possibles : Configurer les applications temps réel pour ne permettre que les actions nécessaires à leur fonctionnement.

Automatisation et verrouillage : Automatiser certaines fonctions critiques pour limiter l'intervention humaine.

Verrouiller les fonctionnalités sensibles non utilisées.

Renforcement des communications

Chiffrement des échanges :

Utiliser des protocoles sécurisés (ex. : TLS, SSH) pour les communications entre les systèmes temps réel et les périphériques externes.

Assurer la confidentialité et l'intégrité des données transmises.

Validation des commandes : Exiger une vérification supplémentaire pour toute commande critique (par exemple, une confirmation manuelle ou via un mécanisme automatisé).

Sécurisation du système en lui-même

Durcissement des configurations :

Désactiver tous les services ou interfaces inutiles.

Appliquer les derniers correctifs de sécurité pour le système d'exploitation et les logiciels.

Liste blanche d'exécution : Empêcher l’exécution de tout programme ou commande non autorisé via une liste blanche.

Protection des interfaces de démarrage (BIOS/UEFI) : Protéger les paramètres critiques du système pour empêcher un accès non contrôlé au démarrage (même si cela nécessite un mot de passe physique).

Segmentation des données et systèmes critiques

Isolation fonctionnelle : Isoler les parties critiques du système temps réel des autres services ou environnements (par exemple, données utilisateur séparées des contrôles industriels).

Redondance et récupération : Mettre en place des mécanismes de sauvegarde et de récupération rapide en cas de compromission ou d’erreur humaine.

Mise en œuvre de mesures de sécurité par obscurcissement

Réduction des surfaces d’attaque :

Limiter la visibilité du système sur le réseau (par exemple, en masquant ses ports ou interfaces inutilisées).

Complexification des chemins d'accès :

Implémenter des noms non triviaux pour les interfaces, fichiers ou processus critiques.

Formation et sensibilisation

Formation des utilisateurs : Sensibiliser les utilisateurs sur les bonnes pratiques de sécurité dans un contexte sans authentification.

Mettre en garde contre les erreurs humaines et les conséquences possibles.

Procédures claires : Documenter les actions autorisées et les processus d’escalade en cas d’incident.

Migration progressive vers une authentification

Implémentation progressive d’une authentification légère : Même si l’authentification n’est pas immédiatement envisageable, envisager des solutions légères comme des jetons matériels, des clés USB de sécurité ou des codes PIN simples.

Transition vers des mécanismes d'authentification robustes : Planifier une migration vers un système d’authentification complet, en prenant en compte les contraintes du système temps réel.

MCO – MCS

Un mauvais MCO (Maintien en Conditions Opérationnelles) ou MCS (Maintien en Conditions de Sécurité) expose les systèmes, les données et les opérations à plusieurs risques critiques. Ces risques découlent d'une gestion insuffisante ou inappropriée des mises à jour, des configurations, et du suivi des systèmes en production. Un mauvais MCO/MCS expose donc l’organisation à des attaques évitables, des pannes critiques et des sanctions réglementaires. Une gestion proactive et rigoureuse de la maintenance est essentielle pour garantir la sécurité et la fiabilité des systèmes tout en réduisant les risques d'incidents majeurs.

Vulnérabilités non corrigées

Les systèmes non maintenus régulièrement restent exposés à des failles de sécurité connues, ce qui augmente le risque d’attaques réussies (ex. : rançongiciel, attaques par exploitation de vulnérabilités).

Exemple : Un logiciel obsolète non corrigé peut être ciblé par des maliciels exploitant des failles publiquement documentées (ex. : CVE).

Dégradations des performances et interruptions

Sans un MCO adéquat, les systèmes peuvent rencontrer des problèmes de performance ou d’instabilité, entraînant des interruptions de service (ou pannes) et une perte de disponibilité. Cela peut impacter :

Les services critiques (ex. : applications financières, industrielles).

La continuité des opérations.

Perte de conformité réglementaire

Un MCS inadéquat peut entraîner une non-conformité avec les exigences réglementaires ou normatives (ex. ISO 27001, RGPD, PCI-DSS). Cela peut exposer l’entreprise à :

Des sanctions financières.

Une perte de certification.

Des litiges juridiques.

Exposition accrue aux cyberattaques

Une mauvaise gestion des correctifs de sécurité, des signatures antivirus ou des systèmes IDS/IPS (Intrusion Détection/Prévention System) ouvre la porte aux attaques ciblées ou opportunistes.

Exemple : Les systèmes mal configurés ou non surveillés peuvent être exploités dans des attaques de type "réseaux zombies" ou être utilisés comme pivot pour attaquer d'autres systèmes.

Accumulation de failles et complexité croissante

Les environnements non entretenus deviennent difficiles à gérer à cause d’une accumulation de :

Configurations obsolètes.

Logiciels non compatibles.

Matériels dépassés.

Cette complexité augmente les risques d'erreur humaine ou d'incidents liés à une gestion imprécise.

Dégradation des mesures de sécurité

Les mécanismes de sécurité (firewall, systèmes de chiffrement, authentification, etc.) peuvent devenir inefficaces si :

Ils ne sont pas mis à jour.

Ils ne sont pas correctement configurés pour suivre les évolutions des menaces.

Cela peut conduire à des compromissions ou à des contournements des protections en place.

Données non sauvegardées ou corrompues

Un mauvais MCO/MCS peut inclure l’absence de sauvegardes régulières, ce qui expose l’organisation à :

Une perte de données irréversible.

Une incapacité à restaurer les systèmes après un incident (attaque, panne, etc.).

Non-détection des incidents de sécurité

Une absence de suivi des journaux, d’audits ou de surveillance en temps réel réduit la capacité à :

Identifier les intrusions.

Réagir rapidement en cas d’attaque.

Cela peut amplifier les impacts d’un incident, comme la propagation d’un rançongiciel ou l’exfiltration prolongée de données.

Impact financier et opérationnel

Coûts directs :

Remédiation après une attaque ou une panne majeure.

Amendes dues à une non-conformité.

Coûts indirects :

Perte de productivité liée à des interruptions de service.

Détérioration de la réputation et perte de confiance des clients et partenaires.

Exploitation des équipements et logiciels obsolètes

L’utilisation de matériels ou logiciels non supportés (fin de vie) empêche l’application des correctifs de sécurité ou des mises à jour critiques.

Exemple : Un système d’exploitation en fin de support (ex. : Windows Server 2008) est une cible privilégiée pour les cybercriminels.

Antivirus

Une absence ou une mauvaise configuration d’un antivirus dans un environnement informatique expose une organisation à des risques majeurs, liés à l’incapacité de détecter, prévenir et neutraliser les menaces, qu’elles soient connues ou émergentes. L’absence ou une mauvaise configuration d’un antivirus expose le système d’information à des risques graves, allant de l’infection par des maliciels à la compromission des données et des systèmes. Un antivirus correctement installé, configuré et régulièrement mis à jour est une mesure de sécurité essentielle mais doit être complété par d’autres contrôles de cyber sécurité pour assurer une protection robuste.

Voici les principaux risques associés :

Propagation de logiciels malveillants

Absence de détection des menaces connues : Les virus, rançongiciels, chevaux de Troie, et autres logiciels malveillants peuvent s’introduire dans le système et se propager sans opposition.

Exemple : Un rançongiciel peut chiffrer les données critiques et exiger une rançon, paralysant ainsi les opérations.

Exécution de programmes malveillants

Un antivirus mal configuré peut ne pas analyser certains fichiers ou processus critiques, ce qui permet aux logiciels malveillants d’être exécutés.

Exemple : Un logiciel malveillant caché dans une pièce jointe ou un logiciel compromis peut infecter l’ensemble du réseau.

Exfiltration de données sensibles

Sans antivirus, les logiciels malveillants d’espionnage (spyware) ou de contrôle à distance (RAT - Remote Access Trojan) peuvent extraire des informations sensibles (ex. : données personnelles, mots de passe, secrets commerciaux).

Cela peut entraîner :

Des violations de données.

Des pertes financières et juridiques.

Attaques ciblées et persistantes (APT)

Les attaques avancées utilisent des logiciels malveillants personnalisés pour contourner les protections standard. Un antivirus mal configuré ou absent ne pourra pas détecter ces menaces sophistiquées.Cela favorise :

L’installation de portes dérobées (portes dérobées).

Des campagnes prolongées d’espionnage ou de sabotage.

Utilisation des ressources comme "réseaux zombies"

Les systèmes compromis sans antivirus peuvent être intégrés à des réseaux de réseaux zombies, utilisés pour des activités malveillantes telles que :

Les attaques par déni de service distribué (DDoS).

L’envoi de spam ou d’hameçonnage.

. Infection des autres systèmes

Dans un réseau, un poste de travail ou un serveur sans antivirus devient un vecteur de propagation pour infecter d’autres systèmes connectés.

Exemple : Une simple clé USB infectée introduite dans un poste non protégé peut compromettre l’ensemble du réseau.

Dégradation des performances du système

Les logiciels malveillants non détectés peuvent consommer des ressources système (CPU, mémoire, bande passante), affectant :

La disponibilité des services.

Les performances globales du système.

Non-respect des normes et obligations légales

Certaines réglementations (ex. : RGPD, ISO 27001, PCI-DSS) exigent l’utilisation d’antivirus comme une mesure de protection standard.

L’absence ou une mauvaise configuration peut entraîner :

Une non-conformité.

Des sanctions financières et juridiques.

Fausses alertes ou absence d'alertes

Une mauvaise configuration peut entraîner :

Des faux positifs, perturbant les opérations en bloquant des fichiers ou processus légitimes.

L’absence de détection de véritables menaces (fichiers exclus, désactivation des analyses automatiques, etc.).

Journalisation

Dans ce thème on identifie 2 grandes non-conformités globales :

La journalisation

La synchronisation du matériel.

Journalisation

Une absence ou une mauvaise configuration de la journalisation expose l’organisation à plusieurs risques importants qui affectent la détection, l'analyse, et la réponse aux incidents de sécurité. Une mauvaise configuration ou une absence de journalisation représente un risque majeur pour la cyber sécurité d’un système d’information. Elle empêche la détection des menaces, complique les enquêtes post-incident, et entrave la conformité réglementaire. Mettre en place une journalisation robuste et bien configurée est essentiel pour garantir une bonne gestion des incidents de sécurité, la détection des attaques et la continuité des opérations. Voici les principaux risques associés :

Non-détection des incidents de sécurité

La journalisation permet de suivre et de détecter les anomalies ou les intrusions en temps réel. Sans elle ou avec une configuration incorrecte, il devient extrêmement difficile d'identifier des activités suspectes ou malveillantes (ex. : attaques par force brute, tentatives d’hameçonnage, mouvements latéraux).

Exemple : Un attaquant pourrait réussir à pénétrer le réseau, s’y déplacer discrètement et exfiltrer des données sans être détecté si les journaux ne sont pas activés ou sont mal configurés.

Difficulté à effectuer des enquêtes post-incident

Sans une journalisation adéquate, il est impossible de reconstituer un incident de sécurité pour comprendre son origine, son étendue et son impact. Les enquêtes deviennent donc longues et peu efficaces.

Exemple : Après une fuite de données, la journalisation permet de savoir quels utilisateurs ou systèmes ont été compromis et d’analyser la chronologie des événements. Si les journaux sont absents ou mal configurés, il est difficile de déterminer ce qui s’est passé.

Absence de preuves lors d’une violation de sécurité

Les journaux servent souvent de preuve légale lors d’une violation de sécurité ou d’un audit. Une absence de journalisation ou une journalisation incomplète peut entraîner des difficultés pour répondre à des demandes juridiques ou réglementaires, notamment en cas de violation de données.

Exemple : En cas d’enquête externe (ex. : une fuite de données personnelles dans le cadre du RGPD), l’absence de journalisation peut nuire à la capacité de l’organisation à prouver qu’elle a pris les mesures de sécurité adéquates.

Perte de visibilité sur les activités des utilisateurs

Sans une journalisation correcte, il est difficile de suivre les actions des utilisateurs sur le réseau ou dans les applications. Cela rend le contrôle de l’accès et des privilèges plus difficile à gérer et à surveiller.

Exemple : Un utilisateur malveillant pourrait abuser de ses privilèges pour accéder à des informations sensibles sans laisser de traces visibles.

Non-conformité aux exigences légales et réglementaires

De nombreuses réglementations de cyber sécurité (ex. : RGPD, ISO 27001, PCI-DSS, HIPAA) exigent que les organisations conservent et protègent les journaux d’activité pour garantir la sécurité, la traçabilité et la transparence des systèmes.

Exemple : Si les journaux d'accès aux données sensibles ne sont pas correctement configurés ou conservés, l'entreprise pourrait être exposée à des sanctions légales et financières pour non-conformité.

Absence de réponse rapide et de remédiation en cas d'incident

La journalisation est essentielle pour réagir rapidement en cas d'incident de sécurité. En son absence ou avec une mauvaise configuration, il est difficile de déterminer l'étendue des dommages et de mettre en place des mesures correctives rapidement.

Exemple : Un comportement anormal dans les journaux (par exemple, un grand nombre de tentatives de connexion échouées) pourrait être un indicateur de tentative de piratage. Sans une journalisation bien configurée, l'équipe de sécurité pourrait ne pas détecter cela à temps.

Difficulté à analyser les menaces persistantes avancées (APT)

Les attaques avancées, telles que les APT, sont souvent furtives et se développent sur une longue période. Sans des journaux complets et bien configurés, il devient difficile de détecter et d'analyser ces menaces sur le long terme.

Exemple : Une intrusion initiale pourrait se produire, suivie d’une exploitation discrète pendant plusieurs mois. La journalisation des événements peut aider à détecter des comportements inhabituels ou à remonter à la source de l’attaque.

Incomplétude dans la gestion des incidents

Si la journalisation est mal configurée, il est possible que des événements clés, comme des erreurs système, des alertes de sécurité ou des informations critiques sur les accès utilisateurs, soient ignorés ou non capturés.

Exemple : Les erreurs d’application ou les accès non autorisés peuvent passer inaperçus si les événements relatifs à ces actions ne sont pas correctement enregistrés ou surveillés.

Incapacité à effectuer des audits de sécurité efficaces

La journalisation est un outil clé pour effectuer des audits de sécurité internes ou externes. Une mauvaise configuration peut empêcher une évaluation précise de la posture de sécurité de l’organisation et rendre l’audit inefficace.

Exemple : Un audit peut montrer que certaines actions critiques n’ont pas été enregistrées, ce qui rend difficile l’identification des failles de sécurité.

Protection et chiffrement des journaux.

Risque de falsification ou d'effacement de preuves

Si les journaux sont mal configurés ou non protégés, un attaquant ou un utilisateur malveillant peut potentiellement modifier ou effacer les journaux pour masquer ses traces.

Exemple : Un attaquant qui réussit à s’introduire dans un réseau pourrait supprimer ou modifier les journaux d'accès pour effacer les traces de son activité.

Synchronisation des équipements

L'absence de synchronisation des équipements (en particulier des horloges des systèmes, des serveurs et des dispositifs réseau) peut entraîner plusieurs risques importants, affectant la sécurité, l'intégrité des données et la gestion des incidents. L'absence de synchronisation des équipements dans un environnement informatique crée de multiples risques, allant de la difficulté à enquêter sur les incidents de sécurité à des problèmes de conformité, de gestion des incidents, et de manipulation des logs. La synchronisation précise de l'heure sur tous les systèmes est essentielle pour garantir la fiabilité des données, la détection d’anomalies et la gestion efficace des incidents de sécurité. Voici les principaux risques associés :

Difficulté à corréler les événements de sécurité

La synchronisation des horloges est cruciale pour la corrélation des logs. Si les équipements du réseau ont des horloges désynchronisées, il devient extrêmement difficile de réconcilier les événements de sécurité provenant de différents systèmes.

Exemple : Si les logs de deux serveurs ou d’un pare-feu et d’un système de détection d'intrusion (IDS) sont enregistrés à des heures différentes, il peut être compliqué de déterminer la chronologie exacte d’un incident de sécurité, comme une intrusion ou un rançongiciel.

Incapacité à effectuer des audits précis

Les audits de sécurité reposent sur des horodatages précis des événements. Une absence de synchronisation peut rendre les audits inefficaces, car il est impossible de suivre correctement les actions des utilisateurs ou des processus dans un environnement de manière chronologique.

Exemple : Si les événements critiques, comme les connexions et les changements de privilèges, sont horodatés de manière incohérente sur différents équipements, cela compromet la capacité à retracer un incident de sécurité.

Perturbation de la gestion des incidents

En cas d’incident de sécurité, la réponse rapide et efficace repose sur des informations temporelles précises pour comprendre l’évolution de l’incident et sa propagation. Sans une synchronisation adéquate, il est difficile de déterminer l’heure exacte de l'attaque, de l'exécution des maliciels, ou de l’exfiltration des données.

Exemple : Si les journaux des systèmes sont décalés, il devient difficile de comprendre si un maliciel a été lancé à une heure précise ou si plusieurs attaques se sont produites simultanément.

Problèmes liés aux certificats et à la gestion des clés

La synchronisation des horloges est cruciale pour la gestion des certificats SSL/TLS et des clés de chiffrement. Une mauvaise synchronisation peut entraîner des erreurs dans la validation des certificats, ce qui peut affecter la confiance dans les connexions sécurisées.

Exemple : Si les horloges des serveurs sont désynchronisées, un certificat peut être jugé invalide, car sa période de validité ne correspond pas à l'heure locale, même si le certificat est valide.

Problèmes avec les protocoles de sécurité basés sur le temps

Certains protocoles de sécurité (par exemple, Kerberos, NTP (Network Time Protocol), TLS) dépendent d’un horodatage précis pour fonctionner correctement. Une absence de synchronisation peut entraîner des erreurs de communication ou des échecs d'authentification.

Exemple : Kerberos nécessite une synchronisation stricte de l'heure entre les clients et les serveurs. Si l'heure du client est décalée de trop, il échouera lors de l'authentification, ce qui peut perturber l'accès aux ressources critiques.

Risques pour la gestion des sauvegardes et de la restauration

Les sauvegardes de systèmes et de données dépendent souvent de l’horodatage des fichiers et des journaux. Une désynchronisation des horloges peut rendre difficile la gestion des sauvegardes et compliquer la restauration des données en cas de sinistre.

Exemple : Si la synchronisation des horloges échoue, une restauration de données pourrait aboutir à des incohérences, car les versions des fichiers sauvegardés et de la base de données ne correspondront pas aux horaires attendus.

Impact sur la conformité réglementaire

Certaines réglementations de sécurité exigent la conservation des logs et des données avec des horodatages précis. L'absence de synchronisation des équipements peut conduire à une non-conformité avec ces exigences.

Exemple : Des réglementations comme le RGPD ou PCI-DSS imposent de conserver des journaux d’activité avec des horodatages exacts pour garantir l'intégrité des données et la traçabilité des actions. Une mauvaise synchronisation des équipements pourrait entraîner des violations de ces normes.

Risques de falsification ou de manipulation des journaux

Si les horloges des équipements sont incorrectement synchronisées, il est possible qu'un attaquant ou un utilisateur malveillant modifie ou falsifie les journaux pour masquer ses actions.

Exemple : Un attaquant pourrait altérer les logs pour faire croire qu’il a agi à une autre heure, ce qui pourrait tromper les équipes de sécurité et retarder la détection de l’incident.

Problèmes avec les mécanismes de détection d'anomalies

Les systèmes de détection d'anomalies ou de monitoring reposent sur des données temporelles pour détecter des écarts par rapport aux comportements habituels. Une mauvaise synchronisation peut rendre ces outils inopérants, réduisant leur efficacité.

Exemple : Si l'outil de détection d'anomalies analyse les logs de différents systèmes ayant des horloges désynchronisées, il pourrait manquer des signes de comportements suspects ou d'attaques.

Impact sur les systèmes de gestion des identités (IAM)

Les systèmes de gestion des identités et des accès (IAM) s'appuient sur des horaires synchronisés pour gérer les périodes de validité des sessions et des contrôles d'accès. Une désynchronisation des horloges peut entraîner des erreurs dans l’authentification ou l’expiration des droits d’accès.

Exemple : Un utilisateur dont l’heure est mal synchronisée pourrait être refusé l'accès, même si son compte est valide, ou au contraire se voir accorder un accès à des ressources après la fin de son autorisation.

Sauvegardes

L'absence de sauvegardes représente un risque majeur pour la continuité des activités, la protection des données et la capacité à réagir efficacement en cas d'incident. L'absence de sauvegardes expose le SI à des risques considérables, notamment la perte de données, l'interruption des activités. Pour protéger l'intégrité et la continuité des opérations, il est essentiel de mettre en place une stratégie de sauvegarde solide, automatisée et testée régulièrement. Voici les principaux risques associés à une absence de sauvegardes :

Perte permanente de données

Sans sauvegardes régulières, il est impossible de restaurer les données en cas de perte due à un incident, comme une cyberattaque (rançongiciel, par exemple), une défaillance matérielle ou une erreur humaine.

Exemple : Un rançongiciel pourrait crypter toutes les données sensibles d’une organisation, et sans sauvegardes, ces données seraient irrémédiablement perdues, entraînant des pertes financières et la rupture des services.

Perturbation des opérations

Une perte de données critiques sans possibilité de restauration entraîne une interruption prolongée des opérations de l'entreprise. Les services peuvent être inaccessibles, ce qui peut affecter la production, les services aux clients et la réputation de l'entreprise.

Exemple : Si une base de données essentielle à l’activité est corrompue ou perdue et qu'il n’existe pas de sauvegarde, l'entreprise pourrait être contrainte de suspendre son activité jusqu'à la reconstruction ou la récupération des informations.

Non-respect des exigences réglementaires

De nombreuses réglementations (par exemple RGPD, HIPAA, PCI-DSS) exigent que les organisations disposent de mécanismes appropriés pour protéger les données sensibles, ce qui inclut des sauvegardes régulières. L'absence de sauvegardes peut entraîner une non-conformité à ces obligations légales, avec des sanctions financières et des dommages à la réputation.

Exemple : En cas d'audit, l’absence de stratégies de sauvegarde adéquates peut entraîner des sanctions pour ne pas respecter les exigences de protection des données.

Risque accru lors de cyberattaques (rançongiciels, etc.)

Sans sauvegardes, une organisation est vulnérable à des attaques par rançongiciel et autres cyberattaques. Les attaquants peuvent exiger une rançon pour restaurer les données, et sans copie de sauvegarde, l'entreprise risque de perdre définitivement ses données ou de devoir céder aux demandes des cybercriminels.

Exemple : Lors d'une attaque par rançongiciel, l'absence de sauvegarde peut forcer l'entreprise à payer une rançon, sans garantie de récupération des données.

Difficulté à récupérer après des sinistres (incendies, inondations, etc.)

En cas de désastre physique (incendie, inondation, vol), l'absence de sauvegardes, en particulier hors site, peut rendre la récupération de l'infrastructure et des données quasiment impossible. Sans copies des données, l'organisme pourrait avoir du mal à redémarrer ses opérations.

Exemple : Un incendie détruisant un centre de données physique sans sauvegarde dans un autre lieu ou dans le cloud entraînera une perte définitive de l’infrastructure et des données, compromettant la reprise des activités.

Impact sur la réputation du MINARM

Si une organisation subit une perte de données importante, cela peut affecter la réputation du MINARM. Une absence de sauvegardes aggrave la crise, rendant la situation difficile à gérer.

Augmentation des coûts de récupération

Sans sauvegardes, la récupération des données perdues peut devenir extrêmement coûteuse, nécessitant des efforts manuels, des outils spécialisés ou des services externes de récupération de données. Ces coûts peuvent dépasser largement le budget prévu pour la gestion des risques.

Exemple : La tentative de récupération manuelle de données perdues ou corrompues peut entraîner des coûts de services spécialisés élevés, bien plus que le coût d’une solution de sauvegarde régulière.

Perte de continuité de service en cas de défaillance matérielle ou logiciel

Les pannes matérielles ou logicielles imprévues peuvent rendre les systèmes inaccessibles. Sans sauvegarde, les efforts pour rétablir les services sont intensifiés, et la continuité de service est compromise.

Exemple : Si un serveur clé tombe en panne et que ses données ne sont pas sauvegardées, l’entreprise devra peut-être redémarrer des processus manuels et rencontrer des périodes d'indisponibilité.

Incapacité à restaurer les versions précédentes des données

En l'absence de sauvegarde, il est impossible de restaurer des versions antérieures des fichiers ou des systèmes, ce qui pourrait être essentiel en cas de corruption de données, de modifications malveillantes ou d'erreur humaine.

Exemple : Un utilisateur supprime ou modifie accidentellement des fichiers importants. Sans sauvegarde, ces fichiers sont perdus et ne peuvent pas être récupérés dans leur état initial.

Risque d'altération ou de perte d'intégrité des données

Sans sauvegarde, il est difficile de garantir l'intégrité des données. En cas de corruption de données ou d'attaque, il est impossible de revenir à un état sain.

Exemple : Lors d'un cyber incident, les données peuvent être corrompues ou modifiées de manière malveillante. Une sauvegarde permet de restaurer un état de sécurité antérieur, garantissant l'intégrité des données.

Sécurisation réseaux

Dans le thème de la sécurisation des réseaux, on peut identifier 2 principes :

La sécurisation des réseaux

La séparation des réseaux métier et d’administration

La sécurisation des réseaux

L'absence de sécurisation du réseau expose une organisation à une série de risques graves qui peuvent compromettre la confidentialité, l'intégrité, et la disponibilité des données et des systèmes. L'absence de sécurisation du réseau expose l'organisation à des risques importants de cyberattaques, de fuites de données, d'interruptions de service, et de pertes financières. Pour garantir la confidentialité, l'intégrité et la disponibilité des systèmes, il est essentiel d'implémenter des mesures de sécurité robustes et de maintenir une surveillance continue du réseau. Voici les principaux risques associés à une absence de sécurisation du réseau :

Attaques externes (intrusions, hacking)

Sans sécurisation du réseau, les systèmes sont vulnérables aux attaques externes telles que les intrusions par des hackers, des attaques par force brute ou des exploits de vulnérabilités. Ces attaques peuvent permettre à des attaquants de pénétrer dans l’infrastructure du réseau, d’accéder à des données sensibles et de prendre le contrôle des systèmes.

Exemple : Un attaquant peut exploiter une vulnérabilité dans un pare-feu mal configuré ou non présent, pénétrer dans le réseau et installer un cheval de Troie ou un rootkit, donnant ainsi un contrôle total du système.

Attaques par déni de service (DoS/DDoS)

L'absence de protection contre les attaques par déni de service (DoS) ou attaques par déni de service distribué (DDoS) peut entraîner une saturation du réseau et une indisponibilité des services en ligne. Cela peut perturber les opérations de l'entreprise, empêcher les utilisateurs d'accéder aux ressources et affecter la réputation de l'organisation.

Exemple : Une attaque DDoS peut rendre un site web ou une application en ligne indisponible pendant plusieurs heures ou jours, ce qui a des conséquences directes sur l'activité commerciale.

Espionnage et interception de données

Un réseau non sécurisé peut être intercepté facilement par des attaquants, permettant l'écoute des communications ou le vol de données sensibles (p. ex., informations personnelles, données financières, secrets commerciaux). Cela peut se produire via des attaques de type Man-in-the-Middle (MITM) ou écoute clandestine.

Exemple : Un attaquant pourrait intercepter des données transmises en clair (non chiffrées) entre un utilisateur et un serveur, volant ainsi des informations sensibles comme des mots de passe ou des informations bancaires.

Propagation de logiciels malveillants

Sans un réseau bien sécurisé, les maliciels (tels que les virus, vers, rançongiciel, etc.) peuvent se propager facilement entre les systèmes. L'absence de segmentation du réseau et de contrôles de sécurité efficaces permet aux logiciels malveillants de se propager rapidement à travers l'infrastructure.

Exemple : Un ordinateur infecté par un rançongiciel sur un réseau non sécurisé peut facilement propager le maliciel aux autres ordinateurs du réseau, chiffrant ainsi une grande quantité de fichiers critiques.

Exfiltration de données sensibles

Un réseau non sécurisé permet à des attaquants d'exfiltrer des données sensibles en toute discrétion. Ils peuvent déplacer des données volées hors du réseau de l'entreprise, ce qui peut avoir des conséquences graves, en particulier si des informations personnelles, financières ou confidentielles sont compromises.

Exemple : Des attaquants peuvent utiliser un réseau mal sécurisé pour exfiltrer des bases de données contenant des informations personnelles identifiables (PII), des informations de carte de crédit ou des données clients.

Compromission des équipements IoT

De nombreux appareils de l’internet des objets, comme des caméras, des imprimantes ou des dispositifs connectés, sont souvent mal sécurisés. Une absence de sécurisation du réseau permet aux attaquants de prendre le contrôle de ces dispositifs, ce qui peut entraîner des intrusions physiques, des fuites de données ou même l'utilisation de ces dispositifs dans des attaques par réseaux de zombies.

Exemple : Un dispositif IdO mal sécurisé (comme une caméra de surveillance) peut être piraté et utilisé pour espionner des employés ou collecter des informations confidentielles.

Accès non autorisé aux systèmes internes

Sans une gestion appropriée des accès réseau, des utilisateurs non autorisés peuvent accéder à des ressources internes sensibles ou confidentielles. Cela peut se produire par l'usage de comptes compromis, l'élévation de privilèges ou la découverte de points d'entrée vulnérables.

Exemple : Un employé malveillant ou un attaquant avec des privilèges d'accès insuffisants peut exploiter des failles du réseau pour obtenir un accès administratif et modifier des paramètres critiques ou voler des données sensibles.

Risque de fraude interne

L'absence de sécurisation du réseau permet à des utilisateurs internes malveillants ou mal contrôlés d’exploiter des vulnérabilités pour commettre des fraudes ou des abus, comme la modification de données financières ou la vente de données internes.

Exemple : Un employé ayant un accès insuffisamment restreint pourrait manipuler des fichiers sensibles ou falsifier des transactions sans être détecté, entraînant des pertes financières.

Perte de contrôle et gestion des systèmes

Sans une architecture réseau sécurisée et un contrôle d'accès rigoureux, il devient difficile de maintenir une gestion efficace des systèmes. Les systèmes peuvent être laissés ouverts à des configurations incorrectes ou non sécurisées, augmentant ainsi la surface d'attaque.

Exemple : Des serveurs laissés accessibles sans restrictions de sécurité ou des ports ouverts inutiles peuvent être exploités par des attaquants pour s'introduire dans le réseau et déployer des attaques.

Incapacité à détecter et à prévenir les menaces en temps réel

L'absence de mécanismes de détection d'intrusion ou de pare-feu sur le réseau empêche la détection rapide des attaques. Sans protection appropriée, il est plus difficile de détecter des comportements anormaux ou des tentatives d'intrusion, ce qui peut permettre à un attaquant de rester dans le système pendant une période prolongée.

Exemple : Un attaquant pourrait réussir à rester dans le système pendant des semaines sans être détecté, volant des données ou préparant une attaque plus ciblée, comme un rançongiciel.

Risque pour la confidentialité des communications

Les communications sensibles (emails, messages internes, communications avec des partenaires) peuvent être compromises si le réseau n'est pas sécurisé. L'absence de chiffrement et de protections adéquates rend ces communications vulnérables à l'interception.

Exemple : Un espionnage industriel ou une fuite d'informations stratégiques pourrait avoir lieu si des discussions importantes sont interceptées sur un réseau non sécurisé.

La séparation des réseaux métier et d’administration

L'absence de séparation entre le réseau métier et le réseau d'administration expose une organisation à plusieurs risques importants en matière de sécurité informatique et opérationnelle. En conclusion, l’absence de séparation entre le réseau métier et celui d’administration représente un risque élevé pour la sécurité et l’intégrité des systèmes. La segmentation est une mesure fondamentale de cyber sécurité, à la fois pour prévenir les intrusions, contenir les incidents, et se conformer aux exigences réglementaires. Voici les risques majeurs :

Risques de sécurité accrue

Propagation d'attaques : Si un attaquant parvient à compromettre une machine du réseau métier (par exemple via une attaque par hameçonnage ou un logiciels malveillants), il peut facilement pivoter vers les équipements critiques du réseau d’administration (serveurs, hyperviseurs, équipements réseau, etc.). Cela permet une escalade rapide des privilèges.

Risque d'accès non autorisé : Sans séparation, les utilisateurs du réseau métier peuvent, volontairement ou involontairement, accéder à des ressources sensibles du réseau d'administration, augmentant les chances d'erreur ou d'actions malveillantes.

Vol ou altération des données critiques : Les données d’administration, telles que les configurations réseau, les bases de données des utilisateurs, ou les politiques de sécurité, peuvent être exfiltrées ou modifiées, compromettant l'intégrité et la confidentialité de l'environnement.

Diminution de la résilience et du contrôle

Faible cloisonnement en cas d'incident : Une attaque ou une panne sur le réseau métier peut impacter directement les services d’administration, rendant les mécanismes de gestion et de récupération (comme l’accès aux consoles d’administration) inopérants.

Difficulté dans la gestion des droits : L'absence de séparation complique la mise en œuvre de politiques granulaires de contrôle d'accès, comme le principe du moindre privilège, et réduit la capacité à isoler les différents types d'utilisateurs et leurs permissions.

Impact opérationnel accru

Baisse de performance du réseau : Les activités liées à l’administration (sauvegardes, mises à jour, surveillance) peuvent consommer beaucoup de bande passante. Si ces opérations se déroulent sur le même réseau que les activités métier, cela peut provoquer des ralentissements affectant la productivité.

Complexité du diagnostic et des interventions : En cas d'incident ou de panne, l'absence de séparation rend plus difficile l’identification de l’origine des problèmes et leur résolution, car toutes les ressources sont mélangées.

Conformité et obligations légales

Non-conformité avec les standards de sécurité : De nombreux cadres réglementaires ou normes de sécurité (tels que ISO 27001, RGPD, PCI-DSS, etc.) exigent une segmentation réseau pour limiter les impacts d’une compromission. Une absence de séparation peut donc entraîner des sanctions ou des audits négatifs.

Risque juridique : En cas de fuite de données ou de compromission, la responsabilité de l'organisation peut être engagée si des mesures élémentaires, comme la segmentation réseau, ne sont pas mises en place.

Accès physique

L’absence de sécurisation des accès système représente un risque majeur qui peut compromettre la confidentialité, l'intégrité et la disponibilité des systèmes et des données d’un système d’exploitation. L'absence de sécurisation des accès système expose une organisation à de nombreux risques, notamment l'accès non autorisé, le vol de données, la compromission des systèmes, et des attaques internes

Risques de compromission et d’escalade d’accès

Accès non autorisé facilité : Sans contrôle efficace des accès logiques, un attaquant ou un utilisateur malveillant peut accéder librement au système, notamment par le biais d’interfaces non sécurisées telles que BIOS/UEFI ou GRUB sans mot de passe.

Injection de code malveillant et élévation de privilèges : Les ports USB non maîtrisés peuvent servir à injecter des maliciels. Un GRUB non protégé permet l’accès root sans authentification.

Contournement des mécanismes de sécurité : L’absence de bannière légale réduit la dissuasion. Les interfaces inutilisées activées peuvent être exploitées comme points d’entrée.

Risques liés à la fuite et à la perte de données

Exfiltration de données : Un périphérique USB non contrôlé ou un équipement non autorisé permet la copie furtive d’informations sensibles.

Altération et compromission des données critiques : Un accès non maîtrisé aux interfaces consoles peut permettre l’installation de maliciels furtifs ou de portes dérobées.

Risques opérationnels et de résilience

Perte de traçabilité : L’absence de journalisation rend difficile la détection d’accès non autorisés.

Augmentation de la surface d’attaque : Des ports et interfaces non désactivés multiplient les vecteurs d’attaque.

Perturbation des opérations : Le branchement d’équipements non déclarés peut perturber le système.

Non-conformité et risques réglementaires

- Violation des exigences réglementaires : L'absence de sécurisation viole les normes comme ISO 27001 ou PCI-DSS.

- Responsabilité juridique engagée : En cas d’incident, cela peut être considéré comme une faute grave.

Exposition aux attaques internes

Un accès système insuffisamment sécurisé augmente le risque de menaces internes. Les employés ou les collaborateurs ayant un accès non restreint peuvent exploiter leur position pour nuire à l'organisation, soit par erreur, soit intentionnellement.

Exemple : Un employé mécontent pourrait accéder à des informations sensibles et les partager ou les manipuler, ce qui compromet l'intégrité des données de l'entreprise.

Compromission de l'intégrité des systèmes

Un mauvais contrôle des accès permet à des utilisateurs non autorisés de modifier des systèmes ou des configurations importantes, ce qui peut entraîner des corruptions de données ou des altérations des configurations système, rendant les systèmes non fiables ou vulnérables à des attaques futures.

Exemple : Un attaquant pourrait modifier des configurations de serveur ou des paramètres réseau pour désactiver les mécanismes de sécurité, permettant ainsi d'autres attaques ou intrusions.

Augmentation du risque d'attaques par force brute

Si les mots de passe ou autres mécanismes d'accès ne sont pas correctement protégés, le système devient vulnérable aux attaques par force brute, où un attaquant tente systématiquement de deviner les identifiants d'accès.

Exemple : L'absence de verrouillage après plusieurs tentatives échouées permet à un attaquant de tenter de deviner les mots de passe d'un administrateur ou d'un utilisateur disposant de droits élevés.

Risques d'accès à des ressources non nécessaires (principle of least privilege)

Si les accès aux systèmes ne sont pas strictement contrôlés, des utilisateurs peuvent se voir accorder des permissions qui ne sont pas nécessaires à leur travail. Cela violente le principe du moindre privilège, augmentant le risque d'accès non autorisé à des informations ou systèmes sensibles.

Exemple : Un employé qui n'a pas besoin d'accès à des bases de données financières pourrait se voir accorder un tel accès par défaut, ce qui représente un risque pour la confidentialité de ces données.

Perte de confidentialité et d'intégrité des données

L'absence de sécurisation des accès permet à des utilisateurs non autorisés de modifier, copier ou divulguer des informations sensibles, entraînant une perte de confidentialité et d'intégrité des données.

Exemple : Un attaquant pourrait accéder à un serveur mal sécurisé, voler des informations sensibles, et les divulguer à la concurrence ou à des parties malveillantes.

Durcissement

L'absence de mesures de durcissement des systèmes d'information constitue une faiblesse critique dans toute stratégie de cyber sécurité. Le durcissement vise à réduire la surface d’attaque en supprimant les composants non nécessaires, en renforçant les configurations par défaut, et en appliquant les bonnes pratiques cryptographiques. Voici une analyse des risques encourus en l’absence de ces mesures :

Risques de compromission du système

Présence de services inutiles : Les services et logiciels superflus offrent des vecteurs d’attaque supplémentaires. Leur présence augmente la probabilité de vulnérabilités exploitables.

Exécution de code malveillant : Sans restriction de l’installation ou de l’exécution de fichiers binaires, un attaquant peut facilement introduire des maliciels dans le système.

Utilisation de certificats non sécurisés : Les certificats par défaut ou non conformes au RGS peuvent être compromis, facilitant les attaques de type Man-In-The-Middle (MITM) ou d’usurpation.

Risques de compromission cryptographique

Clés de chiffrement non protégées : L’absence de séquestration des clés (stockage sécurisé et restreint) augmente le risque d’accès non autorisé aux données chiffrées.

Mécanismes cryptographiques faibles : L’utilisation d’algorithmes non conformes au RGS ou obsolètes expose le système à des attaques de déchiffrement.

Absence de contrôle sur les certificats : Des certificats non validés, expirés ou auto-signés peuvent être exploités pour tromper les utilisateurs et systèmes de vérification.

Risques opérationnels et de conformité

Augmentation des coûts de gestion des incidents : Des systèmes non durcis sont plus vulnérables, donc plus souvent victimes d’incidents de sécurité.

Non-respect des normes de sécurité : L’absence de durcissement peut entraîner une non-conformité aux exigences réglementaires (ISO 27001, RGS, ANSSI, etc.).

Risque de réputation : Une compromission facilitée par une mauvaise configuration peut affecter l’image de l’organisation et sa crédibilité auprès des partenaires.
