# Imagem docker do odoo, configurada para os modulos brasileiro 

Comando con as configurações basica

```bash
▶ docker run --name odoo -d -e USER=odoo -e PASSWORD=odoo -e PORT=5432 craines/odoo-brasil:15.0
```

Todos parametos aceito:

* ODOO_PASSWORD=admin
* HOST=localhost
* PORT=5432
* USER=odoo
* PASSWORD=odoo
* DATABASE=False
* DEBUG_MODE=False
* LIST_DB=True
* EMAIL_FROM=odoo@teste.com
* SMTP_PASSWORD=123
* SMTP_PORT=25
* SMTP_SERVER=localhost
* SMTP_SSL=False
* SMTP_USER=False
* ODOO_PORT=8069
* WORKERS=5
* LOG_FILE=/var/lib/odoo/odoo.log
* LONGPOLLING_PORT=8072
* DISABLE_LOGFILE=0
* TIME_CPU=6000
* TIME_REAL=7200
* DB_FILTER=False

Rodando com docker compose:
---------------------
```yaml
version: '3'
services:
  db:
    image: postgres:14
    restart: always
    environment:
      POSTGRES_DB: 'postgres'
      POSTGRES_USER: 'dbuser'
      POSTGRES_PASSWORD: 'as6d54sda'
    ports:
      - "5432:5432"
  odoo:
    image: craines/odoo-brasil:15.0
    ports:
      - "8069:8069"
    depends_on:
      - db
    environment:
      HOST: db
      PORT: 5432
      USER: dbuser
      PASSWORD: as6d54sda
      ODOO_PORT: 8069
```
```bash
▶ docker-compose up
```
