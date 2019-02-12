# v2.02

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force;

    $TIMER = [system.Diagnostics.Stopwatch]::StartNew()
    $DATE = Get-Date -format "dd-MMM-yyyy HH:mm"
    $TIMERLOGFILE = "xxx" # logfile output

    $TABURL = "xxx" # Tableau Server URL
    $SITE = "xxx" # Tableau Server site
    $TUSER = "xxx" # Username
    $TPASSWORD = "xxx" # Password

    $SCHED_FILE = "reportlist.txt" #list of views (format "name/name") to parse
    $TranscriptFile = "xxx$SCHED_FILE" # transcript output
    $SCHED_FOLDER = "xxx" # path to list of views
    $OUTPUT_FOLDER = "xxx" # output folder
    $TEMP_FOLDER = "xxx" # temp staging location (important for parallel use)
    $TABDIR = "xxx" # path to TabCmd
    $TABCMD = "$TABDIRxxx" # TabCmd executable

Start-Transcript -Path $TranscriptFile -Append

    # get schedule file

    Write-Output "===== Parsing $SCHED_FILE script...."
    $SCHEDULEXISTS = Test-path "$SCHED_FOLDER$SCHED_FILE" 
    Write-Output "===== Testing to see if $SCHED_FILE exists..."
    If ($SCHEDULEXISTS -eq $True) 
        { 
        Write-Output "===== $SCHED_FILE exists, copying locally..." 
        cd $TABDIR 
        Copy-Item -Path "$SCHED_FOLDER$SCHED_FILE" -Destination "$TABDIR" 

        # iterate through views

        Write-Output "===== Logging in as $TUSER " 
        & $TABCMD login -s $TABURL -t $SITE -u $TUSER -p $TPASSWORD
        ForEach ($VIEW in Get-Content "$SCHED_FILE")
            {
            Write-Output "===== Parsing '$VIEW' from $SCHED_FILE..."
            $FILENAME = $VIEW -replace "/", "-" 
            & $TABCMD get "/views/$VIEW.png?:size=1946,1096&:refresh=true" -filename $TEMP_FOLDER$FILENAME.png
            if ($? -eq $False)
                {
                Write-Output "===== Tableau GET request for '$VIEW' from $SCHED_FILE failed, trying once more..."
                & $TABCMD get "/views/$VIEW.png?:size=1946,1096&:refresh=true" -filename $TEMP_FOLDER$FILENAME.png
                }
                Else {}
                Write-Output "===== Moving file to output folder"
                $REQUESTCHECK = Test-path "$TEMP_FOLDER$FILENAME.png" 
                If ($REQUESTCHECK -eq $True) 
                    {
                    Move-Item -path $TEMP_FOLDER$FILENAME.png -destination $OUTPUT_FOLDER$FILENAME.png -force
                    }
                    Else {Write-Output "===== Tableau GET request for '$VIEW' from $SCHED_FILE failed twice, skipping..."}
                } 
        }
        Else {Write-Output "===== $SCHED_FILE doesn't exist, quitting."}
        Write-Output "===== Done."
        write-Output "$SCHED_FILE,$DATE,$($TIMER.Elapsed.ToString())" | Out-File $TIMERLOGFILE -append

Stop-Transcript