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
var MooSQL=new Class({
  Implements:[Options,Events],
  options:{
    //Database name
    dbName:'',
    //Database version (max 4 numbers seperated by dots)
    dbVersion:'',
    //Database description (officially database display name)
    dbDesc:'',
    //Estimated size
    dbSize:20*100
  },
  // Initialization
  initialize:function(options){
    //Set options
    this.setOptions(options);
    //Check if the browser supoorts SQL storage
    if($defined(window.openDatabase)){
      //Try to open the databse
      this.db=window.openDatabase(this.options.dbName,this.options.dbVersion,this.options.dbDesc,this.options.dbSize,this.create.bindWithEvent(this));
      if($defined(this.db)){
	//If there is a database fire the 'databaseReady' event
	this.fireEvent('databaseReady');
      }
    }else{
      //If not supported fire the 'notSupported' event
      this.fireEvent('notSupported');
    }
  },
  create:function(db){
    this.db=db;
    //Database created so fire the 'databaseCreated' event
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
  exec:function(statement,callback,args){
    this.db.transaction(function(tr){
      tr.executeSql(statement,$defined(args)?args:null,$defined(callback)?callback:$empty(),this.statmentError);
    },this.error);
  },
  /**
   * error callback: Fires the 'transactionError' event
   **/
  error:function(err){
    this.fireEvent('transactionError',err);
  },
  /**
   * statmentError callback: Fires the 'statmentError' event
   **/
  statmentError:function(err){
    this.fireEvent('statmentError',err);
  }
  })