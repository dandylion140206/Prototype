# Code Style

## 目的

このドキュメントは、プロジェクト内のGDScriptコードスタイルを定義する。

Godot 4.x公式GDScript Style Guideを基準とする。

このドキュメントでは、プロジェクト独自の命名規則や書式規則を追加しない。

Godot公式Style Guideが更新された場合は、原則として最新のGodot 4.x公式ガイドを優先する。

---

# 1. 基本方針

コードスタイルの目的は以下とする。

* 可読性を高める
* コードベース全体の一貫性を保つ
* 他の開発者が理解しやすくする
* 差分を確認しやすくする

Style Guideを機械的な絶対規則として扱わず、既存コードとの一貫性と可読性も考慮する。

ただし、特別な理由がない限りGodot公式の規約に従う。

---

# 2. 命名規則

Godot公式の命名規則を使用する。

| 種類       | 規則              | 例                    |
| -------- | --------------- | -------------------- |
| ファイル名    | `snake_case`    | `yaml_parser.gd`     |
| クラス名     | `PascalCase`    | `YAMLParser`         |
| Node名    | `PascalCase`    | `Camera3D`, `Player` |
| 関数名      | `snake_case`    | `load_level()`       |
| 変数名      | `snake_case`    | `particle_effect`    |
| Signal名  | `snake_case`    | `door_opened`        |
| 定数       | `CONSTANT_CASE` | `MAX_SPEED`          |
| Enum名    | `PascalCase`    | `Element`            |
| Enumメンバー | `CONSTANT_CASE` | `EARTH`              |

---

## 2.1 ファイル名

GDScriptファイル名には`snake_case`を使用する。

名前付きクラスの場合は、PascalCaseのクラス名を`snake_case`へ変換したファイル名を使用する。

```gdscript
# weapon.gd

class_name Weapon
extends Node
```

```gdscript
# yaml_parser.gd

class_name YAMLParser
extends Object
```

---

## 2.2 クラス名とNode名

クラス名とNode名には`PascalCase`を使用する。

```gdscript
class_name PlayerController
extends CharacterBody2D
```

---

## 2.3 関数名と変数名

関数名と変数名には`snake_case`を使用する。

```gdscript
var movement_speed: float


func calculate_velocity() -> Vector2:
    return Vector2.ZERO
```

privateな関数および変数には、先頭に単一のアンダースコアを付ける。

```gdscript
var _counter: int = 0


func _recalculate_path() -> void:
    pass
```

ユーザーがオーバーライドすることを想定したvirtual methodにも、公式規約に従って先頭にアンダースコアを使用する。

Godot組み込みのvirtual methodは、Godotが定義する名前をそのまま使用する。

```gdscript
func _ready() -> void:
    pass
```

---

## 2.4 Signal

Signal名には`snake_case`を使用する。

イベントが発生したことを表す名前には、過去形を使用する。

```gdscript
signal door_opened
signal score_changed
```

---

## 2.5 定数

定数には`CONSTANT_CASE`を使用する。

```gdscript
const MAX_SPEED = 200
const DEFAULT_NAME = "Player"
```

---

## 2.6 Enum

Enum名には単数形の`PascalCase`を使用する。

Enumメンバーには`CONSTANT_CASE`を使用する。

各メンバーは1行ずつ記述する。

```gdscript
enum Element {
    EARTH,
    WATER,
    AIR,
    FIRE,
}
```

---

# 3. インデント

インデントにはタブを使用する。

ブロック構造は一貫したインデントで表現する。

```gdscript
func calculate_damage() -> int:
    if is_critical:
        return base_damage * 2

    return base_damage
```

継続行については、コードの構造が読みやすくなるようにインデントする。

---

# 4. 行の長さ

コードの各行は100文字未満を目安とする。

長い式や関数呼び出しは、読みやすい単位で複数行に分割する。

---

# 5. 1行1ステートメント

複数のステートメントを1行へまとめない。

推奨:

```gdscript
if position.x > width:
    position.x = 0
```

非推奨:

```gdscript
if position.x > width: position.x = 0
```

三項演算子は例外として1行で使用できる。

```gdscript
next_state = "idle" if is_on_floor() else "fall"
```

---

# 6. 空行

関数定義やクラス定義の間には、公式Style Guideに従って空行を配置する。

関数内部では、論理的に異なる処理のまとまりを分けるために空行を使用する。

