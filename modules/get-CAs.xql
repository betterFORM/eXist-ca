xquery version "3.0";
import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";

let $cert-data-collection := $existca:cert-data-collection

let $CA-exists := exists(collection($cert-data-collection)//CA)
let $result := if($CA-exists) then
    <data>{
        for $ca in collection($cert-data-collection)//CA
        return
            $ca
    }
    </data>
    else 
        <data>
            <noentries/>
        </data>

return $result

