# Cosmos Craft

**Космический экшен с элементами RPG на LÖVE2D**

---

## О проекте

**RU**  
Cosmos Craft — моя первая полноценная игра на движке LÖVE2D. Это космический экшен, где вы начинаете с простого корабля и постепенно прокачиваете его до неуязвимой машины. Вас ждут битвы с боссами, система крафта, улучшение оружия и прокачка корабля по тирам. В планах — кооперативный режим и собственные серверы для мультиплеера.

**EN**  
Cosmos Craft is my first full-fledged game built with the LÖVE2D engine. It's a space action game where you start with a basic ship and gradually upgrade it into an unstoppable machine. Features include boss battles, crafting system, weapon upgrades, and ship tier progression. Co-op mode and dedicated servers are planned for the future.

---

## Геймплей

- 🚀 Улучшение корабля и оружия
- 👾 Битвы с уникальными боссами
- ⚙️ Крафт предметов из ресурсов
- 📈 Прокачка тиров корабля
- 💎 Сбор ресурсов с врагов
- 🌌 Исследование космоса

---

## Системные требования

- **LÖVE2D 11.4** или новее
- **OpenGL 2.1**+
- **512 МБ ОЗУ**
- **Любая ОС**: Windows, macOS, Linux

---

## Запуск игры

### Вариант 1: Готовый билд (релизы)

1. Перейдите в раздел **[Releases](https://github.com/yourusername/cosmos-craft/releases)**
2. Скачайте последнюю версию для вашей ОС
3. Распакуйте архив
4. Запустите исполняемый файл

### Вариант 2: Запуск из исходников

```bash
# Клонируем репозиторий
git clone https://github.com/yourusername/cosmos-craft.git

# Переходим в папку игры
cd cosmos-craft

# Запускаем через LÖVE
love .
```

### Вариант 3: Сборка .love файла

```bash
# Создаём архив
zip -r cosmos-craft.love * -x "*.git*" "*.psd" "*.ai"

# Запускаем
love cosmos-craft.love
```

### Сборка .exe для Windows

```bash
# Требуется love.exe в той же папке
copy /b love.exe+cosmos-craft.love CosmosCraft.exe
```

---

## Управление

| Клавиша | Действие |
|---------|----------|
| W/A/S/D | Движение |
| Space | Стрельба |
| E | Взаимодействие / сбор |
| I | Инвентарь |
| C | Крафт |
| Tab | Карта |
| Esc | Пауза / меню |

---

## Технический стек

- **Движок:** LÖVE2D 11.4
- **Язык:** Lua 5.1
- **Основные библиотеки:**
  - Anim8 — анимации
  - Windfield — физика (в разработке)
  - STI — карты Tiled

---

## Структура проекта

```
cosmos-craft/
├── assets/          # Графика, шрифты, звуки
├── src/             # Исходный код
│   ├── scenes/      # Сцены (меню, игра, боссы)
│   ├── entities/    # Корабли, враги, боссы
│   ├── ui/          # Интерфейс
│   └── utils/       # Вспомогательные функции
├── libs/            # Сторонние библиотеки
├── maps/            # Карты Tiled
├── main.lua         # Точка входа
├── conf.lua         # Конфигурация
└── README.md        # Документация
```

---

## Планы разработки

**Ближайшие задачи:**
- [x] Базовая механика движения и стрельбы
- [ ] Система улучшений корабля
- [ ] Первый босс
- [ ] Инвентарь и крафт
- [ ] Ресурсы и добыча

**В будущем:**
- [ ] Кооперативный режим
- [ ] Выделенные серверы
- [ ] PvP-арены
- [ ] Торговая система

---

## Как помочь проекту

- Сообщайте об ошибках в разделе **Issues**
- Предлагайте идеи через **Discussions**
- Делайте пулл-реквесты с исправлениями
- Рисуйте спрайты (нужен пиксель-арт)
- Пишите музыку (космический эмбиент)

---

## Лицензия

Проект распространяется под лицензией **MIT**. Подробнее в файле LICENSE.

---

## Контакты

- **GitHub:** [github.com/yourusername/cosmos-craft](https://github.com/yourusername/cosmos-craft)
- **Автор:** [Ваше имя]
- **Telegram:** [@yourusername](https://t.me/yourusername)
- **Email:** your.email@example.com

---

**Cosmos Craft** — 2025