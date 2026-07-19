# L4D2 Homelander Laser Eyes

**SourceMod plugin for Left 4 Dead 2 dedicated servers.**

This plugin gives survivors Homelander-style laser vision: powerful colored beams, custom sounds, survivor voice lines, damage, ignite effects, and server-side configuration through ConVars.

> This is the **server plugin version**.  
> It is meant for dedicated servers running SourceMod.  
> For local/Workshop-only play, use the VScript Workshop addon version instead.

---

## Features

- Laser beam ability for survivors
- Hold-to-fire command support
- Survivor-colored beams
- Custom laser start / loop / stop sounds
- Survivor voice lines on laser start
- Damage against:
  - common infected
  - special infected
  - Tanks
  - Witches
  - survivors, if friendly fire is enabled
- Optional ignite effect
- Configurable cooldown
- Configurable damage values
- Configurable beam width and color
- Works server-side through SourceMod
- Includes `.sp` source and `.cfg` config

---

## Requirements

- Left 4 Dead 2 dedicated server
- SourceMod 1.11 or newer recommended
- MetaMod:Source
- Basic FastDL or Workshop/server download setup if you use custom sounds

No Left4DHooks requirement is intended for the basic version.

---

## Installation

Put the files into your server:

```text
left4dead2/addons/sourcemod/plugins/l4d2_homelander_laser.smx
left4dead2/addons/sourcemod/scripting/l4d2_homelander_laser.sp
left4dead2/cfg/sourcemod/l4d2_homelander_laser.cfg
```

If you use custom sounds, place them here:

```text
left4dead2/sound/homelaser/laser_start.mp3
left4dead2/sound/homelaser/laser_loop_long.mp3
left4dead2/sound/homelaser/laser_stop.mp3
```

Then restart the server or load the plugin manually:

```text
sm plugins load l4d2_homelander_laser
```

---

## Player Bind

Recommended bind:

```text
bind "MOUSE5" "+homelaser"
```

You can also bind any other key:

```text
bind "v" "+homelaser"
```

---

## Commands

```text
+homelaser
-homelaser
sm_hlaser
sm_homelaser
sm_laser
```

`+homelaser` and `-homelaser` are intended for hold-to-fire binds.

---

## Important ConVars

The config file is generated/loaded from:

```text
cfg/sourcemod/l4d2_homelander_laser.cfg
```

### Enable / cooldown

```text
l4d_homelaser_enabled "1"
l4d_homelaser_cooldown "3.0"
```

Set cooldown to `0.0` if you want players to fire again immediately.

```text
l4d_homelaser_cooldown "0.0"
```

### Damage

```text
l4d_homelaser_damage_common "75.0"
l4d_homelaser_damage_si "45.0"
l4d_homelaser_damage_tank "30.0"
l4d_homelaser_damage_witch "45.0"
```

These values are applied repeatedly while the beam is active, so do not make them too high unless you want an overpowered laser.

### Fire / ignite

```text
l4d_homelaser_ignite "1"
l4d_homelaser_ignite_time "2.0"
```

Set `l4d_homelaser_ignite` to `0` to disable fire effects.

### Friendly fire

```text
l4d_homelaser_friendlyfire "0"
```

Set to `1` if you want the laser to damage other survivors.

### Beam size

```text
l4d_homelaser_beam_width "5.0"
l4d_homelaser_beam_end_width "2.0"
```

For a thinner beam:

```text
l4d_homelaser_beam_width "2.0"
l4d_homelaser_beam_end_width "0.8"
```

### Beam color

```text
l4d_homelaser_survivor_beam_colors "1"
```

When enabled, every survivor can have a different beam color.

Example colors:

```text
l4d_homelaser_color_coach "180 0 255"
l4d_homelaser_color_nick "0 80 255"
l4d_homelaser_color_rochelle "255 40 170"
l4d_homelaser_color_bill "0 255 70"
l4d_homelaser_color_francis "255 220 0"
l4d_homelaser_color_louis "255 255 255"
l4d_homelaser_color_zoey "255 0 0"
l4d_homelaser_color_ellis "255 0 0"
```

---

## Custom Sounds

Recommended paths:

```text
sound/homelaser/laser_start.mp3
sound/homelaser/laser_loop_long.mp3
sound/homelaser/laser_stop.mp3
```

Recommended audio format:

```text
MP3 or WAV
44100 Hz
Mono
Reasonable bitrate
```

If looped MP3 audio has gaps, use a longer loop file and set the loop interval slightly below the file duration.

Example:

```text
l4d_homelaser_sound_loop "homelaser/laser_loop_long.mp3"
l4d_homelaser_loop_interval "29.5"
```

---

## Survivor Voice Lines

The plugin can play survivor voice lines when the laser starts.

Example paths are relative to the `sound/` folder:

```text
player/survivor/voice/mechanic/battlecry01.wav
player/survivor/voice/coach/battlecry01.wav
player/survivor/voice/gambler/battlecry01.wav
```

Do **not** include the full game folder in the path.

Correct:

