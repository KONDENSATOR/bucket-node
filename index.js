// Generated by CoffeeScript 1.6.3
(function() {
  var carrier, clone, fs, _;

  _ = require('underscore');

  fs = require('fs');

  carrier = require('carrier');

  clone = require('clone');

  exports.Bucket = function(fileName) {
    return {
      fileName: fileName,
      bucket: {},
      dirty: {},
      deleted: [],
      obliterate: function(cb) {
        return (function(filename, cb) {
          this.filename = filename;
          return fs.unlink(this.filename, function(err) {
            if (err == null) {
              delete this.bucket;
              delete this.filename;
              delete this.dirty;
              delete this.deleted;
              return cb();
            } else {
              return console.error("Bucket ERROR: Failed to obliterate bucket");
            }
          });
        })(this.filename, cb);
      },
      store: function(cb) {
        return (function(fileName, bucket, dirty, cb) {
          this.fileName = fileName;
          this.bucket = bucket;
          this.dirty = dirty;
          _.each(this.deleted, function(id) {
            return this.dirty[id] = {
              deleted: true,
              id: id
            };
          });
          return fs.appendFile(this.fileName, JSON.stringify(this.dirty) + "\n", 'utf8', function(err) {
            if (err == null) {
              this.bucket = _.extend(this.bucket, this.dirty);
              this.dirty = {};
              _.each(this.deleted, function(id) {
                return delete this.bucket[id];
              });
              this.deleted = [];
              return cb();
            } else {
              console.error("Bucket ERROR: Failed to store transaction!");
              return cb(err);
            }
          });
        })(this.fileName, this.bucket, this.dirty, cb);
      },
      load: function(cb) {
        return (function(fileName, bucket, cb) {
          this.fileName = fileName;
          this.bucket = bucket;
          return fs.exists(this.fileName, function(exists) {
            var contextBucket, dataReader, inStream;
            if (exists) {
              contextBucket = this.bucket;
              console.time("Bucket TIME: Read file");
              inStream = fs.createReadStream(this.fileName, {
                flags: 'r',
                encoding: 'utf8'
              });
              dataReader = carrier.carry(inStream, function(line) {
                var chunk, deleted;
                chunk = JSON.parse(line);
                deleted = _.where(chunk, {
                  deleted: true
                });
                deleted = _.pluck(deleted, 'id');
                _.each(deleted, function(id) {
                  delete chunk[id];
                  return delete this.bucket[id];
                });
                return _.extend(contextBucket, chunk);
              });
              return dataReader.once('end', function() {
                console.timeEnd("Bucket TIME: Read file");
                return cb();
              });
            } else {
              console.warn("Bucket WARN: File empty");
              return cb();
            }
          });
        })(this.fileName, this.bucket, cb);
      },
      deleteById: function(id) {
        return deleted.push(id);
      },
      getById: function(id) {
        return clone(this.bucket[id]);
      },
      getByIds: function(list) {
        return _.map(list, function(id) {
          return clone(this.bucket[id]);
        });
      },
      findWhere: function(properties) {
        var itm;
        itm = _.findWhere(this.bucket, properties);
        if (itm != null) {
          itm = clone(itm);
        }
        return itm;
      },
      where: function(properties) {
        return _.map(_.where(this.bucket, properties), function(itm) {
          return clone(itm);
        });
      },
      set: function(object) {
        return this.dirty[object.id] = clone(object);
      },
      merge: function(childbucket) {
        return (function(childbucket) {
          var timeStamp;
          timeStamp = "Bucket INFO: Merge " + childbucket.fileName;
          console.time(timeStamp);
          _.each(childbucket, function(value) {
            return this.set(value);
          });
          return this.store(function(err) {
            if (err == null) {
              return childbucket.obliterate(function(err) {
                if (err == null) {
                  console.info("Bucket INFO: Merge complete");
                  return console.timeEnd(timeStamp);
                } else {
                  console.error("Bucket ERROR: Failed to merge");
                  return console.timeEnd(timeStamp);
                }
              });
            } else {
              console.error("Bucket ERROR: Failed to merge");
              return console.timeEnd(timeStamp);
            }
          });
        })(childbucket);
      }
    };
  };

  exports.bucket = null;

  exports.initSingletonBucket = function(filename, cb) {
    return (function(exports, filename, cb) {
      if (exports.bucket == null) {
        exports.bucket = new exports.Bucket(filename);
        return exports.bucket.load(function() {
          return cb(exports.bucket);
        });
      }
    })(exports, filename, cb);
  };

}).call(this);
