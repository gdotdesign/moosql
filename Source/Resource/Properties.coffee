MooSQL.Properties = new Class {
  setValues: (values) ->
    @values = $merge @getClean(), values
    @dirty = yes
  getValues: ->
    @values
  getClean: ->
    (new Hash(@properties).map (value,key) ->
      if value.default?
        value.default
      else
        null
    ).getClean()
  merge: (props) ->
    if @values?
      $merge @values, props
    else
      $merge @getClean(), props
  
  #set property
  set: (key,value) ->
    if @properties[key]?
     	@values[key] = value
     	@dirty = yes  
  get: (key) ->
    if @properties[key]?
      @values[key] 
    else
      null
}
