_ = require('lodash')
async = require('async')
gitCli = require('git-cli')
resin = require('../resin')
cli = require('../cli/cli')
ui = require('../ui')

exports.create = (name) ->
	async.waterfall [

		(callback) ->
			deviceType = cli.getArgument('type')

			if deviceType?
				return callback(null, deviceType)
			else
				deviceTypes = resin.device.getSupportedDevices()
				ui.widgets.select('Select a type', deviceTypes, callback)

		(type, callback) ->

			# TODO: Currently returns 'unknown'.
			# Maybe we should break or handle better?
			slugifiedType = resin.device.getDeviceSlug(type)

			resin.models.application.create(name, slugifiedType, callback)

	], resin.errors.handle

exports.list = ->
	resin.models.application.getAll (error, applications) ->
		resin.errors.handle(error) if error?

		resin.log.out ui.widgets.table.horizontal applications, (application) ->
			application.device_type = resin.device.getDisplayName(application.device_type)
			application['Online Devices'] = _.where(application.device, is_online: 1).length
			application['All Devices'] = application.device?.length or 0
			delete application.git_repository
			delete application.device
			return application
		, [ 'ID', 'Name', 'Device Type', 'Online Devices', 'All Devices' ]

exports.info = (id) ->
	resin.models.application.get id, (error, application) ->
		resin.errors.handle(error) if error?

		resin.log.out ui.widgets.table.vertical application, (application) ->
			application.device_type = resin.device.getDisplayName(application.device_type)
			delete application.device
			return application
		, [ 'ID', 'Name', 'Device Type', 'Git Repository', 'Commit' ]

exports.restart = (id) ->

	resin.models.application.restart id, (error) ->
		resin.errors.handle(error) if error?

exports.remove = (id) ->
	confirmArgument = cli.getArgument('yes')
	ui.patterns.remove 'application', confirmArgument, (callback) ->
		resin.models.application.remove(id, callback)
	, resin.errors.handle

exports.init = (id) ->

	currentDirectory = process.cwd()

	async.waterfall [

		(callback) ->
			resin.vcs.isResinProject(currentDirectory, callback)

		(isResinProject, callback) ->
			if isResinProject
				error = new Error('Project is already a resin application.')
				return callback(error)
			return callback()

		(callback) ->
			resin.models.application.get(id, callback)

		(application, callback) ->
			resin.vcs.initProjectWithApplication(application, currentDirectory, callback)

	], (error) ->
		resin.errors.handle(error) if error?
