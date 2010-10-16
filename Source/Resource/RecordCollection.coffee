MooSQL.Resource.RecordCollection = new Class {
  Implements : [Events
                MooSQL.Properties]
  initialize: (properties,table) ->
    @dirty = no
    @saved = no
    @properties = properties
    @table = table
    @records = []
    @
  addRecord: (props) ->
    record = new MooSQL.Resource.Record @properties, @table
    record.setValues props
    @records.push record
    #record.addEvent ''            
  save: (properties) ->
    @reecords.each (record) ->
      record.update properties
  update: (properties) ->
    @records.each (record) ->
      record.update properties
  destroy: ->          
    @records.each (record) ->
      record.destroy()
}
