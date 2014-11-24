# Usage primitives

This is a list of basic operations ("usage primitives") that map to 
individual web forms.  For all usage primitives, a list of parameters 
that are needed from user input is specified. These parameters correspond 
to the required input fields of the corresponding web forms.

## traditional vs. simple certificate common names

X.509 certificates are issued to a "common name" (CN) that identifies the 
certificate holder. This is usually either a person or a network service.

Traditionally, X.509 certs had information about organisation, city, 
province, state etc encoded into the cert, so its textual representation 
would look like this:
"/C=DE/ST=Berlin/L=Berlin/O=Foobar_Project/CN=John_Doe/emailAddress=...".
This was because X.509 certs were thought to be used with and stored in 
LDAP directories.

A more modern approach is to simply omit the organisation, city, province, 
state etc information. If these data is not used anyway, there is no need 
to encode it into the certs. Also there is no need to query them from the 
web forms, so the forms can be much simpler (fewer input elements).

eXistCA now defaults to this simpler modern approach. The traditional style 
should be available in eXistCA "Expert Mode".

## Multiple CAs

eXistCA should be able to support multiple CAs (eg testing and production). 
The implementation MUST NOT assume a single CA instance.

## Expert Mode

eXistCA should be as easy to use as possible, hiding complexity from the end 
user.  Advanced features should be available by selecting an "Expert Mode" 
checkbox, which should display further user input options that are not 
visible in the default view.

Expert Mode should currently allow:
- traditional X.509 Org/City/State.. common name encoding
- modern EC (elliptic curve) crypto algorithms

Elliptic curve crypto is not understood by all application software and for 
that reason hidden in "Expert Mode".

## General Hints

With increasing (RSA) key size, crypto operations need more processing power. 
This implies:
- harder to break for an adversary
- slower for you and your peers

We recommend a 4096 bit RSA key for the CA certificate. You may want to use 
a 2048 bit RSA key if you prefer faster operation and care less about 
powerful attackers decrypting your communication (NSA and friends). You 
may want to choose 8192 bit if you really worry.

For user certificates we recommend 2048 bit RSA keys. Choose 1024 bit if you 
don't worry much, choose 4096 bit if you do. For servers, 1024 bit may be 
useful to allow faster responses on crypto protected services.

Using RSA keys >8192 bit does not make much sense because your services 
may timeout before crypto operations finished.
Using RSA keys <1024 bit is not recommended. This may be broken by an 
attacker with sufficient resources.

A better way to address the Keysize/Proctime issue is to use elliptic 
curve crypto (as in eXistCA "Expert Mode"). Not all crypto peers do 
understand that yet.

# Usage Primitives

## About selecting the start page

- if no CA has been created yet, show the create-ca page
- if only one CA has been created, show the display-ca page
- if more than one CA has been created, show the select-ca page

## About certificate generation

In earlier versions we used a script "create-cert.sh" to create a client 
or server certificate.  This assumed a "trusted admin" scenario, like 
"admin, please create a user cert for John Doe and assign him a password". 

Problem is, admin would need to know and enter John's private password in 
cleartext.  Not the best way to build trust..

This is now split up in two parts:
- request-cert is a form filled out by users to create a certificate request, 
which means creating a user password protected key pair along with some meta 
information ("John Doe").  The CA password is not required.
- sign-cert will be run by the CA admin (CA password required) to sign the 
cert and export it to PKCS12 format.  The user password is not required.

## create-ca

Purpose: initial CA setup page.  All other operations require that at 
least one CA has been created, so this should be the enforced start page 
until a CA has been set up.

Desc: query all required parameters to initially create a CA from user 
input, then call an eXistCA wrapper script to perform all CA setup steps.
These steps include initializing a CA, creating and installing a server 
cert for the eXist Jetty, and a few system level operations.

