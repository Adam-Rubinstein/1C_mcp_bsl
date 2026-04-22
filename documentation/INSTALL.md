# Установка MCP-сервера справки 1С для Cursor

Документ для **частного** использования: пошаговая установка без ссылок на сторонние репозитории в тексте.

## 1. Требования

| Компонент | Минимум |
|-----------|---------|
| ОС | Windows, Linux или macOS |
| Java | JDK **17+** (64-bit) |
| 1С:Предприятие | Платформа **8.3** (рекомендуется не ниже 8.3.20), установленная на машине |
| Cursor | Версия с поддержкой MCP (stdio) |
| Файл сервера | Один **fat JAR** (`1C_mcp_bsl.jar`) |

## 2. Откуда взять JAR

1. **GitHub Releases** — откройте **Releases** репозитория и скачайте приложенный **`1C_mcp_bsl.jar`**. Вложение появляется при push тега (например **`v1.0.0`**, см. корневой `README`) через workflow `.github/workflows/release-jar.yml` (**Actions** должны быть включены в настройках GitHub).
2. **Из клона репозитория** — готовый файл в **`dist/1C_mcp_bsl.jar`**, либо соберите сами из **корня репозитория** (Gradle, см. [SOURCE.md](SOURCE.md)).
3. **Уже есть на ПК** — укажите путь в `mcp.json`.

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
