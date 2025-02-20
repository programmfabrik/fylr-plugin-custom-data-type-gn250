const fs = require('fs')
const https = require('https')
const fetch = (...args) => import('node-fetch').then(({
    default: fetch
}) => fetch(...args));

let databaseLanguages = [];
let frontendLanguages = [];
let default_language = 'de';

let info = {}

let access_token = '';

if (process.argv.length >= 3) {
    info = JSON.parse(process.argv[2])
}

function hasChanges(objectOne, objectTwo) {
    var len;
    const ref = ["conceptName", "conceptURI", "_standard", "_fulltext", "conceptGeoJSON", "facetTerm", "frontendLanguage"];
    for (let i = 0, len = ref.length; i < len; i++) {
        let key = ref[i];
        if (!gn250Util.isEqual(objectOne[key], objectTwo[key])) {
            return true;
        }
    }
    return false;
}

function getConfigFromAPI() {
    return new Promise((resolve, reject) => {
        var url = 'http://fylr.localhost:8081/api/v1/config?access_token=' + access_token
        fetch(url, {
                headers: {
                    'Accept': 'application/json'
                },
            })
            .then(response => {
                if (response.ok) {
                    resolve(response.json());
                } else {
                    console.error("gn250-Updater: Fehler bei der Anfrage an /config ");
                }
            })
            .catch(error => {
                console.error(error);
                console.error("gn250-Updater: Fehler bei der Anfrage an /config");
            });
    });
}

main = (payload) => {
    switch (payload.action) {
        case "start_update":
            outputData({
                "state": {
                    "personal": 2
                },
                "log": ["started logging"]
            })
            break
        case "update":

            ////////////////////////////////////////////////////////////////////////////
            // run gn250-api-call for every given uri
            ////////////////////////////////////////////////////////////////////////////

            // collect URIs
            let URIList = [];
            for (var i = 0; i < payload.objects.length; i++) {
                URIList.push(payload.objects[i].data.conceptURI);
            }
            // unique urilist
            URIList = [...new Set(URIList)]

            let requestUrls = [];
            let requests = [];

            URIList.forEach((uri) => {
                let dataRequestUrl = uri + '?format=json'
                let dataRequest = fetch(dataRequestUrl);
                requests.push({
                    url: dataRequestUrl,
                    uri: uri,
                    request: dataRequest
                });
                requestUrls.push(dataRequest);
            });

            Promise.all(requestUrls).then(function(responses) {
                let results = [];
                // Get a JSON object from each of the responses
                responses.forEach((response, index) => {
                    let url = requests[index].url;
                    let uri = requests[index].uri;
                    let result = {
                        url: url,
                        uri: uri,
                        data: null,
                        error: null
                    };
                    if (response.ok) {
                        result.data = response.json();
                    } else {
                        result.error = "Error fetching data from " + url + ": " + response.status + " " + response.statusText;
                    }
                    results.push(result);
                });
                return Promise.all(results.map(result => result.data));
            }).then(function(data) {
                let results = [];
                data.forEach((data, index) => {
                    let url = requests[index].url;
                    let uri = requests[index].uri;
                    let result = {
                        url: url,
                        uri: uri,
                        data: data,
                        error: null
                    };
                    if (data instanceof Error) {
                        result.error = "Error parsing data from " + url + ": " + data.message;
                    }
                    results.push(result);
                });

                // build cdata from all api-request-results
                let cdataList = [];
                payload.objects.forEach((result, index) => {
                    let originalCdata = payload.objects[index].data;
                    let newCdata = {};
                    let originalURI = originalCdata.conceptURI;

                    const matchingRecordData = results.find(record => record.uri === originalURI);

                    if (matchingRecordData) {
                        // rematch uri, because maybe uri changed / rewrites ..
                        let uri = matchingRecordData.uri;

                        ///////////////////////////////////////////////////////
                        // conceptName, conceptURI, _standard, _fulltext, facet, frontendLanguage, conceptGeoJSON
                        data = matchingRecordData.data;
                        if (data) {
                            // get desired language for preflabel. This is frontendlanguage from original data...
                            let desiredLanguage = originalCdata.frontendLanguage;
                            // save conceptName
                            // lock in save data
                            newCdata.conceptURI = 'https://uri.gbv.de/terminology/gn250/' + data.NNID;
                            newCdata.conceptName = data.NAME;

                            // if no frontendLanguage exists in originalData: add
                            if (!originalCdata?.frontendLanguage?.length == 2) {
                                originalCdata.frontendLanguage = defaultLanguage;
                            }
                            // save frontend language (same as given or default)
                            newCdata.frontendLanguage = originalCdata.frontendLanguage;

                            newCdata.facetTerm = gn250Util.getFacetTerm(newCdata, databaseLanguages);
                            newCdata._fulltext = gn250Util.getFullTextFromObject(data, databaseLanguages);

                            newCdata._standard = gn250Util.getStandardTextFromObject( null, data, originalCdata, databaseLanguages);

                            geoJSON = gn250Util.getGEOJSONFromObject(data);
                            if (geoJSON)
                                newCdata.conceptGeoJSON = geoJSON;

                            if (hasChanges(payload.objects[index].data, newCdata)) {
                                payload.objects[index].data = newCdata;
                            } else {}
                        }
                    } else {
                        console.error('No matching record found');
                    }
                });
                outputData({
                    "payload": payload.objects,
                    "log": [payload.objects.length + " objects in payload"]
                });
            });
            // send data back for update
            break;
        case "end_update":
            outputData({
                "state": {
                    "theend": 2,
                    "log": ["done logging"]
                }
            });
            break;
        default:
            outputErr("Unsupported action " + payload.action);
    }
}

