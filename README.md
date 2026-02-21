# Cosmos Craft

**Космический экшен с элементами RPG / Space action RPG**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![LÖVE2D](https://img.shields.io/badge/LÖVE2D-11.4+-pink.svg)

---

# Russia

### О проекте

Cosmos Craft — моя первая полноценная игра на движке LÖVE2D. Это космический экшен, где вы начинаете с простого корабля и постепенно прокачиваете его до неуязвимой машины. Вас ждут битвы с боссами, система крафта, улучшение оружия и прокачка корабля по тирам. В планах — кооперативный режим и собственные серверы для мультиплеера.

### Геймплей

- 🚀 Улучшение корабля и оружия
- 👾 Битвы с уникальными боссами
- ⚙️ Крафт предметов из ресурсов
- 📈 Прокачка тиров корабля
- 💎 Сбор ресурсов с врагов
- 🌌 Исследование космоса

### Системные требования

- **LÖVE2D 11.4** или новее
- **OpenGL 2.1**+
- **512 МБ ОЗУ**
- **Любая ОС**: Windows, macOS, Linux

### Запуск игры

#### Вариант 1: Готовый билд

1. Перейдите в раздел **[Releases](https://github.com/maredhat/cosmoscraft/releases)**
2. Скачайте последнюю версию для вашей ОС
3. Распакуйте архив
4. Запустите исполняемый файл

#### Вариант 2: Запуск из исходников

```bash
git clone https://github.com/maredhat/cosmoscraft.git
cd cosmoscraft
love .
```

#### Вариант 3: Сборка .love файла

```bash
zip -r cosmoscraft.love * -x "*.git*" "*.psd" "*.ai"
love cosmoscraft.love
```

#### Сборка .exe для Windows

```bash
copy /b love.exe+cosmoscraft.love CosmosCraft.exe
```

### Управление

| Клавиша | Действие |
|---------|----------|
| W/A/S/D | Движение |
| Space | Стрельба |
| E | Взаимодействие / сбор |
| I | Инвентарь |
| C | Крафт |
| Tab | Карта |
| Esc | Пауза / меню |

### Планы разработки

**Ближайшие задачи:**
- [ ] Базовая механика движения и стрельбы
- [ ] Система улучшений корабля
- [ ] Первый босс
- [ ] Инвентарь и крафт
- [ ] Ресурсы и добыча

**В будущем:**
- [ ] Кооперативный режим
- [ ] Выделенные серверы
- [ ] PvP-арены

---

# English

### About

Cosmos Craft is my first full-fledged game built with the LÖVE2D engine. It's a space action game where you start with a basic ship and gradually upgrade it into an unstoppable machine. Features include boss battles, crafting system, weapon upgrades, and ship tier progression. Co-op mode and dedicated servers are planned for the future.

### Gameplay

- 🚀 Ship and weapon upgrades
- 👾 Unique boss battles
- ⚙️ Item crafting from resources
- 📈 Ship tier progression
- 💎 Resource gathering from enemies
- 🌌 Space exploration

### System Requirements

- **LÖVE2D 11.4** or newer
- **OpenGL 2.1**+
- **512 MB RAM**
- **Any OS**: Windows, macOS, Linux

### How to Run

#### Option 1: Pre-built release

1. Go to **[Releases](https://github.com/maredhat/cosmoscraft/releases)**
2. Download the latest version for your OS
3. Extract the archive
4. Run the executable

#### Option 2: Run from source

```bash
git clone https://github.com/maredhat/cosmoscraft.git
cd cosmoscraft
love .
```

#### Option 3: Build .love file

```bash
zip -r cosmoscraft.love * -x "*.git*" "*.psd" "*.ai"
love cosmoscraft.love
```

#### Build .exe for Windows

```bash
copy /b love.exe+cosmoscraft.love CosmosCraft.exe
```

### Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Movement |
| Space | Shoot |
| E | Interact / collect |
| I | Inventory |
| C | Craft |
| Tab | Map |
| Esc | Pause / menu |

### Development Roadmap

**Upcoming:**
- [ ] Basic movement and shooting mechanics
- [ ] Ship upgrade system
- [ ] First boss
- [ ] Inventory and crafting
- [ ] Resources and gathering

**Future:**
- [ ] Co-op mode
- [ ] Dedicated servers
- [ ] PvP arenas

---

## 🛠 Технический стек / Tech Stack

- **Engine:** LÖVE2D 11.4
- **Language:** Lua 5.1
- **Libraries:**
  - Anim8 — animations
  - Windfield — physics (WIP)
  - STI — Tiled maps

## 📁 Структура проекта / Project Structure

```
cosmoscraft/
├── assets/          # Graphics, fonts, sounds
├── src/             # Source code
│   ├── scenes/      # Game scenes
│   ├── entities/    # Ships, enemies, bosses
│   ├── ui/          # Interface
│   └── utils/       # Helper functions
├── libs/            # Third-party libraries
├── maps/            # Tiled maps
├── main.lua         # Entry point
├── conf.lua         # Configuration
└── README.md        # Documentation
```

---

## 📜 Лицензия / License

Copyright (C) 2025 maredhat

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

---

**Cosmos Craft** — 2025 | [GitHub Repository](https://github.com/maredhat/cosmoscraft)
