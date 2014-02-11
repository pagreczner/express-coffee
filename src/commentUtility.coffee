class CommentUtility
  WAITING = 0
  IN_COMMENT = 1
  DONE = 2
  constructor: () ->
    @lines = []
    @state = WAITING
    @commentLines = []

  addLine: (line) ->
    line = @cleanLine line

    switch @state
      when WAITING
        if @isCommentBlockBegin(line)
          @state = IN_COMMENT
      when IN_COMMENT
        if @isCommentBlockEnd(line)
          @state = DONE
        else
          @commentLines.push @getCodeCommentPortion(line)
      when DONE
        @noop()

  noop: () ->

  reset: () ->
    @lines = []
    @state = WAITING
    @commentLines = []

  getCommentDoc: () ->
    @commentLines.join("\n")

  cleanLine: (line) ->
    line = line.trim()
    line

  getCodeCommentPortion: (line) ->
    if line.indexOf("*") == 0
      return line.slice(line.indexOf("*"))
    return line

  isCommentBlockBegin: (line) ->
    (line.indexOf("###") == 0)

  isCommentBlockEnd: (line) ->
    (line.indexOf("###") == 0)

module.exports = CommentUtility