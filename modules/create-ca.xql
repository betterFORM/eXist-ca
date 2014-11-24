xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $config := 
    <CA name="Example CA" keysize="4096" expire="3650" 
    	servername="existca.example.org">
        <capass>craps</capass>
    </CA>

let $options :=
   <options>
       <workingDir>/Users/joern/dev/eXist-ca/ca-scripts</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$config/@name}"/>
           <env name="EXISTCA_CAKEYSIZE" value="{$config/@keysize}"/>
           <env name="EXISTCA_CAEXPIRE" value="{$config/@expire}"/>
           <env name="EXISTCA_CAPASS" value="{$config/capass}"/>
           <env name="EXISTCA_SRVNAME" value="{$config/@servername}"/>
           <env name="EXISTCA_SRVKEYSIZE" value="{$config/@keysize}"/>
           <env name="EXISTCA_SRVEXPIRE" value="{$config/@expire}"/>
       </environment>
       <!-- myopt>myopt</myopt -->
   </options>

return
(process:execute(("sh", "/Users/joern/dev/eXist-ca/ca-scripts/create-ca.sh"), $options))

(: sample data access
return "export KEY_COUNTRY='" || data($config/country) || "'":)
:)

