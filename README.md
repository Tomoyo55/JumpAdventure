# 🏃 JumpAdventure

A simple obstacle course game built with **Roblox Studio** and **Luau**.

This is my first public Roblox game.
The goal is to reach the finish while avoiding traps, moving with conveyors, and using bounce pads to jump across the course.

## 🎮 Demo

You can play the published game on Roblox:

**JumpAdventure**
[\[Roblox Game Link\]](https://www.roblox.com/ja/games/133145526547401/Jump-Adventure)

## ✨ Features

* 🏁 Checkpoints that remember each player's progress
* ⚠️ Trap parts that eliminate the player on contact
* ➡️ Conveyor belts that move players in different directions
* 🚀 Bounce pads that launch players upward
* 🎨 Direction-based conveyor colors and arrow indicators
* 🏷️ Tag-based object management using `CollectionService`
* ⚙️ Configurable object behavior using Roblox Attributes

## 🛠️ Tech Stack

* **Roblox Studio**
* **Luau**
* `CollectionService`
* Roblox `Players` service
* Roblox `Workspace`
* Git / GitHub

## ⚙️ How It Works

### 🏁 Checkpoints

`CheckpointManager.luau` manages checkpoints for each player.

Each checkpoint has a `CheckpointIndex` attribute.
When a player touches a checkpoint, the script records the highest checkpoint they have reached.

When the player's character respawns, they are moved back to their latest checkpoint.

```text
Player
  ↓
Touches Checkpoint
  ↓
CheckpointIndex is checked
  ↓
Latest checkpoint is stored
  ↓
Player respawns
  ↓
Character returns to checkpoint
```

### ➡️ Conveyor Belts

`ConveyorManager.luau` controls conveyor belts using the `Conveyor` CollectionService tag.

The movement speed can be configured using the `Speed` attribute.

The script also:

* Calculates the conveyor's movement direction
* Sets its velocity
* Changes its color depending on direction
* Displays an arrow indicating the movement direction

```text
Conveyor
  ↓
Read Speed attribute
  ↓
Calculate world-space direction
  ↓
Apply AssemblyLinearVelocity
  ↓
Update color & arrow indicator
```

### ⚠️ Traps

`TrapManager.luau` manages objects tagged with `TrapPart`.

When a player touches a trap, the player's Humanoid health is set to `0`, causing the character to be eliminated.

```text
Player touches Trap
        ↓
Touched event
        ↓
Find Humanoid
        ↓
Health = 0
        ↓
Player respawns
```

### 🚀 Bounce Pads

`BouncePadManager.luau` manages objects tagged with `BouncePad`.

Bounce pads use the `BounceImpulse` attribute to control their launch strength.
If no value is specified, a default impulse is used.

Newly tagged bounce pads are also automatically configured.

## 📚 What I Learned

Through this project, I learned how to:

* Create and publish a Roblox experience
* Write scripts using Luau
* Organize game logic into separate scripts
* Use Roblox services such as `Players`, `Workspace`, and `CollectionService`
* Use `Touched` events to detect player interactions
* Store per-player game state
* Use Roblox Attributes to configure object behavior
* Use CollectionService tags to manage multiple objects
* Work with vectors, velocity, and coordinate transformations
* Use Git and GitHub to manage source code

## 💡 Implementation Highlights

One of the main ideas in this project is to use **tags and attributes instead of hard-coding individual objects**.

For example, instead of writing separate code for every conveyor belt, objects can be tagged with:

```text
Conveyor
```

and their speed can be configured with:

```text
Speed
```

This allows the same script to control multiple objects.

The same approach is used for:

```text
BouncePad
TrapPart
```

This makes it easier to add or modify obstacles while keeping the game logic centralized.

## 📂 Project Structure

```text
JumpAdventure/
├── ServerScriptService/
│   ├── CheckpointManager.luau
│   ├── ConveyorManager.luau
│   └── TrapManager.luau
│
├── StarterPlayerScripts/
│   └── BouncePadManager.luau
│
└── README.md
```

The original Roblox place file (`.rbxl`) is not included in this repository.

---

# 🇯🇵 日本語

## 🏃 JumpAdventureについて

**Roblox Studio** と **Luau** を使って制作したシンプルなアスレチックゲームです。

Robloxで初めて公開したゲームで、トラップを避けたり、コンベアやバウンスパッドを利用したりしながらゴールを目指します。

## ✨ 主な機能

* 🏁 プレイヤーごとのチェックポイント
* ⚠️ 触れるとプレイヤーを倒すトラップ
* ➡️ プレイヤーを移動させるコンベア
* 🚀 プレイヤーを上方向へ跳ね飛ばすバウンスパッド
* 🎨 コンベアの移動方向に応じた色・矢印表示
* 🏷️ `CollectionService` のタグを利用したオブジェクト管理
* ⚙️ Roblox Attributesを利用した各オブジェクトの設定

## 🛠️ 使用技術

* Roblox Studio
* Luau
* CollectionService
* Players
* Workspace
* Git / GitHub

## 📚 学んだこと

このプロジェクトを通して、以下について学習しました。

* Robloxゲームの作成・公開
* Luauによるスクリプト作成
* ゲーム処理を複数のスクリプトに分割する方法
* RobloxのServiceを利用した処理
* `Touched` イベントによるプレイヤーとの接触判定
* プレイヤーごとの状態管理
* Attributesを利用したオブジェクト設定
* `CollectionService` のタグを利用したオブジェクト管理
* ベクトル・速度・座標変換
* Git / GitHubを利用したソースコード管理

## 💡 工夫したポイント

このゲームでは、個々のオブジェクトを直接指定するのではなく、**タグとAttributesを利用して複数のオブジェクトをまとめて管理**しています。

例えばコンベアには、

```text
Conveyor
```

というタグを付け、速度を

```text
Speed
```

というAttributeで設定しています。

そのため、コンベアを新しく追加した場合でも、同じスクリプトで処理できます。

バウンスパッドやトラップについても同様に、

```text
BouncePad
TrapPart
```

というタグを利用しています。

これにより、ゲーム内のオブジェクトを追加・変更しやすくし、ゲームロジックを一つの場所にまとめています。

## 📂 ファイル構成

```text
JumpAdventure/
├── ServerScriptService/
│   ├── CheckpointManager.luau
│   ├── ConveyorManager.luau
│   └── TrapManager.luau
│
├── StarterPlayerScripts/
│   └── BouncePadManager.luau
│
└── README.md
```

Robloxのゲーム本体ファイル（`.rbxl`）は、このリポジトリには含めていません。
