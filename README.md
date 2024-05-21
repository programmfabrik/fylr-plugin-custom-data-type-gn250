> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# fylr-custom-data-type-gn250

This is a plugin for [fyr](http://docs.fylr.io/) with Custom Data Type `CustomDataTypeGN250` for references to entities of the gn250-Set of [Bundesamt für Kartographie](http://www.geodatenzentrum.de/geodaten/gdz_rahmen.gdz_div?gdz_spr=deu&gdz_akt_zeile=5&gdz_anz_zeile=1&gdz_unt_zeile=20&gdz_user_id=0).

The Plugins uses <http://ws.gbv.de/suggest/gn250/> for the autocomplete-suggestions and the mapbox-API for displaying the result in a map.

## installation
The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-plugin-custom-data-type-gn250/releases/latest/download/customDataTypeGN250.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all releases](https://github.com/programmfabrik/fylr-plugin-custom-data-type-geonames/releases/).


## configuration
As defined in `manifest.master.yml` this datatype can be configured:

### Schema options
* which "mapbox-token" to use

### Mask options
* editordisplay: default or condensed (oneline)

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptGeoJSON
    * point or polygon as geoJSON
* frontendLanguage
    * the frontendlanguage of the entering user
* facetTerm
    * custom facets, which support multilingual facetting
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/fylr-custom-data-type-gn250>.
