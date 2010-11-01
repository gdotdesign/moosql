MooSQL.Resource = new Class {
  Implements : [Events
                MooSQL.Properties]
  table: null
  properties: {}
  initialize: () ->
    MooSQL.tableExists @table, ( ->
      if arguments[1].code?
        if arguments[1].code == 5
          createmap = new Hash(@properties).map (value,key) ->
            ret = value.type
            if value.key?
              ret += ' PRIMARY KEY'
            else if value.unqiue?
              ret += ' UNIQUE'
            if value.default?
              ret += " DEFAULT '#{value.default}'"
            ret 
          MooSQL.create @table, createmap, ( ->
            @fireEvent 'created'
          ).bind @
      else
        @fireEvent 'ready'
    ).bind @
  create: (properties) ->
    record = new MooSQL.Resource.Record(@properties,@table)
    record.save properties
  new: ->
    new MooSQL.Resource.Record(@properties,@table)
  first: (properties) ->
    if properties?
      props = @merge(properties)
    else
      props = null
    record = @new @properties, @table
    MooSQL.find @table, props, (tr,result) ->
      if result.rows.length > 0
        record.setValues result.rows.item(0)
        console.log result.rows.item(0), 'first'
      record.fireEvent 'ready'
    record
  find: (properties) ->
    if properties?
      props = @merge(properties)
    else
      props = null
    ret = new MooSQL.Resource.RecordCollection  @properties, @table
    MooSQL.find @table, props, ( (tr,result) ->
      ret.setValues properties
      if result.rows.length > 0
        i = 0    
        while i < result.rows.length
          ret.addRecord result.rows.item(i)
          i++
      ret.fireEvent 'ready'
    ).bind @
    ret    
}
