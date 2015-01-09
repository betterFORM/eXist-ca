xquery version "3.0";

(:module namespace ca="http://mecastle.com";:)

import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";

(: 
 : returns a ca cert for import in browser. Browser will respond with dialog for importing the CA. 
 :)
 
let $foo := response:set-header("content-type","application/x-x509-ca-cert")
let $result := $existca:pki-home || "/myname/ca.crt"
return file:read($result)
    