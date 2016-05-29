stage1

```scala
[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  [Go(Up()), Go(Up()), Go(Up()), Go(Up())]
}
```

stage2

```scala
Int fact(Int n) {
  if(n == 0) { 1 }
  else { n * fact(n - 1) }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  [AddItem(fact), Unlock(Up()), Go(Up()), Go(Up())]
}
```

stage3

```scala
Int sum((Int, Int, Int) tri) {
  match(tri) {
    (a, b, c) -> a + b + c
  }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  [AddItem(sum), Unlock(Up()), Go(Up()), Go(Up())]
}
```

stage4

```scala
[Command] repeat(Command value, Int n) {
    if(n == 0) { [] }
    else { Cons(value, repeat(value, n - 1)) }
}

Int second((Int, Int) pos) {
    match(pos) {
        (x, y) -> y
    }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
    repeat(Go(Up()), second(player) - second(goal))
}
```

stage5

```scala
[Int] double([Int] list) {
  match(list) {
    [] -> []
    Cons(x, xs) -> Cons(x * 2, double(xs))
  }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  [AddItem(double), Unlock(Up()), Go(Up()), Go(Up())]
}
```

stage6

```scala
[Command] repeat(Command value, Int n) {
    if(n == 0) { [] }
    else { Cons(value, repeat(value, n - 1)) }
}

Int second((Int, Int) pos) {
    match(pos) {
        (x, y) -> y
    }
}

[Command] append([Command] list, Command value) {
    match(list) {
        [] -> [value]
        Cons(x, xs) -> Cons(x, append(xs, value))
    }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  repeat(Go(Up()), second(player) - second(goal)).append(Go(Right())).append(Go(Right()))
}
```

stage7

```scala
[Command] repeat(Command value, Int n) {
    if(n == 0) { [] }
    else { Cons(value, repeat(value, n - 1)) }
}

Int first((Int, Int) pos) {
    match(pos) {
        (x, y) -> x
    }
}

Int second((Int, Int) pos) {
    match(pos) {
        (x, y) -> y
    }
}

[Command] append([Command] list, Command value) {
    match(list) {
        [] -> [value]
        Cons(x, xs) -> Cons(x, append(xs, value))
    }
}

[Command] concat([Command] front, [Command] back) {
    match(back) {
        [] -> front
        Cons(x, xs) -> concat(append(front, x), xs)
    }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  val dx = first(goal) - first(player)
  val dy = second(goal) - second(player)
  val vmove = if(dx >= 0) {
      repeat(Go(Right()), dx)
  } else {
      repeat(Go(Left()), -dx)
  }
  val hmove = if(dy >= 0) {
      repeat(Go(Down()), dy)
  } else {
      repeat(Go(Up()), -dy)
  }
  concat(hmove, vmove)
}
```

stage7(別解)

```scala
[Command] repeat(Command value, Int n, [Command] init) {
    if(n == 0) { init }
    else { Cons(value, repeat(value, n - 1, init)) }
}

Int first((Int, Int) pos) {
    match(pos) {
        (x, y) -> x
    }
}

Int second((Int, Int) pos) {
    match(pos) {
        (x, y) -> y
    }
}

[Command] getCommands((Int, Int) player, (Int, Int) goal) {
  val dx = first(goal) - first(player)
  val dy = second(goal) - second(player)
  val vmove = if(dx >= 0) {
      repeat(Go(Right()), dx, [])
  } else {
      repeat(Go(Left()), -dx, [])
  }
  if(dy >= 0) {
      repeat(Go(Down()), dy, vmove)
  } else {
      repeat(Go(Up()), -dy, vmove)
  }
}
```

