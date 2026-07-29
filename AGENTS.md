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

情報が不足している、選択肢が複数あるなど確認が必要な場合、質問してから実装を進める。

複数の規則が競合する場合は、次の優先順位に従う。

1. ユーザーからの明示的な指示
2. 参照ドキュメント
3. 既存実装

### 注意事項

- `.godot/` 以下のファイルは編集しない。ただし、Godotによるインポートや検証で自動的に生成、更新されることは許容する。
- `addons/` 以下のファイルは編集しない。
- 実装に関係ない部分の構造、命名などを勝手に変更しない。

## Godot AI MCP

Godot Editorとの連携にはGodot AI MCPを使用する。公開ドメインは次のとおり。

- `api`
- `editor`
- `filesystem`
- `game`
- `project`
- `testing`

基本的なファイルの参照・編集にはCodexの通常のファイル操作を使用する。Godot AI MCPは主に次の用途で使用する。

- Editorの状態、SceneTree、Nodeプロパティの確認
- 使用中のGodotバージョンに対応したAPIの確認
- EditorFileSystemのスキャンとアセットの再インポート
- プロジェクトの実行・停止
- ログ、スクリーンショット、実行時状態の確認
- ゲーム入力とテストの実行

Editorに依存する作業の前に`editor_state`を実行する。シーンやノードの確認には`scene_get_hierarchy`と`node_get_properties`を使用する。

## 作業前の確認

作業を開始する前に、対象とその周辺の実装を確認する。

- 責務、所有関係、依存関係
- SceneTree上の位置
- Signalと公開API
- 関連するResourceとプロジェクト設定
- 再利用可能な既存実装

## 検証


Godotプロジェクトの検証は、次の優先順位に従う。

1. Godot AI MCP
2. GodotのCLIコマンド
3. 静的なファイル確認

MCPで検証できない場合に限り、プロジェクトルートで次を実行する。

```powershell
cmd.exe /d /c 'set "APPDATA=%TEMP%\codex-godot-validation\Roaming" && set "LOCALAPPDATA=%TEMP%\codex-godot-validation\Local" && call godot.cmd --headless --path . --import'
```

> [!WARNING]
> PowerShell の外側の単一引用符を二重引用符へ変更したり、`\"` でエスケープしたりしてはならない。

作業中に発生したエラー・警告は、作業後に以下に従って報告する。

## 実装後の報告

- 実装: どこをどのように変更・追加したのかを文章で簡潔に。
- エラー: 作業中に発生したものも含めて、解決済みと未解決に分け列挙する。
