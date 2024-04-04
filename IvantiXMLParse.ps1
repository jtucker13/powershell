#Takes an xml from Ivanti export and runs down the tree via recursion, gathering useful info into an arraylist of custom objects
#Arraylist is exported into a CSV format once the traversal is complete
#Written by Josh Tucker 3/28/24
param(
    [Parameter(Mandatory)]$XMLIn, 
    $CSVOut,
    [Parameter(Mandatory)][ValidateSet("UserGroup","FilePath")]$Type
)
    if($Type -eq "UserGroup"){$xpath = "//*[@Identifier='UEM.Condition.UserGroupMembership']"}
    if($Type -eq "FilePath"){$xpath = "//*[@Identifier='UEM.Condition.FileCondition']"}
    $l1Nodes = Select-XML $XMLIn -XPath $xpath|Select-Object -ExpandProperty Node
    $global:usefulInfo = [System.Collections.ArrayList]@()
    function CheckNode{
        param(
            $node,
            [String]$parentGroupName,
            [String]$addQuals
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
            CheckNode $node.Actions.Action $parentGroupName $addQuals
        }
    }
    foreach($l1node in $l1Nodes){
        $l2Nodes = $l1node.Actions.Action
        [String]$conditionGroup=($l1node.Name).Substring(23)
        foreach($l2node in $l2Nodes)
        {
            CheckNode $l2node $conditionGroup ""        
        }    
    }
    if($CSVOut){
        $Global:usefulInfo|Export-CSV -Path $CSVOut
    }
    else{$Global:usefulInfo}
    #L2 Node (select-xml c:\temp\shortcuts.xml -Xpath "//*[@Identifier='UEM.Condition.UserGroupMembership']"|Select-Object -Exp Node).Actions.Action
    #(select-xml c:\temp\shortcuts.xml -Xpath "//*[@Identifier='UEM.Condition.UserGroupMembership']"|Select-Object -Exp Node).Actions.Action.Actions.Action.Identifier