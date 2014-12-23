# Metaphors for Certificates, Certificate Authorities and Operations on Certificates

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
- the person holding the passport needs to interact with the authority (government):
- apply for a passport
- passport gets issued by the authority
- pickup and use new passport
- renew passport when it expires
- passport gets revoked by the authority (if stolen)

Although X.509 certificates have a strong similarity to passports, there 
are some differences:

- certificates can also be issued to Internet servers like "www.example.org" or "mail.example.org" (think passports for servers)
- unlike passports, certificates can be used for crypto operations, because they contain a public key crypto keypair
- passports are issued by nation state authorities (governments), while anyone may create ID cards that are valid for "something"

This last one is important because it leads to the problem of "trust", or 
who should be trusted and why.

## Certificates are not like passports, more like company ID cards

Consider the following scenario: 

Your company issues ID cards to company employees. These ID cards enable 
card holders to access company buildings, the parking lot, and maybe the 
Intranet Web server. [This is usually done with SmartCards that use X.509 
internally or something functionally equivalent]


[...]

## Trust (or lack thereof)

[...]

## Certificates have similarities to bank and credit cards

[...]

