
<div align="center">

# 🚂 SwitchYard

### 8086 Assembly Based Train Routing Game

A real-mode DOS game where players control railway switches, route incoming trains, and deliver them to their correct destinations. Play solo or collaborate with another player to keep the railway running smoothly.

![8086 Assembly](https://img.shields.io/badge/8086-Assembly-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-DOS-black?style=for-the-badge)
![Language](https://img.shields.io/badge/Language-x86%20Assembly-orange?style=for-the-badge)
![Modes](https://img.shields.io/badge/Game%20Modes-2-purple?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

</div>

---

## 📌 Overview

**SwitchYard** is a railway management and train-routing game developed using 8086 Assembly Language. Players must operate railway switches to guide incoming trains toward their assigned destination stations.

The game features two entrances, multiple railway tracks, four interactive switches, and destination stations labeled A, B, C, and D.

Players must make the correct routing decisions while managing multiple trains simultaneously. Incorrect deliveries increase mistakes, and reaching the mistake limit ends the game.

The project demonstrates low-level programming concepts through an interactive DOS-based game.

## ✨ Features

- **Single Player Mode** – Control all four railway switches independently.
- **Two Player Co-op Mode** – Collaborate with another player to manage the railway.
- **Dynamic Train Spawning** – New trains arrive automatically from two entrances.
- **Random Destinations** – Each train receives a randomly selected destination.
- **Interactive Railway Switches** – Toggle four switches to change train routes.
- **Collision Prevention** – Prevent multiple trains from occupying the same railway cell.
- **Score Tracking** – Earn points for successfully delivering trains.
- **Mistake Tracking** – Incorrect deliveries increase the mistake count.
- **Progressive Difficulty** – Train movement speed increases as the game progresses.
- **Game Over & Replay** – Win or lose, view your results, and restart the game.

## 🎮 Game Controls

| Action | Single Player | Two Player Co-op |
|---|---|---|
| Switch 1 | `1` | Player 1: `1` |
| Switch 2 | `2` | Player 1: `2` |
| Switch 3 | `3` | Player 2: `J` |
| Switch 4 | `4` | Player 2: `K` |
| Exit Game | `Esc` | `Esc` |
| Replay | `R` | `R` |

## 🎯 Game Rules

- Successfully deliver a train to its assigned station to earn one point.
- Delivering a train to the wrong station adds one mistake.
- The game ends after **5 mistakes**.
- Single Player requires **10 successful deliveries** to win.
- Two Player Co-op requires **20 successful deliveries** to win.
- Train movement speed increases after 6 successful deliveries in Single Player or 12 in Co-op.
- New trains spawn approximately every 2 seconds.
- Players must manage all active trains without causing railway congestion.

## 🛠️ Technologies & Concepts

- 8086 Microprocessor Architecture
- x86 Assembly Language
- NASM Assembler
- DOS Real Mode Programming
- BIOS Interrupts
- DOS Interrupts
- Video Memory Manipulation (`0xB800`)
- Timer Interrupt Handling (`INT 8`)
- Interrupt Vector Table (IVT)
- Keyboard Input Handling
- Stack-Based Procedures
- Registers and Memory Addressing
- Random Number Generation
- Train Movement and Collision Detection
- Multi-Entity Game State Management

## 📂 Project Structure

```text
SwitchYard/
│
├── MAIN.COM          # Compiled game executable
├── main.asm          # Main program and game loop
├── Mustafa.asm       # Game logic and core procedures
├── Shauzab.asm       # Railway graphics and switch handling
├── cwsdpmi.exe       # DOS protected-mode support utility
└── project.json      # Project configuration
```

## ▶️ Running the Game

The game is designed to run in a DOS environment.

1. Install [DOSBox](https://www.dosbox.com/).
2. Clone or download this repository.
3. Mount the project directory in DOSBox.
4. Navigate to the project directory.
5. Run the executable:

```dos
MAIN.COM
```

### Assembling from Source

Install [NASM](https://www.nasm.us/) and assemble the source files:

```bash
nasm -f bin main.asm -o MAIN.COM
```

Run the generated `MAIN.COM` inside DOSBox.

## 📚 Project Files

| File | Description |
|---|---|
| `main.asm` | Program entry point, initialization, and main game loop. |
| `Mustafa.asm` | Train management, timer handling, scoring, and game-state logic. |
| `Shauzab.asm` | Railway rendering, switch operations, keyboard controls, and train movement. |
| `MAIN.COM` | Ready-to-run compiled game. |

## 👨‍💻 Contributors

- **Mustafa** – Core game logic, train management, timer interrupts, scoring, and game-state handling.
- **Shauzab** – Railway graphics, track management, interactive switches, and train movement.

---

<div align="center">

**Built with 8086 Assembly Language**

*Manage the switches. Route the trains. Keep the railway running.*

</div>
