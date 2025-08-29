# Note: Set $AUTH0_CLIENT_ID first.

echo "AUTH0_CLIENT_ID: $AUTH0_CLIENT_ID"

# Get the ID and IDENTIFIER fields of the Auth0 Management API
AUTH0_MANAGEMENT_API_ID=$(auth0 apis list --json | jq -r 'map(select(.name == "Auth0 Management API"))[0].id')
AUTH0_MANAGEMENT_API_IDENTIFIER=$(auth0 apis list --json | jq -r 'map(select(.name == "Auth0 Management API"))[0].identifier')

echo "AUTH0_MANAGEMENT_API_ID: $AUTH0_MANAGEMENT_API_ID"
echo "AUTH0_MANAGEMENT_API_IDENTIFIER: $AUTH0_MANAGEMENT_API_IDENTIFIER"

# Get the SCOPES to be authorized
AUTH0_MANAGEMENT_API_SCOPES=$(auth0 apis scopes list $AUTH0_MANAGEMENT_API_ID --json | jq -r '.[].value' | jq -ncR '[inputs]')

echo "AUTH0_MANAGEMENT_API_SCOPES: $AUTH0_MANAGEMENT_API_SCOPES"

# Authorize the Auth0 Terraform Provider application to use the Auth0 Management API

auth0 login --scopes create:client_grants
auth0 api post "client-grants" --data='{"client_id": "'$AUTH0_CLIENT_ID'", "audience": "'$AUTH0_MANAGEMENT_API_IDENTIFIER'", "scope":'$AUTH0_MANAGEMENT_API_SCOPES'}'
