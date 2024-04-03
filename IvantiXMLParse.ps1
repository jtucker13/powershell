#Takes an xml from Ivanti export and runs down the tree via recursion, gathering useful info into an arraylist of custom objects
#Arraylist is exported into a CSV format once the traversal is complete
#Written by Josh Tucker 3/28/24
param(
    [Parameter(Mandatory)]$XMLIn, 
    [Parameter(Mandatory)]$CSVOut,
    [switch]$UserGroup
    )  
    if($UserGroup){$xpath = "//*[@Identifier='UEM.Condition.UserGroupMembership']"}
    $l1Nodes = Select-XML $XMLIn -XPath $xpath|Select-Object -ExpandProperty Node
    $usefulInfo = [System.Collections.ArrayList]@()
    function CheckNode{
        param(
            $node,
            $parentGroupName,
            $addQuals
            )
        if($node.Identifier -notlike "UEM.Condition*"){
            $listitem=[PSCustomObject]@{
                Group = $parentGroupName
                AdditionalQuals = $addQuals
                Type = $node.Identifier
                Action = $node.Name
                Enabled = $node.Enabled
            }
            $Global:usefulInfo.Add($listitem)
        }
        else{
            $addQuals+=($node.Name+"::::")
            CheckNode($node.Actions.Action,$parentGroupName,$addQuals)
        }
    }
    foreach($l1node in $l1Nodes){
        $l2Nodes = $l1node.Actions.Action
        foreach($l2node in $l2Nodes)
        {
            CheckNode($l2node,($l1node.Name).Substring(23),"")         
        }    
    }
    $usefulInfo| Export-Csv -path $CSVOut
    #L2 Node (select-xml c:\temp\shortcuts.xml -Xpath "//*[@Identifier='UEM.Condition.UserGroupMembership']"|Select-Object -Exp Node).Actions.Action
    #(select-xml c:\temp\shortcuts.xml -Xpath "//*[@Identifier='UEM.Condition.UserGroupMembership']"|Select-Object -Exp Node).Actions.Action.Actions.Action.Identifier