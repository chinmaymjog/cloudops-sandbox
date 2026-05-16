#!/bin/bash
set -e

# Function to create a database and user if they don't exist
create_user_and_database() {
	local database=$1
	local user=$2
	local password=$3
	echo "  Ensuring database '$database' and user '$user' exist..."
	
	# Create user if it doesn't exist
	export PGPASSWORD="${POSTGRES_PASSWORD}"
	psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "postgres" <<-EOSQL
		DO \$$
		BEGIN
			IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$user') THEN
				CREATE USER "$user" WITH PASSWORD '$password';
			END IF;
		END
		\$$;
EOSQL

	# Create database if it doesn't exist
	psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "postgres" <<-EOSQL
		SELECT 'CREATE DATABASE "$database" OWNER "$user"'
		WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_database WHERE datname = '$database')\gexec
		GRANT ALL PRIVILEGES ON DATABASE "$database" TO "$user";
EOSQL
}

echo "🚀 Starting database initialization..."

POSTGRES_USER="${POSTGRES_USER:-postgres}"

# Create databases and users for each service
create_user_and_database "keycloak" "keycloak" "${KEYCLOAK_DB_PASSWORD}"
create_user_and_database "n8n" "n8n" "${N8N_DB_PASSWORD}"
create_user_and_database "grafana" "grafana" "${GRAFANA_DB_PASSWORD}"

echo "✅ Database initialization complete!"
