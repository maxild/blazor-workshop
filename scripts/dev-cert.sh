#!/usr/bin/env bash
set -eu

# Create *.crt file (self-signed certificate using openssl)

org=localhost-ca
domain=localhost
path="$HOME/.aspnet/https"

openssl genpkey -algorithm RSA -out "$path/ca.key"
openssl req -x509 -key "$path/ca.key" -out "$path/ca.crt" \
    -subj "/CN=$org/O=$org"

openssl genpkey -algorithm RSA -out "$path/$domain".key
openssl req -new -key "$path/$domain".key -out "$path/$domain".csr \
    -subj "/CN=$domain/O=$org"

openssl x509 -req -in "$path/$domain".csr -days 365 -out "$path/$domain".crt \
    -CA "$path/ca.crt" -CAkey "$path/ca.key" -CAcreateserial \
    -extfile <(cat <<END
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:$domain
END
    )

openssl pkcs12 -export -out "$path/$domain".pfx -inkey "$path/$domain".key -in "$path/$domain".crt

##################################

# METHOD: Generate public/private key using 'localhost.conf' and 'openssl' instructions:

# sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -config localhost.conf -passin pass:crypticpassword

# sudo openssl pkcs12 -export -out localhost.pfx -inkey localhost.key -in localhost.crt

# Delete previously installed certificate named "localhost"
# certutil -D -d sql:${HOME}/.pki/nssdb -n "localhost"

# Install new certificate
# certutil -D -d sql:${HOME}/.pki/nssdb -n "localhost"

##################################

# Arch Linux trust certificate system wide
# $ sudo trust anchor $HOME/.aspnet/https/ca.crt

# install the self-signed certificate (public key) portion into the machine's trusted store (/usr/local/share/ca-certificates)
# Ubuntu ($HOME/.aspnet/https/ca.crt...TODO: rename to 'dev-cert-linux.crt')
# $ sudo cp ~/dev-cert.crt /usr/local/share/ca-certificates/dev-cert.crt
# $ sudo update-ca-certificates

######################################################

# That is an option that Kestrel usually looks at to specify the PFX file for the server
# I set the following environment variables so that ASP.NET Core would use my *.pfx file
# Add the following enviroments variables (for example to launch.json in .vscode folder)
# "env": {
#   "ASPNETCORE_ENVIRONMENT": "Development",
#   "ASPNETCORE_Kestrel__Certificates__Default__Password": "password",
#   "ASPNETCORE_Kestrel__Certificates__Default__Path": "${env:HOME}/.aspnet/https/localhost.pfx"
# },
# NOTE: "$HOME/.aspnet/https/localhost.pfx" is the public key (self-signed certificate)

# Credit: https://github.com/amadoa/dotnet-devcert-linux
