window.Movie ||= {}
window.Movie.Views ||= {}

class Movie.Views.MainDisplayView extends Backbone.View


  initialize: ->
    @loadCastRequirements()
    @playerOne = {ready: false, name: null}
    @playerTwo = {ready: false, name: null}


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
      window.clearInterval(@message) if @message?
      @message = window.setInterval(@pulsate, 700)
    if message.playerNumber
      @setPlayerNumber(message.playerNumber)
    if message.setPlayerName
      @setPlayerName(message.setPlayerName, e.senderId)
    if message.ready
      @setPlayerAsReady(e.senderId)

    
  pulsate: =>
    $("#message").html(@displayMessage)
    $("#message").fadeToggle()
      
    
  setPlayerNumber:(numberOfPlayers) =>
    if numberOfPlayers == 'single-player'
      setTimeout =>
        @customMessageBus.broadcast("start")
      , 2000 # TODO add a message stating that it is single player mode
    else
      @launchGame = window.setInterval(@launchMultiplayer, 4000)

  setPlayerAsReady:(playerId) =>
    if @playerOne.senderId == playerId
      @playerOne.ready = true
    else
      @playerTwo.ready = true
      

  launchMultiplayer: =>
    if @playerOne.ready && @playerTwo.ready
      window.clearInterval(@launchGame)
      @launchGame = 0 # in the off chance clearInterval does not work
      @setVsView()
      # TODO Send message to player 1 to play sound
      setTimeout =>
        @customMessageBus.broadcast("start")
      , 2500
      
      
  setVsView: =>
    $('#player1').html(@playerOne.name)
    $('#player2').html(@playerTwo.name)
    $('.logo-area').addClass("hidden")
    setTimeout =>
      $('.vs-view').fadeIn()
    , 200


  setPlayerName:(name, senderId) =>
    if @playerOne.name?
      @playerTwo.name = name
      @playerTwo.senderId = senderId
    else
      @playerOne.name = name
      @playerOne.senderId = senderId

  senderConnected:(e) ->
    # $(".container").append("<h1>#{e}</h1>")
