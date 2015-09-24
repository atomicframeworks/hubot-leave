# hubot-leave

A hubot script to leave a room and not return until asked to.

See [`src/leave.coffee`](src/leave.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-leave --save`

Then add **hubot-leave** to your `external-scripts.json`:

```json
[
  "hubot-leave"
]
```

## Configuration

### Heroku Credentials
Set environment variables `HEROKU_EMAIL` and `HEROKU_PASSWORD` 
so the bot can maintain the `HUBOT_HIPCHAT_ROOMS_BLACKLIST` environment variable
which controls the rooms not to join on reboot.


## Sample Interaction

```
user1>> @hubot leave
hubot>> It's alright user1, I understand...
hubot left the room 
```

```
user1>> @hubot stay
hubot>> Of course! However, I may have to leave for just a moment...
hubot left the room 
hubot joined the room 
```

## Notes

In order to have Hubot remove the room from the blacklist you will have to first invite hubot to the room. Once Hubot is in the room you can tell it to stay which will remove the room the blacklist allowing Hubot to auto join on reboot.