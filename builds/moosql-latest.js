var MooSQL;
MooSQL = new Class.Singleton({
  Implements: [Options, Events],
  initialize: function() {},
  connect: function(db) {
    if (window.openDatabase !== null) {
      this.db = window.openDatabase(db, '', '', '', (function(db) {
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
    console.log(statement);
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
  find: function(table, Where, callback) {
    var wheremap;
    if (Where === null) {
      wheremap = '';
    } else {
      wheremap = this.whereMap(Where);
    }
    return this.exec(("SELECT * FROM '" + (table) + "' ") + (Where === (typeof null !== "undefined" && null !== null) ? ';' : ("WHERE " + (wheremap) + ";")), callback);
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
      return (typeof item !== "undefined" && item !== null) ? ("'" + (item) + "'") : "NULL";
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
MooSQL.Resource = new Class({
  Implements: [Options, Events],
  table: null,
  properties: {},
  initialize: function() {
    console.log(this.table);
    return MooSQL.tableExists(this.table, (function() {
      var _a, createmap;
      if (typeof (_a = arguments[1].code) !== "undefined" && _a !== null) {
        if (arguments[1].code === 5) {
          createmap = new Hash(this.properties).map(function(value, key) {
            var _a, _b, _c, ret;
            ret = value.type;
            if (typeof (_a = value.key) !== "undefined" && _a !== null) {
              ret += ' PRIMARY KEY';
            } else if (typeof (_b = value.unqiue) !== "undefined" && _b !== null) {
              ret += ' UNIQUE';
            }
            if (typeof (_c = value["default"]) !== "undefined" && _c !== null) {
              ret += (" DEFAULT '" + (value["default"]) + "'");
            }
            return ret;
          });
          return MooSQL.create(this.table, createmap, function() {});
        }
      }
    }).bind(this));
  },
  create: function(properties) {
    var record;
    record = new MooSQL.Resource.Record(this.properties, this.table);
    return record.save(properties);
  },
  "new": function() {
    return new MooSQL.Resource.Record(this.properties, this.table);
  },
  first: function(properites) {},
  find: function() {},
  parseProperties: function() {
    return this.properties.each(function(item, i) {});
  }
});
MooSQL.Resource.Properties = new Class({
  Implements: [Options, Events],
  initialize: function(properties) {
    this.props = properties;
    return this;
  },
  getClean: function() {
    return (new Hash(this.props).map(function(value, key) {
      var _a;
      return (typeof (_a = value["default"]) !== "undefined" && _a !== null) ? value["default"] : null;
    })).getClean();
  },
  setValues: function(values) {
    return (this.values = $merge(this.getValues(), values));
  },
  getValues: function() {
    return this.values;
  },
  merge: function(props) {
    var _a;
    return (typeof (_a = this.values) !== "undefined" && _a !== null) ? $merge(this.getValues(), props) : $merge(this.getClean(), props);
  }
});
MooSQL.Resource.Record = new Class({
  Implements: [Options, Events],
  initialize: function(properites, table) {
    this.properties = new MooSQL.Resource.Properties(properites);
    this.table = table;
    return this;
  },
  save: function(properties) {
    var props;
    props = this.properties.merge(properties);
    MooSQL.insert(this.table, props, (function(tr, result) {
      if (result.rowsAffected === 0) {

      } else {
        return this.getROWID(result.insertId);
      }
    }).bind(this));
    return this;
  },
  getROWID: function(id) {
    return MooSQL.find(this.table, {
      ROWID: id
    }, (function(tr, result) {
      if (result.rows.length > 0) {
        return this.properties.setValues(result.rows.item(0));
      } else {

      }
    }).bind(this));
  },
  get: function(properties) {
    return MooSQL.find(this.table, this.properties.merge(properties), (function(tr, result) {
      if (result.rows.length > 0) {
        return this.properties.setValues(result.rows.item(0));
      } else {

      }
    }).bind(this));
  },
  update: function(properties) {
    MooSQL.update(this.table, properties, this.properties.getValues(), (function(tr, result) {
      console.log(arguments);
      if (result.rowsAffected > 0) {
        return this.properties.setValues(properties);
      } else {

      }
    }).bind(this));
    return this;
  },
  destroy: function() {
    MooSQL.remove(this.table, this.properties.getValues(), (function(tr, result) {
      if (result.rowsAffected > 0) {

      } else {

      }
    }).bind(this));
    return this;
  }
});