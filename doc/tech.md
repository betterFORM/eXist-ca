# Software only, VM Images, Appliances, Server Deployment?

Whatever.  The software should run on any modern Unix-like operating system.

Currently no support for MS Windows platforms.  OpenSSL and EasyRSA are 
supported, as OpenVPN runs fine on Windows.  eXist does run on Windows. 
Most work is probably to port the CA wrapper scripts to Windows Shell.

We are focussed on building products (appliances or server solutions, or 
even VM images), running on Linux or *BSD.

# OpenBSD

We have a prototype appliance running OpenBSD 5.6 on a spare Dell PE750. 

Any modern Unix will do (Linux, BSD, Solaris), we have chosen OpenBSD for 
general OS security and reliability.

And because OpenBSD includes LibreSSL 2.0.  LibreSSL is OpenBSDs 
re-implementation of OpenSSL.  LibreSSL is the result of a massive code 
audit of OpenSSL, ripping out and fixing a lot of dirty code as well as 
adding better stuff like EC crypto.  I expect LibreSSL to be the most 
secure, best audited SSL implementation available.

# Software Stack

Sun/Oracle Java7 is available as installable package for OpenBSD 5.6. 
eXist was installed from zip file.  EasyRSA are just shell scripts. 
OpenSSL is in the base OS (under the hood it's LibreSSL, fully compatible). 

Setting up a CA and issuing certs: works fine.

# Application Testing

Proof vs. pudding: I'm preparing a test setup with OpenVPN to see if 
everything works as expected.  Work in progress.

