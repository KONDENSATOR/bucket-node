bucket = require './bucket'

bucketByName = (name) ->
  bucket.bucket

# Persist any changes
# '/:name/db'
exports.postDb = (req, res) ->
  b = bucketByName req.params.name
  b.store () ->
    result = { status: 'OK' }
    res.end(JSON.stringify(result))

# Delete database file
# '/:name/db'
exports.deleteDb = (req, res) ->
  b = bucketByName req.params.name
  b.obliterate () ->
    result = { status: 'OK' }
    res.end(JSON.stringify(result))

# Delete pending changes
# '/:name/changes'
exports.deleteChanges = (req, res) ->
  b = bucketByName req.params.name
  b.discardUnstoredChanges()
  result = { status: 'OK' }
  res.end(JSON.stringify(result))

# Check if we have pending changes (returns bool)
# '/:name/changes'
exports.getChanges = (req, res) ->
  b = bucketByName req.params.name
  changes = b.hasChanges()
  result = { status: 'OK', result: changes }
  res.end(JSON.stringify(result))

# Find all matching
# '/:name/where'
exports.getWhere = (req, res) ->
  b = bucketByName req.params.name
  res.end('NOT IMPLEMENTED YET')

# Store or update item(s)
# '/:name/items'
exports.postItems = (req, res) ->
  b = bucketByName req.params.name
  res.end('NOT IMPLEMENTED YET')

# Delete item(s)
# '/:name/items/:ids'
exports.deleteItems = (req, res) ->
  b = bucketByName req.params.name
  res.end('NOT IMPLEMENTED YET')

# Get item(s)
# '/:name/items/:ids'
exports.getItems = (req, res) ->
  b = bucketByName req.params.name
  res.end('NOT IMPLEMENTED YET')

