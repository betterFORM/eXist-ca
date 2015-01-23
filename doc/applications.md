# Applications

This document explains what "theproject" can be used for, from a high-level 
point of view.

Recommended reading: metaphors.md

## General

You have created your trust center (the Certification Authority [CA]) and 
are ready to issue certificates.  Let's look at some real life problems 
where certificates come into play.

## Email Encryption (End-to-End)

Alice, Bob and Charlie want encrypted emails when emailing each other. They 
still communicate unencrypted with customers, colleages or mailing lists, 
but they want their confidential communication protected by strong 
cryptography.

They agree to use the S/MIME standard for email encryption which is available 
for most email clients. S/MIME builds around X.509 certificates, which are 
exactly what "theproject" provides. So they

- create their own trust center called "ABC CA"
- use "ABC CA" to create 3 client certificates for Alice, Bob and Charlie
- install the "ABC CA" certificate into their mail client
- install their personal client certificate into their mail client
- start mailing each other. encrypted

[detailed description missing]

NOTE: this is email "end-to-end" encryption where encryption/decryption 
happens inside the email client and "crypted blob email content" is sent 
over possibly unencrypted SMTP transports. Do not confuse this with SMTP 
transport encryption, where mail servers encrypt their peer-to-peer 
communication in order to transport possibly unencrypted emails.

Basically, "end-to-end" encryption is what email users want, while 
"transport encryption" is only relevant to mail server admins [see below]. 
Having both on top of each other is just fine.

NOTE: PGP/GPG encryption not covered here.

## VPN Access to Company (or Cloud) Resources via OpenVPN

Alice, Bob and Charlie are now CEOs of a startup company, and they want full 
access from their home computers to data in the company's accounting and 
engineering departments.

And some of the staff work from home or need remote access for other reasons: 
Dan is an admin who needs to have access to all company and cloud servers. 
Eliza is an engineer who needs access to project data on her workgroup share. 
Fritz is a sales road warrior, often connecting from hotel networks to read 
emails and access the CRM web interface.

All of their network usage should be considered confidential, requiring 
encryption. So they

- reuse the existing "ABC CA" trust center (or create a new one)
- use "ABC CA" to create 3 more client certificates for Dan, Eliza and Fritz
- configure the OpenVPN subsystem on the "theproject" appliance
- install OpenVPN on their Windows/Mac/Unix computers
- install their customized OpenVPN client config files
- connect and authenticate to the OpenVPN gateway
- access company resources

[detailed description missing]

NOTE: this is a bit simplified, the story mentioned the {boss,admin,eng,sales} 
roles for a reason. It is possible to assign finer grained access control, 
but that's out of scope for this document.

## VPN Access to Company (or Cloud) Resources via IPsec

Similar to above, but support IPsec VPNs instead of OpenVPN.

## Encrypted Access to Closed User Group Web Services

The ABC startup plans to provide confidential price lists to selected 
resellers.  Access must be encrypted, authentication not required to keep 
it simple. So they

- reuse the existing "ABC CA" trust center (or create a new one)
- use "ABC CA" to create one or more reseller client certificates
- use "ABC CA" to create a server certificate for the "reseller.example.com" web server
- configure the web server to require strong encryption and a certficate issued by "ABC CA"
- offer a link "click here to install reseller cert"
- certificates get installed into resellers web browser
- reseller can access price lists




## Email Transport Encryption

[...]
