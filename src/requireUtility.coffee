# Responsible for importing all of the requires that a 
# node.js express type project involves. Though
# it should (hopefully) be able to do many types of projects.

# First step will be to find all the requires contained within a file.
# Second step is to consider each .coffee file as a require.
# Third is we'll bring those together

fs = require 'fs'
_ = require 'lodash'
requiredFileReader = require './requiredFileReader'
functionReader = require './requiredFileFunctionReader'

module.exports = 
  importRequires: (localContext, workingDir) ->
    # We only want to go through the server
    workingDir = @ensureWorkingDirIsServer workingDir

    fileNames = []
    manualHash = {}
    @betterWalkTree workingDir, fileNames
    
    # Loop through all the potential files to include and let's develop a
    # list of global requires
    internalRequires = []
    _.each fileNames, (fileName) ->
      # Read the file and find the aittional internal requires
      additionalInternalRequires = requiredFileReader.determineRequires(fileName)

      # Read the file and create a function name to parameter mapping hash
      fileFunctionHash = functionReader.createFunctionHash fileName
      manualHash[fileFunctionHash[0]] = 
        params: fileFunctionHash[1]
        swagger: fileFunctionHash[2]
        comments: fileFunctionHash[3]

      # Loop over the new additional requires and add them sequentially,
      # so that we don't have nested arrays.
      _.each additionalInternalRequires, (add) ->
        internalRequires.push add

    # Filter out the uniq internals
    uniqInternals = _.uniq internalRequires, (ir) ->
      return ir.join(",")

    # Put strict evals first
    uniqInternals = _.sortBy uniqInternals, (ui) ->
      if ui[3]?
        return 0
      else
        return 1


    requireIters = 0
    # Loop through a few times to resolve dependencies on ordering
    while (requireIters < 3) and (uniqInternals.length > 0)
      remaining = []
      _.each uniqInternals, (uiRequire) ->
        try
          if uiRequire[3]?
            if uiRequire[3] == 'eval'
              localContext.eval(uiRequire[0])
            if uiRequire[3] == 'named_eval'
              localContext[uiRequire[1]] = localContext.eval(uiRequire[0])
          else
            if uiRequire[2]
              localContext[uiRequire[1]] = eval("require('#{uiRequire[0]}')")
            else
              localContext[uiRequire[1]] = localContext.eval("require('#{uiRequire[0]}')")
          console.log "Loaded: #{uiRequire}"  
        catch e
          remaining.push uiRequire

      uniqInternals = remaining

      requireIters++

    finalRequireFailures = []
    if uniqInternals.length > 0
      # Let's force the dist directory on them
      _.each uniqInternals, (ui) ->
        ui[0] = ui[0].replace("/server","/dist/server")
        try
          localContext[ui[1]] = eval("require('#{ui[0]}')")
          console.log "Loaded: #{ui}"
        catch e
          finalRequireFailures.push ui
        
        
        


      console.log "#{finalRequireFailures.length} Modules failed to load: "
      console.log (_.collect(finalRequireFailures, (ui) -> ui[1])).join(",")
      

    # Let's do some special imports for our use case
    # Default Calling ID
    localContext.fid = eval("id= {userUid: 'anonymous', groupUid: 'anonymous'}")
    # Default Callback Result
    localContext.cres = null
    localContext.dfc = (err, args) -> 
      if err
        localContext.cres = err
      else
        localContext.cres = args
      console.log args


    localContext.LD = require 'lodash'

    # Load the Manual Data
    for contextName, functionDatums of manualHash
      try
        localContext[contextName]['__man__'] = functionDatums.params
        localContext[contextName]['__swag__'] = functionDatums.swagger
        localContext[contextName]['__cmnt__'] = functionDatums.comments
      catch e

      for functionName, params of functionDatums.params
        try 
          localContext[contextName][functionName]['__man__'] = "#{contextName}.#{functionName} (#{params.join(', ')})"
        catch e

      for functionName, swagg of functionDatums.swagger
        try
          localContext[contextName][functionName]['__swag__'] = swagg
        catch e

      for functionName, comments of functionDatums.comments
        try
          localContext[contextName][functionName]['__cmnt__'] = comments
        catch e
        
          
        
    localContext.swag = (obj) ->
      swag = obj.__swag__
      if swag?
        if typeof(swag) == 'string'
          console.log swag
        else
          if typeof(swag) == 'object'
            for functionName, _swag of swag
              console.log "#{functionName}\n--------------"
              if (not _swag?) or (_swag == "")
                console.log "No Swagger Entry Available.\n"
      else
        console.log "No Swagger Entry Available."
      null
      
        
    localContext.cmnt = (obj) ->
      cmnt = obj.__cmnt__
      if cmnt?
        if typeof(cmnt) == 'string'
          console.log cmnt
        else
          if typeof(cmnt) == 'object'
            for functionName, _cmnt of cmnt
              console.log "#{functionName}\n-------------"
              if (not _cmnt?) or (_cmnt == "")
                console.log "No Comment Entry Available.\n"
      else
        console.log "No Comment Entry Available."
      null      

    localContext.man_partial = (obj) ->
      if obj.__man__?
        data = obj.__man__
        if typeof(data) == 'string'
          console.log obj.__man__
        else
          if typeof(data) == 'object'
            for functionName, params of obj.__man__
              console.log "#{functionName} (#{params.join(', ')})"    
      else
        console.log "No Manual Entry Available."
      null

    localContext.man = (obj) ->
      localContext.swag(obj)
      console.log "Usage:"
      localContext.man_partial(obj)
      localContext.cmnt(obj)

      


    console.log "****************************************"
    console.log "Welcome to the expressCoffee console!"
    console.log "Helpers:"
    console.log "\t* fid: returns a fake id Object"
    console.log "\t* dfc: a default callback that returns either the error or successful arguments to the response."
    console.log "\t* cres: the result of a callback (either error or the success arguments)"
    console.log "\t* man object.funcName: returns the parameters needed to pass to the function."
    console.log "Done Loading Express Coffee...(press enter to start using)..."





  # Makes sure we are only including files from the server portion of
  # express
  ensureWorkingDirIsServer: (workingDir) ->
    if workingDir[workingDir.length-1] == "/"
      workingDir = workingDir.slice(0,-1)
    
    # Best case scenario, we are in the server dir
    if workingDir.split("/").last == "server"
      return workingDir

    # first check down
    currentDirs = fs.readdirSync workingDir
    return "#{workingDir}/server" if _(currentDirs).contains "server"

    # Ok, we'll go up a maximum of 3 levels to check for a server dir
    max_level_check = 3
    checkLevel = 0
    foundServerDir = false
    while (not foundServerDir) and (checkLevel < max_level_check)
      workingDir = workingDir.split("/")[0..-2].join("/")
      foundServerDir = _(fs.readdirSync(workingDir)).contains "server"
      checkLevel++
    return workingDir+"/server"


  # Returns true/false whether we want to do some procesing on this file.
  # Generally we only want .coffee files and want to ignore any templates
  # or tests.
  isRequirableFile: (fileName) ->
    extension = _(fileName.split('.')).last()
    filterable_extensions = ["jade","json","tpl","gitignore"]
    return false if _(filterable_extensions).contains extension

    filterable_substrings = {"Test.coffee"}
    isOk = true
    _.each filterable_substrings, (filterable_substring) ->
      isOk = false unless fileName.indexOf(filterable_substring) < 0
    return false if not isOk

    # Return true if it passes all checks
    true


  #Synchronously walks the tree and returns all the files to check later
  betterWalkTree: (currentDir, fileNames) ->
    if not fileNames?
      fileNames = []

    files = fs.readdirSync currentDir
    _.each files, (file) =>
      relativePath = "#{currentDir}/#{file}"
      fileStat = fs.statSync relativePath
      if fileStat.isDirectory()
        @betterWalkTree(relativePath, fileNames)
      else
        if @isRequirableFile(file)
          fileNames.push relativePath

    return fileNames



