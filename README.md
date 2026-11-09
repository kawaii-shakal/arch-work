# Arch-Work

Персональный образ Arch Linux x86-64 для WSL 2. В него входят твои настройки zsh, Oh My Zsh и Powerlevel10k, утилиты из `packages.txt` и инструменты из `mise.toml`.

## Установка

Скачай `arch-work.wsl` из GitHub Releases или возьми его из папки `dist` после локальной сборки. В PowerShell из папки с файлом запусти:

```powershell
wsl --install --from-file .\arch-work.wsl
```

Можно также открыть файл двойным кликом. При первом запуске `Arch-Work` предложит задать пароль для `sudo`. Он относится к Linux-пользователю `user`. Для Docker включи `Arch-Work` в **Docker Desktop → Settings → Resources → WSL Integration**, затем проверь `docker version` и `docker compose version` внутри WSL.

Рядом с образом лежит `arch-work.wsl.sha256`. Для сверки сравни первые 64 символа файла с результатом `(Get-FileHash .\arch-work.wsl).Hash`.

## Сборка и обновление списка

- `packages.txt` содержит по одному пакету Arch на строку. Пустые строки и строки, начинающиеся с `#`, пропускаются.
- `mise.toml` задаёт версии Go, golangci-lint, Terraform, kubectl и argocd. `latest` означает актуальную версию на момент сборки.
- `dotfiles/` содержит настройки оболочки. Настройки доступа к кластерам, ключи и токены подключаются отдельно после установки.

Для локальной сборки запусти Docker Desktop с Linux-контейнерами и выполни в PowerShell:

```powershell
.\build.ps1
```

Сборка сверяет контрольную сумму официального образа Arch, устанавливает инструменты и проверяет запуск zsh с ними. Результат появится в `dist/arch-work.wsl`. Сборка завершится ошибкой, если файл достигнет 2 ГиБ.

## GitHub Actions

Для проверочной сборки открой **Actions → Build Arch-Work → Run workflow**. Проверка также запускается при изменениях в `main` и при открытии или обновлении pull request.

Чтобы собрать и скачать готовую версию из **Releases**, отправь тег с префиксом `v`:

```sh
git tag v0.1.0
git push origin v0.1.0
```

Каждая сборка берёт свежий официальный базовый образ Arch и обновляет пакеты `pacman`. При необходимости зафиксируй версии инструментов в `mise.toml` до сборки релиза.
