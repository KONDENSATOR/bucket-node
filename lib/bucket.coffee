cp      = require 'child_process'
fs      = require 'fs'
carrier = require 'carrier'
clone   = require 'clone'
uuid    = require 'node-uuid'
_       = require 'underscore'
md5     = require 'md5'


exports.Bucket = (fileName) -> {
    fileName    : fileName
    bucket      : {}
    dirty       : {}
    deleted     : []
    tailProcess : null
    writehashes : []

    obliterate : (cb) ->
      closing = () =>
        fs.unlink @fileName, (err) ->
          unless err?
            delete @bucket
            delete @filename
            delete @dirty
            delete @deleted
            exports.bucket = null
            cb()
          else
            console.error "Bucket ERROR: Failed to obliterate bucket"
            cb(err)

      @tailProcess.on 'exit', closing

      @tailProcess.kill()

    store : (cb) ->
      console.log "store called"
      unless @hasChanges()
        return cb(null, "No changes to save")

      dirtyToWrite   = @dirty
      deletesToWrite = @deleted
      _.extend @bucket, @dirty
      @dirty = {}
      _.each @deleted, (id) =>
        delete @bucket[id]
      @deleted = []

      do (@fileName, dirtyToWrite, deletesToWrite, cb) =>
        _.each deletesToWrite, (id) -> dirtyToWrite[id] = {deleted:true, id:id}

        dirtyData = JSON.stringify(dirtyToWrite)
        hash = md5.digest_s(dirtyData)
        @writehashes.push hash
        dirtyData = "#{dirtyData}\n"

        fs.appendFile @fileName, dirtyData, {encoding:'utf8'}, (err) =>
          unless err?
            console.log "Store about to call success callback"
            cb(null, "Changes saved")
          else
            console.error "Bucket ERROR: Failed to store transaction!"
            # TODO: Must take care of this execution path
            cb(err, "Error during save") # Continue our with business!?!?! Not a good choice

    close : (cb) ->
      @tailProcess.kill()

    reader : (cb) ->
      doneReading  = _.debounce _.once(cb), 200
      _.delay doneReading, 200
      @tailProcess = cp.spawn 'tail', ['-f', '-n +0', @fileName]
      inStream = @tailProcess.stdout
      dataReader = carrier.carry inStream, (line) =>
        console.log "Reader LINE callback..."
        hash = md5.digest_s(line)
        if _.contains @writehashes, hash
          console.log "Got match"
          @writehashes = _.without @writehashes, hash
        else
          chunk   = JSON.parse line
          deleted = _.where chunk, {deleted:true}
          deleted = _.pluck deleted, 'id'
          _.each deleted, (id) =>
            delete chunk[id]
            delete @bucket[id]
          _.extend @bucket, chunk
        console.log "Reader LINE callback end!"
        doneReading()

      dataReader.once 'end', () ->
        console.log "Reader END callback..."
        doneReading()

    load : (cb) ->
      fs.closeSync(fs.openSync(@fileName, 'a'))
      @reader(cb)


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
      @dirty   = {}
      @deleted = []
  }

exports.bucket = null
exports.initSingletonBucket = (filename, cb) ->
  do (exports, filename, cb) ->
    unless exports.bucket?
      exports.bucket = new exports.Bucket(filename)
      exports.bucket.load () ->
        cb(exports.bucket)
    else
      cb(exports.bucket)

