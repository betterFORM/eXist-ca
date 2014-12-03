xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $ca-scripts := "/usr/local/eXistCA"

let $config := 
    <CA name="Example CA">
        <capass>craps</capass>
	<pend-req name="www.example.org" type="server" expire="1825"/>
    </CA>

let $options :=
   <options>
       <workingDir>$ca-scripts</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$config/@name}"/>
           <env name="EXISTCA_CAPASS" value="{$config/capass}"/>
           <env name="EXISTCA_CERTNAME" value="{$config/pend-req/@name}"/>
           <env name="EXISTCA_CERTTYPE" value="{$config/pend-req/@type}"/>
           <env name="EXISTCA_CERTEXPIRE" value="{$config/pend-req/@expire}"/>
       </environment>
       <!-- myopt>myopt</myopt -->
   </options>

return
(process:execute(("sh",  $ca-scripts || "/renew-cert.sh"), $options))

