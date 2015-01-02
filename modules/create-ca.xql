xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";


let $ca-home := $existca:ca-home
let $pki-home := $ca-home || '/pki'

let $data := request:get-data()

(:let $data := :)
(:    <CA name="exist-db.org" nicename="">:)
(:        <keysize>4096</keysize>:)
(:        <expire>1825</expire>:)
(:        <capass>a</capass>:)
(:        <expiry-date>2019-12-22</expiry-date>:)
(:        <dnsname>x</dnsname>:)
(:        <country/>:)
(:        <province/>:)
(:        <city/>:)
(:        <org/>:)
(:        <org-unit/>:)
(:        <email/>:)
(:        <cacert/>:)
(:        <cakey/>:)
(:        <pending-requests>:)
(:            <req name="" type=""/>:)
(:        </pending-requests>:)
(:        <rejected-requests>:)
(:            <req name="" rej-reason="" type=""/>:)
(:        </rejected-requests>:)
(:    </CA>:)

(: 
 : prepare options for calling external ca-scripts via shell
 : todo: for unknown reasons using util:uuid instead of $data/@name did not work
 :)

let $cert-tmp := $existca:ca-home || '/pki/' || $data/@name || '.xml'

let $create-ca-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="EXISTCA_CANAME" value="{$data//@name}"/>
           <env name="EXISTCA_CAKEYSIZE" value="{$data//keysize}"/>
           <env name="EXISTCA_CAEXPIRE" value="{$data//expire}"/>
           <env name="EXISTCA_CAPASS" value="{$data//capass}"/>
           <env name="EXISTCA_CACOUNTRY" value="{$data//country}"/>
           <env name="EXISTCA_CAPROVINCE" value="{$data//province}"/>
           <env name="EXISTCA_CACITY" value="{$data//city}"/>
           <env name="EXISTCA_CAORG" value="{$data//org}"/>
           <env name="EXISTCA_CAOU" value="{$data//org-unit}"/>
           <env name="EXISTCA_CAEMAIL" value="{$data//email}"/>
           <env name="EXISTCA_XMLOUT" value="{$cert-tmp}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="PKI_BASE" value="{$pki-home}"/>
           <env name="DEBUG" value="1"/>
       </environment>
   </options>
 
 
let $result := (process:execute(("sh", "create-ca.sh"), $create-ca-options))


let $generated-cert-file:=util:parse(file:read($cert-tmp))
let $cert-collection-name := $generated-cert-file/CA/@name
let $cert-data-collection := xmldb:create-collection($existca:cert-data-collection, $cert-collection-name)

let $foo := if($result/@exitCode=0) then
        let $resourceName := "ca.xml"
        let $foo := xmldb:store($cert-data-collection, $resourceName, $generated-cert-file)
        return $generated-cert-file
        
else (
    <error>hello bullshit</error>
    )

return $foo

 
