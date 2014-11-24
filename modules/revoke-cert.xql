xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $config := 
    <CA name="Example CA">
        <capass>craps</capass>
	<revoke name="www.example.org"/>
    </CA>

let $options :=
   <options>
       <workingDir>/Users/joern/dev/eXist-ca/ca-scripts</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$config/@name}"/>
           <env name="EXISTCA_CAPASS" value="{$config/capass}"/>
           <env name="EXISTCA_CERTNAME" value="{$config/revoke/@name}"/>
       </environment>
       <!-- myopt>myopt</myopt -->
   </options>

return
(process:execute(("sh", "/Users/joern/dev/eXist-ca/ca-scripts/revoke-cert.sh"), $options))

(: sample data access
return "export KEY_COUNTRY='" || data($config/country) || "'":)
:)

