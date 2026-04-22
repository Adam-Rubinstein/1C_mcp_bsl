# MCP справки платформы 1С в Cursor

Репозиторий для **личного** использования: **Cursor** + MCP‑сервер, который читает **справку установленной платформы** **1С:Предприятие** по пути `--platform-path` (встроенный язык и объектная модель, без доступа к вашим базам).

Здесь в одном месте: **готовый JAR** (`dist/1C_mcp_bsl.jar`), **исходники сервера** (Kotlin / Gradle в корне), шаблоны **`.cursor/`** и **документация**. Прикладной код ERP, выгрузки конфигурации и т.п. **в этот репозиторий не входят** (см. `.gitignore`).

**Пошаговая установка**, проверка из терминала, `mcp.json`, типичные ошибки — **[`documentation/`](documentation/README.md)**.

**В Cursor** достаточно написать: **«установи mcp»** и при желании **ссылку на репозиторий** (по умолчанию **`https://github.com/Adam-Rubinstein/1C_mcp_bsl`**).

- В **этом** репозитории срабатывает проектное правило **`.cursor/rules/use-1c-platform-mcp.mdc`**: агент запускает скрипт или однострочник с **raw.githubusercontent.com** и подставляет корень workspace как **`-WorkspaceRoot`**.
- В **любом другом** проекте **один раз** добавьте в **Cursor → Settings → Rules** текст из **[`documentation/cursor-user-rule-snippet.txt`](documentation/cursor-user-rule-snippet.txt)** — после этого та же фраза и ссылка работают без файлов из репо в проекте. После первой установки в проект копируется **`use-1c-platform-mcp.mdc`**, можно обойтись без глобального правила.

После успеха: **Reload Window**.

Ниже — краткий обзор и быстрый старт.

### Что делает MCP‑сервер `1c-platform` (после настройки)

Это **не** часть 1С и **не** доступ к вашей базе данных. Отдельная программа (JAR), которую запускает Cursor:

- читает **файлы справки установленной платформы** 1С по пути `--platform-path` (аналог опоры на «Синтаксис‑помощник», но из файлов на диске);
- по запросам ассистента отвечает инструментами **`search`**, **`info`**, **`getMember`**, **`getMembers`**, **`getConstructors`** — поиск и описания встроенных функций, методов, свойств, типов и конструкторов;
- **не выполняет** прикладной код и **не меняет** конфигурацию — только помогает **писать и проверять BSL** по справке выбранной версии платформы.

