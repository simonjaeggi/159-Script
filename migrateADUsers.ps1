[array]$sourceUsers = Import-csv -Delimiter ";" -encoding "utf8" -Path "C:\Skripts\159\adusers.csv"
#initialise empty array
$finalUsers = @()

#set usercount to 1
$userCount = 0
$userBaseOu =  "ou=User,ou=Verwaltung,dc=gertzenstein,dc=local"
$gid=$null
$uidCount = 1000
#function which can be used to get rid of diacritics and special chars
function get-sanitizedUTF8Input {
    Param(
        [String]$inputString
    )
    $replaceTable = @{"ß" = "ss"; "à" = "a"; "á" = "a"; "â" = "a"; "ã" = "a"; "ä" = "a"; "å" = "a"; "æ" = "ae"; "ç" = "c"; "è" = "e"; "é" = "e"; "ê" = "e"; "ë" = "e"; "ì" = "i"; "í" = "i"; "î" = "i"; "ï" = "i"; "ð" = "d"; "ñ" = "n"; "ò" = "o"; "ó" = "o"; "ô" = "o"; "õ" = "o"; "ö" = "o"; "ø" = "o"; "ù" = "u"; "ú" = "u"; "û" = "u"; "ü" = "u"; "ý" = "y"; "þ" = "p"; "ÿ" = "y" }

    foreach ($key in $replaceTable.Keys) {
        $inputString = $inputString -Replace ($key, $replaceTable.$key)
    }
    $inputString = $inputString -replace '[^a-zA-Z0-9]', ''
    return $inputString
}


#loop through each user
foreach ($sourceUser in $sourceUsers) {
    $surname = get-sanitizedUTF8Input $sourceUser.surname
    $givenname = get-sanitizedUTF8Input $sourceUser.givenname
    $ignoreString = "deaktiviert"
    if (!($sourceUser.description -match $ignoreString)) {
        #define $userRole and groups !!all users are separated into individual if queries for later group assignment!!
        #get instructors
        if ($sourceUser.description -match "Lehrer") {
            $userRole = "L"
            if ($sourceUser.description -match "Lehrer Gym") {

            }
            elseif ($sourceUser.description -match "Lehrer Handel") {

            }
            elseif ($sourceUser.description -match "Lehrer Sekundar") {

            }
        }
        #get students
        elseif ($sourceUser.description -match "Oberstufe - Matur") {
            $userRole = "S"
        }
        elseif ($sourceUser.description -match "Oberstufe extern") {
            $userRole = "S"
        }
        elseif ($sourceUser.description -match "Sekundar extern") {
            $userRole = "S"
        }
        elseif ($sourceUser.description -match "Sekundar") {
            $userRole = "S"
        }
        elseif ($sourceUser.description -match "Handelsmatur") {
            $userRole = "S"
        }
        #get management people
        elseif ($sourceUser.description -match "Leitung") {
            $userRole = "A"
        }
        elseif ($sourceUser.description -match "Verwaltung") {
            $userRole = "A"
        }

        #default if there is no match
        else {
            $userRole = "S"
        }

        #Convert int to string to allow leading 0's (new var is required, because otherwise you would have to convert it back to int to be able to ++ the counter)
        $sUserCount = $userCount.ToString("000000")
        #Create username 
        $username = $userRole + $sUserCount

        #create object for current user and add object to $finalusers array
        $newUser = New-Object PSObject
        $newUser | Add-Member -type NoteProperty -Name 'surname' -Value $surname
        $newUser | Add-Member -type NoteProperty -Name 'givenname' -Value $givenName
        $newUser | Add-Member -type NoteProperty -Name 'username' -Value $username
        $newUser | Add-Member -type NoteProperty -Name 'description' -Value $sourceuser.Description
        $finalUsers += $newUser


        $output += "#-------------- User $username start --------------"
        $output += "dn: uid=$username,ou=$userBaseOu"
        $output += "cn: $surname $givenname"
        $output += "sn: $surname"
        $output += "givenname: $givenname"
        $output += "homedirectory: /home/users/$username"
        $output += "gidnumber: $gid"
        $output += "objectclass: inetOrgPerson"
        $output += "objectclass: posixAccount"
        $output += "objectclass: top"
        $output += "uid: $username"
        $output += "uidnumber: $uidCount"
        $output += "#-------------- User $username end ---------------"
        #userCount +1
        $userCount++
        $uidCount++
    }else{
        #Write-Host "User $givenname $surname was ignored, because his/her description contained the string '$ignoreString'"
        #Write-Host "Description: " $sourceUser.Description
    }
    
}



