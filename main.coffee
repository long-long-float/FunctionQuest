Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

generateCommand = (commandName) ->
  (dir) ->
    name: commandName
    direction: dir
    toString: -> "#{commandName}(#{@direction.name})"

Go = generateCommand('Go')
Unlock = generateCommand('Unlock')
InvokeItems = (func) ->
  name: 'InvokeItems'
  func: func
  toString: -> @name

Up =
  name: 'Up'
  delta: { x: 0, y: -1 }

Down =
  name: 'Down'
  delta: { x: 0, y: 1 }

Left =
  name: 'Left'
  delta: { x: -1, y: 0 }

Right =
  name: 'Right'
  delta: { x: 1, y: 0 }

obj2dir = (obj) ->
  switch obj.name
    when 'Up'
      Up
    when 'Down'
      Down
    when 'Left'
      Left
    when 'Right'
      Right
    else
      throw "unknown obj: #{JSON.stringify(obj)}"

appendAlert = (type, text) ->
  $alert = $('#alert-template').clone().attr(id: '').addClass("alert-#{type}").append(text)
  $('#alerts').append($alert)
  $alert.fadeIn('slow')

showAOError = (e) ->
  message = if e.name == 'SyntaxError'
        editor.gotoLine(e.line, e.column, true)
        "文法エラー (#{e.line}行 #{e.column}列) 期待していない識別子\"#{e.found}\""
      else if e.location?
        editor.gotoLine(e.location.line, e.location.column, true)
        "エラー (#{e.location.line}行 #{e.location.column}列) #{e.toString()}"
      else
        e.toString()
  appendAlert('danger', message)

showText = (stageIndex) ->
  if stageIndex > game.currentStageIndex
    appendAlert('danger', "クリアしていないステージの説明は見ることができません")
    return

  if stageIndex == game.currentStageIndex
    $('#hint-btn').show()
  else
    $('#hint-btn').hide()

  $('#text-nav li').removeClass('active')
  $("#text-nav li:nth-child(#{stageIndex + 1})").addClass('active')
  $("#text").html($("#md-text#{stageIndex}").html())

class Condition
  class @Require
    constructor: (@requiredItems, @noParticularOrder = true) ->
    check: (items) ->
      return false unless _.every(items, (item) -> item instanceof Item)

      a = items.map((item) -> item.value)
      b = @requiredItems
      if @noParticularOrder
        greater = (x, y) ->
          if a < b
            return -1
          else if a > b
            return 1
          else
            return 0
        a = a.sort(greater)
        b = b.sort(greater)

      JSON.stringify(a) == JSON.stringify(b)

    toString: ->
      """
      #{@requiredItems.join(", ")}が必要
      順不同: #{if @noParticularOrder then 'はい' else 'いいえ'}
      """

  class @Test
    constructor: (opts) ->
      {input: @input, output: @output, inputText: @inputText, outputText: @outputText} = opts

    check: (items) ->
      # itemsはaoscriptのLambdaの配列と仮定
      val = null
      try
        val = _.reduce(items, (args, item) ->
          aoscript.applyFunction(item, args.map(aoscript.obj2ao)).toObject()
        , @input)
        appendAlert('info', "入力#{@input}に対して出力が#{@output}となるかテスト")
        appendAlert('info', "出力#{val}")
        _.isEqual(val, @output)
      catch e
        showAOError(e)
        return false

    toString: ->
      "入力#{@inputText || @input.join(', ')}に対して#{@outputText || @output}を出力"

  @requires: -> new Condition.Require(arguments...)
  @test: -> new Condition.Test(arguments...)

valueFromImmidiatelyOrLazy = (val) ->
  if typeof val == 'function'
    val()
  else
    _.clone(val)

class Cell
  constructor: (@type, @x, @y, @note) ->

class Item
  constructor: (obj) ->
    @x = obj.x
    @y = obj.y
    @value = obj.value

  toString: -> "#{@value} :: #{typeof @value}"

