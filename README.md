# Play Challenge

This mod requires players to answer question before they can play.

每隔一定的时间要求玩家回答问题,回答正确才能继续玩.
需要两个间隔时间,一个是检查的间隔时间(checkInterval),另一个是回答问题的间隔时间(idleInterval).

* Chat 命令
  * 加载问答配置
  * 问答CRUD
  * 保存问答配置

当玩家进入游戏的时候:

* 启动检查的定时器(最小定时器)
  * 检查是否是回答问题的时间
  * 检查是否是已经达到totalPlayTime



- Remove interact (and possibly other privs) from default_privs.
- Add any additional privs to `grant` in the `play_challenge.conf` config file.

play_challenge.conf:

the quiz types: string, number, string[], number[]

```yaml
# totalPlayTime unit is minute
totalPlayTime: 30
# Whether skip the question has already be answered correctly.
skipAnswered: false
# checkInterval unit is seconds
checkInterval: 10
# idleInterval unit is minute
idleInterval: 5
# the default permissions to revoke or grant
grant: "interact,basic_privs"
quiz:
  - id: "optional Id"
    title: "Howto do?"
    desc: "not used yet"
    icon: "not used"
    type: "number[]"
    maxLen: 2
    value: [1,2,3]
    answer: 2
  - title: "What's my favor color?"
    answer: red
  - title: "What's the year?"
    answer: 2021
```

FormSpec:

```
formspec_version[4]size[4,4]field[0,0.4;4,0.6;title;How to do this?;]button_exit[1,2;2,1;btnExit;Ok]
```

