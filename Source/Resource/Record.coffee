MooSQL.Resource.Record = new Class {
  Implements : [Events
                MooSQL.Properties]
  initialize: (properties,table) ->
    @dirty = no
    @saved = no
    @properties = properties
    @table = table
    @

  save: (properties) ->
    if properties?
      props = @merge properties
    MooSQL.insert @table, props, ( (tr,result) ->
      if result.rowsAffected is 0
        @fireEvent 'saveFailed', result.message 
      else
        @getROWID result.insertId
    ).bind @
    @
  getROWID: (id) ->
    MooSQL.find @table, {ROWID:id}, ( (tr,result) ->
      if result.rows.length > 0
        @setValues result.rows.item(0)
        @dirty = no
        @fireEvent 'ready'
      else
        @fireEvent 'fetchFailed', result.message
    ).bind @
  update: (properties) ->
    MooSQL.update @table, properties, @getValues(), ( (tr,result) ->
      if result.rowsAffected?
        @setValues properties
        @dirty = no
        @fireEvent 'updated'
      else
        @fireEvent 'updateFailed', result.message
    ).bind @
    @
  destroy: ->
    MooSQL.remove @table, @getValues(), ( (tr,result) ->
      if not (result.rowsAffected > 0)
        @fireEvent 'destroyFailed', result.message
    ).bind @
    @
}
