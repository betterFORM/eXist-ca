# Metaphors for Certificates, Certificate Authorities and Operations on 
Certificates

X.509 certificates and their use in cryptology are quite abstract concepts. 
Our goal is to provide certicates and cryptology to the masses. We should find 
suitable metaphors that explain the basic concepts to people who are not 
familiar with the technical details.

In the remainder of this text, "certificates" refer to cryptograhic certificates 
encoded with the X.509 standard, as commonly used with SSL and TLS.

## Certificates are similar to passports

A certificate, just like a passport or ID card, is:

- a document that identifies some person
- that document is stamped and signed by some authority (government)
- it is valid for some years and needs to be renewed afterwards
- you need to possess and show it, and it must be valid, to access restricted 
  resourcea (travel to a foreign country)
- the person holding the passport needs to interact with the authority (government)
-- apply for a passport
-- passport gets issued by the authority
-- pickup and use new passport
-- renew the passport when it expires
-- paasport gets revoked by the authority (if stolen)

Although similar to passports, digital certificates are different in these aspects:

- certs can also be issued to network hosts, not only to persons
- certs include a crypto public key pair that can be used for crypto operations, unlike passports (yet)

## Scope of Certificates ("global" vs. "local" Validity)

[...]
