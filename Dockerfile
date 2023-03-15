FROM debian:bullseye-slim
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gettext-base \
        build-essential \
        libxml2-dev \
        libxmlsec1-dev \
        libxmlsec1-openssl \
        pkg-config \
        wget \
        unzip \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-dev \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 15.0
ARG ODOO_RELEASE=20230313
ARG ODOO_SHA=ac05136a4488236afc1990879d46c97890fa34cf
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb

# install addons
RUN mkdir /mnt/addons
COPY addons /mnt/addons/extra-addons

RUN wget https://github.com/oca/web/archive/15.0.zip -O web.zip && \
    wget https://github.com/oca/account-reconcile/archive/15.0.zip -O account-reconcile.zip && \
    wget https://github.com/oca/server-ux/archive/15.0.zip -O server-ux.zip && \
    wget https://github.com/oca/reporting-engine/archive/15.0.zip -O reporting-engine.zip && \
    wget https://github.com/oca/account-financial-reporting/archive/15.0.zip -O account-financial-reporting.zip && \
    wget https://github.com/oca/mis-builder/archive/15.0.zip -O mis-builder.zip && \
    wget https://github.com/OCA/commission/archive/15.0.zip -O commission.zip && \
    wget https://github.com/odoo/design-themes/archive/15.0.zip -O design-themes.zip && \
    wget https://github.com/Trust-Code/trustcode-addons/archive/15.0.zip -O trustcode-addons.zip && \
    wget https://github.com/Trust-Code/odoo-brasil/archive/15.0.zip -O odoo-brasil.zip && \
    wget https://github.com/code-137/odoo-apps/archive/15.0.zip -O code137-apps.zip

RUN unzip -q web.zip && rm web.zip && mv web-15.0 /mnt/addons/web && rm -rf /mnt/addons/web/web_responsive && \
    unzip -q account-reconcile.zip && rm account-reconcile.zip && mv account-reconcile-15.0 /mnt/addons/account-reconcile && \
    unzip -q server-ux.zip && rm server-ux.zip && mv server-ux-15.0 /mnt/addons/server-ux && \
    unzip -q reporting-engine.zip && rm reporting-engine.zip && mv reporting-engine-15.0 /mnt/addons/reporting-engine && \
    unzip -q account-financial-reporting.zip && rm account-financial-reporting.zip && mv account-financial-reporting-15.0 /mnt/addons/account-financial-reporting && \
    unzip -q mis-builder.zip && rm mis-builder.zip && mv mis-builder-15.0 /mnt/addons/mis-builder && \
    unzip -q commission.zip && rm commission.zip && mv commission-15.0 /mnt/addons/commission && \
    unzip -q design-themes.zip && rm design-themes.zip && mv design-themes-15.0 /mnt/addons/design-themes && \
    unzip -q trustcode-addons.zip && rm trustcode-addons.zip && mv trustcode-addons-15.0 /mnt/addons/trustcode-addons && \
    unzip -q odoo-brasil.zip && rm odoo-brasil.zip && mv odoo-brasil-15.0 /mnt/addons/odoo-brasil && \
    unzip -q code137-apps.zip && rm code137-apps.zip && mv odoo-apps-15.0 /mnt/addons/code137-apps

# install python depedency
ADD ./br_requirements.txt br_requirements.txt
RUN pip install --no-cache-dir -r br_requirements.txt

# Copy entrypoint script and Odoo configuration file
ADD ./entrypoint.sh /
ADD ./odoo.conf /etc/odoo/
# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown odoo /etc/odoo/odoo.conf \
    && chown -R odoo /mnt/addons \
    && chown -R odoo ./entrypoint.sh \
    && chmod +x ./entrypoint.sh

# clear
RUN apt-get autoremove -y && \
    apt-get autoclean

ENV ODOO_PASSWORD=admin
ENV HOST=localhost
ENV PORT=5432
ENV USER=odoo
ENV PASSWORD=odoo
ENV DATABASE=False
ENV DEBUG_MODE=False
ENV LIST_DB=True
ENV EMAIL_FROM=odoo@teste.com
ENV SMTP_PASSWORD=123
ENV SMTP_PORT=25
ENV SMTP_SERVER=localhost
ENV SMTP_SSL=False
ENV SMTP_USER=False
ENV ODOO_PORT=8069
ENV WORKERS=5
ENV LOG_FILE=/var/lib/odoo/odoo.log
ENV LONGPOLLING_PORT=8072
ENV DISABLE_LOGFILE=0
ENV TIME_CPU=6000
ENV TIME_REAL=7200
ENV DB_FILTER=False
ENV SENTRY_DSN=False
ENV SENTRY_ENABLED=False

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod +x /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

# ENTRYPOINT ["ls", "-lsa"]
ENTRYPOINT ["./entrypoint.sh"]
CMD ["odoo"]