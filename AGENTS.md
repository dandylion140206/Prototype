# AGENTS

## 前提

- ゲームエンジン: Godot 4.7
- スクリプト言語: GDScript
- シェーダー言語: Godot Shader Language

## ドキュメント

作業前に以下のファイルを参照すること。

- 設計: `docs/DESIGN.md`
- GDScript関連: `docs/GDSCRIPT.md`
- Shader関連: `docs/SHADER.md`
- プロジェクト構造: `docs/ARCHITECTURE.md`

## 基本方針

Godotに関する仕様や推奨事項については、[Godot Docs](https://docs.godotengine.org/en/stable/index.html) を基本とする。

複数の規則が競合する場合は、次の優先順位に従う。

1. ユーザーからの明示的な指示
2. 参照ドキュメント
3. 既存実装

次のような状況が発生した場合、対策や方針をドキュメントへの追加することを提案する。

- エラーが多発
- 方針が定められておらず、判断に迷う

## 注意事項

- 実装に関係ない部分の構造、命名などを勝手に変更しない。
- `.godot/` 以下のファイルを手動で編集しない。ただし、Godotによるインポートや検証で自動的に生成、更新されることは許容する。

## 作業前の確認

作業を開始する前に、対象とその周辺の実装を確認する。

- 責務
- 所有関係
- 依存関係
- SceneTree上の位置付け
- Signalによる接続
- 外部から利用される公開API
- 関連するResource
- プロジェクト設定
- 再利用可能な既存実装

## 検証

実装後は変更内容に応じて、可能な範囲で次を確認する。

- GDScript に構文エラーや型エラーがないか
- Node や Resource の参照が壊れていないか
- Signal の接続が有効か
- Shader にコンパイルエラーがないか
- 変更対象の Scene を読み込み、実行したときに期待どおり動作するか

プロジェクトの実装を変更した場合は、プロジェクトルートで次を実行する。

```powershell
cmd.exe /d /c 'set "APPDATA=%TEMP%\codex-godot-validation\Roaming" && set "LOCALAPPDATA=%TEMP%\codex-godot-validation\Local" && call godot.cmd --headless --path . --import'
```

作業中に発生したエラー・警告は、作業後に以下に従って報告する。

- 解決済みの問題: 原因と行った変更・対策を記載する
- 未解決の問題: 判明している原因、試した対策、残っている問題を記載する。
