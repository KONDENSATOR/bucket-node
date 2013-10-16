bucket = require './bucket'
_ = require 'underscore'

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
  items = b.where req.query
  result = { status: 'OK', result: items }
  res.end(JSON.stringify(result))

# Store or update item(s)
# '/:name/items'
exports.postItems = (req, res) ->
  b = bucketByName req.params.name
  items = req.body
  _.each items, bucket.set
  result = { status: 'OK' }
  res.end(JSON.stringify(result))

# Delete item(s)
# '/:name/items/:ids'
exports.deleteItems = (req, res) ->
  b = bucketByName req.params.name
  ids = req.params.ids.split(',')
  _.each ids, bucket.deleteById
  result = { status: 'OK' }
  res.end(JSON.stringify(result))

# Get item(s)
# '/:name/items/:ids'
exports.getItems = (req, res) ->
  b = bucketByName req.params.name
  ids = req.params.ids.split(',')
  items = bucket.getByIds ids
  result = { status: 'OK', result: items }
  res.end(JSON.stringify(result))

