MooSQL.Resource = new Class {
  Implements : [Options, Events]
  table: null
  properties: {}
  initialize: () ->
    
  create: (properites) ->
    record = new MooSQL.Resource.Record(@properties,@table)
    record.save properties
  new: ->
    new MooSQL.Resource.Record(@properties,@table)
  first: (properites) ->
  find: () ->
  parseProperties: ->
    @properties.each (item,i) ->
      
}
MooSQL.Resource.Properties = new Class {
  Implements : [Options, Events]
  initialize: (properties) ->
    @props = properties
  getClean: ->
    @props.map (value,key) ->
      if value.default?
        default
      else
        ''
  setValues: (values) ->
    $merge @getClean(), values
  getValues: ->
    @values
  merge: (props) ->
    if @values?
      $merge @getValues(), props
    else
      $merge @getClean(), props
}
MooSQL.Resource.Record = new Class {
  Implements : [Options, Events]
  initialize: (properites,table) ->
    @properties = new MooSQL.Resource.Properties(properites)
    @table = table
    @
  save: (properties) ->
    proprs = @properties.merge properties
    MooSQL.insert @table, props, ( (tr,result) ->
      if result.rowsAffected is 0
        #throw error
      else
        @properties.setValues props
    ).bind @
    @
  get: (properties) ->
    MooSQL.find @table, @properties.merge( properties ), ( (tr,result) ->
      if result.rows.length > 0
        @properties.setValues result.rows.item(0)
      else
        #throw error
    ).bind @
  update: (properties) ->
    MooSQL.update @table, properties, @properties.getValues(), ( (tr,result) ->
      if result.rowsAffected > 0
        @properties.setValues result.rows.item(0)
      else
        #throw error
    ).bind @
    @
  destroy: ->
    MooSQL.remove @table, @properties.getValues(), ( (tr,result) ->
      if result.rowsAffected > 0
        #deleted
      else
        #throw error
    ).bind @
    @
}
