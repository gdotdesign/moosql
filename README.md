MooSql
===========

Class wrapper for HTML5 SQL Storage
More information on HTML5 SQL Storage http://dev.w3.org/html5/webdatabase/

How to use
----------

        //Create an instance.
        var sqlDB = new MooSQL({
            //Database name
            dbName:'Test',
            //Database version (max 4 numbers seperated by dots)
            dbVersion:'1.0',
            //Database description (officially database display name)
            dbDesc:'This is a test Database',
            //Estimated size
            dbSize:20*100
        })
        sqlDB.addEvent('databaseReady',function(){
            //Execute some SQL statement, callback is needed
            sqlDB.exec("SELECT * FROM 'sometable'",callback.bindWithEvent());
        })
       
        //Callback function
        function callback(transaction,result){
           log(result.rows.item(0));
        }

Events
----------

databaseReady - fires when the database is ready for work.

databaseCreated - fires when the database created if there is none.

notSupported - fires if the browser not supports SQL storage

transactionError - fires if something goes wrong with the transation, 1 argument(SQLException)

statmentError - fires if the statement is invalid , 1 argument(SQLException)