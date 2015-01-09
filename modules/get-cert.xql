xquery version "3.0";

(:module namespace ca="http://mecastle.com";:)

import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";

(: returns a user cert :)

let $foo := response:set-header("content-type","application/x-x509-user-cert")
let $result := $existca:pki-home || "/myname/????"
return file:read($result)
    