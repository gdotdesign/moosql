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

User.create {
  name: 'gdotdesign'
}
