# Use Cases


## Actors

### Cert Admin

Manages the CA and handles creation, renewal and revocation of certificates of various kinds. These include:

* server-certs
* code-signing certs
* email-certs

A Cert Admin must have admin (dba) rights for the eXistdb database. It is the only role being able to issue certs directly.

### Cert User

Installs and uses certs for communication with a server or for email encryption and signing. May request actions from Cert Admin.

# System Use Cases

## 0. setup CA

### Actor. Cert Admin
When the system is started for the first time the admin has to setup the Certificate Authority (need a better
more user-friendly term here) by creating and installing the initial root cert. The setup has to take place on a
secure, network-detached system.


### Steps

1. the admin logs into the system
2. the admin connects to the server by opening a predefined URL in the browser
3. the 'create CA' screen is shown and the admin will provide the necessary data like CA name, keysize, expiry etc.
4. the admin commits by clicking 'create'. System asks for 'really create?' and after confirmation will trigger
the actual cert creation process.
5. system will store created CA cert in a special place for later referral.
6. system will deploy CA to jetty keystore to establish a secure server. System will message admin to restart system
when ready.

### Quetions/Comments

* to make the intial install more secure we can deploy the system with a cert from existsolutions that secures the
communication during the initial setup steps.

* If we assume that initial setup is done ideally on the same machine that runs 'secure server' this system needs
a UI and an up-to-date browser.

## 1. create CA

### Actor: Cert Admin

As a first step of using 'the product' the admin creates a root certificate for the certificate authority established. 

### Steps

1. admin logs into the system
2. admin fills in the fields 'name', 'keysize', 'expires', 'password' and 'hostname'
3. admin hits 'create' button

### Result

The system will create a CA cert and store it to the local keystore. Further the cert will be deployed into jetty for use with the local eXistdb installation.
 
The admin is messaged about the successful creation.

## 2. list certs

### Actor: Cert Admin

At any time the Cert Admin can list all certs issued for a given CA.

### Steps

## 3. display cert

### Actor: Cert Admin
### Actor: Cert User

### Steps

## 4. issue cert

### Actor: Cert Admin

### Steps

## 5. revoke cert
### Actor: Cert Admin
### Steps

## 6. renew CA
### Actor: Cert Admin
### Steps

## 7. renew cert
### Actor: Cert Admin
### Steps

## 8. request cert
### Actor: Cert User
### Steps

## 9. install cert
### Actor: Cert User, Cert Admin
### Steps

## 10. request renewal
### Actor: Cert User
### Steps

## 11. request revocation
### Actor: Cert User
### Steps


# use case candidates

This section list further use cases that may be explored later on in detail.

### establish vpn ***

### create mail cert

### manage docs (securely) **

### safe environment *
