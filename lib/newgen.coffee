cp      = require 'child_process'
fs      = require 'fs'
carrier = require 'carrier'
clone   = require 'clone'
uuid    = require 'node-uuid'
_       = require 'underscore'
md5     = require 'md5'
path    = require 'path'

# Keep track of any spawned child
childProcessStash = {}

# On exit, kill all spawned children
process.on 'exit', () ->
  for pid, child of childProcessStash
    child.kill()

# Description of INITIAL_LOAD_TIMEOUT
#
# 10 ms might be very low i certain situations. Say file got opened
# from cache, but disk are not up to speed. There might be a timelaps
# between the opening and the getting data.
#
# If load() hits callback prematurely (eg. when not all data is read)
# then you should crank up this value
#
# If your application opens a lot of files, then there will be latency
# to gain if optimizing this down to as low as possible
INITIAL_LOAD_TIMEOUT = 10 # miliseconds

# Description
# Bucket
#   - bucketDelete
#   - bucketStore
#   - bucketClose
#   - bucketLoad
#   - bucketMerge
#   - bucketChanges
#   - bucketDiscardChanges
#   - deleteItems
#   - getItems
#   - whereItems
#   - setItems

exports.Bucket = (fileName) -> {
    fileName    : fileName
    bucket      : {}
    dirty       : {}
    deleted     : []
    tailProcess : null
    writehashes : []
    instanceid  : Math.floor((Math.random()*10000)+1);

    bucketDelete : (cb) ->
      closing = () =>
        fs.unlink @fileName, (err) ->
          unless err?
            delete @bucket
            delete @filename
            delete @dirty
            delete @deleted
            # We must check if this instance is the default instance
            exports.bucket = null
            cb()
          else
            console.error "Bucket ERROR: Failed to obliterate bucket"
            cb(err)

      delete childProcessStash[@tailProcess.pid]
      @tailProcess.on 'exit', closing

      @tailProcess.kill()

    bucketStore : (comment, cb) ->
      unless @hasChanges()
        return cb(null, "No changes to save")

      dirtyToWrite   = @dirty
      deletesToWrite = @deleted
      _.extend @bucket, @dirty
      @dirty = {}
      _.each @deleted, (id) =>
        delete @bucket[id]
      @deleted = []

      do (comment, @fileName, dirtyToWrite, deletesToWrite, cb) =>
        _.each deletesToWrite, (id) -> dirtyToWrite[id] = {deleted:true, id:id}

        dirtyToWrite = { log: comment, date: (new Date()).getTime(), payload: dirtyToWrite }
        dirtyData = JSON.stringify(dirtyToWrite)
        hash = md5.digest_s(dirtyData)
        @writehashes.push hash
        dirtyData = "#{dirtyData}\n"

        fs.appendFile @fileName, dirtyData, {encoding:'utf8'}, (err) =>
          unless err?
            cb(null, "Changes saved")
          else
            console.error "Bucket ERROR: Failed to store transaction!"
            # TODO: Must take care of this execution path
            cb(err, "Error during save") # Continue our with business!?!?! Not a good choice

    bucketClose : (cb) ->
      delete childProcessStash[@tailProcess.pid]

      @tailProcess.on 'exit', cb
      @tailProcess.kill()

    bucketLoad : (cb) ->
      # Create file if not existing
      fs.closeSync(fs.openSync(@fileName, 'a'))
      # After read delay, we suggest the file is initially fully read.
      # This call can only go throgh once.
      doneReading  = _.debounce _.once(cb), INITIAL_LOAD_TIMEOUT
      # Make sure that doneReading will be executed no matter if the file is empty
      doneReading()

      # Spawn child process
      @tailProcess = cp.spawn 'tail', ['-f', '-n', '+0', @fileName]

      # Stash our child process so that we can kill it if the main process is killed
      childProcessStash[@tailProcess.pid] = @tailProcess

      # Logging
      @tailProcess.stdout.setEncoding('utf8')
      @tailProcess.stderr.setEncoding('utf8')

      # The reader loop
      dataReader = carrier.carry @tailProcess.stdout, (line) =>

        # Make hash of new line
        hash = md5.digest_s(line)
        # Check if we wrote the line by looking up the hash
        if _.contains @writehashes, hash
          # Since we were the one creating the line, just remove the hash
          # from index and do nothing
          @writehashes = _.without @writehashes, hash
        else
          # Since we didn't generate the line, do process the data
          chunk   = JSON.parse line
          chunk   = chunk.payload
          deleted = _.where chunk, {deleted:true}
          deleted = _.pluck deleted, 'id'
          _.each deleted, (id) =>
            delete chunk[id]
            delete @bucket[id]
          _.extend @bucket, chunk

        # Inform our caller that we have read a line, if the caller is the initial
        # load, it will be informed that the full file is initially loaded.
        doneReading()

    bucketFork : (name) ->
      childName = path.dirname(@fileName) + "#{name}.#{path.basename(@fileName)}"

      new Bucket(childName)

    bucketMerge : (childbucket) ->
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

    bucketChanges : () ->
      _.keys(@dirty).length > 0 or @deleted.length > 0

    bucketDiscardChanges : () ->
      @dirty   = {}
      @deleted = []

    deleteItems : (ids) ->
      if not ids?
        return

      ids = [ids] if not _.isArray ids
      _.each ids, (id) -> @deleted.push id

    getItems : (ids, includeDirty = false) ->
      if not ids?
        return []

      ids = [ids] if not _.isArray ids
      items = @bucket

      if includeDirty
        included = _.extend {}, @bucket, @dirty
        items = included

      _.map list, (id) -> clone items[id]

    whereItems : (properties, includeDirty = false) ->
      if includeDirty
        _.map _.where(_.extend({}, @bucket, @dirty), properties), (itm) ->clone(itm)
      else
        _.map _.where(@bucket, properties), (itm) -> clone(itm)

    setItems : (objects) ->
      objects = [objects] if not _.isArray objects
      _.map objects, (object) ->
        unless object.id?
          _.extend object, {id: uuid.v4()}
        @dirty[object.id] = clone(object)
        object.id
  }