```text
player/survivor/voice/mechanic/battlecry01.wav
```

Wrong:

```text
left4dead2_russian/sound/player/survivor/voice/mechanic/battlecry01.wav
```

---

## Compiling

Place the `.sp` file in:

```text
left4dead2/addons/sourcemod/scripting/
```

Compile with:

```text
spcomp.exe l4d2_homelander_laser.sp
```

On Windows, avoid adding a trailing slash to the output file path.

Correct:

```text
spcomp.exe l4d2_homelander_laser.sp -o compiled\l4d2_homelander_laser.smx
```

Wrong:

```text
spcomp.exe l4d2_homelander_laser.sp -o compiled\l4d2_homelander_laser.smx\
```

---

## Notes for Server Owners

This plugin is intentionally powerful by default. For public servers, consider reducing:

```text
l4d_homelaser_damage_tank
l4d_homelaser_damage_si
l4d_homelaser_ignite_time
```

For fun/sandbox servers, cooldown can be disabled:

```text
l4d_homelaser_cooldown "0.0"
```

For more serious balance, use:

```text
l4d_homelaser_cooldown "5.0"
l4d_homelaser_friendlyfire "0"
```

---

## Troubleshooting

### The sound does not play

Check that the file exists on the server:

```text
left4dead2/sound/homelaser/laser_start.mp3
left4dead2/sound/homelaser/laser_loop_long.mp3
left4dead2/sound/homelaser/laser_stop.mp3
```

Also check client download/FastDL configuration if clients need custom sounds.

### The beam is too thick

Lower:

```text
l4d_homelaser_beam_width
l4d_homelaser_beam_end_width
```

### The laser is too strong

Lower the damage values or increase cooldown.

### Survivors hurt each other

Set:

```text
l4d_homelaser_friendlyfire "0"
```

---

## Repository Structure

Recommended GitHub layout:

```text
.
├── addons/
│   └── sourcemod/
│       └── scripting/
│           └── l4d2_homelander_laser.sp
├── cfg/
│   └── sourcemod/
│       └── l4d2_homelander_laser.cfg
├── sound/
│   └── homelaser/
│       └── README.txt
└── README.md
```

Compiled `.smx` files can be uploaded under GitHub Releases.

---

## License

Choose a license before publishing the repository.

Recommended options:

- MIT License, if you want people to freely modify and reuse the code
- GPLv3, if you want modified versions to remain open-source
- No license, if you do not want to grant reuse rights by default

---

# RU — L4D2 Homelander Laser Eyes

**SourceMod-плагин для выделенных серверов Left 4 Dead 2.**

Плагин добавляет выжившим лазерное зрение в стиле Homelander: цветные лучи, кастомные звуки, voice-фразы, урон, поджигание и настройку через серверные ConVars.

> Это **серверная SourceMod-версия**.  
> Она предназначена для dedicated servers.  
> Для локальной игры через Workshop нужна VScript-версия аддона.

---

## Возможности

- Лазерная способность для выживших
- Поддержка hold-to-fire команды
- Разные цвета лучей для разных выживших
- Кастомные звуки старта, удержания и остановки лазера
- Voice-фразы выживших при запуске лазера
- Урон по:
  - обычным заражённым
  - особым заражённым
  - Танкам
  - Ведьмам
  - выжившим, если включён friendly fire
- Поджигание целей
- Настраиваемый кулдаун
- Настраиваемый урон
- Настраиваемая ширина и цвет луча
- Полностью серверная работа через SourceMod
- В комплекте `.sp` исходник и `.cfg` конфиг

---

## Требования

- Left 4 Dead 2 dedicated server
- SourceMod 1.11 или новее
- MetaMod:Source
- FastDL или другой способ загрузки файлов, если используются кастомные звуки

Для базовой версии Left4DHooks не требуется.

---

## Установка

Разложите файлы на сервере:

```text
left4dead2/addons/sourcemod/plugins/l4d2_homelander_laser.smx
left4dead2/addons/sourcemod/scripting/l4d2_homelander_laser.sp
left4dead2/cfg/sourcemod/l4d2_homelander_laser.cfg
```

Если используете кастомные звуки:

```text
left4dead2/sound/homelaser/laser_start.mp3
left4dead2/sound/homelaser/laser_loop_long.mp3
left4dead2/sound/homelaser/laser_stop.mp3
```

После этого перезапустите сервер или загрузите плагин вручную:

```text
sm plugins load l4d2_homelander_laser
```

---

## Bind для игрока

Рекомендуемый bind:

```text
bind "MOUSE5" "+homelaser"
```

Можно использовать любую удобную кнопку:

```text
bind "v" "+homelaser"
```

---

## Команды

```text
+homelaser
-homelaser
sm_hlaser
sm_homelaser
sm_laser
```

`+homelaser` и `-homelaser` предназначены для удержания кнопки.

---

## Основные ConVars

Конфиг находится здесь:

```text
cfg/sourcemod/l4d2_homelander_laser.cfg
```

### Включение и кулдаун

