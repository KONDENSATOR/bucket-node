bucket = require "../index.js"

exports.testGroup1 = {

  setUp : (callback) ->
    bucket.initSingletonBucket "./test.db", (instance) =>
      @myBucket = instance
      instance.set {id: "123", fluff: "fluff", diff: "diff1"}
      instance.set {id: "456", fluff: "fluff", diff: "diff2"}
      instance.store () ->
        callback()

  tearDown : (callback) ->
    @myBucket.obliterate () ->
      callback()

  testGetById : (test) ->
    test.expect(3)
    data = {id: "test-id", niff: "niff", nuff: "nuff"}
    @myBucket.set(data)
    get = @myBucket.getById("test-id")
    test.ok(!get?, "object shouldn't be available here...")
    get = @myBucket.getById("test-id", true)
    test.ok(get?, "object should be availabel using the include dirty flag")
    do(@myBucket) ->
      @myBucket.store () ->
        get = @myBucket.getById("test-id")
        test.ok(get?, "object should be available after store")
        test.done()

  testFindWhere : (test) ->
    test.expect(3)
    found = @myBucket.findWhere({diff: "diff1"})
    test.ok(found?, "There should be a matching object...")
    test.equal(found.id, "123", "Should be the object with id 123")
    found = @myBucket.findWhere({diff: "diff3"})
    test.ok(!found?, "Shouldn't be such an object")
    test.done()

  testWhere : (test) ->
    test.expect 4
    found = @myBucket.where({fluff: "fluff"})
    test.equals(found.length, 2, "Should be two objects")
    @myBucket.set({fluff: "fluff", diff: "diff3"})
    found = @myBucket.where({fluff: "fluff"})
    test.equals(found.length, 2, "Should be two objects, since the set one is dirty...")
    found = @myBucket.where({fluff: "fluff"}, true)
    test.equals(found.length, 3, "Should be three objects when dirty is included.")
    found = @myBucket.where({diff : "diffOther"})
    test.equal(found.length, 0, "No object found should return empty array.")
    test.done()


  testAutoId : (test) ->
    test.expect(1)
    data = {niff: "niff", nuff: "nuff"}
    @myBucket.set(data)
    @myBucket.store () ->
      where = (@myBucket.where {niff: "niff"})[0]
      test.ok(where.id?, "ID should be auto-assigned")
      test.done()
}
