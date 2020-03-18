#-----functions start----------------------------------------------------------------------------------------
#function which can be used to get rid of diacritics and special chars
function get-sanitizedUTF8Input {
    Param(
        [String]$inputString
    )
    $replaceTable = @{"ß" = "ss"; "à" = "a"; "á" = "a"; "â" = "a"; "ã" = "a"; "ä" = "a"; "å" = "a";
     "æ" = "ae"; "ç" = "c"; "è" = "e"; "é" = "e"; "ê" = "e"; "ë" = "e"; "ì" = "i"; "í" = "i";
     "î" = "i"; "ï" = "i"; "ð" = "d"; "ñ" = "n"; "ò" = "o"; "ó" = "o"; "ô" = "o"; "õ" = "o";
     "ö" = "o"; "ø" = "o"; "ù" = "u"; "ú" = "u"; "û" = "u"; "ü" = "u"; "ý" = "y"; "þ" = "p";
     "ÿ" = "y" }

    foreach ($key in $replaceTable.Keys) {
        $inputString = $inputString -Replace ($key, $replaceTable.$key)
    }
    $inputString = $inputString -replace '[^a-zA-Z0-9]', ''
    return $inputString
}
#function used to get certain random characters for the password string
function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 
#function used to scramble the password string
function Scramble-String([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}
 
#-----functions end----------------------------------------------------------------------------------------



[array]$sourceUsers = Import-csv -Delimiter ";" -encoding "utf8" -Path "C:\Skripts\159\adusers.csv"
#initialise empty array
$finalUsers = @()

#set usercount to 1
$userCount = 0
$userBaseOu = "ou=User,ou=Verwaltung,dc=gertzenstein,dc=local"
$gid = $null
$uidCount = 1000
[array]$output = $null
[array]$test = $null





#loop through each user
foreach ($sourceUser in $sourceUsers) {
    $surname = get-sanitizedUTF8Input $sourceUser.surname
    $givenname = get-sanitizedUTF8Input $sourceUser.givenname
    #$ignoreString = "deaktiviert"
    #if (!($sourceUser.description -match $ignoreString)) {
    #define $userRole and groups !!all users are separated into individual if queries for later
    # group assignment!!
    #get instructors

    if ($sourceUser.description -match "Lehrer") {
        $userRole = "L"
        if ($sourceUser.description -match "Lehrer Gym") {
            $gid=505
        }
        elseif ($sourceUser.description -match "Lehrer Handel") {
            $gid=505
        }
        elseif ($sourceUser.description -match "Lehrer Sekundar") {
            $gid=507
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
    #overwrite gid if description matches "deaktiviert"
    if ($sourceUser.description -match "deaktiviert") {
        
    }

    #Convert int to string to allow leading 0's (new var is required, because otherwise you would 
    # have to convert it back to int to be able to ++ the counter)
    $sUserCount = $userCount.ToString("000000")
    #Create username 
    $username = $userRole + $sUserCount
    $password = Get-RandomCharacters -length 4 -characters 'abcdefghiklmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 4 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 1 -characters '1234567890'
    $password += Get-RandomCharacters -length 1 -characters '!"§$%&/()=?}][{@#*+'

    $password = Scramble-String $password

    #create object for current user and add object to $finalusers array
    $newUser = New-Object PSObject
    $newUser | Add-Member -type NoteProperty -Name 'surname' -Value $surname
    $newUser | Add-Member -type NoteProperty -Name 'givenname' -Value $givenName
    $newUser | Add-Member -type NoteProperty -Name 'username' -Value $username
    $newUser | Add-Member -type NoteProperty -Name 'description' -Value $sourceuser.Description
    $newUser | Add-Member -type NoteProperty -Name 'password' -Value $password
    
    $finalUsers += $newUser


    $output += "#-------------- User $username start --------------" + "`r`n" +
    "dn: uid=$username,ou=$userBaseOu" + "`r`n" +
    "cn: $surname $givenname" + "`r`n" +
    "sn: $surname" + "`r`n" +
    "givenname: $givenname" + "`r`n" +
    "homedirectory: /home/users/$username" + "`r`n" +
    "gidnumber: $gid" + "`r`n" +
    "objectclass: inetOrgPerson" + "`r`n" +
    "objectclass: posixAccount" + "`r`n" +
    "objectclass: top" + "`r`n" +
    "uid: $username" + "`r`n" +
    "uidnumber: $uidCount" + "`r`n" +
    "userPassword: $password" + "`r`n" +
    "#-------------- User $username end ---------------"
    #userCount +1
    $userCount++
    $uidCount++
    #}else{
    #Write-Host "User $givenname $surname was ignored, because his/her description contained the 
    # string '$ignoreString'"
    #Write-Host "Description: " $sourceUser.Description
    #}
    #Simple combination of names for later comparison to check for non unique accounts
    $test += $givenname + $surname 
    
}

$reference = $test | select-object -unique
Write-Host "Doppelte Benutzer anhand Kombination von Vor- und Nachname:" -ForegroundColor yellow
Compare-object –referenceobject $reference –differenceobject $test
$output | Out-File -Encoding utf8 -FilePath "C:\Skripts\159\output.ldif"