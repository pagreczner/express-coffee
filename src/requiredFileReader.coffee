
fs = require 'fs'
_ = require 'lodash'

module.exports =
  determineRequires: (absoluteFilePath) ->
    # Read in the file code and split it up into lines
    fileCode = fs.readFileSync absoluteFilePath, 'utf8'
    lines = fileCode.split /\n/

    # The current working directory of the file we are reading
    currentWorkingDir = @getWorkingDir(absoluteFilePath)

    # We want to go through and generate a list of requires
    # which include the absolute path and the name
    requirables = []

    _.each lines, (line) =>
      if @isRequirable(line)
        # For special ones which we'll have to eval
        if line.indexOf("dotenv") >= 0
          requirables.push ["require('dotenv').load()", 'dotenv', false, 'eval']
        else
          if @isEvalRequire(currentWorkingDir, line)
            requirables.push @getEvalRequire(currentWorkingDir, line)
          else
            requireOfInterest = @getRequirePortion(line)
            requirableTriplet = @parseRequire(currentWorkingDir, requireOfInterest)
            requirables.push requirableTriplet

    requirables

  # true/false whether the line is requireable or not
  isRequirable: (line) ->
    return false unless @isARequire(line)
    true


  getWorkingDir: (filePath) ->
    filePath = filePath.trim()
    filePath = _(filePath.split("/")[0..-2]).join("/")
    filePath = "/#{filePath}"
    filePath.replace("//","/")

  isRelativeRequire: (line) ->
    if (line.indexOf("./") >= 0) or (line.indexOf("../") >= 0)
      return true
    false

  goNextLevelUp: (workingDir) ->
    workingDir = _(workingDir.split("/")[0..-2]).join("/")
    workingDir

  # returns a 2 element array where the first
  # element is the absolute path of the require
  # and the next element is the name of the require
  parseRequire: (workingDir, interest) ->
    # Immediately return if it is a global npm require
    return [interest, interest, false] unless @isRelativeRequire(interest)

    # Return all same directory relative requires
    if interest.indexOf("./") == 0
      realInterest = interest.replace("./","")
      exactInterest = _(realInterest.split("/")).last()
      return [
        "#{workingDir}/#{realInterest}",
        exactInterest,
        true
      ]

    realWorkingDir = workingDir
    while interest.indexOf("../") >= 0
      realWorkingDir = @goNextLevelUp(realWorkingDir)
      interest = interest.replace("../","")

    realInterest = _(interest.split("/")).last()
    return [
      "#{realWorkingDir}/#{interest}",
      realInterest,
      true
    ]

  isEvalRequire: (workingDir, line) ->
    requireIndex = line.indexOf("require")
    requirePortion = line.slice(requireIndex)
    startParen = requirePortion["require".length]
    return false unless startParen == "("
    dotIndex = requirePortion.indexOf(".",requirePortion.indexOf(")"))
    return (dotIndex >= 0)
    

  getEvalRequire: (workingDir, line) ->
    requireIndex = line.indexOf("require")
    requirePortion = line.slice(requireIndex)
    startParen = requirePortion["require".length]
    dotIndex = requirePortion.indexOf(".",requirePortion.indexOf(")"))
    commentHashTag = requirePortion.indexOf("#")

    evalPortion = null
    if commentHashTag > 0
      evalPortion = requirePortion.slice(0,commentHashTag).trim()
    else
      evalPortion = requirePortion.trim()

    requireName = line.split("=")[0].trim()

    [evalPortion, requireName, false, 'named_eval']


  getRequirePortion: (line) ->
    requireIndex = line.indexOf("require")
    requirePortion = line.slice(requireIndex)
    requirePortion = requirePortion.replace(/\(/g, ' ').replace(/\)/g,' ')
    requirePath = requirePortion.slice("require".length).trim()
    requirePath = requirePath.replace(/\'/g,'').replace(/\"/g,'')
    # At this point in the method we should have turned
    # ld = require 'lodash' 
    # into
    # lodash
    requirePath



  isARequire: (line) ->
    return true if (line.indexOf("= require") >= 0)
    return true if (line.trim().indexOf("require") == 0)
    false

