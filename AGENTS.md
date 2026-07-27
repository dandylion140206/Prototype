# AGENTS

## 前提

- ゲームエンジン: Godot 4.7
- スクリプト言語: GDScript
- シェーダー言語: Godot Shader Language

### プラグイン

- [Godot AI](https://github.com/hi-godot/godot-ai)

## ドキュメント

作業前に、次の対応するファイルを参照すること。

- 設計: `docs/DESIGN.md`
- GDScript関連: `docs/GDSCRIPT.md`
- Shader関連: `docs/SHADER.md`
- プロジェクト構造: `docs/ARCHITECTURE.md`

## 基本方針

複数の規則が競合する場合は、次の優先順位に従う。

1. ユーザーからの明示的な指示
2. 参照ドキュメント
3. 既存実装

## 注意事項

- `.godot/` 以下のファイルは編集しない。ただし、Godotによるインポートや検証で自動的に生成、更新されることは許容する。
- `addons/` 以下のファイルは編集しない。
- 実装に関係ない部分の構造、命名などを勝手に変更しない。

## Godot AI MCP

このプロジェクトでは、Godot Editor との連携に Godot AI MCPサーバーを使用する。

- Godot Editorの状態確認、Scene、Node の参照や変更、プロジェクト設定、ゲーム実行に関する操作には、Godot AI MCPツールを優先して使用する。
- Godot Editorに依存する作業を開始する前に、`editor_state` を実行してGodot Editorとの接続状態と現在の状態を確認する。
- 使用するツールは、MCPから提供される各ツールの説明を確認して選択する。ツール一覧を固定的に想定しない。
- Godot AI MCP または Godot Editor に接続できない場合は、操作が成功したものとして扱わず、接続できないことを明示する。

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

- GDScript に構文エラーや型エラーがないか。
- Node や Resource の参照が壊れていないか。
- Signal の接続が有効か。
- Shader にコンパイルエラーがないか。
- 変更対象の Scene を読み込み、実行したときに期待どおり動作するか。

プロジェクトの実装を変更した場合は、プロジェクトルートで次を実行する。

```powershell
cmd.exe /d /c 'set "APPDATA=%TEMP%\codex-godot-validation\Roaming" && set "LOCALAPPDATA=%TEMP%\codex-godot-validation\Local" && call godot.cmd --headless --path . --import'
```

> [!WARNING]
> PowerShell の外側の単一引用符を二重引用符へ変更したり、`\"` でエスケープしたりしてはならない。

作業中に発生したエラー・警告は、作業後に以下に従って報告する。

## 実装後の報告

- 実装: どこをどのように変更・追加したのかを文章で簡潔に。
- エラー: 作業中に発生したものも含めて、解決済みと未解決に分け列挙する。
