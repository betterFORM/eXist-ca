# overview of the backend components

- parameters for CA or cert manipulation are collected from XForms.
- on submit, scripts shipped with eXistCA get called. these are rather 
  simple wrapper scripts that call scripts from the "EasyRSA" software.
- EasyRSA is a seperate open source software package for simple manipulation 
  of X.509 certificates.  EasyRSA should be shipped with eXistCA, but there's 
  no need to fork it.
- EasyRSA is a wrapper around the "openssl" binary from the OpenSSL software.
- the openssl binary performs all crypto and encoding operations to create 
  certs and CA infrastructure.  These are files in a certain directory with 
  well-defined names and semantics.
- XForms needs to pull generated cert files from the cert store and present 
  them to the user. It may serialize the certs for internal storage, but the 
  primary data store of certs is file based.

# details on eXistCA shell wrapper scripts

[to be written]

# details on EasyRSA operation

## CA initialization

The main purpose of eXistCA to create X.509 certificates for private use. 
A one-time initialization of a CA (certificate authority) is required 
before any certs can be issued. This CA initialization is performed by 
the eXistCA wrapper script "create-ca.sh".

CA initialization includes the following steps:

- read CA init parameters from XForms.
- run an XSLT transformation to merge these parameters into a template file. 
  This creates a file containing "personalized" configuration data for 
  EasyRSA (think organization, city, country). This file is required for 
  EasyRSA.
- initialize CA directories and data structures by calling EasyRSA scripts 
  from the eXistCA wrapper script.
- report back to XForms UI.

# changes to EasyRSA

There is no real *need* to change EasyRSA, but 2 simple changes may be useful:

- fetch required passwords by other means than interactive input
- patch out interactive confirmation in "clean-all"

# storage of ca scripts

ca scripts shall be deployed and stored as part of the XAR. By loading them
into the database as binaries these end up as binaries on disk and can be
read and referenced from XQuery


