# PRuby

PRuby est une bibliothèque simple, en Ruby, pour s'initier à la programmation
parallèle.

PRuby permet d'exprimer diverses formes de parallélisme:

* Parallélisme de tâches: {PRuby.pcall pcall} et {PRuby.future future}

* Parallélisme de données (opérations utilisables avec Array et
Range): {PRuby::PArrayRange#peach peach},
{PRuby::PArrayRange#peach_index peach_index}, {PRuby::PArrayRange#pmap
pmap}, {PRuby::PArrayRange#preduce preduce},

+ Parallélisme de flux avec pipelines et processus <<à la go>>: {PRuby.pipeline pipeline},
{PRuby.pipeline_source pipeline_source}, {PRuby.pipeline_sink
pipeline_sink}

+ Parallélisme de flux avec des streams: {PRuby.Stream Stream}

## Installation

TODO: Décrire comment installer (git clone ...)


## Utilisation

Il suffit d'importer le module avec require:

* require 'pruby'


## Auteur

Guy Tremblay, professeur, Département d'informatique, UQAM

## Historique

* Création initiale: Printemps 2015
* Modification de l'API des pipelines pour utiliser le style go: Printemps 2016
* Ajout des Streams: Printemps 2016
