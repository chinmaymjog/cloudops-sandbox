#!/bin/bash
set -e

echo "🚀 Initializing DevOps Lab..."

# Base directory
BASE_DIR=$(dirname "$0")
SERVICES_DIR="$BASE_DIR/services"
ROOT_ENV="$BASE_DIR/.env"

if [ ! -d "$SERVICES_DIR" ]; then
    echo "❌ Error: 'services' directory not found!"
    exit 1
fi

if [ ! -f "$ROOT_ENV" ]; then
    echo "❌ Error: Root '.env' file not found!"
    echo "Please create $ROOT_ENV with your required variables."
    exit 1
fi

echo "📦 Setting up environment variables..."
count=0

# Iterate through each service directory
for service in "$SERVICES_DIR"/*; do
    if [ -d "$service" ]; then
        service_name=$(basename "$service")
        env_template="$service/.env.template"
        env_file="$service/.env"

        if [ -f "$env_template" ]; then
            # Export all variables from root .env and run envsubst on the template
            set -a
            source "$ROOT_ENV"
            set +a
            
            envsubst < "$env_template" > "$env_file"
            echo "✅ $service_name: Created/Updated .env using envsubst from .env.template"
            ((count++))
        else
            echo "ℹ️  $service_name: no .env.template found (skipping)"
        fi
    fi
done

echo ""
echo "🎉 Initialization complete! ($count files created)"
echo ""
echo "Next Steps:"
echo "1. Review the .env files in 'services/*/' and verify your secrets."
echo "   (Especially for Traefik, databases, and Grafana)"
echo "2. Start a service:"
echo "   cd services/traefik && docker compose up -d"
echo ""
echo "Happy Coding! 🐳"
