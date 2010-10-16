MooSQL.connect 'moosql'

User = new Class{
  Extends: MooSQL.Resource
  table: 'user'
  properties: {
    id: {type: 'SERIAL', key: true }
    name: {type: 'TEXT', default: 'me'}
  }
}

#User.autoUpdate()

u = User.create {
  name: 'gdotdesign'
}
u = User.first {
  name: 'gdotdesign'
}
u.addEvent 'ready', ->
  console.log 'Record ready'
