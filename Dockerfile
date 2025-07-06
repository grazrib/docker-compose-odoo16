FROM odoo:16

USER root

# Installa le dipendenze necessarie
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libcups2-dev \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copia e rende eseguibile l'entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Crea le directory necessarie con i permessi corretti
RUN mkdir -p /mnt/extra-addons \
    && mkdir -p /etc/odoo \
    && chown -R odoo:odoo /mnt/extra-addons /etc/odoo

# Torna all'utente odoo per sicurezza
USER odoo

# Usa il nostro entrypoint personalizzato
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
