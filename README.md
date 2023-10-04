# Certificate Authority for The BPM Group Development Team

## Background

This is a docker container that creates :

- ROOT Private Key for generating Certificate Signing Request
- ROOT Certificate Signing Request
- ROOT Certificate for Certificate Authority
- INTERMEDIATE Private Key for generating Intermediage Certificate Signing Request
- INTERMEDIATE Certificate Signing Request
- INTERMEDIATE Certificate
- INTERMEDIATE Chain of Trust Certificate

All this is created on build.
Additionally it also installs Postfix and configures it as an SMTP relay for gmail.

## To Use this container to generate certificates
Clone the repo
```bash
docker-compose up
docker exec -it containerid bash
sh ./root/scripts/gencert.sh desireddomain.com emailtosendcertsto.co.uk
```
e.g.

```bash
sh ./root/scripts/gencert.sh example.com suityou01@yahoo.co.uk
```

Then your certificates will be sent as attachments to suityou01@yahoo.co.uk with the following attached

- chain of trust certificate
- new certificate
- new key
