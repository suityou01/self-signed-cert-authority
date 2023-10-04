FROM node:latest
USER root

RUN apt-get update && apt-get -y upgrade

RUN echo "postfix postfix/mailname string donotreply.newcerts.com" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

RUN apt-get -y install nano && \
    apt-get -y install --assume-yes postfix && \
    apt-get -y install --assume-yes mailutils && \
    apt-get -y install --assume-yes libsasl2-modules && \
    apt-get -y install --assume-yes rsyslog

# For more information on creating your own CA, Intermediate CA and Client Certs please see
# this excellent article by Jamie Nguyen
# https://jamielinux.com/docs/openssl-certificate-authority/introduction.html

ARG A_CA_EXPIRE=3650
#Key generation algorithm, one of RSA, DSA, ECDSA, or EdDSA
ARG A_KEY_ALGORITHM=RSA
#Key size in bits, typically 2048, 4096
ARG A_KEY_SIZE_IN_BITS=4096
ARG A_CERT_PASSPHRASE=It5A53cr3t

ENV CA_EXPIRE=${A_CA_EXPIRE}
ENV KEY_PASSWORD=${A_KEY_PASSWORD}
ENV KEY_SIZE_IN_BITS=${A_KEY_SIZE_IN_BITS}
ENV CERT_PASSPHRASE=${A_CERT_PASSPHRASE}}

# Set up mailer and smtp relay
COPY etc/postfix/* /etc/postfix/
RUN echo "[smtp.gmail.com]:587 suityou01@gmail.com:Lavalamp4!" > /etc/postfix/sasl_passwd
RUN postmap /etc/postfix/sasl_passwd
RUN chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
RUN chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
RUN cat /etc/ssl/certs/thawte_Primary_Root_CA.pem | tee -a /etc/postfix/cacert.pem

# Create Root Key and Cert pair for our Certificate Authority
RUN mkdir -p /root/ca/certs
RUN mkdir /root/scripts
COPY ./root/scripts/* /root/scripts/
RUN export PATH="/root/scripts:$PATH"
RUN mkdir /root/ca/crl 
RUN mkdir /root/ca/newcerts 
RUN mkdir /root/ca/private
RUN chmod 700 /root/ca/private
RUN touch /root/ca/index.txt
RUN echo 1000 > /root/ca/serial
COPY ./root/ca/openssl.cnf root/ca/openssl.cnf
RUN openssl genrsa -aes256 -passout pass:password -out /root/ca/private/ca.key.pem 4096
RUN chmod 400 /root/ca/private/ca.key.pem
RUN openssl req -new -x509 -key /root/ca/private/ca.key.pem -passin pass:password -out /root/ca/certs/ca.cert.pem -config /root/ca/openssl.cnf -days 365
RUN chmod 400 /root/ca/certs/ca.cert.pem
RUN openssl x509 -noout -text -in /root/ca/certs/ca.cert.pem

# Create our intermediate pair
RUN mkdir /root/ca/intermediate
RUN mkdir /root/ca/intermediate/certs
RUN mkdir /root/ca/intermediate/crl
RUN mkdir /root/ca/intermediate/csr
RUN mkdir /root/ca/intermediate/newcerts
RUN mkdir /root/ca/intermediate/private
RUN chmod 700 /root/ca/intermediate/private
RUN touch /root/ca/intermediate/index.txt
RUN echo 1000 > /root/ca/intermediate/serial
RUN echo 1000 > /root/ca/intermediate/crlnumber
COPY ./root/ca/intermediate/openssl.cnf root/ca/intermediate/openssl.cnf
COPY ./root/ca/intermediate/opensslbase.cnf root/ca/intermediate/opensslbase.cnf

# Generate intermediate private key
RUN openssl genrsa -aes256 \
        -passout pass:password \
        -out /root/ca/intermediate/private/intermediate.key.pem 4096 
RUN chmod 400 /root/ca/intermediate/private/intermediate.key.pem
# Generate intermediate csr
RUN openssl req -config /root/ca/intermediate/openssl.cnf -new -sha256 \
      -key /root/ca/intermediate/private/intermediate.key.pem \
      -out /root/ca/intermediate/csr/intermediate.csr.pem \
      -passin pass:password
# Generate intermediate cert
RUN openssl ca -batch -config /root/ca/openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in /root/ca/intermediate/csr/intermediate.csr.pem \
      -out /root/ca/intermediate/certs/intermediate.cert.pem \
      -passin pass:password 
RUN chmod 444 /root/ca/intermediate/certs/intermediate.cert.pem
RUN openssl x509 -noout -text \
      -in /root/ca/intermediate/certs/intermediate.cert.pem
# Create certificate chain file
RUN cat /root/ca/intermediate/certs/intermediate.cert.pem \
      /root/ca/certs/ca.cert.pem > /root/ca/intermediate/certs/ca-chain.cert.pem
RUN chmod 444 /root/ca/intermediate/certs/ca-chain.cert.pem
# Generate client private key like so
# openssl genrsa -aes256 \
#      -out intermediate/private/www.example.com.key.pem 2048
# omitting -aes256 digest so password is not needed by client 
# on every restart of their application
RUN openssl genrsa \
      -out /root/ca/intermediate/private/www.thebpmgroup.co.uk.key.pem 2048
RUN chmod 400 /root/ca/intermediate/private/www.thebpmgroup.co.uk.key.pem
# Generate client csr
RUN openssl req -config /root/ca/intermediate/openssl.cnf \
      -batch \
      -key /root/ca/intermediate/private/www.thebpmgroup.co.uk.key.pem \
      -new -sha256 \
      -out /root/ca/intermediate/csr/www.thebpmgroup.co.uk.csr.pem \
      -passin pass:password
RUN openssl ca -config /root/ca/intermediate/openssl.cnf \
      -batch \
      -extensions server_cert \
      -days 375 \ 
      -notext \
      -md sha256 \
      -in /root/ca/intermediate/csr/www.thebpmgroup.co.uk.csr.pem \
      -out /root/ca/intermediate/certs/clientcert.pem \
      -passin pass:password
RUN chmod 444 /root/ca/intermediate/certs/clientcert.pem
RUN openssl x509 -noout -text \
      -in /root/ca/intermediate/certs/clientcert.pem

COPY ./entrypoint.sh .

ENTRYPOINT ["./entrypoint.sh"]

