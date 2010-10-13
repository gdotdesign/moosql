###
SERIAL = Integer with auto increment

###
MooSQL = new Class.Singleton {
  Implements : [Options, Events]
  options: {
    dbName: ''
    dbVersion:''
    dbDesc:''
    dbSize:20*100
  } 
}
MooSQL.connect('INK');

User = new Class{
  Extends: MooSQL.Resource
  table: 'user'
  properties: {
    id: {type: 'SERIAL', key: true }
    name: {type: 'TEXT', default: 'me'}
  }
}

#User.autoUpdate()

User.create {
  name: 'gdotdesign'
}
