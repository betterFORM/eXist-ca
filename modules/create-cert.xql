xquery version "3.0";

import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";
import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";


let $ca-home := $existca:ca-home
let $pki-home := $ca-home || '/pki'

let $data := request:get-data()
(:let $data := <CA name="asasasas" nicename="asasasas  ">:)
(:    <keysize>4096</keysize>:)
(:    <expire>1095</expire>:)
(:    <capass>a</capass>:)
(:    <cacert>-----BEGIN CERTIFICATE----- MIIFMjCCAxqgAwIBAgIJANVWgFt1AzssMA0GCSqGSIb3DQEBCwUAMBUxEzARBgNV BAMMCmFzYXNhc2FzICAwHhcNMTUwMTAyMjI0NzA2WhcNMTgwMTAxMjI0NzA2WjAV MRMwEQYDVQQDDAphc2FzYXNhcyAgMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC CgKCAgEApoUoijEzAGJUQTA5NPW1BBUFYTflw55f0PeIBTg7yLFUzrpeOIxG0Ezo 1GDZ85HvS5VIBRLNPiwXfCwM6A2/Jh6EbslSyvBbVdVcLkw6OUNBwsblL9g4C8if koskXpYqq3onFPpkfSy+vmUfwX0az+xPkmcodGwkjYOw6MHRAslYm0ZV6IMepRLE xqTbL7GVbw6Asr1ViDDp8tB7Qawlch2k0jU9Xu3pmzHdE/bgc13NWAvguQPQ4ooF RvLYGmuHAvYaoXbJsqTr1gm1umyRgA2m7gdaXszjEWTS0/VCKxxKZhnhHRTnBQDK VxgJpe4GPTxHbUZO5j5IxxaKXXOIRCRaFTQ6fXcGDbQ3Zigszq2BMIe4lAY6YU8k yhM2RyGvbTLOp+h+7JNug7l/XRgWo/i8yyxtS8zZu7YQ3ax6oxlUv3MZlTZFq5DU E4+PULsrjt05ZtbMTP8y9Z/pBbHJGWTsC1DBcBmec2QisCPWvdIdojb3kX+BU0WX hHFvpPNGHG4eSXcVlj3rAZpp5A5vRKavetDT6GsPR0PGAQG+hsc7D5MPkm4Dg/C4 3/5dyAOKIQhpJXgNsq3M/e8lpjQHKPvi+pji78JyGgbS1QYza+E4jYLdCQ8OJtDl wcvKMVUCFkpyjtCYp/kx26jgjz7rU0gd2wLpkw54mhh4BoRqM0UCAwEAAaOBhDCB gTAdBgNVHQ4EFgQU2YBzSXvpjmVVMsGicO1Ol6UXRPwwRQYDVR0jBD4wPIAU2YBz SXvpjmVVMsGicO1Ol6UXRPyhGaQXMBUxEzARBgNVBAMMCmFzYXNhc2FzICCCCQDV VoBbdQM7LDAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkqhkiG9w0BAQsF AAOCAgEAieEGo3GFZulw43dTphr5b5hhQquZtZeAZjm54Ppf/rMa9P4QIpqpih5k vx+/dvsSTUMYC8w4y8bUqACowbUwVD3CNXBgLlyeoAAMzRJtCv2c0Q2aVY9h80/z O0TuO9Jt1zIwVK1V7hng3FAUFlC0OZrTHkekRyIWwNVZ/LzVQJoGIPa7PRGSftNW bl886GhT+GjsgLYjtZjPivy0ODCR8eguo0pCHlO8KP7pvdm4hJ03iS9AIvsN2afx NTdbNAKx1o44+7+4ue4kdJgDCQxv0+5OhhbGbGBZrRHkeEbTS6ebmv76j7u9TnCQ V7BgtAC/1uBtB0NowsWUC/hCslctzulk82xHh4WFeHyKSAzphbyXVZZ96zz/XWjo Fqeut+KwkN/n4VVS5Cb5cPzglGg+IZSz7m6E/WSat35pWvFGU4yh9osb9B6zmdZn syAflL8j33kuPWcoOr2WcHKW41zL436rL5QVU1YElTCighB+SnNF/68mgtbANGzz /GjYuh/XQ/jKER9ZnutX45yIhZkO+cUQeoJXlpSgLsEVCoaEPn4x/TyzYV7RwOB/ 16xnL2yC0iEVnP6AbeL5DyVmPILwE/VvSTZMKBJ3qt8mvTooHWVhNF0gbxM341oV gFz7DOzxop07Rfz1eQSBctzxexLYODlSUkPGw9fwriW5wdv4bvs= -----END CERTIFICATE-----</cacert>:)
(:    <cakey>-----BEGIN RSA PRIVATE KEY----- Proc-Type: 4,ENCRYPTED DEK-Info: DES-EDE3-CBC,F29F1727997DAFBC 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 -----END RSA PRIVATE KEY-----</cakey>:)
(:    <current-serial>01</current-serial>:)
(:    <expiry-date>Jan 1 22:47:06 2018 GMT</expiry-date>:)
(:    <dnsname>test</dnsname>:)
(:    <country/>:)
(:    <province/>:)
(:    <city/>:)
(:    <org/>:)
(:    <org-unit/>:)
(:    <email/>:)
(:    <certs/>:)
(:</CA>:)
 
 
(: 
 : prepare options for calling external ca-scripts/create-casrvcert.sh via shell
 :)
 
let $casrvcert-tmp := $pki-home || '/' || util:uuid() || '.xml'

let $create-cert-options :=
   <options>
       <workingDir>{$ca-home}</workingDir>
       <environment>
           <env name="EXISTCA_CAPASS" value="{$data//capass}"/>
           <env name="EXISTCA_CANAME" value="{$data//@name}"/>
           <env name="EXISTCA_CERTNAME" value="{$data//dnsname}"/>
           <env name="EXISTCA_CERTPASS" value="{$data//capass}"/>
           <env name="EXISTCA_CERTTYPE" value="server"/>
           <env name="EXISTCA_CERTKEYSIZE" value="{$data//keysize}"/>
           <env name="EXISTCA_CERTEXPIRE" value="{$data//expire}"/>
           <env name="EXISTCA_CERTCOUNTRY" value="{$data//country}"/>
           <env name="EXISTCA_CERTPROVINCE" value="{$data//province}"/>
           <env name="EXISTCA_CERTCITY" value="{$data//city}"/>
           <env name="EXISTCA_CERTORG" value="{$data//org}"/>
           <env name="EXISTCA_CERTOU" value="{$data//org-unit}"/>
           <env name="EXISTCA_CERTEMAIL" value="{$data//email}"/>
           <env name="EXISTCA_HOME" value="{$ca-home}"/>
           <env name="EXISTCA_XMLOUT" value="{$casrvcert-tmp}"/>
           <env name="PKI_BASE" value="{$pki-home}"/>
            <env name="DEBUG" value="1"/>
       </environment>
   </options>

let $result := (process:execute(("sh", "create-cert.sh"), $create-cert-options))

let $generated-cert-file:=util:parse(file:read($casrvcert-tmp))

let $foo := if($result/@exitCode=0) then
        let $cert-data-collection := $existca:cert-data-collection || "/" || $data//@name
        let $resourceName := util:uuid() || ".xml"
        return xmldb:store($cert-data-collection, $resourceName, $generated-cert-file)
else ()

return $result
