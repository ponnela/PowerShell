# Pekka Onnela 
Import-Module AzureAD
import-module ActiveDirectory
Connect-AzureAD -Credential

$AZPrefix= "AZ" # Jos halutaan azure-ryhmän nimestä poistaa jotain ennen OnPremryhmän nimen muodostamista
$ADPrefix= "AD" # Jos halutaan ad-ryhmän nimeen lisätä jotain ennen OnPremryhmän nimen muodostamista

$azgroupstosyncgroup=Get-AzureADGroup -SearchString "AZGroupsToSync" # Luetaan tästä Azure-ryhmästä synkronoitavat ryhmät

$GroupsToSync=Get-AzureADGroupMember -ObjectId $azgroupstosyncgroup.ObjectId -All $true # Haetaan synronoitavat ryhmät

foreach ($group in $GroupsToSync)
   {
   $AzureGroupMembers=Get-AzureADGroupMember -ObjectId $group.ObjectId -All $true 
   $ADGroupName=$group.DisplayName -replace $AZPrefix , $ADPrefix
   $ADGroupMembers=Get-ADGroupMember -Identity $ADGroupName
   foreach ($user in $AzureGroupMembers)
      {
      if ($ADGroupMembers.distinguishedName -ccontains $user.ExtensionProperty.onPremisesDistinguishedName) 
         {
         # Jos käyttäjä oli jo ryhmässä jäsenenä 
         if ($ADGroupMembers.Count)
            {
            $ADGroupMembers = $ADGroupMembers | Where-Object {$_.distinguishedName -ne $user.ExtensionProperty.onPremisesDistinguishedName}
            }
         else
            {
            $ADGroupMembers = ""
            }
         }
      else
         {
          # Lisätään uusi käyttäjä ryhmään
         Add-ADGroupMember -Identity $ADGroupName -Members $user.ExtensionProperty.onPremisesDistinguishedName
         }
      }
   if ($ADGroupMembers)
      {
      # Poistetaan ryhmästä jäsenet joita ei ole Azuren ryhmän jäseninä
      foreach ($aduser in $ADGroupMembers)
         {
         Remove-ADGroupMember -Identity $ADGroupName -Members $aduser.distinguishedName -Confirm:$false
         }
      }
   }



