FROM odoo:16

USER root

# Fix critico SSL/TLS per Odoo 16 - VERSIONI TESTATE
RUN pip3 install --upgrade pip && \
    pip3 install --upgrade \
        cryptography==3.4.8 \
        pyOpenSSL==19.0.0

# Dipendenze essenziali
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libcups2-dev \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copia e configura entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Directory con permessi corretti
RUN mkdir -p /mnt/extra-addons /etc/odoo && \
    chown -R odoo:odoo /mnt/extra-addons /etc/odoo

USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
