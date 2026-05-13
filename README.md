# WordPress Docker Starter

> A production-quality local WordPress development environment powered by Docker.  
> Apache · PHP 8.4 · MySQL 8.4 · WP-CLI · Xdebug 3 · Mailpit

---

**[🇵🇱 Wersja polska →](README.pl.md)**

---

## Features

- **One-command setup** — `make start` copies config, builds images, starts all services
- **PHP version switching** — change `PHP_VERSION` in `.env`, rebuild with `make build`
- **Xdebug 3** — installed but disabled by default; trigger-based activation (zero overhead)
- **Email interception** — Mailpit catches all outgoing mail; nothing reaches real recipients
- **WP-CLI** — available directly via `make wp cmd="..."`
- **Healthchecks** — MySQL and WordPress containers report a real `healthy` status
- **Pinned image versions** — reproducible builds, no surprise upgrades
- **Permissions fix** — `make fix-permissions` syncs file ownership to your host UID

## Stack

| Service        | Image                           | Purpose                          |
|----------------|---------------------------------|----------------------------------|
| **WordPress**  | `wordpress:php8.4-apache`       | Apache + PHP + WP-CLI + Xdebug   |
| **MySQL**      | `mysql:8.4.9`                   | Database                         |
| **phpMyAdmin** | `phpmyadmin:5.2.3`              | Database GUI                     |
| **Mailpit**    | `axllent/mailpit:v1.29`         | SMTP catch-all + web UI          |

## Requirements

- [Docker](https://docs.docker.com/get-docker/) ≥ 24
- [Docker Compose](https://docs.docker.com/compose/) ≥ 2.20 (Compose V2)

## Quick Start

```bash
make start
```

This command automatically copies `.env.example` → `.env` (if not present), builds the images,
and starts all containers. Wait ~30 s for MySQL to initialise, then open:

| Service        | URL                              |
|----------------|----------------------------------|
| WordPress      | http://localhost:8000            |
| phpMyAdmin     | http://localhost:8080            |
| Mailpit UI     | http://localhost:8025            |

> Default ports can be changed in `.env`.

On first start, WordPress core files are installed automatically into `./wordpress/`.
The directory is available for editing directly in VS Code.

## Configuration

Copy `.env.example` to `.env` and adjust as needed. After any change run `docker compose up -d`
(add `--build` if you changed `PHP_VERSION`).

| Variable               | Default            | Description                                    |
|------------------------|--------------------|------------------------------------------------|
| `PROJECT_NAME`         | `mywordpress`      | Container name prefix                          |
| `WP_PORT`              | `8000`             | WordPress HTTP port                            |
| `WP_DOMAIN`            | `localhost`        | Site domain (without `http://`)                |
| `WP_DEBUG`             | `false`            | Enable WordPress debug mode                    |
| `WP_TABLE_PREFIX`      | `wp_`              | Database table prefix                          |
| `PHP_VERSION`          | `8.4`              | PHP version used to build the image (8.2/8.3/8.4) |
| `PHP_MEMORY_LIMIT`     | `256M`             | PHP memory limit                               |
| `WP_MAX_MEMORY_LIMIT`  | `512M`             | WordPress memory limit (imports, updates)      |
| `HOST_UID`             | `1000`             | Host user UID — run `id -u` to check yours     |
| `DB_NAME`              | `wordpress`        | Database name                                  |
| `DB_USER`              | `wordpress`        | Database user                                  |
| `DB_PASSWORD`          | `wordpress_secret` | Database user password                         |
| `DB_ROOT_PASSWORD`     | `root_secret`      | MySQL root password                            |
| `PMA_PORT`             | `8080`             | phpMyAdmin port                                |
| `MAILPIT_UI_PORT`      | `8025`             | Mailpit web UI port                            |
| `MAILPIT_SMTP_PORT`    | `1025`             | Mailpit SMTP port                              |

## WP-CLI

```bash
# Run WP-CLI commands from the host via Makefile
make wp cmd="core version"
make wp cmd="plugin list"
make wp cmd="cache flush"

# Or open a shell inside the container
make shell
wp --info --allow-root

# Install WordPress programmatically (skips the browser wizard)
make wp cmd='core install --url="http://localhost" --title="My Site" \
  --admin_user="admin" --admin_password="admin123" --admin_email="admin@localhost"'
```

## Xdebug

Xdebug 3 is installed but **disabled by default** (`xdebug.mode = off`).  
The `start_with_request = trigger` setting means Xdebug only activates for requests that
carry an `XDEBUG_TRIGGER` cookie, header, or query parameter — no slowdown during normal browsing.

### Enabling Xdebug

1. Edit `docker/php/php.ini` and change:
   ```ini
   xdebug.mode = debug
   ```
2. Restart the container:
   ```bash
   make restart
   ```
3. Install the [PHP Debug](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) extension in VS Code.
4. Create `.vscode/launch.json`:
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
5. Start debugging in VS Code (`F5`) and refresh the page in your browser.

## Email Testing

All emails sent by WordPress are **captured by Mailpit** — no mail ever reaches a real recipient.

- Web UI: **http://localhost:8025**
- SMTP host (from inside containers): `mailpit:1025`

## Makefile Commands

| Command                | Description                                                    |
|------------------------|----------------------------------------------------------------|
| `make start`           | First run: copies `.env`, builds images, starts containers     |
| `make up`              | Start without rebuilding (faster for subsequent starts)        |
| `make stop`            | Stop containers (volumes preserved)                            |
| `make restart`         | Restart all containers                                         |
| `make down`            | Stop and remove containers (volumes preserved)                 |
| `make destroy`         | Remove containers **and volumes** — wipes the database!        |
| `make build`           | Rebuild WordPress/PHP image after changes in `docker/php/`     |
| `make logs`            | Stream logs from all services (Ctrl+C to exit)                 |
| `make shell`           | Open a Bash shell inside the WordPress container               |
| `make db`              | Open a MySQL client as root                                    |
| `make wp cmd=...`      | Run a WP-CLI command, e.g. `make wp cmd="plugin list"`         |
| `make fix-permissions` | Fix file ownership in `./wordpress/` to match host UID         |

Run `make help` for the full list.

## Project Structure

```
wp-docker-starter/
├── .editorconfig               # Editor settings (indent, charset, LF)
├── .env                        # Active local config (gitignored)
├── .env.example                # Config template — copy to .env
├── .gitignore
├── Makefile                    # Developer shortcuts
├── README.md                   # This file
├── README.pl.md                # Polish version
├── docker-compose.yml
└── docker/
    ├── php/
    │   ├── .dockerignore       # Excludes php.ini from build context
    │   ├── Dockerfile          # Apache + PHP + WP-CLI + Xdebug image
    │   ├── msmtprc             # SMTP config → Mailpit
    │   └── php.ini             # PHP config (mounted at runtime)
    └── mysql/
        └── my.cnf              # MySQL config
```

> `wordpress/` is not part of the repository — it is created automatically by Docker
> on first run (`make start`) and excluded via `.gitignore`.

## License

MIT
