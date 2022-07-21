# Quiz - Play Challenge

This mod requires players to answer question before they can play.

每隔一定的时间要求玩家回答问题,回答正确才能继续玩.
需要两个间隔时间,一个是检查的间隔时间(checkInterval),另一个是回答问题的间隔时间(idleInterval).

* Chat 命令
  * 加载问答配置
  * 问答的增删改查(CRUD)
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
TODO: 可以在单人游戏增加一个管理密码,只有密码输入正确才能管理,留待以后实现.

还有一个问题,就是多人游戏时,如果一个人没有回答完问题,那么另一个人不会弹出问题对话框.

当回答正确后,奖励物品.

还要增加选择题: select(最多9个选项,再多界面放不下)

```yml
quiz:
  - title: "?"
    type: "select"
    options:
      - Red
      - Blue
      - Green
    answer: [1,2]

```

已经增加问题类别: 计算类型:自动出计算题; 选择题(单项或多项)
需要从配置中独立出题目列表.快速切换题目列表. 增加一个问题类别: `file`,从指定文件中加载问题列表. `title`为文件名.

除法余数的处理? 如果有余数只允许最后一个操作符是除法.
如何挑选能被整除的数?

- Remove interact (and possibly other privs) from default_privs.
- Add any additional privs to `grant` in the `play_challenge.conf` config file.

play_challenge.conf:

单选多选还是匹配答案即可,只要支持模式匹配即可.
answer增加Lua字符模式匹配,模式匹配使用斜杆表示:`/字符模式/`

选择题目也必须随机扰乱顺序.

没法子了,孩子把答案都记住了,手工出题目太麻烦,还是增加自动出计算题类别(`calc`): 随机产生数字四则计算的类别
n: 随机数字(0-9)
N: 随机非零数字(1-9)
[1-3]: 随机指定数字范围
[+-]: 随机指定操作符

```yml
quiz:
  - title: "$calc=?"
    type: "calc"
    answer: "nn[+*]n+2"
  - title: "$calc=?"
    type: "calc"
    forceInt: true
    answer: "(Nn+3)/N"
```

```lua
function parse_charset(s)
  local result = ""
  local i = 1
  while i <= #s do
    local c = s:sub(i,i)
    if string.find(c, "%d") then
      local next_c = s:sub(i+1,i+1)
      local to_c = s:sub(i+2,i+2)
      if next_c == "-" and string.find(to_c, "%d") then

        local n_from = tonumber(c)
        local n_to = tonumber(to_c)
        if n_from > n_to then
          local t = n_from
          n_from = n_to
          n_to = t
        end
        for j = n_from, n_to do
          result = result .. j
        end
        i = i + 2
      else
        result = result .. c
      end
    else
      result = result .. c
    end
    i = i + 1
  end
  return result
end
function parse_calc_type_str(s)
  local result = ""
  local i = 1
  while i <= #s do
    local c = s:sub(i,i)
    if c == "n" then
      result = result .. math.random(0, 9)
    elseif c == "N" then
      result = result .. math.random(1, 9)
    elseif c == "[" then
      local t = ""
      repeat
        i = i + 1
        c = s:sub(i,i)
        if c ~= "]" then t = t .. c end
      until c == "]" or i > #s
      if #t > 0 then
        local charset = parse_charset(t)
        local ix = math.random(1, #charset)
        result = result .. charset:sub(ix, ix)
      end
    elseif string.find(c, "[%+-*/()^%d.]") then
      result = result .. c
    end
    i = i + 1
  end
  return result
end

function compile_expr(s)
  return loadstring("return " .. s)
end

function run_expr(s)
  return compile_expr(s)()
end

```

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

## Lua字符模式匹配

### 字符类

Lua 中允许在模式串中使用字符类

字符类指可以匹配一个特定字符集合内任何字符的模式项。

比如，字符类 %d 匹配任意数字，所以可以使用模式串 '%d%d/%d%d/%d%d%d%d' 搜索 dd/mm/yyyy 格式的日期：

\> s \= "Deadline is 11/11/2017, firm"
\> date \= "%d%d/%d%d/%d%d%d%d"
\> print(string.sub(s, string.find(s, date)))
11/11/2017

### 下表列出了 Lua 支持的所有字符类

