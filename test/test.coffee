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
    @myBucket.obliterate () =>
      callback()

  testGetById : (test) ->
    test.expect(3)
    data = {id: "test-id", niff: "niff", nuff: "nuff"}
    @myBucket.set(data)
    get = @myBucket.getById("test-id")
    test.ok(!get?, "object shouldn't be available here...")
    get = @myBucket.getById("test-id", true)
    test.ok(get?, "object should be availabel using the include dirty flag")
    @myBucket.store () =>
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
    @myBucket.store () =>
      where = (@myBucket.where {niff: "niff"})[0]
      test.ok(where.id?, "ID should be auto-assigned")
      test.done()

  testHasChanges : (test) ->
    test.expect 5
    test.ok(!@myBucket.hasChanges(), "Shouldn't have changes before any operations...")
    @myBucket.set {fjorp: "fjorp"}
    test.ok(@myBucket.hasChanges(), "Un-stored set, should have changes")
    @myBucket.discardUnstoredChanges()
    test.ok(!@myBucket.hasChanges(), "Shouldn't have changes after discard")
    @myBucket.deleteById("456")
    test.ok(@myBucket.hasChanges(), "Un-stored delete, should have changes")
    @myBucket.store () =>
      test.ok(!@myBucket.hasChanges(), "Shouldn't have changes after store")
      test.done()

  testHasChangesImpatient : (test) ->
    test.expect 5
    test.ok(!@myBucket.hasChanges(), "Shouldn't have changes before any operations...")
    @myBucket.set {fjorp: "fjorp"}
    test.ok(@myBucket.hasChanges(), "Un-stored set, should have changes")
    @myBucket.discardUnstoredChanges()
    test.ok(!@myBucket.hasChanges(), "Shouldn't have changes after discard")
    @myBucket.deleteById("456")
    test.ok(@myBucket.hasChanges(), "Un-stored delete, should have changes")
    @myBucket.store () ->
    test.ok(!@myBucket.hasChanges(), "Shouldn't have changes after store")
    test.done()

  testStore : (test) ->
    test.expect 2
    test.equal(@myBucket.where({fluff : "fluff"}).length, 2, "Should contain two fluffs after setup")
    @myBucket.set({fluff : "fluff", miff : "miff"})
    @myBucket.store =>
      anotherBucket = new bucket.Bucket("./test.db")
      anotherBucket.load ->
        test.equal(anotherBucket.where({fluff : "fluff"}).length, 3, "Should contain three fluffs after store and reload")
        test.done()

  testStoreImpatient : (test) ->
    test.expect 3
    test.equal(@myBucket.where({fluff : "fluff"}).length, 2, "Should contain two fluffs after setup")
    @myBucket.set({fluff : "fluff", miff : "miff"})
    @myBucket.store =>
      anotherBucket = new bucket.Bucket("./test.db")
      anotherBucket.load ->
        test.equal(anotherBucket.where({fluff : "fluff"}).length, 3, "Should contain three fluffs after store and reload")
        test.done()
    test.equal(@myBucket.where({fluff : "fluff"}).length, 3, "Should contain three fluffs after store")


  testReplace : (test) ->
    test.expect 6
    @myBucket.set({id : "456", fluff: "floff", fiff: "fiff"})
    object = @myBucket.getById("456", true)
    test.equal(object.fiff, "fiff", "Should be the updated object")
    test.equal(object.fluff, "floff", "Should be the updated fluff")
    @myBucket.store =>
      object = @myBucket.getById "456"
      test.equal(object.fiff, "fiff", "Should be the updated object after store")
      test.equal(object.fluff, "floff", "Should be the updated fluff after store")
      anotherBucket = new bucket.Bucket("./test.db")
      anotherBucket.load =>
        object = anotherBucket.getById "456"
        test.equal(object.fiff, "fiff", "Should be the updated object after store and load")
        test.equal(object.fluff, "floff", "Should be the updated fluff after store and load")
        test.done()

  testReplaceImpatient : (test) ->
    test.expect 4
    @myBucket.set({id : "456", fluff: "floff", fiff: "fiff"})
    object = @myBucket.getById("456", true)
    test.equal(object.fiff, "fiff", "Should be the updated object")
    test.equal(object.fluff, "floff", "Should be the updated fluff")
    @myBucket.store ->
    object = @myBucket.getById "456"
    test.equal(object.fiff, "fiff", "Should be the updated object after store")
    test.equal(object.fluff, "floff", "Should be the updated fluff after store")
    test.done()

  testStoreEmpty : (test) ->
    test.expect 1
    @myBucket.store (err, message) =>
      test.equal(message, "No changes to save", "Should be status: no changes to save")
      test.done()

  testDelete : (test) ->
    test.expect 2
    @myBucket.deleteById "456"
    @myBucket.store () =>
      object = @myBucket.getById("456");
      test.ok(!object?, "Object with id 456 should be deleted here...")
      anotherBucket = new bucket.Bucket("./test.db")
      anotherBucket.load =>
        object = anotherBucket.getById "456"
        test.ok(!object?, "Object with id 456 should be deleted in thei bucket as well...")
        test.done()

  testDeleteImpatient : (test) ->
    test.expect 1
    @myBucket.deleteById "456"
    @myBucket.store () ->
    object = @myBucket.getById("456");
    test.ok(!object?, "Object with id 456 should be deleted here...")
    test.done()

  testBunchOfImpatientStores : (test) ->
    test.expect 8
    @myBucket.set({fluff: "fluff", piff: "piff"})
    @myBucket.store ->
    test.equal(@myBucket.where({fluff: "fluff"}).length, 3, "Should be three fluff objects");
    @myBucket.deleteById "456"
    @myBucket.store ->
    test.equal(@myBucket.where({fluff: "fluff"}).length, 2, "Should be two fluff objects");
    @myBucket.set({id: "456", fluff: "fluff"})
    @myBucket.store ->
    @myBucket.set({id: "456", fluff: "fluff", diff: "diff"})
    @myBucket.set({id: "789", fluff: "fluff", diff: "hoff"})
    @myBucket.store ->
    @myBucket.set({id: "456", fluff: "fluff", diff: "diff2"})
    @myBucket.store ->
    test.equal @myBucket.getById("456").diff, "diff2", "the new 456 should have the diff property with value diff2"
    @myBucket.set({id: "456", fluff: "fluff"})
    @myBucket.store ->
    test.equal(@myBucket.where({fluff: "fluff"}).length, 4, "Should be three fluff objects");
    test.ok !@myBucket.getById("456").diff?, "teh new 456 shouldn't have the diff property"
    anotherBucket = new bucket.Bucket("./test.db")
    anotherBucket.load =>
      test.equal(anotherBucket.where({fluff: "fluff"}).length, 4, "Should be three fluff objects in the saved file");
      test.equal @myBucket.getById("789").diff, "hoff", "the 789 should have the diff property with value hoff"
      test.ok !anotherBucket.getById("456").diff?, "the new 456 shouldn't have the diff property in the saved file"
      test.done()
}
