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