```gdscript
func update_state() -> void:
    _calculate_velocity()

    if velocity.is_zero_approx():
        _set_idle_state()
```

空行を過剰に使用せず、処理のまとまりを明確にするために使用する。

---

# 7. 空白

演算子の前後には原則として1つの空白を入れる。

```gdscript
var total = value_a + value_b
```

カンマの後には1つの空白を入れる。

```gdscript
calculate_position(x, y, delta)
```

関数呼び出しやDictionaryアクセスなどに不要な空白を追加しない。

---

# 8. コード順序

GDScriptファイル内の要素は、原則として以下の順序で配置する。

```text
01. @tool, @icon, @static_unload
02. class_name
03. extends
04. ## documentation comment

05. signals
06. enums
07. constants
08. static variables
09. @export variables
10. remaining regular variables
11. @onready variables

12. _static_init()
13. remaining static methods

14. overridden built-in virtual methods
    1. _init()
    2. _enter_tree()
    3. _ready()
    4. _process()
    5. _physics_process()
    6. remaining virtual methods

15. overridden custom methods
16. remaining methods
17. inner classes
```

同じ種類のメンバー内では、原則としてpublicなものをprivateなものより先に配置する。

基本的な考え方は以下とする。

1. プロパティとSignalをメソッドより先に置く。
2. publicをprivateより先に置く。
3. virtual callbackをクラス固有のインターフェースより先に置く。
4. 初期化処理を実行時に状態を変更する処理より先に置く。

---

# 9. クラス宣言

Editor上で実行するScriptでは、`@tool`を先頭に配置する。

必要に応じて`@icon`、`class_name`を続ける。

その後に`extends`を配置する。

例:

```gdscript
@tool
@icon("res://icon.svg")
class_name ExampleNode
extends Node
```

クラスの役割を説明する必要がある場合は、documentation commentを使用する。

```gdscript
class_name StateMachine
extends Node
## Manages state transitions.
```

---

# 10. コメント

コメントは、コードそのものから明確に分かる内容を繰り返すために使用しない。

コメントが必要な場合は、処理内容そのものより、必要に応じて理由や意図を説明する。

公開するクラスやメンバーについてドキュメントが必要な場合は、GDScriptのdocumentation commentを使用する。

```gdscript
## Calculates the final damage after modifiers.
func calculate_damage() -> int:
    return _base_damage + _bonus_damage
```

---

# 11. 静的型付け

GDScriptでは静的型付けと動的型付けの両方を使用できる。

同一コードベースでは、どちらかのスタイルへ可能な範囲で統一し、一貫性を保つ。

静的型付けを使用する場合は、変数、関数引数、戻り値などへ型を指定できる。

```gdscript
var damage: float = 10.5


func calculate_damage(base_damage: float, multiplier: float) -> float:
    return base_damage * multiplier
```

型推論を使用することもできる。

```gdscript
var damage := 10.5
```

静的型付けを使用している既存コードを編集する場合は、周辺コードと同じ型付けスタイルを維持する。

動的型付けを使用している既存コードを編集する場合も、理由なく局所的に異なるスタイルへ変更しない。

---

# 12. 型キャスト

型の確認またはキャストが必要な場合は、失敗時の挙動を考慮する。

`as`によるキャストは、型が一致しない場合に`null`となる可能性があるため、その挙動が意図したものであるか確認する。

型が一致することが必須条件の場合は、`is`による確認など、失敗を明示的に扱う方法を検討する。

---

# 13. Collection

型付きコードでは、必要に応じて型付きArrayなどを使用する。

```gdscript
var scores: Array[int] = []
```

型を指定することで意図が明確になる場合は、適切な型を使用する。

ただし、静的型付けを使用するかどうかはコードベース全体の方針との一貫性を優先する。

---

# 14. Shader

Shaderコードを編集する場合は、GDScript Style GuideではなくGodot公式Shaders Style Guideを基準とする。

GDScript固有の命名やコード順序をShaderへそのまま適用しない。

---

# 15. 一貫性

Style Guideの目的はコードの一貫性と可読性を高めることである。

既存コードを編集するときは、Godot公式Style Guideを基本としながら、周辺コードとの一貫性も考慮する。

大規模なスタイル変更を、機能変更と同時に行わない。

コードスタイルのみを変更する場合を除き、要求と無関係なフォーマット変更によって差分を拡大しない。
