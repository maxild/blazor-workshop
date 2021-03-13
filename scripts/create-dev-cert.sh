#!/usr/bin/env bash

# CREDIT: https://github.com/BorisWilhelms/create-dotnet-devcert
# See also https://github.com/dotnet/aspnetcore/issues/7246

TMP_PATH=/var/tmp/localhost-dev-cert
if [ ! -d $TMP_PATH ]; then
  mkdir $TMP_PATH
fi

KEYFILE=$TMP_PATH/dotnet-devcert.key
CRTFILE=$TMP_PATH/dotnet-devcert.crt
PFXFILE=$TMP_PATH/dotnet-devcert.pfx

# Import destinations for self-signed development certificate:
#   - User nssdb - to trust the certificate in supported application like Chromium or Microsoft Edge
#   - Snap Chromium nssdb - to trust the certificate in Chromium if installed via snap
#   - Snap Postman nssdb - to trust the certificate in Postman if installed via snap
NSSDB_PATHS=(
  "$HOME/.pki/nssdb"
  # "$HOME/snap/chromium/current/.pki/nssdb"
  # "$HOME/snap/postman/current/.pki/nssdb"
)

CONF_PATH=$TMP_PATH/localhost.conf
cat >>$CONF_PATH <<EOF
[req]
prompt                  = no
default_bits            = 2048
distinguished_name      = subject
req_extensions          = req_ext
x509_extensions         = x509_ext

[ subject ]
commonName              = localhost

[req_ext]
basicConstraints        = critical, CA:true
subjectAltName          = @alt_names

[x509_ext]
basicConstraints        = critical, CA:true
keyUsage                = critical, keyCertSign, cRLSign, digitalSignature,keyEncipherment
extendedKeyUsage        = critical, serverAuth
subjectAltName          = critical, @alt_names
1.3.6.1.4.1.311.84.1.1  = ASN1:UTF8String:ASP.NET Core HTTPS development certificate # Needed to get it imported by dotnet dev-certs

[alt_names]
DNS.1                   = localhost
EOF

# REQUIRES: libnss3-tools (install via 'sudo apt update && sudo apt install libnss3-tools')
function configure_nssdb() {
  echo "Configuring nssdb for $1"
  certutil -d sql:$1 -D -n dotnet-devcert
  certutil -d sql:$1 -A -t "CP,," -n dotnet-devcert -i $CRTFILE
}

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $KEYFILE -out $CRTFILE -config $CONF_PATH --passout pass:
openssl pkcs12 -export -out $PFXFILE -inkey $KEYFILE -in $CRTFILE --passout pass:

for NSSDB in ${NSSDB_PATHS[@]}; do
  if [ -d "$NSSDB" ]; then
    configure_nssdb $NSSDB
  fi
done

# if not root, add sudo prefix
if [ $(id -u) -ne 0 ]; then
  SUDO='sudo'
fi

# System certificates (Ubuntu)
$SUDO rm /etc/ssl/certs/dotnet-devcert.pem
$SUDO cp $CRTFILE "/usr/local/share/ca-certificates"
$SUDO update-ca-certificates

dotnet dev-certs https --clean --import $PFXFILE -p ""
rm -R $TMP_PATH
