_     = require 'underscore'
fs    = require 'fs'
carrier = require 'carrier'
clone = require 'clone'
uuid = require 'node-uuid'

exports.Bucket = (fileName) -> {
    fileName : fileName
    bucket : {}
    dirty : {}
    deleted : []

    obliterate : (cb) ->
        fs.unlink fileName, (err) ->
          unless err?
            delete @bucket
            delete @filename
            delete @dirty
            delete @deleted
            exports.bucket = null
            cb()
          else
            console.error "Bucket ERROR: Failed to obliterate bucket"


    store : (cb) ->
      dirty = @dirty
      @dirty = {}
      do (@fileName, @bucket, dirty, @deleted, cb) ->

        _.each @deleted, (id) -> dirty[id] = {deleted:true, id:id}

        fs.appendFile @fileName, JSON.stringify(dirty) + "\n", 'utf8', (err) ->
          unless err?
            @bucket = _.extend @bucket, dirty
            _.each @deleted, (id) -> delete @bucket[id]
            @deleted = []
            cb()
          else
            console.error "Bucket ERROR: Failed to store transaction!"
            # TODO: Must take care of this execution path
            cb(err) # Continue our with business!?!?! Not a good choice

    load : (cb) ->
      do (@fileName, @bucket, cb) ->
        fs.exists @fileName, (exists) ->
          if exists
            contextBucket = @bucket
            console.time "Bucket TIME: Read file"
            inStream = fs.createReadStream(@fileName, {flags:'r', encoding:'utf8'})
            dataReader = carrier.carry inStream, (line) ->
              chunk = JSON.parse line
              deleted = _.where chunk, {deleted:true}
              deleted = _.pluck deleted, 'id'
              _.each deleted, (id) ->
                delete chunk[id]
                delete @bucket[id]

              _.extend contextBucket, chunk

            dataReader.once 'end', () ->
              console.timeEnd "Bucket TIME: Read file"
              cb()
          else
            console.warn "Bucket WARN: File empty"
            cb()

    deleteById : (id) ->
      @deleted.push id

    getById : (id, includeDirty = false) ->
      if includeDirty
        included = _.extend {}, @bucket, @dirty
        clone included[id]
      else
        clone @bucket[id]

    getByIds : (list) ->
      _.map list, (id) -> clone @bucket[id]

    findWhere : (properties) ->
      itm = _.findWhere(@bucket, properties)
      itm = clone itm if itm?
      itm

    where : (properties, includeDirty = false) ->
      if includeDirty
        _.map _.where(_.extend({}, @bucket, @dirty), properties), (itm) ->clone(itm)
      else
        _.map _.where(@bucket, properties), (itm) -> clone(itm)

    set : (object) ->
      unless object.id?
        id = uuid.v4()
        _.extend object, {id: id}
      @dirty[object.id] = clone(object)

    merge : (childbucket) ->
      do (childbucket) ->
        timeStamp = "Bucket INFO: Merge #{childbucket.fileName}"
        console.time timeStamp
        _.each childbucket, (value) -> @set(value)
        @store (err) ->
          unless err?
            childbucket.obliterate (err) ->
              unless err?
                console.info "Bucket INFO: Merge complete"
                console.timeEnd timeStamp
              else
                console.error "Bucket ERROR: Failed to merge"
                console.timeEnd timeStamp
          else
            console.error "Bucket ERROR: Failed to merge"
            console.timeEnd timeStamp

    hasChanges : () ->
      _.keys(@dirty).length > 0 or @deleted.length > 0

    discardUnstoredChanges : () ->
      @dirty = {}
      @deleted = []
  }

exports.bucket = null
exports.initSingletonBucket = (filename, cb) ->
  do (exports, filename, cb) ->
    unless exports.bucket?
      exports.bucket = new exports.Bucket(filename)
      exports.bucket.load () ->
        cb(exports.bucket)

