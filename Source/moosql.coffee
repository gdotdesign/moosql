# MooSql
# ===========
# 
# Class wrapper for HTML5 SQL Storage
# 
# More information on HTML5 SQL Storage http://dev.w3.org/html5/webdatabase/
# 
# How to use
# ----------
# 
#         //Create an instance.
#         var sqlDB = new MooSQL({
#             //Database name
#             dbName:'Test',
#             //Database version (max 4 numbers seperated by dots)
#             dbVersion:'1.0',
#             //Database description (officially database display name)
#             dbDesc:'This is a test Database',
#             //Estimated size
#             dbSize:20*100
#         })
#         sqlDB.addEvent('databaseReady',function(){
#             //Execute some SQL statement, callback is needed
#             sqlDB.exec("SELECT * FROM 'sometable'",callback.bindWithEvent());
#         })
#        
#         //Callback function
#         function callback(transaction,result){
#            log(result.rows.item(0));
#         }
# 
# Events
# ----------
# 
# databaseReady - fires when the database is ready for work.
# 
# databaseCreated - fires when the database created if there is none.
# 
# notSupported - fires if the browser not supports SQL storage
# 
# transactionError - fires if something goes wrong with the transation, 1 argument(SQLException)
# 
# statmentError - fires if the statement is invalid , 1 argument(SQLException)

# ##Options
# * **dbName**: Database name.
# * **dbVersion**: DaDatabase version (max 4 numbers seperated by dots).
# * **dbDesc**: Database description (officially database display name).
# * **dbSize**: Estimated size.
MooSQL = new Class {
  Implements : [Options, Events]
  options: {
    dbName: ''
    dbVersion:''
    dbDesc:''
    dbSize:20*100
  }
  # ##Constructor
  initialize: (options) ->
    # Set options.
    @setOptions options
    # Check for sqllite database support.
    if window.openDatabase isnt null
      # Open the database.
      @db = window.openDatabase(
        @options.dbName
        @options.dbVersion
        @options.dbDesc
        @options.dbSize
        # Callback for database creation.
        ( (db) ->
          @db = db
          @fireEvent 'databaseCreated'
        ).bind @
      )
    # If there is a database fire the ready event.
    if @db isnt null
      @fireEvent 'databaseReady'
    else
      @fireEvent 'notSupported'
    # Return "this".
    @
  # ##exec
  # Basic sql statement execution function (asynchronous).
  # ###Arguments:
  # 
  # * **statement**: A valid SQL statement.
  # * **callback**:  Runs either when the transtaction successfull, when there is a statement error
  #   or when is a transation error.
  # * **args**: Addition arguments.
  exec: (statement, callback, args) ->
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
  # ##like
  # Runs a select statement with LIKE.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **what**: Columns for selecting.
  # * **where**: Key, value pair specifing the arguments for the WHERE clause .
  # * **callback**: The callback function.
  like: (table, what, Where, callback) ->
    if Where is null
      wheremap = ''
    else
      wheremap = @likeMap Where
    @exec "SELECT "+$splat(what).join(',')+" FROM '#{table}' "+(if Where is null? then ';' else "WHERE #{wheremap};"), callback
  # ##findAll
  # Selects everything from the specified tables.
  # ###Arguments:
  # 
  # * **tables**: The name of the tables.
  # * **callback**: The callback function.
  findAll: (tables, callback) ->
    query = ''
    $splat(tables).each (item,i) ->
      if i is 0
        query +="SELECT *, '#{item}' AS type FROM '#{item}' "
      else
        query +="union SELECT *, '#{item}' AS type FROM '#{item}' "
    @exec "#{query};", callback
  # ##findA
  # Selects everything from a table.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **callback**: The callback function.
  findA: (table,callback) ->
    @exec "SELECT * FROM '"+table+"';", callback
  # ##find
  # Runs a SELECT query.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **what**: Columns for selecting.
  # * **where**: Key, value pair specifing the arguments for the WHERE clause.
  # * **callback**: The callback function.
  find: (table, what, Where, callback) ->
    if Where is null
      wheremap = ''
    else
      wheremap = @whereMap Where
    @exec "SELECT "+$splat(what).join(',')+" FROM '#{table}' "+(if Where is null? then ';' else "WHERE #{wheremap};"), callback
  # ##tableExists
  # Checks for a table with the given name.
  # If there isn't an error the table exists.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **callback**: The callback function.
  tableExists: (name,callback) ->
    @exec "select * from #{name}",callback
  # ##create
  # Creates a table.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **callback**: The callback function.
  create: (table, values, callback) ->
    valuesmap = new Hash(values).map((value,key) ->
      '"'+key+'" '+$splat(value).join(" ").toUpperCase()
    )
    values = $splat(valuesmap.getValues()).join ', '
    @exec "CREATE TABLE '#{table}' ( #{values} )", callback
  # ##save
  # Saves a record in a table. If there isn't a record inserts it.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **set**: Key value pairs for the SET.
  # * **where**: Key, value pairs specifing the arguments for the WHERE clause.
  # * **callback**: The callback function
  save: (table, set, Where, callback) ->
    @find table, '*', Where, ( (tr, result) ->
      if result.rows.length > 0
        @update table, set, Where, callback
      else
        @insert table, $extend(set,Where), callback
      ).bindWithEvent @
  # ##insert
  # Inserts a record in a table.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **values**: Key, value pairs.
  # * **callback**: The callback function
  insert: (table, values, callback) ->
    vals = new Hash values
    valuesa = vals.getValues().map (item) ->
      "'#{item}'"
    keys = vals.getKeys().map (item) ->
      "'#{item}'"
    @exec "INSERT INTO '#{table}' ( #{keys} ) VALUES ( #{valuesa} );", callback
  # ##remove
  # Removes a record from a table.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **where**: Key, value pairs specifing the arguments for the WHERE clause.
  # * **callback**: The callback function
  remove: (table, Where, callback) ->
    wheremap =  @whereMap Where
    @exec "DELETE FROM '#{table}' WHERE #{wheremap};", callback
  # ##update
  # Updates a record in a table.
  # ###Arguments:
  # 
  # * **table**: The name of the table.
  # * **set**: Key value pairs for the SET.
  # * **where**: Key, value pairs specifing the arguments for the WHERE clause.
  # * **callback**: The callback function
  update: (table, set, Where, callback) ->
    wheremap =  @whereMap Where
    setmap = $splat(new Hash(set).map((value,key) ->
      "#{key}='#{value}'"
    ).getValues()).join ', '
    @exec "UPDATE '#{table}' SET #{setmap} WHERE #{wheremap};", callback
  # ##whereMap
  # Generates "key='value' AND key='value' AND..." map of objects
  # ###Arguments:
  # 
  # * **wher**: Key, value pairs. 
  whereMap: (wher) ->
    $splat(new Hash(wher).map((value,key) ->
      key+"='"+value+"'"
    ).getValues()).join " AND "
  # ##likeMap
  # Generates "key LIKE 'value' AND key LIKE 'value' AND..." map of objects
  # ###Arguments:
  # 
  # * **wher**: Key, value pairs.
  likeMap: (wher) ->
    $splat(new Hash(wher).map((value,key) ->
      key+" LIKE '"+value+"'"
    ).getValues()).join " AND "
}
