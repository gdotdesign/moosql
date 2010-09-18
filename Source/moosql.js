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
var MooSQL;
MooSQL = new Class({
  Implements: [Options, Events],
  options: {
    dbName: '',
    dbVersion: '',
    dbDesc: '',
    dbSize: 20 * 100
  },
  initialize: function(options) {
    this.setOptions(options);
    if (window.openDatabase !== null) {
      this.db = window.openDatabase(this.options.dbName, this.options.dbVersion, this.options.dbDesc, this.options.dbSize, (function(db) {
        this.db = db;
        return this.fireEvent('databaseCreated');
      }).bind(this));
    }
    if (this.db !== null) {
      this.fireEvent('databaseReady');
    } else {
      this.fireEvent('notSupported');
    }
    return this;
  },
  exec: function(statement, callback, args) {
    return this.db.transaction((function(tr) {
      return tr.executeSql(statement, args, callback || function() {}, (function(tr, err) {
        callback.run([tr, err]);
        this.fireEvent('statementError', err);
        return false;
      }).bind(this));
    }).bind(this), (function(tr, err) {
      callback.run(tr, err);
      this.fireEvent('transactionError', err);
      return false;
    }).bind(this));
  },
  like: function(table, what, Where, callback) {
    var wheremap;
    if (Where === null) {
      wheremap = '';
    } else {
      wheremap = this.likeMap(Where);
    }
    return this.exec("SELECT " + $splat(what).join(',') + (" FROM '" + (table) + "' ") + (Where === (typeof null !== "undefined" && null !== null) ? ';' : ("WHERE " + (wheremap) + ";")), callback);
  },
  findAll: function(tables, callback) {
    var query;
    query = '';
    $splat(tables).each(function(item, i) {
      return i === 0 ? query += ("SELECT *, '" + (item) + "' AS type FROM '" + (item) + "' ") : query += ("union SELECT *, '" + (item) + "' AS type FROM '" + (item) + "' ");
    });
    return this.exec("" + (query) + ";", callback);
  },
  findA: function(table, callback) {
    return this.exec("SELECT * FROM '" + table + "';", callback);
  },
  find: function(table, what, Where, callback) {
    var wheremap;
    if (Where === null) {
      wheremap = '';
    } else {
      wheremap = this.whereMap(Where);
    }
    return this.exec("SELECT " + $splat(what).join(',') + (" FROM '" + (table) + "' ") + (Where === (typeof null !== "undefined" && null !== null) ? ';' : ("WHERE " + (wheremap) + ";")), callback);
  },
  tableExists: function(name, callback) {
    return this.exec("select * from " + (name), callback);
  },
  create: function(table, values, callback) {
    var valuesmap;
    valuesmap = new Hash(values).map(function(value, key) {
      return '"' + key + '" ' + $splat(value).join(" ").toUpperCase();
    });
    values = $splat(valuesmap.getValues()).join(', ');
    return this.exec("CREATE TABLE '" + (table) + "' ( " + (values) + " )", callback);
  },
  save: function(table, set, Where, callback) {
    return this.find(table, '*', Where, (function(tr, result) {
      return result.rows.length > 0 ? this.update(table, set, Where, callback) : this.insert(table, $extend(set, Where), callback);
    }).bindWithEvent(this));
  },
  insert: function(table, values, callback) {
    var keys, vals, valuesa;
    vals = new Hash(values);
    valuesa = vals.getValues().map(function(item) {
      return "'" + (item) + "'";
    });
    keys = vals.getKeys().map(function(item) {
      return "'" + (item) + "'";
    });
    return this.exec("INSERT INTO '" + (table) + "' ( " + (keys) + " ) VALUES ( " + (valuesa) + " );", callback);
  },
  remove: function(table, Where, callback) {
    var wheremap;
    wheremap = this.whereMap(Where);
    return this.exec("DELETE FROM '" + (table) + "' WHERE " + (wheremap) + ";", callback);
  },
  update: function(table, set, Where, callback) {
    var setmap, wheremap;
    wheremap = this.whereMap(Where);
    setmap = $splat(new Hash(set).map(function(value, key) {
      return "" + (key) + "='" + (value) + "'";
    }).getValues()).join(', ');
    return this.exec("UPDATE '" + (table) + "' SET " + (setmap) + " WHERE " + (wheremap) + ";", callback);
  },
  whereMap: function(wher) {
    return $splat(new Hash(wher).map(function(value, key) {
      return key + "='" + value + "'";
    }).getValues()).join(" AND ");
  },
  likeMap: function(wher) {
    return $splat(new Hash(wher).map(function(value, key) {
      return key + " LIKE '" + value + "'";
    }).getValues()).join(" AND ");
  }
});
