bucket-node
===========

Simple file storage for node.js

Usage
=====

Warning, Coffee-Script ahead..

    bucket = require 'bucket-node'

    data = bucket.initSingletonBucket 'mytestfile.db', (data) ->
      # Any data is available in data
      # Any data is available in bucket.bucket
      console.log "Data read from DB"

      # Create a new object
      newobj = {id:"i need an id", name:"my name is"}

      # Stash the new object
      data.set newobj

      # Commit any stashed objects to disk
      data.store () ->
        console.log "All pending changes are stored"

        another_ref = data.getById "i need an id"
        console.log "Should be true #{another_ref == newobj}"

        # where returns array (check out underscore.js _.where)
        third_ref = data.where {name:"my name is"}
        console.log "Should be true #{third_ref[0] == newobj}"

        # findWhere returns first hit (check out underscore.js _.where)
        fourth_ref = data.findWhere {name:"my name is"}
        console.log "Should be true #{fourth_ref == newobj}"

        data.deleteById fourth_ref.id
        data.store () ->
          console.log "Any changes is stored"


      data = new bucket.Bucket(filename)
      data.load () ->
        # Any data is now available in data
        # ... perform any changes
        # ... store these changes

        # Append this state to the bottom of another data set
        foreignBucket.merge data