| 字符类 | 说明 |
| :-- | :-- |
| 单个字符( 除 ^$()%.\[\]\*+-? 外 ) | 与该字符自身配对 |
| .(点) | 与任何字符配对 |
| %a | 与任何字母配对 |
| %c | 与任何控制符配对(例如\\n) |
| %d | 与任何数字配对 |
| %l | 与任何小写字母配对 |
| %p | 与任何标点(punctuation)配对 |
| %s | 与空白字符配对 |
| %u | 与任何大写字母配对 |
| %w | 与任何字母/数字配对 |
| %x | 与任何十六进制数配对 |
| %z | 与任何代表0的字符配对 |
| %x(此处x是非字母非数字字符) | 与字符x配对. 主要用来处理表达式中有功能的字符(^$()%.\[\]\*+-?)的配对问题, 例如%%与%配对 |
| \[数个字符类\] | 与任何\[\]中包含的字符类配对. 例如\[%w\_\]与任何字母/数字, 或下划线符号(\_)配对 |
| \[^数个字符类\] | 与任何不包含在\[\]中的字符类配对. 例如\[^%s\]与任何非空白字符配对 |

#### 上述的字符类用大写书写时, 表示与非此字符类的任何字符配对

例如 **%S** 表示与任何非空白字符配对 例如 **'%A'** 非字母的字符

\> print(string.gsub("hello, www.twle.cn!", "%A", "."))
hello..www.twle.cn. 5

数字 5 不是字符串结果的一部分，它是 gsub 返回的第二个结果，代表发生替换的次数

### 特殊字符

在模式匹配中有一些特殊字符，它们有特殊的意义

#### Lua 中的特殊字符如下

( ) . % + \- \* ? \[ ^ $

* '%' 用作特殊字符的转义字符，因此 '%.' 匹配点
* '%%' 匹配字符 '%'
* 转义字符 '%' 不仅可以用来转义特殊字符，还可以用于所有的非字母的字符

### 模式条目

* 单个字符类匹配该类别中任意单个字符；

* 单个字符类跟一个 '`*`'，

    将匹配零或多个该类的字符。 这个条目总是匹配尽可能长的串；

* 单个字符类跟一个 '`+`'，

    将匹配一或更多个该类的字符。 这个条目总是匹配尽可能长的串；

* 单个字符类跟一个 '`-`'，

    将匹配零或更多个该类的字符。 和 '`*`' 不同， 这个条目总是匹配尽可能短的串；

* 单个字符类跟一个 '`?`'，

    将匹配零或一个该类的字符。 只要有可能，它会匹配一个；

* `% **n**`，

    这里的 **n** 可以从 1 到 9； 这个条目匹配一个等于 **n** 号捕获物（后面有描述）的子串。

* `%b **xy**`，

    这里的 **x** 和 **y** 是两个明确的字符； 这个条目匹配以 **x** 开始 **y** 结束， 且其中 **x** 和 **y** 保持 **平衡** 的字符串。 意思是，如果从左到右读这个字符串，对每次读到一个 **x** 就 **+1** ，读到一个 **y** 就 **\-1** ， 最终结束处的那个 **y** 是第一个记数到 0 的 **y** 。 举个例子，条目`%b()`可以匹配到括号平衡的表达式。

* `%f[ **set** ]`

    指 **边境模式** ； 这个条目会匹配到一个位于 **set** 内某个字符之前的一个空串， 且这个位置的前一个字符不属于 **set** 。 集合 **set** 的含义如前面所述。 匹配出的那个空串之开始和结束点的计算就看成该处有个字符 '`\0`' 一样。


### 模式

**模式** 指一个模式条目的序列。 在模式最前面加上符号 '`^`' 将锚定从字符串的开始处做匹配。 在模式最后面加上符号 '`$`' 将使匹配过程锚定到字符串的结尾。 如果 '`^`' 和 '`$`' 出现在其它位置，它们均没有特殊含义，只表示自身。

### 捕获

模式可以在内部用小括号括起一个子模式；

这些子模式被称为 **捕获物** 当匹配成功时，由 **捕获物** 匹配到的字符串中的子串被保存起来用于未来的用途。 捕获物以它们左括号的次序来编号。 例如，对于模式`"(a*(.)%w(%s*))"`， 字符串中匹配到`"a*(.)%w(%s*)"`的部分保存在第一个捕获物中 （因此是编号 1 ）； 由 "`.`" 匹配到的字符是 2 号捕获物， 匹配到 "`%s*`" 的那部分是 3 号。

作为一个特例，空的捕获`()`将捕获到当前字符串的位置（它是一个数字）。 例如，如果将模式`"()aa()"`作用到字符串`"flaaap"`上，将产生两个捕获物： 3 和 5