class Player
  constructor: (opts) ->
    @x = opts.x
    @y = opts.y
    @items = opts.items or []

    @direction = Up

    @updateItemList()

  addItem: (item) ->
    @items.push item
    @updateItemList()

  updateItemList: ->
    $('#items').text(@items.map((item) -> item.toString()).join(', '))

class Game
  initialize: (initialStageIndex) ->
    @currentStageIndex = initialStageIndex

    @repeat = 0

    @stages = [
      {
        field: { width: 9, height: 9 }
        player: { x: 4, y: 6 }
        goal  : { x: 4, y: 2 }
      },
      {
        field: ["         "
                "         "
                "   ###   "
                "   #G#   "
                "   # #   "
                "    P    "
                "         "
                "         "
                "         "]
        walls: [
          {
            x: 4, y: 4
            condition: ->
              n = _.random(0, 10)
              fact = (a) ->
                if a == 0
                  1
                else
                  a * fact(a - 1)
              Condition.test(input: [n], output: fact(n), inputText: 'n', outputText: 'n!')
          }]
      },
      {
        field: ["         "
                "         "
                "   ###   "
                "   #G#   "
                "   # #   "
                "    P    "
                "         "
                "         "
                "         "]
        walls: [
          {
            x: 4, y: 4
            condition: ->
              a = _.random(0, 10)
              b = _.random(0, 10)
              c = _.random(0, 10)
              Condition.test(input: [aoscript.Tuple.fromObject([a, b, c])], output: a + b + c, inputText: '(a, b, c)', outputText: 'a + b + c')
          }]
      },
      {
        field: ["   # #   "
                "   # #   "
                "   # #   "
                "   # #   "
                "   # #   "
                "   # #   "
                "   # #   "
                "   #P#   "
                "    #    "]
        goal: -> { x: 4, y: _.random(0, 4), note: 'y座標はランダム' }
        repeat: 1
      },
      {
        field: ["         "
                "         "
                "   ###   "
                "   #G#   "
                "   # #   "
                "    P    "
                "         "
                "         "
                "         "]
        walls: [
          {
            x: 4, y: 4
            condition: ->
              a = _.random(0, 10)
              b = _.random(0, 10)
              c = _.random(0, 10)
              ary = [a, b, c]
              Condition.test(
                input: [aoscript.Cons.fromObject(ary)],
                output: ary.map((e) -> e * 2),
                inputText: '[a, b, c]', outputText: '[a*2, b*2, c*2]')
          }]
      },
      {
        field: ["   #     "
                "   #     "
                "   #     "
                "   #     "
                "   #     "
                "   # #   "
                "   # #   "
                "   #P#   "
                "    #    "]
        goal: -> { x: 6, y: _.random(0, 4), note: 'y座標はランダム' }
        repeat: 1
      },
      {
        field: { width: 9, height: 9 }
        player: { x: 4, y: 6 }
        goal: -> { x: _.random(0, 8), y: _.random(0, 4), note: 'x, y座標ともにランダム' }
        repeat: 1
      },
    ]

    game.setupStage(@currentStageIndex)

  setupStage: (stageIndex, opts) ->
    opts = $.extend(true, {}, {
      setRepeat: true
    }, opts)

    @player = null
    @goal   = null

    # @field[y][x]
    @field = null

    stage = @stages[stageIndex]
    fieldIsArray = Object.prototype.toString.call(stage.field) == '[object Array]'

    @height = if fieldIsArray then stage.field.length else stage.field.height
    @field = new Array(@height)
    for y in [0...@height]
      @width = if fieldIsArray then stage.field[y].length else stage.field.width
      @field[y] = new Array(@width)
      for x in [0...@width]
        if fieldIsArray
          @field[y][x] =
            switch stage.field[y][x]
              when ' '
                new Cell('floor', x, y)
              when 'G'
                @goal = new Cell('goal', x, y)
              when 'P'
                @player = new Player(x: x, y: y)
                new Cell('floor', x, y)
              when '#'
                new Cell('wall', x, y)
        else
          @field[y][x] = new Cell('floor', x, y)

    @field.items = []

    if stage.player?
      @player = new Player(valueFromImmidiatelyOrLazy(stage.player))

    if stage.goal?
      goalPos = valueFromImmidiatelyOrLazy(stage.goal)
      @goal = @field[goalPos.y][goalPos.x] = new Cell('goal', goalPos.x, goalPos.y, goalPos.note)

    if stage.items?
      for item in stage.items
        item = valueFromImmidiatelyOrLazy(item)
        @field.items.push new Item(item)

    if stage.funcs?
      for fun in stage.funcs
        fun = valueFromImmidiatelyOrLazy(fun)
        @field.items.push new Item(fun)

    if stage.walls?
      for wall in stage.walls
        wall = valueFromImmidiatelyOrLazy(wall)
        cell = new Cell('wall', wall.x, wall.y)
        cell.condition = valueFromImmidiatelyOrLazy(wall.condition)
        @field[wall.y][wall.x] = cell

    if opts.setRepeat and stage.repeat?
      @repeat = stage.repeat

    $('#stage-num').text(stageIndex + 1)

    showText(stageIndex)

  @property 'repeat',
    get: -> @_repeat
    set: (rep) ->
      @_repeat = rep
      if @_repeat > 0
        $('#loop-num').text("loop #{@_repeat}")

  isCleared: ->
    return false if @isAllCleared()

    return @field[@player.y][@player.x].type == 'goal'

  isAllCleared: ->
    @currentStageIndex >= @stages.length

  goToNextStage: ->
    @currentStageIndex = Math.min(@currentStageIndex + 1, @stages.length)
    if @currentStageIndex < @stages.length
      @setupStage(@currentStageIndex)

  executeCommand: (command) ->
    dir = null

    switch command.name
      when 'Go'
        dir = obj2dir(command.values[0])

        tx = @player.x + dir.delta.x
        ty = @player.y + dir.delta.y
        return unless @isInField(tx, ty)
        return if @field[ty][tx].type == 'wall'

        @player.x = tx
        @player.y = ty

      when 'Unlock'
        dir = obj2dir(command.values[0])

        x = @player.x + dir.delta.x
        y = @player.y + dir.delta.y
        return unless @field[y][x].condition?

        wall = @field[y][x]
        if wall.condition.check(@player.items)
          @field[y][x] = new Cell('floor', wall.x, wall.y)
        else
          appendAlert('danger', 'Unlock失敗')

      when 'InvokeItems'
        try
          items = aoscript.applyFunction(
              command.values[0],
              [aoscript.Cons.fromObject(@player.items.map((i) -> i.value))]).toArray()
          @player.items = items.map((i) -> new Item(i))
          @player.updateItemList()
        catch e
          alert e

      when 'AddItem'
        @player.addItem command.values[0]

    @player.direction = dir if dir?

    # キーの取得
    isSamePosition = (item) =>
      item.x == @player.x and item.y == @player.y
    item = _.find(@field.items, isSamePosition)
    if item != undefined
      @field.items = _.reject(@field.items, isSamePosition)
      @player.addItem item

  getCurrentStage: ->
    @stages[@currentStageIndex]

  isFinalStage: ->
    @currentStageIndex >= @stages.length - 1 and @repeat == 0

  isInField: (x, y) ->
    0 <= x < @width and 0 <= y < @height