outputData = (data) => {
    out = {
        "status_code": 200,
        "body": data
    }
    process.stdout.write(JSON.stringify(out))
    process.exit(0);
}

outputErr = (err2) => {
    let err = {
        "status_code": 400,
        "body": {
            "error": err2.toString()
        }
    }
    console.error(JSON.stringify(err))
    process.stdout.write(JSON.stringify(err))
    process.exit(0);
}

(() => {

    let data = ""

    process.stdin.setEncoding('utf8');

    ////////////////////////////////////////////////////////////////////////////
    // check if hour-restriction is set
    ////////////////////////////////////////////////////////////////////////////

    if(info?.config?.plugin?.['custom-data-type-gn250']?.config?.update_gn250?.restrict_time === true) {
        let plugin_config = info.config.plugin['custom-data-type-gn250'].config.update_gn250;
        // check if hours are configured
        if(plugin_config?.from_time !== false && plugin_config?.to_time !== false) {
            const now = new Date();            
            const hour = now.getHours();
            // check if hours do not match
            if(hour < plugin_config.from_time && hour >= plugin_config.to_time) {
                // exit if hours do not match
                outputData({
                    "state": {
                        "theend": 2,
                        "log": ["hours do not match, cancel update"]
                    }
                });
            }
        }
    }

    access_token = info && info.plugin_user_access_token;

    if (access_token) {

        ////////////////////////////////////////////////////////////////////////////
        // get config and read the languages
        ////////////////////////////////////////////////////////////////////////////

        getConfigFromAPI().then(config => {
            databaseLanguages = config.system.config.languages.database;
            databaseLanguages = databaseLanguages.map((value, key, array) => {
                return value.value;
            });

            frontendLanguages = config.system.config.languages.frontend;

            const testDefaultLanguageConfig = config.plugin['custom-data-type-gn250'].config.update_gn250.default_language;
            if (testDefaultLanguageConfig) {
                if (testDefaultLanguageConfig.length == 2) {
                    defaultLanguage = testDefaultLanguageConfig;
                }
            }

            ////////////////////////////////////////////////////////////////////////////
            // availabilityCheck for gn250‚-api
            ////////////////////////////////////////////////////////////////////////////
            let testURL = 'https://uri.gbv.de/terminology/gn250/DEBKGGND00000B2J?format=json';
            https.get(testURL, res => {
                let testData = [];
                res.on('data', chunk => {
                    testData.push(chunk);
                });
                res.on('end', () => {
                    const testVocab = JSON.parse(Buffer.concat(testData).toString());
                    if (testVocab.OBA == "AX_Ortslage") {
                        ////////////////////////////////////////////////////////////////////////////
                        // test successfull --> continue with custom-data-type-update
                        ////////////////////////////////////////////////////////////////////////////
                        process.stdin.on('readable', () => {
                            let chunk;
                            while ((chunk = process.stdin.read()) !== null) {
                                data = data + chunk
                            }
                        });
                        process.stdin.on('end', () => {
                            ///////////////////////////////////////
                            // continue with update-routine
                            ///////////////////////////////////////
                            try {
                                let payload = JSON.parse(data)
                                main(payload)
                            } catch (error) {
                                console.error("caught error", error)
                                outputErr(error)
                            }
                        });
                    } else {
                        console.error('Error while interpreting data from gn250-API.');
                    }
                });
            }).on('error', err => {
                console.error('Error while receiving data from gn250-API: ', err.message);
            });
        }).catch(error => {
            console.error('Es gab einen Fehler beim Laden der Konfiguration:', error);
        });
    } else {
        console.error("kein Accesstoken gefunden");
    }
})();