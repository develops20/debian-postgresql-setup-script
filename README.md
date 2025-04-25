# PostgreSQL Ultimate Setup Script

⚡ Installs PostgreSQL, creates a database, user, and configures external access — in one simple step.

# You Tube Video Here
https://www.youtube.com/watch?v=ieHKvGRABAc

---

## Features

✅ Installs PostgreSQL if missing  
✅ Creates a default cluster if missing  
✅ Configures custom database and user  
✅ Validates IP address input  
✅ Configures PostgreSQL to allow external connections  
✅ Restarts PostgreSQL cleanly  
✅ Safe to re-run: will not duplicate users or databases  



## Usage

```bash
chmod +x postgresqlStarter.sh
./postgresqlStarter.sh
```


## You will be asked:

* Database name
* PostgreSQL port (default 5432)
* New username
* Password
* Allowed IP address or CIDR block (e.g., 0.0.0.0/0)

## Requirements
* Debian/Ubuntu-based Linux server
* Root or sudo access
* Internet access (to install PostgreSQL packages)

```bash
Enter database name: mydb
Enter PostgreSQL port (default 5432): 5432
Enter new username: myuser
Enter password for user 'myuser':
Allow connections from (IP address or CIDR, e.g., 0.0.0.0/0): 192.168.1.0/24
```
✅ PostgreSQL will be installed and configured automatically!

## Notes
* Default listen address is set to *
* Default authentication method is md5 (password)
* Firewall rules might be needed to open port 5432

---

## To clear the machine in case of errors
Run these commands
```bash
systemctl stop postgresql
apt purge -y postgresql* postgresql-client* postgresql-contrib*
apt autoremove --purge -y
rm -rf /var/lib/postgresql/ /etc/postgresql/ /etc/postgresql-common/ /var/log/postgresql/ /usr/lib/postgresql/
```
---