Input Fields: there are 2 groups of fields, one for data pertaining to the 
CA itself and another for data pertaining to the web server cert to be 
installed into eXist/Jetty.  These should probably a third group (or sub 
page) to network settings for the CA appliance. not covered yet.

First group: data for CA creation

- "CA Name"
-- UI type: textfield
-- data type: simple string
-- default value: "Example CA"
-- env var passed to wrapper scripts: EXISTCA_CANAME

- "CA Key Size"
-- UI type: select, values ("RSA 2048 bit":2048, "RSA 4096 bit":4096, "RSA 8192 bit":8192)
-- data type: integer
-- default value: 4096
-- env var passed to wrapper scripts:  EXISTCA_CAKEYSIZE

- "CA Validity"
-- UI type: select, values ("1 year":365, "3 years":1095, "5yrs":1825, "10yrs":3650)
-- data type: integer
-- default value: "5 years":1825
-- env var passed to wrapper scripts: EXISTCA_CAEXPIRE
-- remarks: could be a combo box (choose value or type a number)

- "CA Password"
-- UI type: textfield, password
-- data type: string
-- default value: [none]
-- env var passed to wrapper scripts:  EXISTCA_CAPASS
-- remarks: 2 password fields to confirm, check values match

Second group: data for eXistCA web server cert

- "Server Name" (DNS name of eXistCA web server host)
-- UI type: textfield
-- data type: valid DNS name
-- default value: "existca.example.org"
-- env var passed to wrapper scripts: EXISTCA_SRVNAME

- "Server Cert Key Size"
-- UI type: select, values (1024, 2048, 4096, 8192)
-- data type: integer
-- default value: 2048
-- env var passed to wrapper scripts:  EXISTCA_SRVKEYSIZE

- "Server Cert Validity"
-- UI type: select, values ("1 year":365, "3 years":1095, "5yrs":1825, "10yrs":3650)
-- data type: integer
-- default value: "5 years":1825
-- env var passed to wrapper scripts: EXISTCA_SRVEXPIRE
-- not even needed, use same validity as for CA

## display-ca

Purpose: display metadata about the selected CA (CA name, valid until). 
Display the "Expert Mode" checkbox for this CA.  Display a list of pending 
cert requests that wait for signing.  By selecting a cert request from this 
list, a CA admin may sign the request.
Display a list of all certs issued by this CA and their status (valid, 
revoked).  By selecting a cert from this list, operations that work on 
this cert may be triggered (renew, revoke).

## select-ca

Purpose: if more than one CA has been created, display a simple page with 
"Please select the CA to work on".  To avoid workflow confusion, the 
relevant CA for cert operations should be explicitly queried and passed 
to subsequent forms.

Choosing a CA should call display-ca for that CA.

- "Select CA"
-- UI type: select, values [available CAs]
-- data type: string
-- default value: [none]
-- env var passed to wrapper scripts:  EXISTCA_CANAME

## request-cert

Purpose: allow unprivileged users to request a cert without needing to know 
the CA password.  If successful, the request is put into the queue of 
pending cert waiting to be signed by a CA admin.

- "Certificate Name" (user name or server DNS name)
-- UI type: textfield
-- data type: string
-- default value: [none]
-- env var passed to wrapper scripts: EXISTCA_CERTNAME

- "Certificate Password"
-- UI type: textfield, password
-- data type: string
-- default value: [none]
-- env var passed to wrapper scripts:  EXISTCA_CERTPASS
-- remarks: 2 password fields to confirm, check values match

- "Certificate Key Size"
-- UI type: select, values (1024, 2048, 4096, 8192)
-- data type: integer
-- default value: 2048
-- env var passed to wrapper scripts:  EXISTCA_CERTKEYSIZE

## sign-cert

Purpose: allow a CA admin to sign a pending cert. 

## revoke-cert

Purpose: revoke a previously issued cert.

## renew-cert

Purpose: renew a previously issued cert.

[not implemented yet]

