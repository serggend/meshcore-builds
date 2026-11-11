# Сборки MeshCore

Прошивки стационарных LoRa-репитеров на базе MeshCore 1.18.0. Скачивание начинается по ссылкам в таблице. [Все выпуски](https://github.com/serggend/meshcore-builds/releases)

| Плата | Репитер с консолью · v0.1.0-preview.1 | Репитер с BLE Companion · v0.2.0-preview.2 |
| --- | --- | --- |
| **Heltec WiFi LoRa 32 V4 OLED** | [Первая установка BIN](https://github.com/serggend/meshcore-builds/releases/download/v0.1.0-preview.1/heltec-v4-oled-repeater-connect-merged.bin) · [Обновление BIN](https://github.com/serggend/meshcore-builds/releases/download/v0.1.0-preview.1/heltec-v4-oled-repeater-connect-app.bin) | [Первая установка BIN](https://github.com/serggend/meshcore-builds/releases/download/v0.2.0-preview.2/heltec-v4-oled-repeater-companion-merged.bin) · [Обновление BIN](https://github.com/serggend/meshcore-builds/releases/download/v0.2.0-preview.2/heltec-v4-oled-repeater-companion-app.bin) |
| **FakeTec V4 · ProMicro nRF52840 + HT-RA62** | [Скачать UF2](https://github.com/serggend/meshcore-builds/releases/download/v0.1.0-preview.1/faketec-v4-repeater-connect.uf2) | [Скачать UF2](https://github.com/serggend/meshcore-builds/releases/download/v0.2.0-preview.2/faketec-v4-repeater-companion.uf2) |

Контрольные суммы SHA-256 для сборок. [репитер с консолью](https://github.com/serggend/meshcore-builds/releases/download/v0.1.0-preview.1/SHA256SUMS) · [репитер с Companion](https://github.com/serggend/meshcore-builds/releases/download/v0.2.0-preview.2/SHA256SUMS). [Инструкция по установке](#установка-и-откат)

### Какую сборку выбрать

| Профиль | Возможности | Что учесть |
| --- | --- | --- |
| Репитер с консолью | USB, BLE-терминал Nordic UART и Wi-Fi на Heltec. Подходит для стационарной работы с MeshDash, статистикой, объявлениями и Public | Меньше кода и расход статической ОЗУ. BLE работает в текстовом терминале |
| Репитер с BLE Companion | Штатное приложение MeshCore, контакты, личка и 40 слотов каналов. Остаются USB и Wi-Fi для MeshDash на Heltec | Примерно на 84 КиБ больше статической ОЗУ и на 33 КиБ больше кода в локальных сборках. Обе роли делят время одного LoRa-радиомодуля. Задержку и энергопотребление ещё надо измерить |

У FakeTec доступны USB и BLE, SSD1306 опционален. Для очередей Public и объявлений используй один экземпляр MeshDash на плату. Прошивки предварительные. Проверены сборка, формат файлов и отдельные сценарии на компьютере. Проверки с телефоном и реальными LoRa-нодами ещё впереди.

## Установка и откат

Скачай файл и контрольные суммы из одного столбца. Сверь SHA-256 нужного файла командой `shasum -a 256 ИМЯ_ФАЙЛА` со строкой в `SHA256SUMS`.

### Heltec V4 OLED

Для первой установки запиши объединённый образ по адресу `0x0`. Перед обновлением сохрани полный дамп флеша, сверь таблицу разделов и активный слот. Приложение по адресу `0x10000` предназначено для штатного слота `app0`. Запись только приложения в этот слот сохраняет разделы настроек.

Пример для esptool 4.x и Heltec с флешем 16 МиБ. Подставь порт платы вместо `PORT`. Для гибридной версии подставь имя скачанного файла с `-companion-`.

```sh
# Резервная копия
esptool.py --chip esp32s3 --port PORT read_flash 0x0 0x1000000 heltec-backup.bin

# Первая установка
esptool.py --chip esp32s3 --port PORT write_flash 0x0 heltec-v4-oled-repeater-connect-merged.bin

# Обновление приложения при штатном активном слоте app0
esptool.py --chip esp32s3 --port PORT write_flash 0x10000 heltec-v4-oled-repeater-connect-app.bin

# Откат из резервной копии той же платы
esptool.py --chip esp32s3 --port PORT write_flash 0x0 heltec-backup.bin
```

### FakeTec V4 в Windows

**Для установки и обновления достаточно скопировать UF2. Стирание флеша заранее не требуется.** Эта инструкция для FakeTec V4 с ProMicro nRF52840, HT-RA62 и UF2-загрузчиком с SoftDevice S140 6.1.1. [Документация платы FakeTec](https://github.com/gargomoma/fakeTec_pcb#bootloader)

1. Скачай UF2 для нужного профиля. Для обновления поверх прежней гибридной сборки выбери профиль BLE Companion. [Репитер с BLE Companion](https://github.com/serggend/meshcore-builds/releases/download/v0.2.0-preview.2/faketec-v4-repeater-companion.uf2) · [Репитер с консолью](https://github.com/serggend/meshcore-builds/releases/download/v0.1.0-preview.1/faketec-v4-repeater-connect.uf2)
2. Подключи плату к компьютеру USB-кабелем с передачей данных. Два раза подряд нажми Reset. Если кнопки нет, дважды кратко замкни подписанные контакты `RST` и `GND`.
3. Открой **Проводник → Этот компьютер**. Там появится USB-диск загрузчика, например `NICENANO`. Файл `INFO_UF2.TXT` на диске поможет сверить модель и версию загрузчика.
4. Скопируй скачанный `.uf2` на этот диск. Дождись, пока плата перезапустится. Исчезновение диска после копирования — нормальная часть обновления.
5. На гибридной сборке открой MeshCore и подключись к плате по BLE. Если нужно сверить ключ репитера, запиши результат `get public.key` в USB-консоли до обновления и сравни после него. При обновлении с предыдущей гибридной сборки UF2 записывает область приложения с адреса `0x26000`. Ключи, настройки, контакты и каналы находятся в отдельных областях флеша.

Если диск не появился, попробуй другой кабель с передачей данных или другой USB-порт и повтори двойной сброс. При повреждённом загрузчике сначала восстанови совместимый загрузчик ProMicro с SoftDevice через SWD по документации платы. Для отката через исправный загрузчик скопируй предыдущий совместимый UF2. [Восстановление загрузчика FakeTec](https://github.com/gargomoma/fakeTec_pcb#my-promicro-is-dead-what-can-i-do)

#### Когда нужен Erase Flash

`Erase Flash` на сайте MeshCore нужен для намеренного сброса данных, например если повреждённые настройки мешают запуску. Для обычного обновления сразу копируй UF2 прошивки. В официальном прошивальщике для **ProMicro nrf52 (faketec)** с SoftDevice **6.1.1** используется стиратель версии **v6**. Если нужен именно файл для USB-диска загрузчика, в официальном выпуске он называется `FLASH_ERASE_nrf52_softdevice_v6.uf2`. Этот стиратель форматирует InternalFS и ExtraFS. Ключи и настройки перед таким сбросом нужно сохранить отдельно. Полное стирание микросхемы через SWD также удаляет загрузчик. [Конфигурация прошивальщика MeshCore](https://github.com/meshcore-dev/flasher.meshcore.io/blob/main/config.json) · [Официальный стиратель MeshCore](https://github.com/meshcore-dev/nRF52-Flash-Format/releases/tag/v1.1)

## Настройка

Открой USB-терминал на 115200 бод с отправкой конца строки. Проверь `get role`, `get repeat` и `get radio`. Для администрирования через LoRa на новой плате задай пароль командой `password <пароль>`. Заводской пароль `password` отключается при запуске. Сверь частоту и параметры с радиопрофилем своей сети.

- **Wi-Fi на Heltec.** Введи `wifi set <IPv4 компьютера с MeshDash>|<SSID>|<пароль Wi-Fi>`. Команда `wifi status` покажет адрес репитера. Выбери TCP-транспорт репитера в MeshDash и порт `5001`. TCP работает в доверенной локальной сети без шифрования и принимает соединение от указанного IPv4. `wifi off` отключает Wi-Fi и удаляет сохранённые параметры.
- **BLE на обеих платах.** Введи `ble set <шесть цифр>`, затем `reboot`. Для консольной сборки в BLE-терминале выбери устройство `Repeater-…` и сервис Nordic UART. Включи уведомления TX и для проверки отправь `get role` с концом строки. `ble off` выключает BLE. Для изменения PIN достаточно USB, экран для настройки не требуется.

## Сборка из исходников

Скрипт загружает [зафиксированный снимок MeshCore 1.18.0](https://github.com/meshcore-dev/MeshCore/tree/81dbae592ffad40b4212bc0b37e82b38da08f4bc), накладывает [патч репитера](patches/repeater-connect.patch) и, для гибридного профиля, [патч Companion](patches/repeater-companion.patch). После тестов файлы появляются в `dist/repeater/` или `dist/companion/`. Версии библиотек указаны в [конфигурации выпуска](platformio.releases.ini). [Лицензии зависимостей](THIRD-PARTY.md)

```sh
python3 -m venv .venv
. .venv/bin/activate
python -m pip install platformio==6.2.0
./scripts/build.sh repeater
./scripts/build.sh companion
```

Нужны Git, curl и компилятор C++ с ASan и UBSan. [Сборки GitHub Actions](https://github.com/serggend/meshcore-builds/actions)

## Подключение из приложения MeshCore

Установи гибридную сборку. Задай PIN по USB командой `ble set <шесть цифр>` и введи `reboot`. В обычном MeshCore выбери устройство `MeshCore-…`. Для лички разошли объявление из приложения или поделись ключом Companion. Ключ репитера сохранится для маршрутов и удалённого управления. Частоту, мощность и PIN задавай в USB-консоли.

Телефон можно отключить. Репитер продолжит пересылку, а Companion будет принимать сообщения в очередь на 64 записи в ОЗУ до следующей синхронизации. Очередь очищается при перезагрузке. Выключение BLE командой `ble off` также выключает приём новых сообщений Companion. Очередь MeshDash живёт отдельно.

На FakeTec контакты и каналы Companion хранятся в ExtraFS по адресу `0xD4000`. Настройки и ключ репитера остаются в InternalFS. Для проверки версии на стенде нужны две внешние ноды и телефон. Сценарии включают двустороннюю личку с подтверждением, Public и закрытый канал, а также пересылку между внешними нодами до и после отключения телефона. [Протокол MeshCore Companion](https://docs.meshcore.io/companion_protocol/)
