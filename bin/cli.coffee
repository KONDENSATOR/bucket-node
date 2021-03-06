program = require 'commander'
express = require 'express'
http    = require 'http'
fs      = require 'fs'

rest    = require '../lib/rest'


tcpServer = null
unixServer = null

tcpAddr = (value) ->
  return value.split ':'

program.version('0.0.1')
  .usage('[options] <path ...>')
  .option('-t, --tcp <addr>:<port>', 'IP and port to bind to socket', tcpAddr)
  .option('-u, --unix <path>', 'File path to bind to socket')
  .parse(process.argv);

process.on 'exit', () ->
 console.log("Exiting, have a nice day")

main = () ->
  if program.args.length == 0
    console.error "No database path defined"
    process.exit()

  rest.path = program.args[0]

  console.info "Using path #{rest.path}"

  app = express()
  app.use express.bodyParser()

  # :name refere to database name (usually default)

  # Persist any changes
  app.post   '/:name/db', rest.postDb
  # Delete database file
  app.delete '/:name/db', rest.deleteDb
  # Load db into ram
  app.post   '/:name/db/load', rest.postDbLoad
  # Close db
  app.post   '/:name/db/unload', rest.postDbUnload
  # Fork db to child
  app.post   '/:name/db/fork', (req, res) -> res.send('NOT IMPLEMENTED YET')
  # Merge db into parent
  app.post   '/:name/db/merge', (req, res) -> res.send('NOT IMPLEMENTED YET')

  # Delete pending changes
  app.delete '/:name/changes', rest.deleteChanges
  # Check if we have pending changes (returns bool)
  app.get    '/:name/changes', rest.getChanges

  # Find all matching
  app.get    '/:name/where', rest.getWhere

  # Store or update item(s)
  app.post   '/:name/items', rest.postItems
  # Delete item(s)
  app.delete '/:name/items/:ids', rest.deleteItems
  # Get item(s)
  app.get    '/:name/items/:ids', rest.getItems


  if program.tcp?
    tcpServer = http.createServer(app)
    tcpServer.listen(program.tcp[1])
    tcpServer.once "listening", () -> console.info "TCP socket open on port #{program.tcp[1]}"
    tcpServer.once "close", () -> console.info "TCP socket closed"

  if program.unix?
    fs.exists program.unix, (existing) ->
      if existing
        console.warn 'Removing lingering socket file'
        fs.unlinkSync(program.unix)
      unixServer = http.createServer(app)
      unixServer.listen(program.unix)
      unixServer.once "listening", () -> console.info "Unix socket open on #{program.unix}"
      unixServer.once "close", () -> console.log "Unix socket closed"

main()
