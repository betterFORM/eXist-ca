xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $ca-scripts := "/usr/local/eXistCA"

let $config := 
    <CA name="Example CA">
        <capass>craps</capass>
	<revoke name="www.example.org"/>
    </CA>

let $options :=
   <options>
       <workingDir>$ca-scripts</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$config/@name}"/>
           <env name="EXISTCA_CAPASS" value="{$config/capass}"/>
       </environment>
       <!-- myopt>myopt</myopt -->
   </options>

return
(process:execute(("sh", $ca-scripts || "/gen-crl.sh"), $options))

