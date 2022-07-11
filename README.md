# Quiz - Play Challenge

[![ContentDB](https://content.minetest.net/packages/snowyu/quiz/shields/title/)](https://content.minetest.net/packages/snowyu/quiz/)

This mod requires players to answer question before they can play. If you answer correctly, you will get a award and continue to play, otherwise you will not be able to play.

Players are required to answer questions at regular intervals(`idleInterval`), and the answer is correct to continue playing.

When the game time(`totalPlayTime`) is up, kick the player out.

When logging in, check whether you have enough rest time, based on the recorded last time you left. If you do not have enough rest, you will be kicked out.

* Chat Commands to mange quiz(need quiz privilege)
  * `loadQuiz`: reload quizzes from config file.
  * `quiz <list>`: list all quiz
  * `quiz <del> <Index|Id>`: delete a quiz
  * `quiz <set> <Index|Id> title="Title" answer="Answer"`: edit/add the quiz
  * `quiz reset [<playerName>]`: reset the game time of a player
  * `quizAward <list>`: list all awards
  * `quizAward <del> <Index|name>`: delete a award
  * `quizAward <set> <Id> title="Title" [mod="default"] [count=<Number>]`: edit/add the award
  * `saveQuiz`: save quizzes to config file.
  * `totalPlayTime [<minutes>]`: get or set the total play time at most.
  * `restTime [<min>]`: get or set the rest time at least.
  * `skipAnswered [true|false]`: get or set whether skip the correct answered.
  * `idleInterval [<minutes>]`: get or set the time between answering quiz.
  * `forceAdminRest [true|false]`: get or set the whether force the administrator reset too.
  * `kickDelay [<seconds>]`: get or set the delay time to kick off.
  * `checkInterval [<seconds>]`: get or set the interval time to check quiz.
  * `forceAdminQuiz [true|false]`: get or set the whether force the administrator answer the quiz too. defaults to false.
  * `immediateQuiz [true|false]`: get or set the whether ask the quiz immediately after joining the game. defaults to true.

Put the `quiz_config.yml` file in world folder:

```yaml
# the revoke or grant privileges, defaults to "interact,shout"
grant: interact,shout
# totalPlayTime unit is minute, 0 means disable totalPlayTime
totalPlayTime: 30
# the rest time after playing, unit is minute, 0 means disable resetTime
restTime: 20
# Whether skip the question which has already be answered correctly.
# The number is answered count correctly to skip
skipAnswered: 1
# checkInterval unit is second
checkInterval: 5
# idleInterval unit is minute
idleInterval: 5
# the delay time to kick off, unit is second
kickDelay: 2
# the awards to give
awards:
  # the item name to give
  # minetest_game/mods/default/nodes.lua
  - id: coalblock
    # optional, for translation
    title: Coal Block
    # optional, the defaults to default mod
    mod: default
    # the item count, optional the defaults to 1
    count: 1
  - id: wood
    title: Apple Wood Planks
    count: 3
  - id: stone
    title: Stone
    count: 3
  - id: torch
    title: Torch
  - id: steel_ingot
    title: Steel Ingot
    count: 3
# the quiz list
quiz:
  - id: favorColor
    title: "What's my favor color?"
    answer: red
  - id: theYear
    title: "What's the year?"
    answer: 2021
  - title: "18/7=?"
    answer: "/^2%.%.%.+4/" # the lua string pattern: 2...4 (three dots and more)
```

The `answer` supports the [Lua string pattern](https://www.lua.org/pil/20.2.html) enclosed in "/" slashes.

