/*
---
description: MooSQL class, a wrapper for the HTML5 SQL storage.

license: MIT-style

authors:
- Szikszai Gusztáv

requires:
- Class
- Class.Options
- Class.Events

provides: [MooSQL]

...
*/
var MooSQL = new Class({
	
	Implements : [Options, Events],
	options: {
		//Database name
		dbName:'',
		//Database version (max 4 numbers seperated by dots)
		dbVersion:'',
		//Database description (officially database display name)
		dbDesc:'',
		//Estimated size
		dbSize:20*100
	},
	
	initialize:function(options){
		this.setOptions(options);

		if(window.openDatabase != null){
			
			this.db = window.openDatabase(
				this.options.dbName,
				this.options.dbVersion,
				this.options.dbDesc,
				this.options.dbSize,
				function(e){
					this.create.apply(this,[e]);
				}.bind(this)
			);
		}
		
		if (this.db != null) {
			this.fireEvent('databaseReady');
		} else {
			this.fireEvent('notSupported');
		}
	},
	
	create: function(db){
		this.db = db;
		this.fireEvent('databaseCreated');
	},
	
	/**
	 * Exec function
	 * Executes an SQL statment on the database.
	 * 
	 * statement: any valid SQL statement...
	 * callback: function, runs it after the statement completed with 2 arguments: transaction, and the result.
	 * args: arguments to pass to the statement
	 **/
	exec: function(statement, callback, args){
		this.db.transaction(function(tr){
			tr.executeSql(
				statement, 
				args,
				callback || function(){},
				function(err){
					this.fireEvent('transactionError', err);
				});
		},
		function(err){
			this.fireEvent('statementError', err);
		});
	}
	
});