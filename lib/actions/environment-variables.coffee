_ = require('lodash')
table = require('../table/table')
errors = require('../errors/errors')
patterns = require('../patterns/patterns')
log = require('../log/log')
resin = require('../resin')
authHooks = require('../hooks/auth')

SYSTEM_VAR_REGEX = /^RESIN_/

isSystemVariable = (environmentVariable) ->
	SYSTEM_VAR_REGEX.test(environmentVariable.name)

exports.list = authHooks.failIfNotLoggedIn (program) ->
	applicationId = program.parent?.application

	if not applicationId?
		errors.handle(new Error('You have to specify an application'))

	resin.models.environmentVariables.getAll(applicationId).then (environmentVariables) ->

		if not program.parent.verbose?
			environmentVariables = _.reject(environmentVariables, isSystemVariable)

		log.out(table.horizontal(environmentVariables))
	.catch(errors.handle)

exports.remove = authHooks.failIfNotLoggedIn (id, program) ->
	patterns.remove 'environment variable', program.parent.yes, (callback) ->
		resin.models.environmentVariables.remove(id).then ->
			return callback()
		.catch(callback)
	, errors.handle