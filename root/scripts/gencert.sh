#!/bin/bash
# Command line arguments :
# certname - The filename of the certificate to be used
# keyfile - The key file used to genereate the csr. Defaults to default key if not set.
# usage - sh ./gencert.sh -certname mycert

certname=$1
email=$2

echo creating san file conf
sed "s/hostname/$1/g"  /root/ca/intermediate/opensslbase.cnf > /root/ca/intermediate/openssl.cnf


echo Generating private key for $certname

# Generate client key file
openssl genrsa \
	-out /root/ca/intermediate/private/$certname.key.pem 2048
chmod 400 /root/ca/intermediate/private/$certname.key.pem

echo Generating client certificate signing request
# Generate client csr
openssl req -config /root/ca/intermediate/openssl.cnf \
      -subj "/C=GB/ST=London/L=London/O=$certname/OU=IT Department/CN=$certname" \
      -key /root/ca/intermediate/private/$certname.key.pem \
      -new -sha256 \
      -out /root/ca/intermediate/csr/$certname.csr.pem \
      -passin pass:password

echo Generating certificate for $certname
openssl ca -config /root/ca/intermediate/openssl.cnf \
      -extensions server_cert \
      -days 375 \
      -notext \
      -md sha256 \
      -in /root/ca/intermediate/csr/$certname.csr.pem \
      -out /root/ca/intermediate/certs/$certname.pem \
      -passin pass:password
chmod 444 /root/ca/intermediate/certs/$certname.pem
echo Verifying certificate for $certname
openssl x509 -noout -text \
      -in /root/ca/intermediate/certs/$certname.pem

echo Certificate can now be found at /root/ca/intermediate/certs/$certname.pem
echo Keyfile can be found at /root/ca/intermediate/private/$certname.key.pem
echo chain of trust certificate can be found at /root/ca/intermediate/certs/ca-chain.cert.pem

echo Sending your certificates now to $email

sh ./sendcert.sh $certname


