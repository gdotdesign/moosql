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
MooSQL.Properties = new Class({
  setValues: function(values) {
    this.values = $merge(this.getClean(), values);
    return (this.dirty = true);
  },
  getValues: function() {
    return this.values;
  },
  getClean: function() {
    return (new Hash(this.properties).map(function(value, key) {
      var _a;
      return (typeof (_a = value["default"]) !== "undefined" && _a !== null) ? value["default"] : null;
    })).getClean();
  },
  merge: function(props) {
    var _a;
    return (typeof (_a = this.values) !== "undefined" && _a !== null) ? $merge(this.values, props) : $merge(this.getClean(), props);
  },
  set: function(key, value) {
    var _a;
    if (typeof (_a = this.properties[key]) !== "undefined" && _a !== null) {
      this.values[key] = value;
      return (this.dirty = true);
    }
  },
  get: function(key) {
    var _a;
    return (typeof (_a = this.properties[key]) !== "undefined" && _a !== null) ? this.values[key] : null;
  }
});
MooSQL.Resource = new Class({
  Implements: [Events, MooSQL.Properties],
  table: null,
  properties: {},
  initialize: function() {
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
  first: function(properties) {
    var record;
    record = this["new"](this.properties, this.table);
    MooSQL.find(this.table, $merge(properties), function(tr, result) {
      return result.rowsAffected > 0 ? record.setValues(result.rows.item(0)) : null;
    });
    return record;
  },
  find: function(properties) {
    var ret;
    ret = new MooSQL.Resource.RecordCollection(this.properites, this.table);
    MooSQL.find(this.table, $merge(properties), (function(tr, result) {
      var _a, i;
      if (result.rowsAffected > 0) {
        ret.setValues(properties);
        if (result.rows.length > 0) {
          i = 0;
          _a = [];
          while (i < result.rows.length) {
            _a.push((function() {
              ret.addRecord(result.rows.item(i));
              return i++;
            })());
          }
          return _a;
        }
      }
    }).bind(this));
    return ret;
  },
  parseProperties: function() {
    return this.properties.each(function(item, i) {});
  }
});
MooSQL.Resource.Record = new Class({
  Implements: [Events, MooSQL.Properties],
  initialize: function(properties, table) {
    this.dirty = false;
    this.saved = false;
    this.properties = properties;
    this.table = table;
    return this;
  },
  save: function(properties) {
    var props;
    if (typeof properties !== "undefined" && properties !== null) {
      props = this.merge(properties);
    }
    MooSQL.insert(this.table, props, (function(tr, result) {
      return result.rowsAffected === 0 ? this.fireEvent('saveFailed', result.message) : this.getROWID(result.insertId);
    }).bind(this));
    return this;
  },
  getROWID: function(id) {
    return MooSQL.find(this.table, {
      ROWID: id
    }, (function(tr, result) {
      if (result.rows.length > 0) {
        this.setValues(result.rows.item(0));
        this.dirty = false;
        return this.fireEvent('ready');
      } else {
        return this.fireEvent('fetchFailed', result.message);
      }
    }).bind(this));
  },
  update: function(properties) {
    MooSQL.update(this.table, properties, this.getValues(), (function(tr, result) {
      var _a;
      if (typeof (_a = result.rowsAffected) !== "undefined" && _a !== null) {
        this.setValues(properties);
        this.dirty = false;
        return this.fireEvent('updated');
      } else {
        return this.fireEvent('updateFailed', result.message);
      }
    }).bind(this));
    return this;
  },
  destroy: function() {
    MooSQL.remove(this.table, this.getValues(), (function(tr, result) {
      return !(result.rowsAffected > 0) ? this.fireEvent('destroyFailed', result.message) : null;
    }).bind(this));
    return this;
  }
});
MooSQL.Resource.RecordCollection = new Class({
  Implements: [Events, MooSQL.Properties],
  initialize: function(properties, table) {
    this.dirty = false;
    this.saved = false;
    this.properties = properties;
    this.table = table;
    this.records = [];
    return this;
  },
  addRecord: function(props) {
    var record;
    record = new MooSQL.Resource.Record(this.properties, this.table);
    record.setValues(props);
    return this.records.push(record);
  },
  save: function(properties) {
    return this.reecords.each(function(record) {
      return record.update(properties);
    });
  },
  update: function(properties) {
    return this.records.each(function(record) {
      return record.update(properties);
    });
  },
  destroy: function() {
    return this.records.each(function(record) {
      return record.destroy();
    });
  }
});