cert=$1

echo Certs | mail -s "Certificates attached for $cert" suityou01@yahoo.co.uk \
	-A /root/ca/intermediate/certs/$cert.pem \
	-A /root/ca/intermediate/certs/ca-chain.cert.pem \
	-A /root/ca/intermediate/private/$cert.key.pem
