# WordPress Docker Starter

> Profesjonalne środowisko deweloperskie WordPress oparte na Docker.  
> Apache · PHP 8.4 · MySQL 8.4 · WP-CLI · Xdebug 3 · Mailpit

---

**[🇬🇧 English version →](README.md)**

---

## Funkcjonalności

- **Uruchomienie jedną komendą** — `make start` kopiuje konfigurację, buduje obrazy i startuje usługi
- **Przełączanie wersji PHP** — zmień `PHP_VERSION` w `.env`, przebuduj przez `make build`
- **Xdebug 3** — zainstalowany, domyślnie wyłączony; aktywacja przez trigger (zerowy narzut)
- **Przechwytywanie e-maili** — Mailpit przechwytuje wszystkie maile; żaden nie trafia do prawdziwego odbiorcy
- **WP-CLI** — dostępny bezpośrednio przez `make wp cmd="..."`
- **Healthchecks** — kontenery MySQL i WordPress raportują rzeczywisty status `healthy`
- **Przypięte wersje obrazów** — powtarzalne buildy, brak niespodziewanych aktualizacji
- **Naprawa uprawnień** — `make fix-permissions` synchronizuje własność plików z UID hosta

## Stack

| Usługa         | Obraz                           | Przeznaczenie                    |
|----------------|---------------------------------|----------------------------------|
| **WordPress**  | `wordpress:php8.4-apache`       | Apache + PHP + WP-CLI + Xdebug   |
| **MySQL**      | `mysql:8.4.9`                   | Baza danych                      |
| **phpMyAdmin** | `phpmyadmin:5.2.3`              | Interfejs graficzny bazy danych  |
| **Mailpit**    | `axllent/mailpit:v1.29.7`       | SMTP catch-all + interfejs web   |

## Wymagania

