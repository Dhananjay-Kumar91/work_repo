whoami

######################################################################################################################
#'Start a timer for logging.
######################################################################################################################

$elapsedTime = [System.Diagnostics.Stopwatch]::StartNew()

######################################################################################################################
#'Function to Get-IsoDateTime.
######################################################################################################################

Function Get-IsoDateTime{
   Return (Get-IsoDate) + " " + (Get-IsoTime)
}

######################################################################################################################
#'Function to Get-IsoDate.
######################################################################################################################

Function Get-IsoDate{
   Return Get-Date -uformat "%Y-%m-%d"
}

######################################################################################################################
#'Function to Get-IsoTime.
######################################################################################################################

Function Get-IsoTime{
   Return Get-Date -Format HH:mm:ss.fff
}

######################################################################################################################
#'Initialization Section. Define Global Variables.
######################################################################################################################

[String]$scriptPath     = Split-Path($MyInvocation.MyCommand.Path)
[String]$scriptSpec     = $MyInvocation.MyCommand.Definition
[String]$scriptBaseName = (Get-Item $scriptSpec).BaseName
[String]$scriptName     = (Get-Item $scriptSpec).Name
[String]$scriptLogPath  = $($scriptPath + "\" + (Get-IsoDate))
[Int]$script:errorCount        = 0
$ErrorActionPreference  = "Stop"
[String]$fileSpec1 = "C:\Users\Administrator.DEMO\Documents\test_env\s1_c.txt"
[String]$fileSpec2 = "C:\Users\Administrator.DEMO\Documents\test_env\s2_c.txt"
[String]$fileSpec_port = "C:\Users\Administrator.DEMO\Documents\test_env\s1_c_ports.txt"
$script:first      = $null
[String]$fileSpec_out = "C:\Users\Administrator.DEMO\Documents\test_env\StorageHC.html"
#[String]$script:bodyd = ""
[String]$script:msgBody = ""
#[String]$script:body = ""
######################################################################################################################
#'Initialization Section. Initialize Variables to NULL.
######################################################################################################################

Function var-Init(){
   $script:snpm=$script:snpm=$script:snpv=$script:snpvd=$null
   $script:Vols=$script:Voffs=$script:Voffsd=$script:volc=$script:volnm=$script:Vold=$null
   $script:agrs=$script:agr=$script:a1=$script:a2=$script:agrd=$null
   $script:sds=$script:sd=$null
   $script:fds=$script:fd=$script:fdc=$script:fdsd=$script:bodyd=$script:body=$null
   $script:envs=$script:envsd=$script:clus=$script:clusd=$script:fcps=$script:fcpsd=$script:fcps1=$null
   $script:smlagd=$script:smls=$script:smlag=$script:smlag1=$:null
   $script:lunad=$script:ilun=$script:patha=$script:useda=$script:sizea=$script:percentused=$script:ilunoff=$script:lunaoff=$script:ay1=$script:ax1=$null
   $script:aab2=$script:aab1=$script:Voffsab=$null
   $script:SPD1=$script:SPD2=$script:SPD3=$null
   $script:a1=$script:a2=$null

}

######################################################################################################################
#'Tab Creation code
######################################################################################################################

Function Table-Cr(){
    $script:body  = "<table cellpadding=1 cellspacing=1  bgcolor=#FF8F2F style='font-family:verdana; font-size:7pt;'>"
    $script:body += "<tr bgcolor=#DDDDDD><th>Filer Name</th><th>Failed Disk</th><th>Spare Disk</th><th>Cluster status</th><th>Lif Status</th><th>Aggr Status</th><th>Volumeinfo(Status & >90%)</th><th>LUN Status</th><th>Snapmirror Status</th><th>Snapmirror Lagtime</th><th>Cluster Peer Status</th><th>Autosupport</th><th>Environment Status</th><th>Node</th><th>Ethernet Port</th></tr>"
    $script:linc  = 1
    #$body
}

######################################################################################################################
#'Ensure that dates are always returned in English
######################################################################################################################

[System.Threading.Thread]::CurrentThread.CurrentCulture="en-US"

######################################################################################################################
#'Function to Write-Log
######################################################################################################################

Function Write-Log{
   Param(
      [Switch]$Info,
      [Switch]$Error,
      [Switch]$Debug,
      [Switch]$Warning,
      [String]$Message
   )
   #'---------------------------------------------------------------------------
   #'Add an entry to the log file and disply the output. Format: [Date],[TYPE],MESSAGE
   #'---------------------------------------------------------------------------
   [String]$lineNumber = $MyInvocation.ScriptLineNumber
   [Bool]$debugLogging = $False;
   If($Debug -And (-Not($debugLogging))){
      Return $Null;
   }
   Try{
      If($Error){
         If([String]::IsNullOrEmpty($_.Exception.Message)){
            [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[ERROR`],`[LINE $lineNumber`]," + $Message)
         }Else{
            [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[ERROR`],`[LINE $lineNumber`]," + $Message + ". Error """ + $_.Exception.Message + """")
         }
      }ElseIf($Info){
         [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[INFO`]," + $Message)
      }ElseIf($Debug){
         [String]$line = $("`[" + $(Get-IsoDateTime) + "`],`[DEBUG`],`[LINE $lineNumber`]," + $Message)
      }ElseIf($Warning){
         [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[WARNING`],`[LINE $lineNumber`]," + $Message)
      }Else{
         [String]$line = $("`[" + (Get-IsoDateTime) + "`],`[INFO`]," + $Message)
      }
      #'------------------------------------------------------------------------
      #'Display the console output.
      #'------------------------------------------------------------------------
      If($Error){
         If([String]::IsNullOrEmpty($_.Exception.Message)){
            Write-Host $($line + ". Error " + $_.Exception.Message) -Foregroundcolor Red
         }Else{
            Write-Host $line -Foregroundcolor Red
         }
      }ElseIf($Warning){
         Write-Host $line -Foregroundcolor Yellow
      }ElseIf($Debug -And $debugLogging){
         Write-Host $line -Foregroundcolor Magenta
      }Else{
         Write-Host $line -Foregroundcolor White
      }
      #'------------------------------------------------------------------------
      #'Append to the log. Omit debug loggging if not enabled.
      #'------------------------------------------------------------------------
      If($Debug -And $debugLogging){
         Add-Content -Path "$scriptLogPath.log" -Value $line -Encoding UTF8 -ErrorAction Stop
      }Else{
         Add-Content -Path "$scriptLogPath.log" -Value $line -Encoding UTF8 -ErrorAction Stop
      }
      If($Error){
         Add-Content -Path "$scriptLogPath.err" -Value $line -Encoding UTF8 -ErrorAction Stop
      }
      }Catch{
      Write-Warning "Could not write entry to output log file ""$scriptLogPath.log"". Log Entry ""$Message"""
   }
}

######################################################################################################################
#'Function to Invoke-DnsReverseLookup.
######################################################################################################################

Function Invoke-DnsReverseLookup{
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory=$True, HelpMessage="The IP Address to resolve")]
      [IPAddress]$IPAddress
   )
   $ErrorActionPreference = "silentlycontinue"
   $record = $null
   $record = [System.Net.Dns]::GetHostEntry($IPAddress)
   If($Null -ne $record){
      $result = [string]$record.HostName
   }Else{
      Return $Null;
   }
   Return $result.ToLower();
}

######################################################################################################################
#'Function to Convert Volume Size.
######################################################################################################################

Function cala($size){
   #VolumeName
   $org  = $size
   $size = [math]::round($org/1Tb,2)*1024
   $size = "$size"
   Return $size
}

######################################################################################################################
#'Import the PSTK.
######################################################################################################################

Function Modules(){
    [String]$moduleName = "DataONTAP"
    Try{
        Import-Module DataONTAP -ErrorAction Stop
        Get-Module -All | Out-Null
        Write-Log -Info -Message "Imported Module ""$moduleName"""
    }Catch{
        Write-Log -Error -Message "Failed importing module ""$moduleName"""
        Exit -1
    }
}

######################################################################################################################
#'Read the list of clusters.
######################################################################################################################

Function Read-Cluster($fileSpec){
    If(-Not(Test-Path -Path $fileSpec)){
        Write-Log -Warning -Message "The file ""$fileSpec"" does not exist"
        Exit -1
    }
    Try{
        $script:clusters = Get-Content -Path $fileSpec -ErrorAction Stop
        Write-Log -Info -Message "Read file ""$fileSpec"""
    }Catch{
        Write-Log -Error -Message "Failed reading file ""$fileSpec"""
        Exit -1
    }
}

######################################################################################################################
#'Enumerate Failed disks.
######################################################################################################################

Function Failed-Disk(){
    $script:fdc = $null
      Try{
         $script:fds = Get-NcDisk -ErrorAction Stop | Where-Object {$_.DiskRaidInfo.ContainerType -eq "broken"} #get broken disks n store In fds
         Write-Log -Info -Message "Enumerated Disks on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating disks on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
      If($Null -ne $script:fds){
         $script:fdc=$fds.count
      }
      if($fdc -gt 0){
         $script:fd = "<font color=red ><b>$fdc disk(s) are down<a href=#filer$script:linc><br>Investigate</a></b></font>" #if failure of disk
         If(-Not($bodyd)){
            $script:bodyd ="<u>Failed Disk -$hostname</u>"
         }Else{
            $script:bodyd +="<br><u>Failed Disk -$hostname</u>"
         }
         ForEach($fdsd In $script:fds){
            $script:bodyd += "<br><font color=red >$fdsd</font> is down"
         }
      }Else{
         $script:fd = "NIL"
      }
}

######################################################################################################################
#'Enumerate Nodes.
######################################################################################################################

Function Chk-Nodes(){
    Try{
         $script:node = Get-NcNode -ErrorAction Stop #getting node spare disks
         $script:nc   = $script:node.count
         Write-Log -Info -Message "Enumerated Nodes on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating nodes on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
}

######################################################################################################################
#'Enumerate Spare Disks.
######################################################################################################################

Function Spare-Disk(){
      Chk-Nodes
      $count = @()
      [Int]$cnt = 0
      Try{
         $script:sds = Get-NcAggrspare -ErrorAction Stop # getting aggregate spare disks
         Write-Log -Info -Message "Enumerated spare disks on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating spare disks on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break; 
      }
      $spc  = $script:sds.count
      $spcn = $script:sds.originalowner 
      $a=$b=$c=$cnt=$count=$null
      $script:sd = $null #'checking count of spare disks
      For($i=0;$i -lt $script:nc;$i++){
         For($j=0;$j -le $spcn.count;$j++){
            If($script:nc -lt 2){
                If($script:node.node -Match $spcn[$j]){
                    $cnt=$cnt+1            
            }
         }else{
            If($script:node.node[$i] -Match $spcn[$j]){
               $cnt=$cnt+1
            }
        }
         }
         $cnt    = $cnt-1
         $count += "$cnt"
         $cnt    = $null
         #$count
      }
      For($i=0;$i -lt $nc;$i++){
         If($script:nc -lt 2){
            $a   = $node.Node
            $b   = $count[$i]
        }else{
            $a   = $node.Node[$i]
            $b   = $count[$i]            
        }
         $script:sd += "$a-<b>$b</b><br>"
      }
}

######################################################################################################################
#'Enumerate Ethernet Ports.
######################################################################################################################

Function Chk-Ports($script:fileSpec){
      $cnct = $null
      $script:ethd = $null
      Try{
         $eth = Get-NcNetPort -ErrorAction Stop
         Write-Log -Info -Message "Enumerated Ports for cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating ports for cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
      If(-Not(Test-Path -Path $script:fileSpec)){
         Write-Log -Error -Message "The File ""$script:fileSpec"" does not exist"
         [Int]$script:errorCount++
         Break;
      }
      Try{
         $script:one = Get-Content -Path $script:fileSpec -ErrorAction Stop
         Write-Log -Info -Message "Read file ""$script:fileSpec"""
      }Catch{
         Write-Log -Error -Message "Failed reading file ""$script:fileSpec"""
         [Int]$script:errorCount++
         Break;
      }
      # [String]$fileSpec = "C:\netapp\Health_Check\port2.txt"
      # If(-Not(Test-Path -Path $fileSpec)){
      #    Write-Log -Error -Message "The file ""$fileSpec"" does not exist"
      #    [Int]$script:errorCount++
      #    Break;
      # }
      # Try{
      #    $two = Get-Content -Path $fileSpec -ErrorAction Stop
      #    Write-Log -Info -Message "Read file ""$fileSpec"""
      # }Catch{
      #    Write-Log -Error -Message "Failed reading file ""$fileSpec"""
      #    [Int]$script:errorCount++
      #    Break;
      # }
      $script:one_hash = @{}
      #$two_hash = @{}
      #if($cluster -eq "10.33.199.61"){
         For($i=0;$i -lt $one.count; $i++){
            $one_hash[$one[$i]] = 0
         }
         For($i=0; $i -lt $eth.count; $i++){
            $sta = "down"
            If(($eth[$i].LinkStatus) -eq $sta){ #checking is the link status of ethernet port is down
               $ethnm  = $eth[$i].Port
               $ethndm = $eth[$i].Node
               $cnct="$ethnm is down In $ethndm"
               If(-Not ($one_hash.ContainsKey($cnct))){
                  $script:bodyd += "<br><u>Ethernet port</u><br>"
                  $script:bodyd += "<font color=red size=2px><i class=material-icons>error</i></font><span id=ep >$cnct</span><br>" 
                  $script:ethd   = "<font color=red size=5px><a href=#filer$script:linc><i class=material-icons><font color=red>error</font></i><br>investigate</a></font>" 
               }
            }
         }
      #}
      # If($cluster -eq "10.33.199.62"){
      #    For($i=0;$i -lt $two.count;$i+=1){
      #       $two_hash[$two[$i]] = 0
      #    }
      #    For($i=0;$i -lt $eth.count;$i=$i+1){
      #       $sta = "down"
      #       If(($eth[$i].LinkStatus) -eq $sta){ #checking is the link status of ethernet port is down 
      #          $ethnm  = $eth[$i].Port
      #          $ethndm = $eth[$i].Node
      #          $cnct   = "$ethnm is down In $ethndm"
      #          If(-Not ($two_hash.ContainsKey($cnct))){
      #             $script:bodyd += "<br><u>Ethernet port</u><br>"
      #             $script:bodyd += "<font color=red size=2px><i class=material-icons>error</i></font><span id=ep >$cnct</span><br>" 
      #             $script:ethd   = "<font color=red size=5px><a href=#filer$linc><i class=material-icons><font color=red>error</font></i><br>investigate</a></font>" 
      #          }
      #       }
      #    }
      # }
      If($Null -eq $script:ethd){
         $script:ethd = "<font color=green size=5px><body>&#128505;</body></font><br><b>OK<b>"
      }
}

######################################################################################################################
#'Enumerate Aggregates.
######################################################################################################################

Function Chk-Aggregates(){
   Try{
      $script:agrs = Get-NcAggr -ErrorAction Stop
      Write-Log -Info -Message "Enumerated Aggregates on cluster ""$cluster"""
   }Catch{
      Write-Log -Error -Message "Failed enumerating aggregates on cluster ""$cluster"""
      [Int]$script:errorCount++
      Break;
   }
   $script:agrd = $null
   $agc  = $null
   $agc  = $script:agrs.state -ne "online"
   $agu  = $null 
   $agc  = $agc.count
   ForEach($agr In $script:agrs){ 
      If($agr.state -ne "online"){ 
         $script:agrd  += "<font color=red size=2px><i class=material-icons>error</i><br></font><font color=red><b><a href=#filer$script:linc>$agc aggr(s) is/are offline</b></font></a><br>"
         $script:bodyd += "<br><u>Aggrs offline-$hostname</u>"
         $script:bodyd += "<br><u>$agr is offline</u>"
      }
   } # checking aggr online/offline
   For($i=0; $i -lt $script:agrs.count; $i++){
      If($agrs[$i].used -gt 60 -And !($agrs[$i].Name.Contains("aggr0"))){ 
         $agu++
      }
   }
   For($i=0; $i -lt $script:agrs.count; $i++){
      If($agrs[$i].used -gt 60 -And !($agrs[$i].Name.Contains("aggr0"))){
         $script:agrd  += "<font color =cyan size =2px><i class=material-icons>warning</i></font><br><font color=black><a href=#filer$script:linc>$agu Aggrs > 60%</font></a><br>"
         $script:bodyd += "<br><u><big>Aggrs > 60%-$hostname</big></u><br>"
         Break;
      }
   }
   ForEach($agr In $script:agrs){
      If(($agr.used -gt 60) -And !($agr.Name.Contains("aggr0"))){
         $script:a1     = $script:agr.name
         $script:a2     = $script:agr.Used
         $script:bodyd += "<font color =cyan size =2px><i class=material-icons>warning</i></font><br><font color=black><b>$a1($a2%)</b></font><br>"
      }
   }
   If($Null -eq $script:agrd){
      $script:agrd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>" #"<font color=green size=5px><body>🗹</body></font><br><b>OK<b>"
   }
      #'------------------------------------------------------------------------
      #'Enumerate Aggregate Object Stores. Might not be a use case for us
      #'------------------------------------------------------------------------
      $aoss   = $null
      $script:bodyd += "<br><br><u><big>Object Stores</big> </u>"
      Try{
         $aoss = Get-NcAggrObjectStore -ErrorAction Stop
         Write-Log -Info -Message "Enumerate Aggregate Object Stores on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed Enumerating Aggregate Object Stores on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
      If($Null -eq $aoss){
         $script:bodyd += "<br>None<br>"
      }
      ForEach($aos In $aoss){
         $name   = $aos.ObjectStoreName
         $size   = cala($aos.UsedSpace)
         $script:bodyd += "<br>$name-$size(Gb)<br>"
      }
}

######################################################################################################################
#'Enumerate Volumes.
######################################################################################################################

Function Chk-Volumes(){
    Try{
         $script:Vols = Get-Ncvol -ErrorAction Stop
         Write-Log -Info -Message "Enumerated volumes on cluster ""$script:cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating volumes on cluster ""$script:cluster"""
         [Int]$script:errorCount++
         Break;
      }
      $volsd = $null
      $vc    = $script:Vols.state -ne "online"
      $vc    = $vc.count
      $vu    = $script:Vols.used -gt 90
      $vu    = $vu.count
      If($script:Vols.state -ne "online"){
         $script:volsd += "<font color=red size=2px><i class=material-icons>error</i><br></font><font color=red><b><a href=#filer$script:linc>$vc vol(s) is/are offline</b></font></a><br>"
         $script:bodyd += "<br><u><big>$script:Vols offline-$hostname</big></u>"
      }
      ForEach($vol In $script:Vols){ 
         If($vol.state -ne "online"){
            $svm    = $vol.vserver
            $script:bodyd += "<br><font color=red size=2px><i class=material-icons>error</i></font><b>$vol is offline In SVM $svm </b><br>"
         }
      } #checking vol online/offline
      For($i=0; $i -lt $script:Vols.count; $i++){
         If($script:Vols[$i].used -gt 90 -And !($script:Vols[$i].Name.equals("vol0"))){ 
            $script:volsd += "<font color =cyan size =2px><i class=material-icons>warning</i></font><br><font color=black><a href=#filer$script:linc>$vu $script:Vols > 90%</font></a><br>"
            $script:bodyd += "<br><u>$script:Vols > 90%-$hostname</u><br>"
            Break;
         }
      }
      ForEach($vol In $script:Vols){ 
         If($vol.used -gt 90 -And !($vol.Name.equals("vol0"))){ 
            $v1=$vol.name
            $v2=$vol.Used
            $v3=$vol.Vserver
            $v4= cala($vol.volumeautosizeattributes.maximumsize) 
            $v5= cala($vol.totalsize-$vol.available)
            $v6=(($vol.totalsize - $vol.available)/$vol.volumeautosizeattributes.maximumsize)*100
            If($v6 -gt 90){
               $script:bodyd += "<font color =red size =2px><br><i class=material-icons>error</i></font><br><font color=black><b>$v1($v6 %) is nearly full</b></font><br>"
            }
            $script:bodyd += "<font color =cyan size =2px><i class=material-icons>warning</i></font><br><font color=black><b>$v1($v2%) SVM: $v3 ; Size- $v5 (Gb); max size- $v4 (Gb)</b></font><br>"
         }
      }
      If($null -eq $script:volsd){
         $script:volsd = "<font color=green size=5px><body>&#128505;</body></font><br><b>OK<b>"
      }
}

######################################################################################################################
#'Enumerate SnapMirror relationships.      *Initialized but not invoked
######################################################################################################################

Function Snap-Relation(){
    $src=$dst=$script:snpm=$null
      Try{
         $snpms = Get-NcSnapMirror -ErrorAction Stop
         Write-Log -Info -Message "Enuemrated SnapMirror relationships on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating SnapMirror relationships on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
      ForEach($script:snpm In $snpms){
         $src = $script:snpm.sourcelocation
         $dst = $script:snpm.destinationlocation
         If($script:snpm.ishealthy.ToString() -eq "false"){
            $script:snpm += "<font color =red size =2px><br><i class=material-icons>error</i></font><br><font color=red><b>$src to $dst is unhealthy</b></font>"
         }
      }
      If($snpms.mirrorstate -eq "snapmirrored"){
         $script:snpm = "<font color=green size =5px><body>&#128505;</body></font><br><b>OK<b>"
      }Else{
         $script:snpm = "No Snapmirror Relations"
      }
}

######################################################################################################################
#'Enumerate SnapMirror lag Times.       *Initialized but not invoked
######################################################################################################################

Function Snap-Lag(){
      $script:smls = $null
      $LagTimeSeconds = "86400" #24 urs In seconds
      Try{
         $script:smlag = Get-NcSnapmirror -ErrorAction Stop | Where-Object {$_.LagTime -gt $LagTimeSeconds} #-And ($_.Vserver -NotMatch "BALLDA01" -And $_.Vserver -NotMatch "BEGADA01" -And $_.Vserver -NotMatch "BOWEDA01" -And $_.Vserver -NotMatch "COREDA03" -And $_.Vserver -NotMatch "COREDA04" -And $_.Vserver -NotMatch "DUBBDA01" -And $_.Vserver -NotMatch "DUBCDA01" -And $_.Vserver -NotMatch "GLENDA01" -And $_.Vserver -NotMatch "GOUSDA01" -And $_.Vserver -NotMatch "GRANDA01" -And $_.Vserver -NotMatch "GRFHDA01" -And $_.Vserver -NotMatch "GRFTCA01" -And $_.Vserver -NotMatch "GRFTDA03" -And $_.Vserver -NotMatch "HAYYDA01" -And $_.Vserver -NotMatch "HUNTDA01" -And $_.Vserver -NotMatch "MILLDA01" -And $_.Vserver -NotMatch "MILLDA02" -And $_.Vserver -NotMatch "MILLDA03" -And $_.Vserver -NotMatch "MILLDA04" -And $_.Vserver -NotMatch "NCLECA01" -And $_.Vserver -NotMatch "NCLEDA01" -And $_.Vserver -NotMatch "ORANDA01" -And $_.Vserver -NotMatch "PARKDA03" -And $_.Vserver -NotMatch "PARRCA04" -And $_.Vserver -NotMatch "PARRDA01" -And $_.Vserver -NotMatch "PARRDA03" -And $_.Vserver -NotMatch "PORTDA01" -And $_.Vserver -NotMatch "ROCKDA01" -And $_.Vserver -NotMatch "TAMWDA01" -And $_.Vserver -NotMatch "WAGGDA03" -And $_.Vserver -NotMatch "WAGSDA01" -And $_.Vserver -NotMatch "WOYWDA01" -And $_.Vserver -NotMatch "WYODDA01" -And $_.Vserver -NotMatch "YENNDA02" -And $_.Vserver -NotMatch "COREDA01" -And $_.Vserver -NotMatch "MITTDA01" -And $_.Vserver -NotMatch "PARRWW01" -And $_.Vserver -NotMatch "WARADA01" -And $_.Vserver -NotMatch "WOLLDA03" -And $_.Vserver -NotMatch "YASSDA01" -And $_.Vserver -NotMatch "redfda02" -And $_.Vserver -NotMatch "BURTDA01" -And $_.Vserver -NotMatch "MILLIM01" -And $_.Vserver -NotMatch "PYRMMA01" -And $_.Vserver -NotMatch "WOLNDA01" -And $_.Vserver -NotMatch "WOYWMA01" -And $_.Vserver -NotMatch "FSMET045")}
         Write-Log -Info -Message "Enumerated SnapMirror Lag times on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating SnapMirror Lag times on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
      $script:smls = $script:smlag.count
      If(-Not($script:smlag)){
         $script:smls = "No"
      }Else{ #is lagtime < 24 hours
         #if lagtime >24 hours
         If(-Not($script:bodyd)){
            $script:bodyd ="<u><big>Snap Mirror Lagtime (>24 hours)</big> </u><br>"
         }Else{
            $script:bodyd +="<br><u><big>Snap Mirror Lagtime (>24 hours)</big> </u><br>"
         } 
         Foreach($smlag1 In $script:smlag){
            $script:SPD1   = $smlag1.Sourcelocation
            $script:SPD2   = $smlag1.Destinationlocation
            $script:SPD3   = $smlag1.status
            $script:bodyd += "<font color=red size=5px><i class=material-icons>error</i></font><span id=sml>$script:SPD1 ---> $script:SPD2 ($script:SPD3)</span><br>" # for printing the relation whose lag time is >24 hours
         }
      }
}

######################################################################################################################
#'Enumerate LUNs.
######################################################################################################################

Function Chk-LUNs(){
      $luns = $lund=$lunsd=$lunc=$null
      Try{
         $luns = Get-NcLun -ErrorAction Stop
         Write-Log -Info -Message "Enumerated LUNs on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating LUNs on cluster ""$cluster"""
         [Int]$script:errorCount++
         Break;
      }
      ForEach($lun In $luns){
         if($lun.state -eq "online"){
            <#
            If($lun.thin -eq "false"){
               $lund   = $lun.path
               $script:bodyd += "$lund<br>"
            }
            #>
         }Else{
            $lund   = $lun.path
            $script:lunsd += "<font color=red size=2px><i class=material-icons>error</i><br><b></font><font color=red>$lund is offline<b></font><br>"
         }
      }
      If($Null -eq $lunsd){
         $script:lunsd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>"
      }
}

######################################################################################################################
#'Enumerate the cluster health.
######################################################################################################################

Function Cluster-Health(){
      $command = @("cluster", "show", "-health", "false") 
      $api     = $("<system-cli><args><arg>" + ($command -join "</arg><arg>") + "</arg></args></system-cli>")
      Try{
         $output3 = Invoke-NcSystemApi -Request $api -ErrorAction Stop
         Write-Log -Info -Message $("Executed Command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")
      }Catch{
         Write-Log -Error -Message $("Failed Executing Command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")
         [Int]$script:errorCount++
         Break;
      }
      $cl = $output3.results.'cli-output'
      If($cl.Contains("There are no entries matching your query.")){
         $script:clusd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>"
      }Else{
         $script:clusd = "<font color=red size=2px><i class=material-icons>error</i><br>Unhealthy</font><br>"
      }
}

######################################################################################################################
#'Enumerate cluster nodes Health.
######################################################################################################################

Function Node-Health(){
    Chk-Nodes
    For($i=0; $i -lt $n.count; $i++){
         If(($n[$i].IsNodeHealthy) -eq $False){ #checking if node is not healthy
            $nodnm = $n[$i].NodeName
            $script:nod  += "<font color=red size=5px><i class=material-icons>error</i></font><font size =2px></font><br><font color =red> <b>$nodnm is down</b></font><br>"
         }
    }
    If($Null -eq $nod){ #if node is healthy
        $script:nod = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>"
    }   
}

######################################################################################################################
#'Enumerate network interfaces.
######################################################################################################################

Function Chk-Interface(){
    Try{
         $vifs = Get-NcNetInterface -ErrorAction Stop
         Write-Log -Info -Message "Enumerated Network interfaces on cluster ""$cluster"""
      }Catch{
         Write-Log -Error -Message "Failed enumerating Network Interfaces on cluster ""$Cluster"""
         [Int]$script:errorCount++
         Break;
      }
      $vifsd = $null
      For($i=0; $i -lt $vifs.count; $i++){
         $sta = "down"
         If(($vifs[$i].OpStatus) -eq $sta){ # checking if opstatus is down
            $vifsnm = $vifs[$i].InterfaceName
            $script:vifsd += "<font color=red size=2px><i class=material-icons>error</i><br></font><font color=red><b>$vifsnm is down</b></font><br>" 
         }
      }
      If($null -eq $script:vifsd){ #if there are no issues
         $script:vifsd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>"
      }
}

######################################################################################################################
#'Enumerate Autosupport.
######################################################################################################################

Function Chk-Autosupport(){
      $aus = $null
      #$aus=Invoke-NcSsh -Command "autosupport Chk show  " -Verbose #running ssh command to Chk autosupport
      $command = @("autosupport", "check", "show") 
      $api     = $("<system-cli><args><arg>" + ($command -join "</arg><arg>") + "</arg></args></system-cli>")
      Try{
         $output1 = Invoke-NcSystemApi -Request $api -ErrorAction Stop
         Write-Log -Info -Message $("Executed Command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")
         $aus = $output1.results.'cli-output'
      }Catch{
         Write-Log -Error -Mesasge $("Failed Executing Command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")
         [Int]$script:errorCount++
         Break;
      }
      If($aus.Contains("failed")){# if it fails
         $script:ausd = "<font color=red size=5px><i class=material-icons>error</i></font><br><font size=1px color= red><b>Failed</font></b>" 
      }Else{ #else put a green symbol
         $script:ausd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>" 
      }
}

######################################################################################################################
#'Enumerate Stale snapshots.       *Initialized not Invoked.
######################################################################################################################

Function Chk-StaleSnapshot(){
    If($cluster.Contains("61")){
         $stale = $null
         $date  = Get-Date
         $month = $date.Month
         $day   = $date.day
         Try{
            $snap = Get-NcSnapshot -ErrorAction Stop
            Write-Log -Info -Message "Enumerated Snapshots on cluster ""$cluster"""
         }Catch{
            Write-Log -Error -Message "Failed enumerating Snapshots on cluster ""$cluster"""
            [Int]$script:errorCount++
            Break;
         }
         $script:snapm = $null
         $stale = $snap | Where-Object { $_.Created -lt (Get-Date).AddDays(-90) -And ($_.Dependency -ne "snapmirror" -And $_.Dependency -ne "vserverdr,snapmirror" -And $_.Dependency -ne "busy,vclone,snapmirror")}
         #$stale=$snap | ?{ $_.Created -lt (Get-Date).AddDays(-60) -And ( $_.Dependency -ne "snapmirror" -And $_.Dependency -ne "vserverdr,snapmirror" -And $_.Dependency -ne "busy,vclone,snapmirror" )}
         If($Null -ne $stale){
            $script:bodyd += "<br><b><u>STALE SNAPSHOTS</u></b><br>"
         }
         For($i=0; $i -lt $stale.count; $i++){
            $script:snapm += Write-Output "<font color=red size=2px><i class=material-icons>error</i></font>"$stale[$i].name"-"$stale[$i].volume"-"$stale[$i].vserver"<br>"
         }
         $script:bodyd += "$script:snapm<br>" 
      }
}

######################################################################################################################
#'Enumerate Cluster Peer relationships.
######################################################################################################################

Function Chk-PeerRelation(){
      $script:peerd = $null
      Try{
         $peer = Get-NcClusterPeer -ErrorAction Stop
         Write-Log -Info -Message "Enumerated cluster peer relationships"
      }Catch{
         Write-Log -Error -Message "Failed enumerating cluster peer relationships"
         [Int]$script:errorCount++
         Break;
      }
      For($i=0; $i -lt $peer.count; $i++){
         If(($peer[$i].availability) -ne "available"){#checking if node is not healthy
            $peernm  = $peer[$i].clustername
            $script:peerd  +="<font color=red size=5px><i class=material-icons>error</i></font><font size =2px></font><br><font color =red> <b>$peernm is down</b></font><br>"
         }
      }
      if($null -eq $script:peerd){ #if node is healthy
         $script:peerd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>"
      }
}

######################################################################################################################
#'Enumerate cluster environment health.
######################################################################################################################

Function Chk-Environment(){
    $command = @("system", "health", "subsystem", "show") 
    $api     = $("<system-cli><args><arg>" + ($command -join "</arg><arg>") + "</arg></args></system-cli>")
    Try{
         $output = Invoke-NcSystemApi -Request $api -ErrorAction Stop
         Write-Log -Info -Message $("Executed command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")
      }Catch{
         Write-Log -Error -Message $("Failed executing command`: """ + $([String]::Join(" ", $command)) + """ on cluster ""$cluster""")
         [Int]$script:errorCount++
         Break;
      }
      $sub = $output.results.'cli-output'
      $b   = "Subsystem         Health`n----------------- ------------------`nSAS-connect       ok`nEnvironment       ok`nMemory            ok`nService-Processor ok`nSwitch-Health     ok`nCIFS-NDO          ok`nMotherboard       ok`nIO                ok`nMetroCluster      ok`nMetroCluster_Node ok`nFHM-Switch        ok`nFHM-Bridge        ok`nSAS-connect_Cluster ok"
      $a   = ($sub.substring(0,215))
      If($a -Match $b){ #if everythings ok
         $script:subsd = "<font color=green size=5px><body>ðŸ—¹</body></font><br><b>OK<b>"
      }Else{
         $script:subsd = "<font color=red size=2px><i class=material-icons>error</i></font><br><font size=1px color= red><b>Failed</font></b>" #"<font color=red size=5px><i class=material-icons>error</i></font><br><font size=1px color= red><b>Failed</font></b>"
      }
}

######################################################################################################################
#'Process the clusters.
######################################################################################################################

Function Process-clusters(){
    ForEach($cluster In $script:clusters){
        Do{
            #'------------------------------------------------------------------------
            #'Enumerate the cluster credentials from the cache.
            #'------------------------------------------------------------------------
            Try{
                $credential = Get-NcCredential -Controller $cluster -ErrorAction Stop
                Write-Log -Info -Message "Enumerated cached credentials for cluster ""$cluster"""
            }Catch{
                Write-Log -Error -Message "Failed enumerating cached credentials for cluster ""$cluster"""
                [Int]$script:errorCount++
                Break;
            }
            #'------------------------------------------------------------------------
            #'Ensure the credentials are valid.
            #'------------------------------------------------------------------------
            If($Null -ne $credential){
                If(([String]::IsNullOrEmpty($credential.Credential.UserName)) -Or ([String]::IsNullOrEmpty($credential.Credential.GetNetworkCredential().Password))){
                    Write-Log -Error -Message "The username or password for cluster ""$cluster"" is invalid"
                    [Int]$script:errorCount++
                    Break;
                }Else{
                    Write-Log -Info -Message $("Validated credentials for cluster ""$cluster"". Connecting to cluster ""$cluster"" as user """ + $credential.Credential.UserName + """")
                }
            }Else{
                Write-Log -Error -Message "The credentials for cluster ""$cluster"" are invalid"
                [Int]$script:errorCount++
                Break;
            }
            #'------------------------------------------------------------------------
            #'Connect to the cluster.
            #'------------------------------------------------------------------------
            Try{
                Connect-NcController -Name $cluster -HTTPS -Credential $credential.Credential -ErrorAction Stop | Out-Null
                Write-Log -Info -Message $("Connected to cluster ""$cluster"" as user """ + $credential.Credential.UserName + """")
            }Catch{
                Write-Log -Error -Message $("Connected to cluster ""$cluster"" as user """ + $credential.Credential.UserName + """")
                [Int]$script:errorCount++
                Break;
            }
            #'------------------------------------------------------------------------
            #'Chk the cluster is an IP Address and perform a DNS reverse lookup.
            #'------------------------------------------------------------------------
            $ip = $cluster -As [IPAddress]
            If($Null -ne $ip){
                [String]$fqdn = Invoke-DnsReverseLookup -IPAddress $cluster
                If($fqdn.Contains(".")){
                    [String]$hostname = $fqdn.Split(".")[0]
                }Else{
                    [String]$hostname = $cluster
                }
            }Else{
                [String]$hostname = $cluster
            }
            $script:bodyd +="<span id=filer$script:linc><br><b><u><big>Highlights of <b><u>$hostname</b></u></big></u></b><br></span>" 
            Failed-Disk
            Chk-Nodes
            Spare-Disk
            Chk-Ports($fileSpec_port)
            Chk-Aggregates
            Chk-Volumes
            Snap-Relation     #Function Initialized but not invoked
            Snap-Lag     #Function Initialized but not invoked
            Chk-LUNs
            Cluster-Health
            Node-Health
            Chk-Interface
            Chk-Autosupport
            Chk-StaleSnapshot     #Function Initialized but not invoked
            Chk-PeerRelation
            Chk-Environment
            #'storing the values of the collected information In a variable
            $script:body += "<tr bgcolor=white align=center><TD><b>$hostname</b></TD>","<td>$script:fd</td>","<TD width=80>$script:sd</TD>","<TD>$script:clusd</TD>","<TD>$script:vifsd</TD>","<TD> $script:agrd</TD>","<TD>$script:volsd</TD>","<TD>$script:lunsd</TD>","<TD>$script:snpm </TD>","<TD><a href=#filer$linc>$smls issue(s) found</a></TD>","<TD>$script:peerd</TD>","<TD>$script:ausd</TD>","<TD>$script:subsd</TD>","<TD>$script:nod</TD>","<TD>$script:ethd</TD>","</tr>"
            $script:linc += 1
        }until($True)
   }
        $script:body += "</Table>"
}

######################################################################################################################
#'Set the email report Header.
######################################################################################################################
Function Mail-Header(){
    if($script:first -eq $null){

        $script:msgBody = "Hi Team,<br><br>
 
        The Storage Daily Health Chk Script has been excecuted:<br><br>

        <b>The report output is better viewed In CHROME browser</b><br><br>

        Note 1-> All the Ethernet ports which were manually disabled are not mentioned In this report.<br><br>
 


        Kindly, find the summary of the Storage health Chk report below: <br><br>"
    

        $script:msgBody += "<b><u>Thomson Reuters Site 1</b></u><br><br>"
        $script:msgBody += "<table  cellpadding=3 cellspacing=1  bgcolor=#FF8F2F>"
        $script:msgBody += "<tr>"
        $script:msgBody += "<td bgcolor=#DDDDDD><FONT face=Verdana size=1.5 ><b>Storage Health Checks</b></font></td>"
        $script:msgBody += "</tr>"
        $script:msgBody += "<tr>"
        $script:msgBody += "<td bgcolor=white><FONT face=Verdana size=1.5 >$script:body</font></td>"
        $script:msgBody += "</tr>"
        $script:msgBody += "<link href=https://fonts.googleapis.com/icon?family=Material+Icons rel=stylesheet>"
        $script:first = $script:bodyd
     }else{
        $script:msgBody += "<br><br>"
        $script:msgBody +="<b><u>Thomson Reuters Site 2</b></u><br><br>"
        $script:msgBody += "<table  cellpadding=3 cellspacing=1  bgcolor=#FF8F2F>"
        $script:msgBody += "<tr>"
        $script:msgBody += "<td bgcolor=#DDDDDD><FONT face=Verdana size=1.5 ><b>Storage Health Checks</b></font></td>"
        $script:msgBody += "</tr>"
        $script:msgBody += "<tr>"
        $script:msgBody += "<td bgcolor=white><FONT face=Verdana size=1.5 >$script:body</font></td>"
        $script:msgBody += "</tr>"
        $script:msgBody += "<link href=https://fonts.googleapis.com/icon?family=Material+Icons rel=stylesheet>"
    }
}

######################################################################################################################
#'Set the email report body.
######################################################################################################################

Function Mail-Body(){
    #$body += "</Table>"
    
    #If($script:first){
     #   $script:msgBody += "<tr>"
     #   $script:msgBody += "<td bgcolor=#DDDDDD><FONT face=Verdana size=1.5 ><b><big><big>Highlights</big></big></b></font></td>"
     #   $script:msgBody += "</tr>"
     #   $script:msgBody += "<tr>"
     #   $script:msgBody += "<td bgcolor=white><FONT face=Verdana size=1.5 >$script:first</font></td>"
     #   $script:msgBody += "</tr>"
    #}
    If($script:bodyd){
        $script:msgBody += "<tr>"
        $script:msgBody += "<td bgcolor=#DDDDDD><FONT face=Verdana size=1.5 ><b><big><big>Highlights</big></big></b></font></td>"
        $script:msgBody += "</tr>"
        $script:msgBody += "<tr>"
        $script:msgBody += "<td bgcolor=white><FONT face=Verdana size=1.5 >$script:bodyd</font></td>"
        $script:msgBody += "</tr>"
    }
    $script:msgBody += "</table>"
}

######################################################################################################################
#'Set the email report Tail.
######################################################################################################################

Function Mail-Tail(){
    $script:msgBody += "<br>Next Health Chk report will be submitted by $((Get-Date).AddDays(1).DayOfWeek) 9:00 PM , Eastern Standard Time (EST).<br>
    <br>Regards<br>
    Keystone Team"
    #$msgBody += "</table>"
}

######################################################################################################################
#'Delete the file if it exists.
######################################################################################################################

Function Delete-Files($fileSpec){
    
    If((Test-Path $fileSpec) -eq $True){
        Try{
            Remove-Item $fileSpec -ErrorAction Stop
            Write-Log -Info -Message "Deleted file ""$fileSpec"""
        }Catch{
            Write-Log -Error -Message "Failed deleting file ""$fileSpec"""
            [Int]$script:errorCount++
    }
}
}

######################################################################################################################
#'Create the file.
######################################################################################################################

Function Create-File($fileSpec){
    Try{
        Add-Content -Path $fileSpec -Value $script:msgBody -ErrorAction Stop
        Write-Log -Info -Message "Created ""$fileSpec"""
    }Catch{
        Write-Log -Error -Message "Failed creating file ""$fileSpec"""
        [Int]$script:errorCount++
}
}

######################################################################################################################
#'Main Logic
######################################################################################################################
Module
var-Init
Table-Cr
Read-Cluster($fileSpec1)
Process-clusters
Mail-Header
Mail-Body
var-Init
Table-Cr
Read-Cluster($fileSpec2)
Process-clusters
Mail-Header
Mail-Body
Mail-Tail
Delete-Files($fileSpec_out)
Create-File($fileSpec_out)
