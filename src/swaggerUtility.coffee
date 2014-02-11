

# utility repsonsible for creating a manual entry for swagger js doc
class SwaggerUtility
  WAITING = 0
  IN_SWAG = 1
  DONE = 2
  constructor: () ->
    @lines = []
    @state = WAITING
    @swagLines = []

  addLine: (line) ->
    line = @cleanLine line
    @lines.push line

    # We are in the waiting state
    switch @state
      when WAITING
        if @isSwaggerable line
          line = @getSwaggerablePortion line
          if @isSwaggerStartLine line
            @state = IN_SWAG
      when IN_SWAG
        # We are currently parsing the swag
        if @isSwaggerable line
          @swagLines.push @getSwaggerablePortion(line, false)
        else
          @state = DONE
      when DONE
        @noop()
    
    @

  noop: () ->

  getSwaggerDoc: () ->
    return @swagLines.join("\n")

  reset: () ->
    @lines = []
    @state = WAITING
    @swagLines = []

  # clean the line to make it easier to parse and detect features
  cleanLine: (line) ->
    line = line.trim()
    line

  # a swaggerable line needs to start with a asterik
  isSwaggerable: (line) ->
    (line[0] == "*")

  getSwaggerablePortion: (line, doTrim) ->
    line = line.slice(line.indexOf("*")+1)
    if doTrim? and (not doTrim)
      return line
    return line.trim()

  isSwaggerStartLine: (line) ->
    (line == "@swagger")




module.exports = SwaggerUtility
