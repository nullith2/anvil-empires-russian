# Воспроизводимая сборка Setup

Этот каталог содержит открытые исходники Windows Setup. Они позволяют собрать
установщик из официального ZIP-релиза и сравнить полученный SHA-256 с файлом,
опубликованным автором.

Обычному пользователю эти действия не нужны: для установки достаточно скачать
готовый Setup со страницы GitHub Releases.

## Требования

- 64-разрядная Windows;
- Windows PowerShell 5.1 или новее;
- официальный ZIP той же версии;
- доступ в интернет при первом запуске для загрузки Inno Setup 7.0.2.

Сценарий самостоятельно загружает закреплённую версию Inno Setup и проверяет
размер, SHA-256, Authenticode-подпись, SHA-256 `ISCC.exe` и отпечаток всего
portable-каталога компилятора. Setup не запускается, игра и Steam не изменяются.

## Сборка

Откройте PowerShell в корне исходников соответствующего release-тега и
выполните:

```powershell
.\packaging\installer\build-setup.ps1 `
  -ReleaseZip .\Anvil-Empires-Russian-v0.10.6-steam-build-24300218.zip
```

В публичном репозитории каталог может называться `installer-source`; тогда
команда выглядит так:

```powershell
.\installer-source\build-setup.ps1 `
  -ReleaseZip .\Anvil-Empires-Russian-v0.10.6-steam-build-24300218.zip
```

По умолчанию используются находящиеся рядом:

- `reproducible-build.json`;
- `release-policy-v<версия>.json`;
- `Anvil-Empires-Russian.iss`;
- `README_INSTALLER_RU.txt`;
- `inno-toolchain-v7.0.2.json`;
- `bootstrap-inno.ps1` и `build-installer.ps1`.

Во внутреннем checkout два последних сценария автоматически находятся также в
каталоге `scripts`. Другую build policy или папку результата можно указать
параметрами `-BuildPolicy` и `-OutputRoot`.

При первом запуске компилятор сохраняется в `.build`; готовый файл появляется
в `out`. Успешное завершение означает, что размер и SHA-256 полученного Setup
точно совпали со значениями build policy. При любом отличии сборка
завершается ошибкой и не считается воспроизведённой.

## Формат build policy

Для каждого неизменяемого release-тега публикуется policy схемы
`anvil-russian-reproducible-build/1`:

```json
{
  "schema": "anvil-russian-reproducible-build/1",
  "version": "0.10.6",
  "release_zip": {
    "file": "Anvil-Empires-Russian-v0.10.6-steam-build-24300218.zip",
    "size": 123456,
    "sha256": "64 lowercase hex characters",
    "root": "Anvil-Empires-Russian-v0.10.6-steam-build-24300218",
    "members": [
      "Anvil-Russian-Full_P.pak",
      "INFO/LICENSE_RU.txt",
      "INFO/LICENSES/Apache-2.0.txt",
      "INFO/SHA256SUMS.txt",
      "INFO/THIRD-PARTY-NOTICES.txt",
      "INFO/release-manifest.json",
      "README_RU.txt",
      "RELEASE_NOTES_RU.txt"
    ]
  },
  "setup": {
    "file": "Anvil-Empires-Russian-v0.10.6-Setup.exe",
    "size": 1234567,
    "sha256": "64 lowercase hex characters"
  }
}
```

Настоящие значения размера и SHA-256 появляются только после окончательной
сборки релиза. Совпадение SHA-256 показывает, что опубликованный unsigned Setup
побайтово воспроизводится из опубликованного ZIP, исходника Inno и закреплённого
компилятора.