Бинарник **`dist/1C_mcp_bsl.jar`** лежит **в самом репозитории** (после клона или скачивания архива с GitHub). Сборка **`./gradlew bootJar`** даёт **`build/libs/1C_mcp_bsl.jar`**. Установка 1С по-прежнему **отдельно** на машине. Тот же JAR публикуется в **[Releases на GitHub](https://github.com/Adam-Rubinstein/1C_mcp_bsl/releases)** (например **[v1.0.0](https://github.com/Adam-Rubinstein/1C_mcp_bsl/releases/tag/v1.0.0)** — вложение **`1C_mcp_bsl.jar`**); без клона репозитория удобно скачать оттуда.

---

## Состав репозитория

| Путь | Назначение |
|------|------------|
| [`documentation/README.md`](documentation/README.md) | Оглавление подробной документации. |
| [`documentation/INSTALL.md`](documentation/INSTALL.md) | Установка: требования, JAR, терминал, Cursor, пути. |
| [`documentation/cursor-user-rule-snippet.txt`](documentation/cursor-user-rule-snippet.txt) | Текст для **Cursor → Rules** — «установи mcp» в любом проекте без локального `.cursor/rules`. |
| [`documentation/CLI.md`](documentation/CLI.md) | Опции JAR, лог, кратко про инструменты MCP. |
| [`documentation/TROUBLESHOOTING.md`](documentation/TROUBLESHOOTING.md) | Типичные сбои и исправления. |
| [`documentation/SOURCE.md`](documentation/SOURCE.md) | Сборка JAR из корня репозитория (Gradle). |
| [`scripts/install-mcp.ps1`](scripts/install-mcp.ps1), [`scripts/install-mcp.sh`](scripts/install-mcp.sh) | Автоустановка **`.cursor/mcp.json`**: поиск Java, JAR (`dist/` или GitHub Release), `--platform-path` (типичные каталоги 1С). |
| [`.cursor/mcp.json.example`](.cursor/mcp.json.example) | Шаблон `mcp.json`: сервер `1c-platform`, `java`, JAR, `--platform-path`. |
| [`.cursor/rules/use-1c-platform-mcp.mdc`](.cursor/rules/use-1c-platform-mcp.mdc) | Правило Cursor: когда вызывать MCP и **точные имена** инструментов. |
| [`README.md`](README.md) | Краткий обзор и быстрый старт. |
| [`LICENSE`](LICENSE) | Лицензия MIT (тексты и шаблоны этого репозитория). |
| [`.gitignore`](.gitignore) | Локальный `.cursor/mcp.json`, каталоги ERP и прочие правила Cursor. |
| [`dist/1C_mcp_bsl.jar`](dist/1C_mcp_bsl.jar) | Готовый JAR в **`dist/`** (основной способ взять файл). Сборка: `.\gradlew.bat bootJar` → **`build/libs/1C_mcp_bsl.jar`**. |
| [`src/`](src/), [`build.gradle.kts`](build.gradle.kts), [`gradlew.bat`](gradlew.bat) | **Исходники** MCP‑сервера (Kotlin, Gradle) в корне — правка и сборка (`.\gradlew.bat build`). |
| [`.github/workflows/release-jar.yml`](.github/workflows/release-jar.yml) | При push тега `v*.*.*` (и включённых Actions) публикуется **[GitHub Release](https://github.com/Adam-Rubinstein/1C_mcp_bsl/releases)** с **`1C_mcp_bsl.jar`**. |
| [`.github/workflows/platform-ci.yml`](.github/workflows/platform-ci.yml) | CI: сборка, тесты (при наличии секретов 1С), Docker (dry-run), анализ зависимостей. |
| [`.github/workflows/platform-release.yml`](.github/workflows/platform-release.yml) | Вручную: полный конвейер с платформой 1С и publish в GitHub Packages. |

Локальный файл **`.cursor/mcp.json`** создаётся у себя на машине (копия из примера с подставленными путями) и **не коммитится**.

### Как встроить в свой проект с кодом 1С

1. Склонируйте этот репозиторий **или** скопируйте из него в свой проект файлы: `.cursor/mcp.json.example`, `.cursor/rules/use-1c-platform-mcp.mdc`.
2. В корне **вашего** проекта создайте `.cursor/mcp.json` по образцу примера (см. раздел 5).
3. Убедитесь, что в каталоге `.cursor/rules/` вашего проекта лежит **`use-1c-platform-mcp.mdc`** (и что в настройках Cursor включены project rules).

---

## Что нужно на машине

1. **1С:Предприятие** — установленная платформа **8.3** (рекомендуется не ниже 8.3.20). Нужен каталог установки с подкаталогами вроде `bin`, `docs` (корень платформы для параметра `--platform-path`).
2. **Java (JDK) 17 или новее** — 64-bit. После установки команда `java -version` в новом терминале должна находиться в `PATH`.
3. **Cursor** — редактор с поддержкой MCP.
4. **JAR MCP-сервера** — один исполняемый **fat JAR** (`1C_mcp_bsl.jar` в этом репозитории в `dist/`), в режиме stdio подключается к Cursor и читает справку из каталога установки платформы 1С. В `mcp.json` укажите **свой** полный путь к файлу.

Положите JAR в каталог **без кириллицы**, например:

`C:\Tools\1C_mcp_bsl\1C_mcp_bsl.jar`

---

## Быстрый старт (новый разработчик)

### 1. Клонировать репозиторий

```powershell
git clone https://github.com/Adam-Rubinstein/1C_mcp_bsl.git
cd 1C_mcp_bsl
```

История в **`main`** намеренно **одним коммитом** (`init`) — без длинной цепочки прошлых правок.

### 2. JDK и проверка Java

Установите JDK 17+ (дистрибутив на выбор организации). Проверка:

```powershell
java -version
```

Должна отображаться версия **17** или выше.

### 3. JAR MCP-сервера

Подробно: **[`documentation/INSTALL.md`](documentation/INSTALL.md)** (откуда взять файл, куда положить, проверка).

Скопируйте JAR в выбранный каталог (см. выше). Убедитесь, что файл существует по полному пути.

Проверка запуска (подставьте **свои** пути к JAR и к корню платформы):

```powershell
java '-Dfile.encoding=UTF-8' -jar "C:\Tools\1C_mcp_bsl\1C_mcp_bsl.jar" --platform-path "C:\Program Files\1cv8\8.3.27.1719" --help
```

В **PowerShell** аргумент `-Dfile.encoding=UTF-8` нужно передавать **в кавычках**, иначе строка разбирается неверно. В `mcp.json` каждый элемент `args` — отдельный аргумент, там кавычки для этого не нужны.

Ожидается текст справки по опциям (`--platform-path`, `--help` и т.д.), без ошибки «Could not find or load main class».

### 4. Каталог платформы 1С (`--platform-path`)

Укажите **корень** конкретной установленной версии платформы — ту папку, где лежат `bin` и `docs`.

Типичные варианты на Windows:

- `C:\Program Files\1cv8\8.3.xx.xxxx`
- при нескольких версиях выберите ту, по которой нужна справка.

Если путь содержит пробелы — в JSON используйте прямые слэши или экранированные обратные, как в примере.

### 5. Файл `.cursor/mcp.json`

В корне проекта в каталоге `.cursor` создайте файл **`mcp.json`** (его нет в Git намеренно).

Скопируйте содержимое из **`.cursor/mcp.json.example`** и замените плейсхолдеры:

- путь к **JAR**;
- значение **`--platform-path`** — корень платформы 1С.

**Важно для Cursor на Windows:** процесс редактора часто **не наследует** обновлённый системный `PATH`. Если в настройках MCP статус красный и в логе фигурирует `java`, а в терминале `java` работает — в поле **`command`** укажите **полный путь** к `java.exe`, например:

`C:/Program Files/Eclipse Adoptium/jdk-17.0.18.8-hotspot/bin/java.exe`

(путь зависит от установленного JDK и версии каталога).

Опционально в `mcp.json` в блоке `env` можно задать **`LOG_FILE`** — путь к лог-файлу сервера (каталог лучше без кириллицы).

### 6. Cursor: перезагрузка и проверка MCP

1. Команда палитры: **Developer: Reload Window**.
2. **Settings → Tools & MCPs** (или аналогичный раздел MCP).
3. Сервер с именем **`1c-platform`** должен быть включён; индикатор **зелёный**; видны инструменты: `search`, `info`, `getMember`, `getMembers`, `getConstructors`.

### 7. Правило для агента

Файл **`use-1c-platform-mcp.mdc`** положите в **`.cursor/rules/`** того проекта, где вы пишете **BSL**. В нём зафиксировано: при вопросах по встроенному языку и объектной модели платформы сначала вызывать MCP **`1c-platform`** с именами инструментов из таблицы ниже.

---

## MCP: имена инструментов (строго)

Используйте только эти имена при вызове из агента (регистр важен):

| Имя | Назначение |
|-----|------------|
| `search` | Поиск по API: `query` (обязательно); опционально `type` (`method`, `property`, `type`), `limit` (1–50). |
| `info` | Детальная справка: `name` (обязательно); опционально `type`. |
| `getMember` | Метод или свойство типа: `typeName`, `memberName`. |
| `getMembers` | Все методы и свойства типа: `typeName`. |
| `getConstructors` | Конструкторы / способы создания: `typeName`. |

Откуда берутся данные справки: сервер **читает файлы справки** из каталога платформы, переданного в `--platform-path` (в типовой поставке это связано с содержимым вроде каталога `docs` внутри корня версии). Смена версии в `--platform-path` меняет источник справки.

---

## Git и GitHub

В Git попадают файлы из таблицы «Состав репозитория» (в т.ч. **`dist/1C_mcp_bsl.jar`**, **`.github/workflows/`**, **`documentation/`**, **`src/`**). Каталоги вроде `ext-ad/`, `base-conf/`, `docs/` в **`.gitignore`** — не коммитятся. Локальный **`.cursor/mcp.json`** тоже не в репозитории.

**Первый пуш** (создали пустой репозиторий на GitHub и инициализировали Git локально — не клонировали готовый `1C_mcp_bsl`):

```powershell
git remote add origin https://github.com/<ваш-логин>/<имя-репо>.git
git branch -M main
git push -u origin main
```

**GitHub Release:** при включённых **Actions** и push тега **`v*.*.*`** срабатывает **`release-jar.yml`** — см. **[Releases](https://github.com/Adam-Rubinstein/1C_mcp_bsl/releases)** (текущий стабильный пример: **[v1.0.0](https://github.com/Adam-Rubinstein/1C_mcp_bsl/releases/tag/v1.0.0)** с вложением **`1C_mcp_bsl.jar`**). Альтернатива без Releases — **`dist/1C_mcp_bsl.jar`** в репозитории после клона.

**CI (`platform-ci.yml`):** job **`test`** всегда стартует; шаги с установкой платформы 1С и **`./gradlew test`** выполняются только при секретах **`ONEC_USERNAME`** и **`ONEC_PASSWORD`**. Без них выводится поясняющий шаг, остальные jobs (сборка JAR, Docker dry-run и т.д.) не затрагиются.

### Настройки Cursor

В корне репозитория каталог **`.cursor/`** — шаблон **`mcp.json.example`**, правило **`use-1c-platform-mcp.mdc`** и др. Локальный **`mcp.json`** по-прежнему не коммитится (см. `.gitignore`).

---

## Краткий чеклист «всё работает»

- [ ] `java -version` — 17+  
- [ ] JAR на диске, `--help` с `--platform-path` отрабатывает  
- [ ] Создан `.cursor/mcp.json` из примера, при необходимости полный путь к `java.exe`  
- [ ] Reload Window в Cursor, MCP **`1c-platform`** зелёный  
- [ ] В чате с `.bsl` запрос вида: через `search` найти метод / через `info` уточнить сигнатуру  

Если что-то ломается — **[`documentation/TROUBLESHOOTING.md`](documentation/TROUBLESHOOTING.md)**.
