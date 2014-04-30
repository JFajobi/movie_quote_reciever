window.Movie ||= {}
window.Movie.Views ||= {}

class Movie.Views.MainDisplayView extends Backbone.View


  initialize: ->
    @loadCastRequirements()
    @playerOne = {ready: false, name: null, score: null, senderId: null}
    @playerTwo = {ready: false, name: null, score: null, senderId: null}
    @notStarted = true


  loadCastRequirements: ->
    cast.receiver.logger.setLevelValue(cast.receiver.LoggerLevel.DEBUG)
    @castReceiverManager = cast.receiver.CastReceiverManager.getInstance()
    @customMessageBus = @castReceiverManager.getCastMessageBus('urn:x-cast:movie.quote.game')
    @castReceiverManager.onSenderConnected = @senderConnected
    @castReceiverManager.start()  
    @customMessageBus.onMessage = @parseMessage

    


  parseMessage:(e) =>
    message = JSON.parse(e.data)

    if message.displayMessage
      @displayMessage = message.displayMessage
      clearInterval(@message) if @message?
      @message = setInterval(@pulsate, 700)
    if message.playerNumber
      @setPlayerNumber(message.playerNumber)
    if message.setPlayerInfo
      @setPlayerInfo(message.setPlayerName, e.senderId)
    if message.ready
      @setPlayerAsReady(e.senderId)
    if message.results
      @results = setInterval(@displayResults(message.results, e.senderId), 4000)

    
  pulsate: =>
    $("#message").html(@displayMessage)
    $("#message").fadeToggle()

  #
  # creates and displays a result view for multiplayer
  #
  displayResults:(score, senderId) =>
    @gatheringResultInfo = true
    if @playerOne.senderId == senderId
      @playerOne.score = score
    else
      @playerTwo.score = score

    if @playerOne.score && @playerTwo.score && @gatheringResultInfo # fail safe since clearinterval doesnt seem to work
      clearInterval(@results)
      resultsView = new Movie.Views.ResultsView
      el: ".container"
      attributes:
        playerOne: @playerOne
        playerTwo: @playerTwo

      @gatheringResultInfo = false
      resultsView.render()
      
    
  setPlayerNumber:(numberOfPlayers) =>
    if numberOfPlayers == 'single-player'
      setTimeout =>
        # @customMessageBus.send(@playerOne.senderId, "round one") #TODO determin proper way to play music
        @customMessageBus.broadcast("start")
      , 2000 # TODO add a message stating that it is single player mode
    else
      @launchGame = setInterval(@launchMultiplayer, 4000)

  setPlayerAsReady:(playerId) =>
    if @playerOne.senderId == playerId
      @playerOne.ready = true
    else
      @playerTwo.ready = true
      

  launchMultiplayer: =>
    if @playerOne.ready && @playerTwo.ready && @notStarted
      clearInterval(@launchGame)
      @launchGame = 0 # in the off chance clearInterval does not work
      @setVsView(@playerOne.name, @playerTwo.name)
      @customMessageBus.send(@playerOne.senderId, "round one")
      # TODO Send message to player 1 to play sound
      setTimeout =>
        @customMessageBus.broadcast("start")
      , 2500
      @notStarted = false # hacky way to insure launchMultiplayer does not get called again TODO fix and 
                          # determine why clearInterval does not work
      
      
  setVsView:(player1, player2) =>
    vsView = new Movie.Views.VsView
      el: ".container"
      attributes:
        player1: player1
        player2: player2

    vsView.render()
  
  #
  # function used to set the players name and session id
  #  
  setPlayerInfo:(name, senderId) =>
    if @playerOne.name?
      @playerTwo.name = name
      @playerTwo.senderId = senderId
    else
      @playerOne.name = name
      @playerOne.senderId = senderId

  senderConnected:(e) ->
    # $(".container").append("<h1>#{e}</h1>")