- [Docker](https://docs.docker.com/get-docker/) ≥ 24
- [Docker Compose](https://docs.docker.com/compose/) ≥ 2.20 (Compose V2)

## Szybki start

```bash
make start
```

Komenda automatycznie kopiuje `.env.example` → `.env` (jeśli nie istnieje), buduje obrazy
i uruchamia wszystkie kontenery. Poczekaj ~30 s na inicjalizację MySQL, następnie otwórz:

| Usługa         | Adres                            |
|----------------|----------------------------------|
| WordPress      | http://localhost:8000            |
| phpMyAdmin     | http://localhost:8080            |
| Mailpit UI     | http://localhost:8025            |

> Domyślne porty można zmienić w pliku `.env`.

Przy pierwszym uruchomieniu pliki WordPressa są instalowane automatycznie do katalogu `./wordpress/`.
Katalog jest dostępny do edycji bezpośrednio w VS Code.

## Konfiguracja

Skopiuj `.env.example` do `.env` i dostosuj według potrzeb. Po każdej zmianie uruchom `docker compose up -d`
(dodaj `--build` jeśli zmieniłeś `PHP_VERSION`).

| Zmienna                | Wartość domyślna   | Opis                                                |
|------------------------|--------------------|-----------------------------------------------------|
| `PROJECT_NAME`         | `mywordpress`      | Prefiks nazw kontenerów                             |
| `WP_PORT`              | `8000`             | Port HTTP WordPressa                                |
| `WP_DOMAIN`            | `localhost`        | Domena strony (bez `http://`)                       |
| `WP_DEBUG`             | `false`            | Włączenie trybu debugowania WordPress               |
| `WP_TABLE_PREFIX`      | `wp_`              | Prefiks tabel bazy danych                           |
| `PHP_VERSION`          | `8.4`              | Wersja PHP do budowania obrazu (8.2/8.3/8.4)        |
| `PHP_MEMORY_LIMIT`     | `256M`             | Limit pamięci PHP                                   |
| `WP_MAX_MEMORY_LIMIT`  | `512M`             | Limit pamięci WordPress (import, aktualizacje)      |
| `HOST_UID`             | `1000`             | UID użytkownika hosta — sprawdź przez `id -u`       |
| `DB_NAME`              | `wordpress`        | Nazwa bazy danych                                   |
| `DB_USER`              | `wordpress`        | Użytkownik bazy danych                              |
| `DB_PASSWORD`          | `wordpress_secret` | Hasło użytkownika bazy danych                       |
| `DB_ROOT_PASSWORD`     | `root_secret`      | Hasło root MySQL                                    |
| `PMA_PORT`             | `8080`             | Port phpMyAdmin                                     |
| `MAILPIT_UI_PORT`      | `8025`             | Port interfejsu web Mailpit                         |
| `MAILPIT_SMTP_PORT`    | `1025`             | Port SMTP Mailpit                                   |

## WP-CLI

```bash
# Komendy WP-CLI z poziomu hosta przez Makefile
make wp cmd="core version"
make wp cmd="plugin list"
make wp cmd="cache flush"

# Lub otwórz shell wewnątrz kontenera
make shell
wp --info --allow-root

# Instalacja WordPress przez CLI (zamiast kreatora w przeglądarce)
make wp cmd='core install --url="http://localhost" --title="Moja strona" \
  --admin_user="admin" --admin_password="admin123" --admin_email="admin@localhost"'
```

## Xdebug

Xdebug 3 jest zainstalowany, ale **domyślnie wyłączony** (`xdebug.mode = off`).  
Ustawienie `start_with_request = trigger` oznacza, że Xdebug aktywuje się tylko dla żądań
zawierających cookie, nagłówek lub parametr `XDEBUG_TRIGGER` — brak spowolnienia przy normalnym przeglądaniu.

### Włączenie Xdebug

1. Edytuj `docker/php/php.ini` i zmień:
   ```ini
   xdebug.mode = debug
   ```
2. Zrestartuj kontener:
   ```bash
   make restart
   ```
3. Zainstaluj rozszerzenie [PHP Debug](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) w VS Code.
4. Utwórz plik `.vscode/launch.json`:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Listen for Xdebug",
         "type": "php",
         "request": "launch",
         "port": 9003,
         "pathMappings": {
           "/var/www/html": "${workspaceFolder}/wordpress"
         }
       }
     ]
   }
   ```
5. Uruchom debugowanie w VS Code (`F5`) i odśwież stronę w przeglądarce.

## Testowanie e-maili

Wszystkie wiadomości e-mail wysyłane przez WordPress są **przechwytywane przez Mailpit** — żaden mail nie trafia do prawdziwego odbiorcy.

- Interfejs web: **http://localhost:8025**
- Host SMTP (z poziomu kontenerów): `mailpit:1025`

## Komendy Makefile

| Komenda                | Opis                                                           |
|------------------------|----------------------------------------------------------------|
| `make start`           | Pierwsze uruchomienie: kopiuje `.env`, buduje obrazy, startuje |
| `make up`              | Uruchomienie bez rebuildu (szybsze przy kolejnych startach)    |
| `make stop`            | Zatrzymanie kontenerów (woluminy zachowane)                    |
| `make restart`         | Restart wszystkich kontenerów                                  |
| `make down`            | Zatrzymanie i usunięcie kontenerów (woluminy zachowane)        |
| `make destroy`         | Usuwa kontenery **i woluminy** — kasuje bazę danych!           |
| `make build`           | Rebuild obrazu WordPress/PHP po zmianach w `docker/php/`      |
| `make logs`            | Podgląd logów wszystkich usług na żywo (Ctrl+C aby zakończyć) |
| `make shell`           | Bash w kontenerze WordPress                                    |
| `make db`              | Klient MySQL jako root                                         |
| `make wp cmd=...`      | Komenda WP-CLI, np. `make wp cmd="plugin list"`               |
| `make fix-permissions` | Naprawa własności plików `./wordpress/` do UID hosta           |

Pełna lista: `make help`.

## Struktura projektu

```
wp-docker-starter/
├── .editorconfig               # Ustawienia edytora (wcięcia, charset, LF)
├── .env                        # Aktywna konfiguracja lokalna (gitignored)
├── .env.example                # Szablon konfiguracji — skopiuj do .env
├── .gitignore
├── Makefile                    # Skróty dla dewelopera
├── README.md                   # Wersja angielska
├── README.pl.md                # Ten plik
├── docker-compose.yml
└── docker/
    ├── php/
    │   ├── .dockerignore       # Wyklucza php.ini z build context
    │   ├── Dockerfile          # Obraz Apache + PHP + WP-CLI + Xdebug
    │   ├── msmtprc             # Konfiguracja SMTP → Mailpit
    │   └── php.ini             # Konfiguracja PHP (montowana w runtime)
    └── mysql/
        └── my.cnf              # Konfiguracja MySQL
```

> Katalog `wordpress/` nie jest częścią repozytorium — Docker tworzy go automatycznie
> przy pierwszym uruchomieniu (`make start`), a `.gitignore` go wyklucza.

## Licencja

MIT
