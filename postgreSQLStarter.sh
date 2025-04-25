#!/bin/bash

# Always exit on real errors
set -e

echo "í ½í´ Checking PostgreSQL installation..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "âŒ PostgreSQL is not installed. Installing it now..."
    apt update && apt install -y postgresql
else
    echo "âš ï¸  Warning: PostgreSQL is already installed."
    echo "í ½í±‰ Continuing anyway..."
fi

# After install, ensure a cluster exists
if ! pg_lsclusters | grep -q main; then
    echo "âš™ï¸ No database cluster found. Creating a new cluster..."
    PG_MAJOR_VERSION=$(psql --version | awk '{print $3}' | cut -d '.' -f1)
    pg_createcluster "$PG_MAJOR_VERSION" main --start
    echo "âœ… Cluster created and PostgreSQL server started."
fi

# Collect user inputs
read -p "Enter database name: " DB_NAME
read -p "Enter PostgreSQL port (default 5432): " DB_PORT
DB_PORT=${DB_PORT:-5432}
read -p "Enter new username: " DB_USER
read -s -p "Enter password for user '$DB_USER': " DB_PASSWORD
echo

# Allow IP input
read -p "Allow connections from (IP address or CIDR, e.g., 0.0.0.0/0): " ALLOWED_IPS
ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0}

# Validate IP format (simple but strong)
if ! [[ "$ALLOWED_IPS" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})$ ]]; then
    echo "âŒ Invalid IP address format: '$ALLOWED_IPS'"
    echo "Example of correct format: 0.0.0.0/0 or 192.168.1.0/24"
    exit 1
fi

# Confirm
echo ""
echo "Configuration:"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Port: $DB_PORT"
echo "Allowed IPs: $ALLOWED_IPS"
read -p "Proceed with setup? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Setup canceled."
    exit 0
fi

# Detect PostgreSQL version properly
PG_VERSION=$(ls /etc/postgresql | head -n 1)

if [ -z "$PG_VERSION" ]; then
    echo "âŒ Could not detect PostgreSQL version. Exiting."
    exit 1
fi

echo "í ½í´¢ Detected PostgreSQL version: $PG_VERSION"

# Config file paths
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

# Ensure configuration files exist
if [ ! -f "$PG_CONF" ] || [ ! -f "$PG_HBA" ]; then
    echo "âŒ PostgreSQL configuration files missing."
    exit 1
fi

# Configure PostgreSQL
sed -i "s/^#port = .*/port = $DB_PORT/" "$PG_CONF"
sed -i "s/^#listen_addresses = .*/listen_addresses = '*'/" "$PG_CONF"

# Avoid duplicate host rules
if ! grep -q "$DB_NAME.*$DB_USER.*$ALLOWED_IPS" "$PG_HBA"; then
    echo "host    $DB_NAME    $DB_USER    $ALLOWED_IPS    md5" >> "$PG_HBA"
else
    echo "âš ï¸  Access rule already exists in pg_hba.conf, skipping append."
fi

# Restart PostgreSQL
echo "í ½í´„ Restarting PostgreSQL..."
systemctl restart postgresql

# Verify PostgreSQL is running before touching users
if ! systemctl is-active --quiet postgresql; then
    echo "âŒ PostgreSQL is not running after restart. Check your configs."
    exit 1
fi

# Create user if missing
echo "í ½í» ï¸ Creating user if missing..."
sudo -u postgres psql 2>/dev/null <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE USER "$DB_USER" WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;
EOF

# Create database if missing
echo "í ½í» ï¸ Creating database if missing..."
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" 2>/dev/null | grep -q 1; then
    sudo -u postgres createdb --owner="$DB_USER" "$DB_NAME" 2>/dev/null
    echo "âœ… Database '$DB_NAME' created."
else
    echo "âš ï¸  Database '$DB_NAME' already exists, skipping creation."
fi

# Grant privileges
echo "í ½í» ï¸ Granting privileges..."
sudo -u postgres psql 2>/dev/null <<EOF
GRANT ALL PRIVILEGES ON DATABASE "$DB_NAME" TO "$DB_USER";
EOF

# Done
echo ""
echo "í ¼í¾‰ âœ… PostgreSQL setup complete!"
echo "Database: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: $DB_PASSWORD"
echo "Port: $DB_PORT"
echo "Allowed IPs: $ALLOWED_IPS"