game = new Game

editor = null

assets =
  imagePaths:
    player: 'images/player.png'
    item  : 'images/item.png'
    field : 'images/field.png'

  loadImages: (onload) ->
    @images = {}
    keys = Object.keys(@imagePaths)
    generateNextImageLoader = (index) =>
      if index >= keys.length
        onimageload
      else
        console.log "loading #{index + 1}/#{keys.length} image..."
        =>
          img = new Image
          img.src = @imagePaths[keys[index]]
          @images[keys[index]] = img
          img.onload = generateNextImageLoader(index + 1)
    generateNextImageLoader(0)()

onimageload = ->
  saveFile = (fileName) ->
    if fileName == ''
      alert 'file name is needed'
      return

    localStorage.setItem("file-#{fileName}", editor.getValue())
    fileList = JSON.parse(localStorage.getItem('filelist') or "[]")
    fileList.push fileName if fileList.indexOf(fileName) == -1
    localStorage.setItem('filelist', JSON.stringify(fileList))
    updateFileList()

    appendAlert('info', "#{fileName}をセーブしました!")

  # set up for ace
  editor = ace.edit('editor')
  editor.setFontSize(20)
  session = editor.getSession()
  session.setMode('ace/mode/scala')
  session.setTabSize(2)
  session.setUseWrapMode(true)
  if code = localStorage.getItem('code')
    editor.setValue(code)

  # REPLのロード
  replCode = ''
  $('#repl-console').console
    promptLabel: '> '
    commandValidate: (line) -> line != ''
    commandHandle: (line) ->
      code = replCode + "\n" + line

      env = new aoscript.Environment(null)
      exec = ->
        result = aoscript.eval(code, env, { allowReassignValue: true })
        replCode = code
        if result is null
          "bind value"
        else
          result.toString()
      try
        exec()
      catch e
        e.toString()
    autofocus: true
    animateScroll: true
    promptHistory: true
    charInsertTrigger: (code, line) -> true

  aoscript.onprint = (val) -> appendAlert('info', val)

  canvas = $('#canvas').get(0)
  unless canvas?.getContext
    alert 'canvas未対応'
    return

  CELL_SIZE = 50

  commands = []
  updateRestCommands = (commands) ->
    $('#rest-commands').empty()

    for command in commands
      $('#rest-commands')
        .append($('<span>')
          .addClass('label label-primary')
          .text(command.toString()))
        .append('&nbsp;')

  updateFileList = ->
    $('#file-list > option').remove()
    fileList = JSON.parse(localStorage.getItem('filelist') or '[]')
    for file in fileList
      $('#file-list').append($('<option>').html(file).val(file))

  clearAlerts = ->
    $('#alerts>div').remove()

  updateFileList()

  initialStageIndex = 0
  # 前回までのステージの進捗をロード
  do ->
    currentStageIndex = localStorage.getItem('currentStage')
    if currentStageIndex
      initialStageIndex = parseInt(currentStageIndex)

  # GETパラメータのstageの数値を初期ステージに設定
  do ->
    [name, val] = window.location.search.substring(1).split('=')
    if name == 'stage'
      initialStageIndex = parseInt(val) - 1

  game.initialize(initialStageIndex)

    # 説明文のナビゲーションバーのロード
  for i in [0...game.stages.length]
    li = $('<li>').append(
      $('<a href="#">')
        .text("Stage #{i + 1}")
        .click do (i) -> ->
          showText(i)
          return false
    )
    $('#text-nav').append(li)

  showText(initialStageIndex)

  $('#hint-btn').click ->
    $modalContent = $('#hint-modal>div>div')
    $modalContent.children('div.modal-header').children('h1')
      .text("Stage #{game.currentStageIndex + 1}のヒント")
    $modalContent.children('div.modal-body')
      .html($("#hint#{game.currentStageIndex}").html())
    $('#hint-modal').modal()

  if sessionStorage.getItem('showed-readme') == null
    $('#readme-modal').modal()
    sessionStorage.setItem('showed-readme', 'true')

  firstRun = true

  mouse = {x: 0, y: 0, canvasRect: { top: 0, left: 0 }}

  code = null
  executeCode = ->
    repeat = (time, val) -> _.times(time, -> val)

    dfs = (x, y, px, py, history, command) ->
      return command if x == px and y == py

      ret = []
      for dir in [Up, Down, Right, Left]
        tx = px + dir.delta.x
        ty = py + dir.delta.y
        if game.isInField(tx, ty) and game.field[ty][tx].type != 'wall' and
            _.find(history, (pos) -> pos[0] == tx and pos[1] == ty) == undefined
          ret.push dfs(x, y, tx, ty, history.concat([[px, py]]), command.concat([Go(dir)]))

      ret = _.reject(ret, _.isNull)

      if _.isEmpty(ret)
        return null
      else
        return _.min(ret, (comm) -> comm.length)

    bfs = (x, y, px, py) ->
      que = [[px, py, [], []]] #px, py, history, commands
      routes = []

      while que.length > 0 and routes.length < 10 #limit
        cur = que.pop()

        if cur[0] == x and cur[1] == y
          routes.push cur[3]
          continue

        for dir in [Up, Down, Right, Left]
          tx = cur[0] + dir.delta.x
          ty = cur[1] + dir.delta.y
          history = cur[2]
          command = cur[3]
          if game.isInField(tx, ty) and game.field[ty][tx].type != 'wall' and
              _.find(history, (pos) -> pos[0] == tx and pos[1] == ty) == undefined
            que.push [tx, ty, history.concat([[cur[0], cur[1]]]), command.concat([Go(dir)])]

      if _.isEmpty(routes)
        return []
      else
        return _.min(routes, (route) -> route.length)

    aStar = (x, y, px, py) ->
      field = game.field.concat().map((row) ->
        row.map((cell) ->
          { x: cell.x, y: cell.y, parent: null, state: 'none', dir: null }
        ))

      startNode = field[py][px]
      startNode.realCost = 0
      startNode.presumeCost = Math.abs(px - x) + Math.abs(py - y)
      startNode.score = startNode.realCost + startNode.presumeCost

      openList = [startNode]
      closeList = []

      while true
        minIdx = _.reduce(openList, (min, node, cur) ->
          if node.score < openList[min].score
            return cur
          else
            return min
        , 0)
        cur = openList[minIdx]
        openList = _.reject(openList, (n, i) -> i == minIdx)

        break if cur == undefined
        break if cur.x == x and cur.y == y

        for dir in [Up, Down, Right, Left]
          tx = cur.x + dir.delta.x
          ty = cur.y + dir.delta.y
          continue unless game.isInField(tx, ty)

          to = field[ty][tx]
          continue if to.state != 'none' or to.type == 'wall'

          to.state = 'open'
          to.realCost = cur.realCost + 1
          to.presumeCost = Math.abs(to.x - x) + Math.abs(to.y - y)
          to.score = to.realCost + to.presumeCost
          to.parent = cur
          to.dir = Go(dir)
          openList.push to

        cur.state = 'close'

        if openList.length == 0
          return [] # failure

      ret = []
      getPath = (node) ->
        if node.parent == null
          return []
        else
          getPath(node.parent).concat([node.dir])
      return getPath(field[y][x])

    goto   = (x, y) ->
      (player) ->
        return {
          command: aStar(x, y, player.x, player.y)
          player: { x: x, y: y } #TODO: Playerクラスにする?
        }

    try
      env = new aoscript.Environment(null)
      env.addUserType('Item', [])
      env.addUserType('Command', ['Go', 'Unlock', 'InvokeItems', 'AddItem'])
      env.addUserType('Direction', ['Up', 'Down', 'Right', 'Left'])
      aoscript.eval(code, env)
      unless getCommands = env.getValue('getCommands')
        throw 'getCommands must be defined at code'
      args = [
        aoscript.Tuple.fromObject([game.player.x, game.player.y]) # player
        aoscript.Tuple.fromObject([game.goal.x, game.goal.y]) # goal
      ]
      commands = aoscript.applyFunction(getCommands, args).toArray().map((v) -> v.toObject())
      updateRestCommands(commands)
    catch e
      showAOError(e)
      return

  $('#run-btn').click ->
    code = editor.getValue()
    localStorage.setItem('code', code)

    unless firstRun
      game.setupStage(game.currentStageIndex)
    else
      firstRun = false

    clearAlerts()

    executeCode()

  prevShowTooltip = false
  showTooltip     = false

  draw = (ctx) ->
    for y in [0...game.field.length]
      for x in [0...game.field[y].length]
        ctx.drawImage(assets.images['field'], 16 * 5, 0, 16, 16, x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

        switch game.field[y][x].type
          when 'goal'
            [left, top] = if game.isFinalStage()
                  [16 * 9, 16]
                else
                  [16 * 14, 0]
            ctx.drawImage(assets.images['field'], left, top, 16, 16, x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
          when 'wall'
            wall = if game.isInField(x, y + 1) and game.field[y + 1][x].type != 'wall'
                # 下にwallがない場合
                if game.field[y][x].condition? then 10 else 4
              else
                3
            ctx.drawImage(assets.images['field'], 16 * wall, 0, 16, 16, x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

    pdir = { Up: 3, Down: 0, Right: 2, Left: 1 }[game.player.direction.name]
    ctx.drawImage(assets.images['player'], 0, pdir * 32, 32, 32, game.player.x * CELL_SIZE, game.player.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

    for item in game.field.items
      x = item.x * CELL_SIZE + 8
      y = item.y * CELL_SIZE + 8
      # TODO: アイテムの種類に依って画像を変えてもいいかも
      ctx.drawImage(assets.images['item'], 16 * 1, 16 * 2, 16, 16, x, y, CELL_SIZE / 2, CELL_SIZE / 2)

    # tooltip
    do ->
      x = Math.floor(mouse.x / CELL_SIZE)
      y = Math.floor(mouse.y / CELL_SIZE)

      tooltipText = null
      if game.isInField(x, y)
        cell = game.field[y][x]
        tooltipText = cell.condition?.toString()
        unless tooltipText
          tooltipText = game.field.items
            .filter((item) -> item.x == x and item.y == y)
            .join("\n")
        if not tooltipText and cell.type != 'floor'
          tooltipText = cell.type
        if not tooltipText and game.player.x == x and game.player.y == y
          tooltipText = 'プレイヤ'

        if tooltipText and cell.note
          tooltipText += "\n" + cell.note

      prevShowTooltip = showTooltip
      showTooltip = if tooltipText then true else false

      # enter
      if !prevShowTooltip and showTooltip
        $tooltip = $('<div>').attr(id: 'tooltip', class: 'fq-tooltip')
        $('body').append($tooltip)

      # leave
      if prevShowTooltip and !showTooltip
        $('#tooltip').remove()

      if showTooltip
        rect = $('#canvas').get(0).getBoundingClientRect()
        $('#tooltip').css(top: mouse.y + mouse.canvasRect.top + 50, left: mouse.x + mouse.canvasRect.left + 20)
        $('#tooltip').text("座標(#{x}, #{y})\n" + tooltipText)

  frameCount = 0
  $('#canvas').lightgamer
    width: 500
    height: 500
    fps: 30
    oninit: ->
    onframe: (ctx) ->
      draw(ctx)

      if frameCount % (@fps / 2) == 0
        if game.isCleared() and commands.length == 0
          clearAlerts()
          commands = []
          if game.repeat > 0
            game.repeat--
            game.setupStage(game.currentStageIndex, setRepeat: false)
            executeCode()
          else
            fileName = "stage#{game.currentStageIndex + 1}"
            saveFile(fileName)

            game.goToNextStage()

            localStorage.setItem('currentStage', game.currentStageIndex)

            if game.isAllCleared()
              localStorage.setItem('currentStage', 0)
              $('#ending-modal')
                .on('hidden.bs.modal', (e) -> location.reload())
                .modal()
            else
              firstRun = true

        appendAlert('success', 'finished executing commands!') if commands.length == 1
        command = commands.shift()
        updateRestCommands(commands)
        game.executeCommand(command) if command?
      frameCount++

  $('#canvas').mousemove (event) ->
    rect = event.target.getBoundingClientRect()
    mouse.x = event.clientX - rect.left
    mouse.y = event.clientY - rect.top
    mouse.canvasRect = rect

  $('#save-btn').click ->
    fileName = $('#file-name').val()
    saveFile(fileName)

  $('#load-btn').click ->
    editor.setValue(localStorage.getItem("file-#{$('#file-list').val()}"))

  $('#reset-btn').click ->
    localStorage.removeItem('currentStage')
    location.reload()

window.onerror = ->
  $('#sorry-modal')
    .on('hidden.bs.modal', (e) -> location.reload())
    .modal()

$ ->
  assets.loadImages(onimageload)

  marked.setOptions
    highlight: (code) -> hljs.highlightAuto(code).value

  $('.markdown-text').each ->
    html = marked($(this).html().replace(/&gt;/g, '>'))
    $(this).html(html)
