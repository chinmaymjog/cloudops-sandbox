#!/bin/bash
set -e

# Function to create a database and user if they don't exist
create_user_and_database() {
	local database=$1
	local user=$2
	local password=$3
	echo "  Ensuring MySQL database '$database' and user '$user' exist..."
	
	mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
		CREATE DATABASE IF NOT EXISTS \`$database\`;
		CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$password';
		GRANT ALL PRIVILEGES ON \`$database\`.* TO '$user'@'%';
		FLUSH PRIVILEGES;
EOSQL
}

echo "🚀 Starting MySQL database initialization..."

# Add future databases here
# create_user_and_database "example_db" "example_user" "example_password"

echo "✅ MySQL database initialization complete!"
