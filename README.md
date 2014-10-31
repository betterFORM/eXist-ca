# eXist CA

Anybody having access to this file is invited to contribute content!

## Motivation
Communication channels on the internet have become increasingly insecure by various breaches
of the underlying technologies and/or infrastructures. The big commercial trust centers have
been tempered in the past. As a result certificates issued by these authorities are immanently insecure
and cannot be trusted any more for data or communication privacy.

## Solution
Users of eXist will be able to setup a CA thereby becoming their own root certificate authority. This establishes a complete new chain of trust. Trusting
yourself is the only secure way today to establish real trusted computing.

## Requirements
Users must be able to:

* create root certificate (create trust chain)
* create client certificates
* revoke certificate
* renew certificate

### Other 
* The application is ideally delivered as a single package and must be easy to install on all operating systems.
* Must use the best encryption technology and tooling available (which includes being open source)

## Architecture
There will be a simple form-based front-end gathering the parameters needed and store them in data/CA-config.xml.

The front-end will call a xquery on the server to invoke the necessary scripts to be executed that invoke openssl.

## Applicability
The certs generated by this app can be used for:
* SSL
* code signing (XML signature)
* (email signing)

# Implementation

## System requirements
* openSSL  - has been choosen for the basic cert management functions as the most elaborate, open and trusted tool around
* eXist LTS 2.?
* openVPN (optional) when using easyRSA (openSSL facility scripts)

## Open questions
* When using easyRSA it would be convenient to package the scripts as binaries in the xar app. This way they would end up in the db but being stored on the filesystem. Is it possible to access those script (execute in a shell) from within an xquery?



# Backlight
(Information not fitting elsewhere)

The application is developed as private code as a first step until the marketing has been clarified. Marketing
discussions will be needed to explore the potential and scope for the application.

## Market
jt: As typical customer i invision small to medium organisations (e.g. in research and development, engeneering or
scientific domains) that have sensitive data to maintain and required strict privacy of their data.

### 'Product' ideas

The ideas below are not mutual exclusive. There might be combinations or overlaps.

* as part of dashboard for LTS users exclusively
* distributed as special 'secure eXist' or 'eXist hardboiled'
* as an OS imagine ready to run (Debian)
* same image can be made Amazon-ready (further marketing chances)
* a complete hardware appliance - 'eXist hardboxed'