```text
l4d_homelaser_enabled "1"
l4d_homelaser_cooldown "3.0"
```

Чтобы отключить кулдаун:

```text
l4d_homelaser_cooldown "0.0"
```

### Урон

```text
l4d_homelaser_damage_common "75.0"
l4d_homelaser_damage_si "45.0"
l4d_homelaser_damage_tank "30.0"
l4d_homelaser_damage_witch "45.0"
```

Урон применяется многократно, пока луч активен, поэтому не ставьте слишком большие значения, если нужен баланс.

### Поджигание

```text
l4d_homelaser_ignite "1"
l4d_homelaser_ignite_time "2.0"
```

Чтобы отключить огонь:

```text
l4d_homelaser_ignite "0"
```

### Friendly fire

```text
l4d_homelaser_friendlyfire "0"
```

Поставьте `1`, если хотите разрешить урон по другим выжившим.

### Размер луча

```text
l4d_homelaser_beam_width "5.0"
l4d_homelaser_beam_end_width "2.0"
```

Тонкий луч:

```text
l4d_homelaser_beam_width "2.0"
l4d_homelaser_beam_end_width "0.8"
```

### Цвета луча

```text
l4d_homelaser_survivor_beam_colors "1"
```

Пример цветов:

```text
l4d_homelaser_color_coach "180 0 255"
l4d_homelaser_color_nick "0 80 255"
l4d_homelaser_color_rochelle "255 40 170"
l4d_homelaser_color_bill "0 255 70"
l4d_homelaser_color_francis "255 220 0"
l4d_homelaser_color_louis "255 255 255"
l4d_homelaser_color_zoey "255 0 0"
l4d_homelaser_color_ellis "255 0 0"
```

---

## Кастомные звуки

Рекомендуемые пути:

```text
sound/homelaser/laser_start.mp3
sound/homelaser/laser_loop_long.mp3
sound/homelaser/laser_stop.mp3
```

Рекомендуемый формат:

```text
MP3 или WAV
44100 Hz
Mono
Нормальный bitrate
```

Если у MP3-loop есть пауза, используйте длинный loop-файл и поставьте интервал чуть меньше длительности файла.

Пример:

```text
l4d_homelaser_sound_loop "homelaser/laser_loop_long.mp3"
l4d_homelaser_loop_interval "29.5"
```

---

## Voice-фразы выживших

Плагин может проигрывать voice-фразы выживших при старте лазера.

Пути указываются относительно папки `sound/`:

```text
player/survivor/voice/mechanic/battlecry01.wav
player/survivor/voice/coach/battlecry01.wav
player/survivor/voice/gambler/battlecry01.wav
```

Правильно:

```text
player/survivor/voice/mechanic/battlecry01.wav
```

Неправильно:

```text
left4dead2_russian/sound/player/survivor/voice/mechanic/battlecry01.wav
```

---

## Компиляция

Положите `.sp` файл сюда:

```text
left4dead2/addons/sourcemod/scripting/
```

Компиляция:

```text
spcomp.exe l4d2_homelander_laser.sp
```

На Windows не добавляйте слэш в конце output-пути.

Правильно:

```text
spcomp.exe l4d2_homelander_laser.sp -o compiled\l4d2_homelander_laser.smx
```

Неправильно:

```text
spcomp.exe l4d2_homelander_laser.sp -o compiled\l4d2_homelander_laser.smx\
```

---

## Рекомендации владельцам серверов

Плагин специально сделан довольно мощным. Для публичных серверов лучше уменьшить:

```text
l4d_homelaser_damage_tank
l4d_homelaser_damage_si
l4d_homelaser_ignite_time
```

Для фан-серверов можно отключить кулдаун:

```text
l4d_homelaser_cooldown "0.0"
```

Для более аккуратного баланса:

```text
l4d_homelaser_cooldown "5.0"
l4d_homelaser_friendlyfire "0"
```

---

## Решение проблем

### Нет звука

Проверьте, что файлы реально лежат на сервере:

```text
left4dead2/sound/homelaser/laser_start.mp3
left4dead2/sound/homelaser/laser_loop_long.mp3
left4dead2/sound/homelaser/laser_stop.mp3
```

Также проверьте FastDL/загрузку файлов для клиентов.

### Луч слишком толстый

Уменьшите:

```text
l4d_homelaser_beam_width
l4d_homelaser_beam_end_width
```

### Лазер слишком сильный

Уменьшите урон или увеличьте кулдаун.

### Выжившие дамажат друг друга

Поставьте:

```text
l4d_homelaser_friendlyfire "0"
```

---

## Структура репозитория

Рекомендуемая структура для GitHub:

```text
.
├── addons/
│   └── sourcemod/
│       └── scripting/
│           └── l4d2_homelander_laser.sp
├── cfg/
│   └── sourcemod/
│       └── l4d2_homelander_laser.cfg
├── sound/
│   └── homelaser/
│       └── README.txt
└── README.md
```

Скомпилированный `.smx` лучше добавлять в GitHub Releases.

---
