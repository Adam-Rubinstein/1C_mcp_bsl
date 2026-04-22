# Установка MCP-сервера справки 1С для Cursor

Документ для **личного** использования: пошаговая установка.

## 1. Требования

| Компонент | Минимум |
|-----------|---------|
| ОС | Windows, Linux или macOS |
| Java | JDK **17+** (64-bit) |
| 1С:Предприятие | Платформа **8.3** (рекомендуется не ниже 8.3.20), установленная на машине |
| Cursor | Версия с поддержкой MCP (stdio) |
| Файл сервера | Один **fat JAR** (`1C_mcp_bsl.jar`) |

## 2. Откуда взять JAR

1. **Из репозитория (клон или ZIP с GitHub)** — файл **`dist/1C_mcp_bsl.jar`** уже лежит в дереве проекта; скопируйте его в удобный каталог (см. ниже).
2. **Сборка у себя** — из **корня** репозитория: `.\gradlew.bat bootJar` (Windows) или `./gradlew bootJar` (Linux/macOS); результат — **`build/libs/1C_mcp_bsl.jar`** (см. [SOURCE.md](SOURCE.md)).
3. **Уже лежит на ПК** — укажите полный путь в `mcp.json`.

**Про раздел Releases на GitHub:** у проекта **может не быть** ни одного релиза — это нормально. JAR для работы берите из **`dist/`** или из сборки. Отдельный **GitHub Release** с вложением появится **только если** в репозитории включены **Actions** и кто-то запушит тег вида **`v*.*.*`** (workflow **`release-jar.yml`**); до этого страница Releases будет пустой.

Положите файл в каталог **без кириллицы** в пути, например:

`C:\Tools\1C_mcp_bsl\1C_mcp_bsl.jar`

Путь (и имя файла) в `mcp.json` должны **точно** указывать на ваш JAR на диске; в этом репозитории стабильное имя артефакта — **`1C_mcp_bsl.jar`**.

## 3. Проверка JAR из терминала

### Windows (PowerShell)

```powershell
java '-Dfile.encoding=UTF-8' -jar "C:\Tools\1C_mcp_bsl\1C_mcp_bsl.jar" --platform-path "C:\Program Files\1cv8\8.3.27.1719" --help
```

В PowerShell строку **`-Dfile.encoding=UTF-8`** обязательно брать **в кавычках**.

### Linux / macOS (пример)

```bash
java -Dfile.encoding=UTF-8 -jar /opt/mcp/1C_mcp_bsl.jar --platform-path "/opt/1cv8/x86_64/8.3.25.1257" --help
```

`--platform-path` — **корень** установки версии платформы (рядом должны быть каталоги вроде `bin`, `docs`).

Ожидается вывод справки по опциям без ошибки JVM.

## 4. Подключение в Cursor

1. Скопируйте [`.cursor/mcp.json.example`](../.cursor/mcp.json.example) в **`.cursor/mcp.json`** в корне того проекта, где работаете (или в глобальную конфигурацию MCP — по правилам Cursor).
2. Подставьте:
   - полный путь к **`java.exe`** (на Windows для Cursor часто нужен **абсолютный** путь, не только `java`);
   - полный путь к **JAR**;
   - **`--platform-path`** на ваш каталог платформы.
3. Положите [`.cursor/rules/use-1c-platform-mcp.mdc`](../.cursor/rules/use-1c-platform-mcp.mdc) в `.cursor/rules/` проекта с BSL.
4. **Developer: Reload Window** → **Settings → MCP** → сервер **`1c-platform`** должен быть зелёным.

Подробнее про опции JAR: [CLI.md](CLI.md).

## 5. Что не входит в эту установку

- Установка самой платформы 1С и лицензий на неё.
- Установка Cursor.
- Прикладная конфигурация / выгрузки ERP — в этом репозитории не версионируются.
