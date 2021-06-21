# Quiz - Play Challenge

[![ContentDB](https://content.minetest.net/packages/snowyu/quiz/shields/title/)](https://content.minetest.net/packages/snowyu/quiz/)

This mod requires players to answer question before they can play. If you answer correctly, you will get a award and continue to play, otherwise you will not be able to play.

Players are required to answer questions at regular intervals(`idleInterval`), and the answer is correct to continue playing.

When the game time(`totalPlayTime`) is up, kick the player out.

When logging in, check whether you have enough rest time, based on the recorded last time you left. If you do not have enough rest, you will be kicked out.

* Chat Commands
  * `loadQuiz`: reload quizzes from config file.
  * `quiz <add> "Title" "Answer"`: add a quiz(TODO)
  * `quiz <list>`: list all quiz
  * `quiz <del> <Index|Id> `: delete a quiz
  * `quiz <edit> <Index|Id> "Title" "Answer"`: edit the quiz(TODO)
  * manage award(TODO)
  * `saveQuiz`: save quizzes to config file.

`quiz_config.yml` in world folder:

```yaml
# the revoke or grant privileges, defaults to "interact,shout"
grant: interact,shout
# totalPlayTime unit is minute
totalPlayTime: 2
restTime: 20
# Whether skip the question which has already be answered correctly.
skipAnswered: 1
# checkInterval unit is seconds
checkInterval: 5
# idleInterval unit is minute
idleInterval: 1
awards:
  # the item name to give
  - name: coalblock
    # for translation
    title: Coal Block
    # optional, the defaults to default mod
    mod: default
    # the item count, optional the defaults to 1
    count: 1
  - name: wood
    title: Apple Wood Planks
    count: 3
  - name: stone
    title: Stone
    count: 3
  - name: torch
    title: Torch
  - name: steel_ingot
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
```

