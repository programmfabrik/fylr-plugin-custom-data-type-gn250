class CustomDataTypeGN250 extends CustomDataTypeWithCommonsAsPlugin

  #######################################################################
  # bugfix, may be removed after next update (1.3.2017)
  getL10NPrefix: ->
    "custom.data.type.gn250"

  #######################################################################
  # configure used facet
  getFacet: (opts) ->
      opts.field = @
      new CustomDataTypeGN250Facet(opts)

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-gn250.gn250"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.gn250.name")

  #######################################################################
  # returns the databaseLanguages
  getDatabaseLanguages: () ->
    databaseLanguages = ez5.loca.getLanguageControl().getLanguages().slice()
    return databaseLanguages
    
  #######################################################################
  # allows usage of "standard (geo)" in maskoptioons
  supportsGeoStandard: 
    ->true 

  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5.loca.getLanguage()
    desiredLanguage = desiredLanguage.split('-')
    desiredLanguage = desiredLanguage[0]

    desiredLanguage
    
  #######################################################################
  # read info from gn250-terminology
  __getAdditionalTooltipInfo: (encodedURI, tooltip, extendedInfo_xhr) ->

    that = @

    # extract gn250ID from uri
    uri = decodeURIComponent(encodedURI)
    gn250ID = uri
    gn250ID = gn250ID.split "/"
    gn250ID = gn250ID.pop()

    # abort eventually running request
    if extendedInfo_xhr.xhr != undefined
      extendedInfo_xhr.xhr.abort()

    # start new request
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//uri.gbv.de/terminology/gn250/' + gn250ID + '?format=json')
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = '<span style="padding: 10px 10px 0px 10px; font-weight: bold">' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.info') + '</span>'
      if that.getCustomSchemaSettings().mapbox_api_key?.value
          mapbox_api_key = that.getCustomSchemaSettings().mapbox_api_key?.value
      if mapbox_api_key
        geoStr = data.BOX_GEO
        geoStr = geoStr.replace('POLYGON ((', '')
        geoStr = geoStr.replace('))', '')
        geoPositions = geoStr.split(',')

        positionTL = geoPositions[0].split(' ')
        positionTL = positionTL.map(Number)

        positionBR = geoPositions[2].split(' ')
        positionBR = positionBR.map(Number)

        coord1 = positionTL[1] + ((positionBR[1] - positionTL[1]) / 2)
        coord2 = positionTL[0] + ((positionBR[0] - positionTL[0]) / 2)

        if coord1 != 0 & coord2 != 0
          url = location.protocol + '//api.mapbox.com/styles/v1/mapbox/streets-v11/static/' + coord2 + ',' + coord1 + ',11/400x200@2x?access_token=' + mapbox_api_key
          htmlContent += '<div style="width:400px; height: 250px; background-size: contain; background-image: url(' + url + '); background-repeat: no-repeat; background-position: center center;"></div>'


      htmlContent += '<table style="border-spacing: 4px; border-collapse: separate;">'

      if data.NNID
        if typeof data.NNID != 'object'
            htmlContent += '<tr><td>NNID:</td><td>' + data.NNID + '</td></tr>'

      if data.OBA
        if typeof data.OBA != 'object'
            htmlContent += '<tr><td>OBA:</td><td>' + data.OBA + '</td></tr>'

      if data.OBA_WERT
        if typeof data.OBA_WERT != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.oba_wert') + ':</td><td>' + data.OBA_WERT + '</td></tr>'

      if data.NAME
        if typeof data.NAME != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.name') + ':</td><td>' + data.NAME + '</td></tr>'

      if data.E
        if typeof data.NAME2 != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.name2') + ':</td><td>' + data.NAME2 + '</td></tr>'

      if data.GEMEINDE
        if typeof data.GEMEINDE != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.gemeinde') + ':</td><td>' + data.GEMEINDE + '</td></tr>'

      if data.VERWGEM
        if typeof data.VERWGEM != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.verwaltungsgemeinde') + ':</td><td>' + data.VERWGEM + '</td></tr>'

      if data.KREIS
        if typeof data.KREIS != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.kreis') + ':</td><td>' + data.KREIS + '</td></tr>'

      if data.REGBEZIRK
        if typeof data.REGBEZIRK != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.bezirk') + ':</td><td>' + data.REGBEZIRK + '</td></tr>'

      if data.BUNDESLAND
        if typeof data.BUNDESLAND != 'object'
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.bundesland') + ':</td><td>' + data.BUNDESLAND + '</td></tr>'

      if data.SOURCE
        if typeof data.SOURCE != 'object'
            dataSource = data.SOURCE.replace(' - ', '<br />')
            htmlContent += '<tr><td>' + $$('custom.data.type.gn250.config.parameter.mask.infopopup.popup.quelle') + ':</td><td>' + dataSource + '</td></tr>'

      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        gn250_searchterm = searchstring
        gn250_countSuggestions = 20

        if cdata_form
          gn250_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
          gn250_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

        if gn250_searchterm.length == 0
            return

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # start new request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//ws.gbv.de/suggest/gn250/?searchterm=' + gn250_searchterm + '&count=' + gn250_countSuggestions)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            # init xhr for tooltipcontent
            extendedInfo_xhr = { "xhr" : undefined }

            # create new menu with suggestions
            menu_items = []
            # the actual Featureclass
            for suggestion, key in data[1]
              do(key) ->
                # the actual Featureclass...
                aktType = data[2][key]
                lastType = ''
                if key > 0
                  lastType = data[2][key-1]
                if aktType != lastType
                  item =
                    divider: true
                  menu_items.push item
                  item =
                    label: aktType
                  menu_items.push item
                  item =
                    divider: true
                  menu_items.push item
                item =
                  text: suggestion
                  value: data[3][key]
                  tooltip:
                    markdown: true
                    placement: "e"
                    content: (tooltip) ->
                      mapbox_api_key = ''
                      if that.getCustomSchemaSettings().mapbox_api_key?.value
                          mapbox_api_key = that.getCustomSchemaSettings().mapbox_api_key?.value
                      that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.gn250.config.parameter.mask.show_infopopup.loading.label'))
                menu_items.push item

            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->
                    
                    
                # https://uri.gbv.de/terminology/gn250/DEBKGGND00000B2J?format=json
                    
                gn250URI = btn.getOpt("value")
                gn250URIParts = gn250URI.split('/')
                gn250ID = gn250URIParts.pop()
                    
                # start new request
                extendedInfo_xhr.xhr = new (CUI.XHR)(url: 'https://uri.gbv.de/terminology/gn250/' + gn250ID + '?format=json')
                extendedInfo_xhr.xhr.start().done((dataDetail, status, statusText) ->
                    # lock in save data
                    cdata.conceptURI = 'https://uri.gbv.de/terminology/gn250/' + dataDetail.NNID
                    cdata.conceptName = dataDetail.NAME
                    
                    activeFrontendLanguage = that.getFrontendLanguage()
                    cdata.frontendLanguage = activeFrontendLanguage

                    databaseLanguages = that.getDatabaseLanguages()
                    
                    cdata.facetTerm = gn250Util.getFacetTerm(cdata, databaseLanguages)
                    cdata._fulltext = gn250Util.getFullTextFromObject(dataDetail, databaseLanguages)
                    
                    cdata._standard = gn250Util.getStandardTextFromObject( that, dataDetail, cdata, false)
                    
                    geoJSON = gn250Util.getGEOJSONFromObject(dataDetail)
                    if geoJSON
                        cdata.conceptGeoJSON = geoJSON
                    
                    # update the layout in form
                    that.__updateResult(cdata, layout, opts)
                    # hide suggest-menu
                    suggest_Menu.hide()
                    # close popover
                    if that.popover
                      that.popover.hide()
                )
                    
              items: menu_items

            # if no hits set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: "kein Treffer"
                  value: undefined
                ]

            suggest_Menu.setItemList(itemList)

            suggest_Menu.show()

        )
    ), delayMillisseconds


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
    fields = [
      {
        type: CUI.Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.gn250.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 ' + $$('custom.data.type.gn250.modal.form.text.count_short')
          )
          (
              value: 20
              text: '20 ' + $$('custom.data.type.gn250.modal.form.text.count_short')
          )
          (
              value: 50
              text: '50 ' + $$('custom.data.type.gn250.modal.form.text.count_short')
          )
          (
              value: 100
              text: '100 ' + $$('custom.data.type.gn250.modal.form.text.count_short')
          )
          (
              value: 500
              text: '500 ' + $$('custom.data.type.gn250.modal.form.text.count_short')
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.gn250.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.gn250.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }]

    fields


  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->

    that = @

    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.gn250.edit.no_gn250")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.gn250.edit.no_valid_gn250")).DOM

    # if status is ok
    cdata.conceptURI = CUI.parseLocation(cdata.conceptURI).url

    extendedInfo_xhr = { "xhr" : undefined }

    # output Button with Name of picked Entry and URI
    new CUI.HorizontalLayout
      maximize: true
      left:
        content:
          new CUI.Label
            centered: false
            text: cdata.conceptName
      center:
        content:
          # Url to the Source
          new CUI.ButtonHref
            appearance: "link"
            href: cdata.conceptURI
            target: "_blank"
            tooltip:
              markdown: true
              placement: 'n'
              content: (tooltip) ->
                that.__getAdditionalTooltipInfo(cdata.conceptURI, tooltip, extendedInfo_xhr)
                new CUI.Label(icon: "spinner", text: "lade Informationen")
            text: ""
      right: null
    .DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.mapbox_api_key?.value
      tags.push "✓ mapbox-token"
    else
      tags.push "✘ mapbox-token"

    tags


CustomDataType.register(CustomDataTypeGN250)
