# Quick install

Installing Odoo 16 with one command.

(Supports multiple Odoo instances on one server)

Install [docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/) yourself, then run:

``` bash
curl -s https://raw.githubusercontent.com/grazrib/docker-compose-odoo16/master/run.sh | sudo bash -s odoo-one 10016 20016
```

to set up first Odoo instance @ `localhost:10015` (default master password: `do_be_modified`)

and

``` bash
curl -s https://raw.githubusercontent.com/grazrib/docker-compose-odoo16/master/run.sh | sudo bash -s odoo-two 11016 21016
```

to set up another Odoo instance @ `localhost:11015` (default master password: `to_be_modified`)

Some arguments:
* First argument (**odoo-one**): Odoo deploy folder
* Second argument (**10016**): Odoo port
* Third argument (**20016**): live chat port

If `curl` is not found, install it:

``` bash
$ sudo apt-get install curl
# or
$ sudo yum install curl
```

# Usage

Start the container:
``` sh
docker-compose up
```

* Then open `localhost:10016` to access Odoo 16.0. If you want to start the server with a different port, change **10016** to another value in **docker-compose.yml**:

```
ports:
 - "10016:8069"
```

Run Odoo container in detached mode (be able to close terminal without stopping Odoo):

```
docker-compose up -d
```

**If you get the permission issue**, change the folder permission to make sure that the container is able to access the directory:

``` sh
$ git clone https://github.com/grazrib/docker-compose-odoo16.git
sudo chmod -R 777 addons
sudo chmod -R 777 etc
mkdir -p postgresql
sudo chmod -R 777 postgresql
sudo chown -R 5050:5050 pgadmin-data
```

Increase maximum number of files watching from 8192 (default) to **524288**. In order to avoid error when we run multiple Odoo instances. This is an *optional step*. These commands are for Ubuntu user:

```
$ if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf); else echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf; fi
$ sudo sysctl -p    # apply new config immediately
```

# Custom addons

The **addons/** folder contains custom addons. Just put your custom addons if you have any.

# Odoo configuration & log

* To change Odoo configuration, edit file: **etc/odoo.conf**.
* Log file: **etc/odoo-server.log**
* Default database password (**admin_passwd**) is `to_be_modified`, please change it @ [etc/odoo.conf#L60](/etc/odoo.conf#L60)

# Odoo container management

**Run Odoo**:

``` bash
docker-compose up -d
```

**Restart Odoo**:

``` bash
docker-compose restart
```

**Rebuild Odoo**:

``` bash
docker-compose build
```

**Stop Odoo**:

``` bash
docker-compose down
```

**For import db**:

``` bash
chmod +x regenerate_static.sh optimize_database.sh
```
``` bash
./regenerate_static.sh
```
``` bash
./optimize_database.sh
```

# Live chat

In [docker-compose.yml#L21](docker-compose.yml#L21), we exposed port **20015** for live-chat on host.

Configuring **nginx** to activate live chat feature (in production):

``` conf
#...
server {
    #...
    location /longpolling/ {
        proxy_pass http://0.0.0.0:20016/longpolling/;
    }
    #...
}
#...
```

# docker-compose.yml

* odoo:16.0
* postgres:16

# Odoo 16 screenshots

<img src="screenshots/2022-10-17_22h16_21.png" width="50%">

<img src="screenshots/2022-10-17_22h16_30.png" width="100%">

<
