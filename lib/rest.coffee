bucket = require './newgen'
_      = require 'underscore'
path   = require 'path'

allBuckets = {}

bucketByName = (name) ->
  allBuckets[name]

addBucket = (name, bucket) ->
  allBuckets[name] = bucket

unloadBucket = (name) ->
  delete allBuckets[name]

exports.path = null

# Persist any changes
# '/:name/db'
exports.postDb = (req, res) ->
  b = bucketByName req.params.name
  message = req.body.message
  b.bucketStore message, () ->
    result = { status: 'OK' }
    res.end(JSON.stringify(result))

# Delete database file
# '/:name/db'
exports.deleteDb = (req, res) ->
  b = bucketByName req.params.name
  b.bucketDelete () ->
    result = { status: 'OK' }
    res.end(JSON.stringify(result))

# Delete pending changes
# '/:name/changes'
exports.deleteChanges = (req, res) ->
  b = bucketByName req.params.name
  b.bucketDiscardChanges()
  result = { status: 'OK' }
  res.end(JSON.stringify(result))

# Check if we have pending changes (returns bool)
# '/:name/changes'
exports.getChanges = (req, res) ->
  b = bucketByName req.params.name
  changes = b.bucketChanges()
  result = { status: 'OK', result: changes }
  res.end(JSON.stringify(result))

# Load db into ram
#'/:name/db/load', rest.loadDb
exports.postDbLoad = (req, res) ->
  name = req.params.name
  if not bucketByName()?
    if exports.path?
      b = new bucket.Bucket(path.join(exports.path, name))
      b.bucketLoad () ->
        addBucket(name, b)
        result = { status: 'OK' }
        res.end(JSON.stringify(result))

    else
      result = { status: 'ERROR', msg: "Service not initialized with path" }
      res.end(JSON.stringify(result))

  else
    result = { status: 'ERROR', msg: "Database with name #{name} already open" }
    res.end(JSON.stringify(result))

# Close db
#'/:name/db/unload', rest.unloadDb
exports.postDbUnload = (req, res) ->
  name = req.params.name
  b = bucketByName name
  if b?
    b.close () ->
      removeBucket name
      result = { status: 'OK' }
      res.end(JSON.stringify(result))
  else
    result = { status: 'ERROR', msg: "Database with name #{name} does not exist"}
    res.end(JSON.stringify(result))

# Fork db to child
#'/:name/db/fork'
exports.postDbFork = (req, res) ->

# Merge db into parent
#'/:name/db/merge'
exports.postDbMerge = (req, res) ->


# Find all matching
# '/:name/where'
exports.getWhere = (req, res) ->
  b = bucketByName req.params.name
  items = b.whereItems req.query
  result = { status: 'OK', result: items }
  res.end(JSON.stringify(result))

# Store or update item(s)
# '/:name/items'
exports.postItems = (req, res) ->
  b = bucketByName req.params.name
  items = req.body
  ids = b.setItems items
  result = { status: 'OK', result: ids }
  res.end(JSON.stringify(result))

# Delete item(s)
# '/:name/items/:ids'
exports.deleteItems = (req, res) ->
  b = bucketByName req.params.name
  ids = req.params.ids.split(',')
  b.deleteItems ids
  result = { status: 'OK' }
  res.end(JSON.stringify(result))

# Get item(s)
# '/:name/items/:ids'
exports.getItems = (req, res) ->
  b = bucketByName req.params.name
  ids = req.params.ids.split(',')
  items = b.getItems ids
  result = { status: 'OK', result: items }
  res.end(JSON.stringify(result))

