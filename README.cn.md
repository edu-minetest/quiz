# Quiz - Play Challenge

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
    * 当游戏时间到了,踢出玩家.
    * 登录时候,要检查是否休息了足够的时间,根据记录的上一次的离开时间.

不限制多人游戏的管理者(拥有`server`权限的人)
disable check if it's admin(has `server` priv).
注意: 无法撤销管理员和单机用户的interact权限!
~~但是不停的弹出窗体,也能打扰她打游戏.~~

当回答正确后,奖励物品.

需要增加问题类别: 计算类型,自动出计算题

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

