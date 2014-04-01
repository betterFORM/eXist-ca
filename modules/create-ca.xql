xquery version "3.0";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";

let $options :=
   <options>
       <workingDir>/tmp</workingDir>    
   </options>

let $config := <CA>
        <country>DE</country>
    <province/>
    <city/>
    <org/>
    <org-unit/>
    <email/>
    <expire-days>1825</expire-days>
    <pass/>
    <!-- list of fixed values for key-size 1024, 2048... -->
    <key-size>2048</key-size>
    <server-certs>
        <server-dns-name/>
    </server-certs>
    <client-certs>
        <cert>
            <email/>
            <pass/>
            <expiry/>
        </cert>
    </client-certs>
    <defaults>
        <client expire=""/>
        <server expire=""/>
    </defaults>
</CA>

process:execute(("sh", "/tmp/createca.sh"), $options)
#return "export KEY_COUNTRY='" || data($config/country) || "'"

(: 
    1. write vars file to working directory
    2. call create-ca.sh
       process:execute(("sh", "create-ca"), $options)

    2a. create server cert
    2b. deploy server cert
    3. restart server

:)

