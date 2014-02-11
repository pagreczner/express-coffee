fs = require 'fs'
_ = require 'lodash'

swaggerUtilityBaseObj = require './swaggerUtility'



module.exports =
  createFunctionHash: (absoluteFilePath) ->
    # Read all the lines of code in the file at once
    fileCode = fs.readFileSync absoluteFilePath, 'utf8'

    # Split the long string into an array of lines
    lines = fileCode.split /\n/

    swaggerUtil = new swaggerUtilityBaseObj()
    # Something to map the swagger
    swaggerMapper = {}

    functionMap = {}
    # Loop over each line of code
    _.each lines, (line) =>
      swaggerUtil.addLine line

      line = @cleanLine(line)
      if @isFunctionLine(line)
        functionParams = @getFunctionParams line
        functionMap[@getFunctionName(line)] = @getFunctionParams(line)
        swaggerMapper[@getFunctionName(line)] = swaggerUtil.getSwaggerDoc()
        swaggerUtil.reset()

    [@getFileName(absoluteFilePath), functionMap, swaggerMapper]


  # Determines true/false whether this is a function line or not
  isFunctionLine: (line) ->
    hasEndingArrow = (line.indexOf("->") >= 0)
    splitByColon = (line.split(':').length == 2)
    return splitByColon and hasEndingArrow

  # Returns an in order array of function parameters
  getFunctionParams: (line) ->
    colonIndex = line.indexOf(":")
    arrowIndex = line.indexOf("->")
    paramArea = line.slice(colonIndex+1, arrowIndex)
    paramArea = paramArea.replace(/\(/g,'').replace(/\)/g,'')
    params = paramArea.split(',')
    finalParams = _.map(params, (param) -> param.trim())
    

  getFunctionName: (line) ->
    line.split(':')[0].trim()


  # Cleans the line of any extraneous information so we can analyze it better
  cleanLine: (line) ->
    # Trim any front and back spaces
    line = line.trim()
    # Replace any double spaces
    line = line.replace(/\ \ /g,' ').replace(/\ \ /g,' ').replace(/\t/g,' ')
    line

  # Gets the non .coffee file name from the given absolute path
  getFileName: (absoluteFilePath) ->
    coffeeFile = _(absoluteFilePath.split("/")).last()
    fileName = coffeeFile.split('.')[0]
    fileName