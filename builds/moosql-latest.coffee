MooSQL = new Class.Singleton {
  Implements : [Options, Events]
  initialize: () ->
    
  connect: (db) ->
    #@setOptions options
    if window.openDatabase isnt null
      @db = window.openDatabase(
        db
        ''
        ''
        ''
        ( (db) ->
          @db = db
          @fireEvent 'databaseCreated'
        ).bind @
      )
    if @db isnt null
      @fireEvent 'databaseReady'
    else
      @fireEvent 'notSupported'
    @

  exec: (statement, callback, args) ->
    console.log statement
    @db.transaction ((tr) ->
      tr.executeSql(
        statement
        args
        callback or ->
        ((tr,err) ->
          callback.run([tr,err])
          @fireEvent('statementError', err);
          false
        ).bind(@))
      ).bind(@),
      ( (tr,err) ->
       callback.run(tr,err)
       @fireEvent('transactionError', err)
       false
       ).bind @
 
  like: (table, what, Where, callback) ->
    if Where is null
      wheremap = ''
    else
      wheremap = @likeMap Where
    @exec "SELECT "+$splat(what).join(',')+" FROM '#{table}' "+(if Where is null? then ';' else "WHERE #{wheremap};"), callback
 
  findAll: (tables, callback) ->
    query = ''
    $splat(tables).each (item,i) ->
      if i is 0
        query +="SELECT *, '#{item}' AS type FROM '#{item}' "
      else
        query +="union SELECT *, '#{item}' AS type FROM '#{item}' "
    @exec "#{query};", callback

  findA: (table,callback) ->
    @exec "SELECT * FROM '"+table+"';", callback

  find: (table, Where, callback) ->
    console.log Where
    if Where is null
      wheremap = ''
    else
      wheremap = @whereMap Where
    @exec "SELECT *, ROWID FROM '#{table}' "+(if Where is null then ';' else "WHERE #{wheremap};"), callback

  tableExists: (name,callback) ->
    @exec "select * from #{name}",callback

  create: (table, values, callback) ->
    valuesmap = new Hash(values).map((value,key) ->
      '"'+key+'" '+$splat(value).join(" ").toUpperCase()
    )
    values = $splat(valuesmap.getValues()).join ', '
    @exec "CREATE TABLE '#{table}' ( #{values} )", callback

  save: (table, set, Where, callback) ->
    @find table, '*', Where, ( (tr, result) ->
      if result.rows.length > 0
        @update table, set, Where, callback
      else
        @insert table, $extend(set,Where), callback
      ).bindWithEvent @
 
  insert: (table, values, callback) ->
    vals = new Hash values
    valuesa = vals.getValues().map (item) ->
      if item?
        "'#{item}'"
      else
        "NULL"
    keys = vals.getKeys().map (item) ->
      "'#{item}'"
    @exec "INSERT INTO '#{table}' ( #{keys} ) VALUES ( #{valuesa} );", callback
 
  remove: (table, Where, callback) ->
    wheremap =  @whereMap Where
    @exec "DELETE FROM '#{table}' WHERE #{wheremap};", callback
 
  update: (table, set, Where, callback) ->
    wheremap =  @whereMap Where
    setmap = $splat(new Hash(set).map((value,key) ->
      "#{key}='#{value}'"
    ).getValues()).join ', '
    @exec "UPDATE '#{table}' SET #{setmap} WHERE #{wheremap};", callback
 
  whereMap: (wher) ->
    $splat(new Hash(wher).filter((value,key) ->
      if value?
        true
      else
        false
    ).map((value,key) ->
        key+"='"+value+"'"
    ).getValues()).join " AND "
 
  likeMap: (wher) ->
    $splat(new Hash(wher).map((value,key) ->
      key+" LIKE '"+value+"'"
    ).getValues()).join " AND "
}



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

