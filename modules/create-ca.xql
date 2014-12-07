xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

(:
import module namespace system="http://exist-db.org/xquery/system"
let $home := system:get-exist-home()
:)

let $ca-scripts := "/usr/local/eXistCA"

let $config := 
    <CA name="Example CA" keysize="4096" expire="3650" 
    	servername="existca.example.org">
        <capass>craps</capass>
    </CA>

let $options :=
   <options>
       <workingDir>$ca-scripts</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$config/@name}"/>
           <env name="EXISTCA_CAKEYSIZE" value="{$config/keysize}"/>
           <env name="EXISTCA_CAEXPIRE" value="{$config/expire}"/>
           <env name="EXISTCA_CAPASS" value="{$config/capass}"/>
           <env name="EXISTCA_CACOUNTRY" value="{$config/country}"/>
           <env name="EXISTCA_CAPROVINCE" value="{$config/province}"/>
           <env name="EXISTCA_CACITY" value="{$config/city}"/>
           <env name="EXISTCA_CAORG" value="{$config/org}"/>
           <env name="EXISTCA_CAOU" value="{$config/org-unit}"/>
           <env name="EXISTCA_CAEMAIL" value="{$config/email}"/>
           <env name="EXISTCA_SRVNAME" value="{$config/@servername}"/>
           <env name="EXISTCA_SRVKEYSIZE" value="{$config/keysize}"/>
           <env name="EXISTCA_SRVEXPIRE" value="{$config/expire}"/>
<!-- note "???" below
           <env name="EXISTCA_SRVCOUNTRY" value="{$config/???/country}"/>
           <env name="EXISTCA_SRVPROVINCE" value="{$config/???/province}"/>
           <env name="EXISTCA_SRVCITY" value="{$config/???/city}"/>
           <env name="EXISTCA_SRVORG" value="{$config/???/org}"/>
           <env name="EXISTCA_SRVOU" value="{$config/???/org-unit}"/>
           <env name="EXISTCA_SRVEMAIL" value="{$config/???/email}"/>
-->
       </environment>
       <!-- myopt>myopt</myopt -->
   </options>

return
(process:execute(("sh", $ca-scripts || "/create-ca.sh"), $options))

