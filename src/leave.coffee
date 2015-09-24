# Description
#   Tell Hubot to add or remove a room from HUBOT_HIPCHAT_ROOMS_BLACKLIST
#
# Dependencies:
#   "<module name>": "<module version>"
#
# Configuration:
#   HEROKU_EMAIL
#   HEROKU_PASSWORD
#
# Commands:
#   hubot leave - Blacklist the room then reboot
#   hubot stay - Remove the room from blacklist then reboot
#
# Notes:
#   The leave and stay commands will update Heroku's HUBOT_HIPCHAT_ROOMS_BLACKLIST configuratuon / environment variable which causes the app to restart.
#
# Author:
#   atomicframeworks

module.exports = (robot) ->
  robot.error (err, res) ->
    robot.logger.error "hubot-leave: Error", err
  
  # Credentials needed for Heroku API
  herokuEmail = process.env.HEROKU_EMAIL
  herokuPassword = process.env.HEROKU_PASSWORD
  authorizationHeader = 'Basic ' + new Buffer(herokuEmail + ':' + herokuPassword).toString('base64')

  # Returns an object with some information regarding the message
  getMsgInfo = (msg) ->
    {
      fullName: msg.message.user.name
      firstName: msg.message.user.name.split(' ')[0]
      LastName: msg.message.user.name.split(' ')[1] or ''
      room: msg.message.room
      roomJid: msg.envelope.user.reply_to
    }
  
  configRequst = ->
    robot.http("https://api.heroku.com/apps/vertafore-hubot/config-vars").header('Authorization', authorizationHeader).header('Content-Type', 'application/json').header('Accept', 'application/vnd.heroku+json; version=3')
  
  # Get the Heroku environment variables / config
  getConfigs = ->
    robot.logger.info "Sending GET request for configs"
    configRequst().get()
  
  # Patch / update the Heroku environment variables / config
  patchConfig = (data) ->
    robot.logger.info "Sending PATCH request for configs", data
    configRequst().patch data
    
  sendPatch = (data) ->
    robot.logger.info "SENDING PATCH patch", data
    patchConfig(data) (err, res, body) ->
      robot.logger.info "patch clalback"

      if err
        msg.send "Encountered an error :("
        robot.logger.error "hubot-leave: Failed to patch Heroku Config", err
        return
      else
        robot.logger.info "Sent patch"
  
  # Must have both config variables to continue
  if (herokuEmail && herokuPassword)

    robot.respond /stay/i, (msg) ->
      # Get some misc info from the msg object
      msgInfo = getMsgInfo msg
      
      getConfigs() (err, res, body) ->
        if err
          msg.send "Encountered an error :("
          robot.logger.error "hubot-leave: Failed to get Heroku Config", err
          return
        configs = JSON.parse body
        # Get the existing blacklist from the configs
        if configs.HUBOT_HIPCHAT_ROOMS_BLACKLIST
          blacklist = configs.HUBOT_HIPCHAT_ROOMS_BLACKLIST
        # If the room is blacklisted remove it from the list and send updated list
        if blacklist && blacklist.indexOf(msgInfo.roomJid) != -1
          roomArray = blacklist.split ','
          roomArray.splice(roomArray.indexOf(msgInfo.roomJid), 1)

          data = JSON.stringify {HUBOT_HIPCHAT_ROOMS_BLACKLIST: roomArray.join(',')}
          msg.send "Of course! However, I may have to leave for just a moment..."
          sendPatch data
        else
          msg.send "Of course!"

    robot.respond /leave/i, (msg) ->
      robot.logger.info "Responding to leave"
      # Get some misc info from the msg object
      msgInfo = getMsgInfo msg

      getConfigs() (err, res, body) ->
        if err
          msg.send "Encountered an error :("
          robot.logger.error "hubot-leave: Failed to get Heroku Config", err
          return
        configs = JSON.parse body
        # Get current blacklist from config and check the room is not already listed
        blacklist = configs.HUBOT_HIPCHAT_ROOMS_BLACKLIST or ''
        if !blacklist or blacklist.indexOf(msgInfo.roomJid) == -1
          msg.send "It's alright #{msgInfo.firstName}, I understand..."
          if !blacklist
            blacklist = msgInfo.roomJid
          else
            blacklist = blacklist + ',' + msgInfo.roomJid
        else
          # Add a blank space at the end so Heroku thinks the config has changed and will reboot
          blacklist = blacklist + ''
          msg.send "No problem. I shouldn't be here anyways..."
        data = JSON.stringify {HUBOT_HIPCHAT_ROOMS_BLACKLIST: blacklist}
        sendPatch data
  else
    robot.logger.error "hubot-leave: Failed to get Heroku credentials. Make sure the environment variables HEROKU_EMAIL & HEROKU_PASSWORD are properly set."

