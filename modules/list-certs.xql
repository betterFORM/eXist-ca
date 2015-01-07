xquery version "3.0";

import module namespace existca="http://exist-db.org/apps/existCA" at "ca-config.xqm";

let $cert-data-collection := $existca:cert-data-collection
return
    <table class="table">
        <thead>
            <tr>
                <td>Name</td>
                <td>Expires</td>
                <td>Status</td>
            </tr>
        </thead>
        {
            for $ca in collection($cert-data-collection)//cert[status]
            let $name := data($ca/@name)
            let $expires := data($ca/expiry-date)
            let $status :=
                switch (data($ca/status))
                case 'V'
                    return 
                        <td class="cert-valid">
                            <i class="fa fa-lock fa-lg active"/>
                        </td>
                    
                default
                    return ()
            return
                <tr class="cert">
                    <td><a href="{$name}">{$name}</a></td>
                    <td>{$expires}</td>
                    {$status}
                </tr>
        }
    </table>
