# we wants to reorganize all the photos into a folder structure like this
# 2010
#  |- 1-January
#    |- photo
#    |- photo
#    |- photo
#  |- 2-February
#    |- photo
#    |- photo
# etc.,...
#this will let us check exif data for "date taken"
# http://archive.msdn.microsoft.com/PowerShellPack
write-host "please wait while I import the PowerShellPack Module"
Import-Module PowerShellPack
write-host "moving.."
$basePath=$args[0] ## this is the path to get the images from
if (!$basePath){break}

$root = $args[1] ## this is the path to move the images to
if (!$root){break}
$count=0 ## count how many files moved
#$basePath = read-host "Type in the path to reorganize: "
#$basePath= "C:\users\andys\Pictures"
$files =  Get-ChildItem $basePath -force -recurse | Where-Object { !$_.PSIsContainer }
foreach ($i in $files)
{
    # get the year for the file creation date
    $dt = get-image $i.FullName | get-ImageProperty | select-object dt
    
    ## it's possible the EXIF data is empty so we should prepare for that
    ## and use .CreationTime
    if (!$dt)
    {
    write-host "$i has no EXIF data"
    continue
    }
    
    $dt = $dt.dt.toString().split(" ")
    $dt = $dt[0].split("/")
    $year=$dt[2]
    
    $yeardir= $root + "\" + $year
    
    
    # get the name of the month for the file creation date
    $month=$dt[0]
    # we wants directories with human readable names in the correct order 
    # hence the format #-Monthname
    switch ($month)
        {
            1{$month="$month-January"}
            2{$month="$month-February"}
            3{$month="$month-March"}
            4{$month="$month-April"}
            5{$month="$month-May"}
            6{$month="$month-June"}
            7{$month="$month-July"}
            8{$month="$month-August"}
            9{$month="$month-September"}
            10{$month="$month-October"}
            11{$month="$month-November"}
            12{$month="$month-December"}
        }
        
    
    # is there a year directory already?
    if (!(test-path $yeardir  -pathtype container))
    {
        new-item $yeardir -type directory
        write-host "Creating $yeardir"
    }
    # is there a Month directory below the Year directory?
    $monthdir = $yeardir + "\" + $month
    if (!(test-path $monthdir  -pathtype container))
    {
        new-item $monthdir -type directory
        write-host "Creating $monthdir"
    }
    # the destination will be either the Month directory or Month\Originals for Picasa Originals folders
    # move the file into the correct folder
    $pf=$i.FullName.split("\") # split the fullname to get this files immediate Parent Folder
    $loc=$pf.Length - 2
    if ($pf[$loc] -eq "Originals")
    {
        $destdir = $monthdir+"\Originals\"
        if (!(test-path $destdir -pathtype container))
        {
            new-item $destdir -type directory
            write-host "Creating $destdir"
        }
    }elseif($pf[$loc] -eq ".picasaoriginals") 
	{
	$destdir = $monthdir+"\.picasaoriginals\"
        if (!(test-path $destdir -pathtype container))
        {
            new-item $destdir -type directory
            write-host "Creating $destdir"
        }
    }else{
    $destdir = $monthdir+"\"
    }
    $destfullname=$destdir+$i
    $i = $i.FullName
    if (!(test-path $destfullname))
    {
        "move-item $destfullname $i" >> "undoMove.log"
        move-item $i $destdir
		$count++
    }else{
        write-host "can't move $i because `n$destfullname already exists"
    }
}
write-host "moved $count files"
write-host "`n remove-item $basePath -recurse -force`n"