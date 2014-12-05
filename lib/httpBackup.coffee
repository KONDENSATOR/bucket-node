bucket = require './bucket'
restler = require 'restler'
_ = require 'underscore'

exports.backup = (backupConfig, bucketData) ->
  CronJob = require('cron').CronJob
  job = new CronJob(backupConfig.cronTime
    , () ->
      restler.postJson(backupConfig.url, {data: bucketData, service: backupConfig.serviceName}, _.pick(backupConfig, "username", "password"))
      .on('complete', (data) -> console.dir data)
    , null
    , true
  )
  job.start()
