# dirsort.yazi

ディレクトリごとにソート順（および reverse / dir_first）を自動適用する Yazi プラグインです。

- ルールは `~/.config/yazi/init.lua` で定義します
- ディレクトリへ移動した「タイミング」で `sort` を発行します（毎回）

## インストール

以下のように配置してください。

```
~/.config/yazi/plugins/dirsort.yazi/main.lua
~/.config/yazi/plugins/dirsort.yazi/README.md
```

## 設定（init.lua）

`~/.config/yazi/init.lua` に以下を追加します。

```lua
require("dirsort")::setup({
  -- 例1: Downloads は更新日時の新しい順（mtime desc）
  {
    path = os.getenv("HOME") .. "/Downloads",
    sort_by = "mtime",
    reverse = true,
    dir_first = true, -- お好みで
  },

  -- 例2: /var/log は更新日時の古い順（mtime asc）
  {
    path = "/var/log",
    sort_by = "mtime",
    reverse = false,
  },

  -- 例3: 「末尾が /Downloads」のような suffix マッチ（末尾に / を付ける）
  -- path = "/Downloads/",
  -- sort_by = "mtime",
  -- reverse = true,

  -- 例4: Lua pattern（pattern: で始める）
  -- 例: どの階層でも「/Downloads」で終わるなら対象
  -- {
  --   path = "pattern:.*/Downloads$",
  --   sort_by = "mtime",
  --   reverse = true,
  -- },
}, {
  debug = false, -- true にすると ya.err() へデバッグ出力します
})
```

## ルールの仕様

- `rules` は配列（`{... , ...}`）で、**先に一致したものが勝ち**です。

### path の指定方法

1. 完全一致

```
path = "/home/user/Downloads"
```

2. suffix一致（末尾 `/` を付ける）

```
path = "/Downloads/"
```

これは「パスの末尾が `/Downloads` の場合に一致」します。

3. Lua pattern

```
path = "pattern:.*/Downloads$"
```

`pattern:` を付けると Lua の pattern マッチになります。

## sort パラメータ

- `sort_by`
  - `"name"`
  - `"mtime"`
  - `"btime"`
  - `"size"`
  - `"extension"`

- `reverse`
  - `true` で降順

- `dir_first`
  - `true` でディレクトリ優先

例

```
{
  path = os.getenv("HOME") .. "/Downloads",
  sort_by = "mtime",
  reverse = true,
  dir_first = true
}
```

## 動作確認の手順

1. `debug = true` に変更

```
dirsort.setup(rules, { debug = true })
```

2. yazi を起動
3. 対象ディレクトリへ移動

ログが `ya.err()` に出ます。

## トラブルシュート

もしソートが適用されない場合、Yazi のバージョンによって  
`sort` コマンドの引数形式が異なる可能性があります。

その場合は以下を確認してください。

```
yazi --version
```

そして次の情報を教えてください。

- yazi のバージョン
- 指定した `sort_by`
- 表示されたエラー

`main.lua` の `ya.manager_emit("sort", ...)` の引数を調整すれば対応できます。

## ライセンス

自由に改変・利用して構いません。

