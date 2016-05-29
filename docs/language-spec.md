# aoscript v1 言語仕様

## コンセプト

* シンプルに、最小限
* できるだけC-likeにする

## 値

| 名前       | 型の表記                                                                 | 型の表記の例                                                | 説明                                                                         | 例                        |
|------------|--------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------------------------------------|---------------------------|
| 整数       | `Int`                                                                    |                                                             |                                                                              | `1`                       |
| ブーリアン | `Bool`                                                                   |                                                             | `true`か`false`となる値                                                      | `true`                    |
| リスト     | `[Type]`  ,  `Cons(Type)`                                                | `[Int]`(`Int`のリスト)                                      | 値の並び。要素の型は全て同じである。                                         | `[1, 2, 3]`               |
| タプル     | `(Type1, Type2, ...)`                                                    | `(Int, Int)`                                                | 値の並び。リストとは違い、要素の型は揃えなくてもよいが要素の数は固定である。 | `(1, 2)`                  |
| 関数       | `(InType1 -> InType2 -> ... -> OutType)` (InTypeNは入力の型、OutTypeは出力の型) | `(Int -> Int)` (`Int`型の引数を１つとり、`Int`型の値を出力) | 入力を取り、出力を返すもの                                                   | `Int fun(Int x){ x * 2 }` |

以下はFunction Questで使用できる値である

| 名前     | 型の表記    | 説明                                             | 使える値                      | 例         |
|----------|-------------|--------------------------------------------------|-------------------------------|------------|
| コマンド | `Command`   | プレイヤに対する命令。向きを指定する必要がある。 | `Go`, `Unlock`, `AddItem`     | `Go(Up())` |
| 向き     | `Direction` | コマンドを実行する向き。                         | `Up`, `Down`, `Right`, `Left` | `Up()`     |

## 関数適用

C言語のように`f(x, y, z...)`で関数適用ができますが、第一引数をオブジェクト指向におけるオブジェクトと見立てて`x.f(y, z...)`と書くこともできます。

```scala
x.y().z()
```

は以下と等価です

```scala
z(y(x))
```

## 関数定義

C言語のように

```scala
Int twice(Int n) {
  n * 2
}
```

とすることで定義できます。`return`がないことに注意してください。

上記は以下と等価です

```scala
val twice = Int fun(Int n) {
  n * 2
}
```

## 型

値が属するもの。名前は先頭大文字(キャメルケース)。

## 式

プログラムは式を並べたものです。式はすべて値を持ちます。

### 変数

変数は再代入不可。先頭に大文字は使えません。また型名の代わりに`val` と書くことで、型推論が使えます。

```
Int n = 10
val a = 2
```

### if, else

elseは必須です。また、`{}`も必須です。

```
if(n == 0){ 1 }
else      { n }
```

### パターンマッチ

値や構造をマッチングして処理できる。C言語におけるswitchの強化版です。

値、リスト、タプルに対してパターンマッチが使えます。

```scala
// リスト
match(list) {
  [] -> 0
  Cons(x, xs) -> x
}

// タプル
match(pair) {
  (x, y) -> x + y
}
```

## 予約語

以下の文字列は識別子(変数名や関数名)に使えません。

```
fun
val
if
else
match
true
false
```

## コメント

`//`の行はコメントとして扱われます

```scala
// this function twices a input
Int twice(Int n) { n * 2 }
```