#include <Date.au3>
#include <Crypt.au3>
#include <GDIPlus.au3>
#include <ScreenCapture.au3>

#include "Key.au3"

$DEFAULT_URL        = "http://waiter.cgh.io/waiter"
$DEFAULT_SCREENSHOT = "http://waiter.cgh.io/screenshot"
$DEFAULT_PERIOD     = 10
$TEMPDIR            = @TempDir & "\waiter"

AutoItSetOption("TrayIconHide", 1)

Func Help()
  Logs("Get and execute commands and take screenshots for a period of time.")
  Logs("Report bugs to caiguanhao@gmail.com.")
  Logs()
  Logs("Usage: waiter [OPTION]")
  Logs()
  Logs("Option:")
  Logs("  -h, --help               Show this help and exit")
  Logs("  -u, --url        <url>   URL to query for commands")
  Logs("  -p, --period     <secs>  Wait n seconds after each query")
  Logs("  -s, --screenshot <url>   Screenshot API address")
  Logs('                           Use "-" as URL to disable')
  Logs()
  Logs("Defaults:")
  Logs("  --url        " & $DEFAULT_URL)
  Logs("  --period     " & $DEFAULT_PERIOD)
  Logs("  --screenshot " & $DEFAULT_SCREENSHOT)
  Logs()
  Logs("API key:")
  Logs("  " & StringLeft($Key, 20) & " ... " & StringLen($Key) & " characters")
  Logs()
  Exit
EndFunc

Func Error($error, $errno = 1)
  ConsoleWriteError($error & @CRLF)
  ConsoleWriteError(@CRLF)
  Exit $errno
EndFunc

Func ConsoleLog($text = "")
  Logs("[" & _NowTime(5) & "] " & $text)
EndFunc

Func Logs($text = "")
  ConsoleWrite($text & @CRLF)
EndFunc

Func GetOpt($i)
  if $i == $CmdLine[0] or (StringLeft($CmdLine[$i + 1], 1) == "-" and _
    $CmdLine[$i + 1] <> "-" ) Then
    Error("Value not provided for option: " & $CmdLine[$i] & ".")
  Else
    $skipCheck = 1
    return StringStripWS($CmdLine[$i + 1], 3)
  EndIf
EndFunc

Local $url        = $DEFAULT_URL
Local $period     = $DEFAULT_PERIOD
Local $screenshot = $DEFAULT_SCREENSHOT
Local $skipCheck  = 0

For $i = 1 To $CmdLine[0]
  Switch $CmdLine[$i]
  Case "-h", "--help"
    Help()
  Case "-u", "--url"
    $url = GetOpt($i)
  Case "-s", "--screenshot"
    $screenshot = GetOpt($i)
  Case "-p", "--period"
    $period = Number(GetOpt($i))
  Case Else
    If $skipCheck == 0 Then
      Error("Unknown option or value: " & $CmdLine[$i] & ".")
    Else
      $skipCheck = 0
    EndIf
  EndSwitch
Next

If $period <= 2 Then  Error("Time period should be more than 2 seconds.")
If $period > 999 Then Error("Time period should not be more than 999 seconds.")

If StringInStr(FileGetAttrib($TEMPDIR), "D") = 0 Then FileDelete($TEMPDIR)
If Not FileExists($TEMPDIR) Then DirCreate($TEMPDIR)

$tracker = _CPUsUsageTracker_Create()

While 1
  Local $tempFile = $TEMPDIR & "\new.bat"
  $bytes = InetGet($url, $tempFile, 1 + 2 + 4)
  If $bytes > 0 Then
    $hash = _Crypt_HashFile($tempFile, $CALG_MD5)
    $filename = $hash & ".bat"
    Local $newTempFile = $TEMPDIR & "\" & $filename
    If Not FileExists($newTempFile) Then
      ConsoleLog("Downloaded " & $bytes & " bytes from " & $url & ".")
      FileMove($tempFile, $newTempFile, 1 + 8)
      ConsoleLog("And the file was saved as " & $filename & ".")
      $pid = Run($newTempFile, "", @SW_HIDE, 0x10000)
      ConsoleLog("And the file was executed as PID " & $pid & ".")
    EndIf
  Else
    ConsoleLog("Downloaded nothing from " & $url & ".")
  EndIf
  FileDelete($tempFile)
  If $screenshot <> "-" Then
    $string = "[" & _NowTime(5) & "] " & GetCPUAndMemoryUsage($tracker)
    $screenshotfile = $TEMPDIR & "\screenshot.jpg"
    TakeScreenshot($screenshotfile, 480, $string)
    SendScreenshot($screenshotfile, $screenshot)
  EndIf
  Sleep($period * 1000)
Wend

Func SendScreenshot($filepath, $to)
  $http = ObjCreate("winhttp.winhttprequest.5.1")
  $http.Open("POST", $to, False)
  $http.SetRequestHeader("Key", $KEY)
  $file = FileOpen($filepath, 16)
  $data = FileRead($file)
  $http.Send($data)
  $status = $http.Status
  If $status == "" Then
    $status = "nothing"
  Else
    $status = $status & " status"
  EndIf
  ConsoleLog("Screenshot HTTP-POST request returned " & $status & ".")
EndFunc

Func TakeScreenshot($filepath, $width = 0, $string = "")
  $bitmap = _ScreenCapture_Capture()
  If $width = 0 Then
    _ScreenCapture_SaveImage($filepath, $bitmap)
    _WinAPI_DeleteObject($bitmap)
  Else
    _GDIPlus_Startup()
    $image = _GDIPlus_BitmapCreateFromHBITMAP($bitmap)
    _WinAPI_DeleteObject($bitmap)
    $scale = _GDIPlus_ImageGetWidth($image) / $width
    $height = _GDIPlus_ImageGetHeight($image) / $scale
    $thumb = _GDIPlus_GetImageThumbnail($image, $width, $height)
    _GDIPlus_ImageDispose($image)
    If $string <> "" Then
      $graphic = _GDIPlus_ImageGetGraphicsContext($thumb)
      _GDIPlus_GraphicsFillRect($graphic, 0, 0, $width, 20)
      $brush = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
      $format = _GDIPlus_StringFormatCreate()
      $family = _GDIPlus_FontFamilyCreate("Courier New")
      $font = _GDIPlus_FontCreate($family, 12)
      $layout = _GDIPlus_RectFCreate(0, 0, $width, 20)
      $info = _GDIPlus_GraphicsMeasureString($graphic, $string, $font, $layout, $format)
      _GDIPlus_GraphicsDrawStringEx($graphic, $string, $font, $info[0], $format, $brush)
      _GDIPlus_FontDispose($font)
      _GDIPlus_FontFamilyDispose($family)
      _GDIPlus_StringFormatDispose($format)
      _GDIPlus_BrushDispose($brush)
      _GDIPlus_GraphicsDispose($graphic)
    EndIf
    _GDIPlus_ImageSaveToFile($thumb, $filepath)
    _GDIPlus_ImageDispose($thumb)
    _GDIPlus_Shutdown()
  EndIf
EndFunc

Func _GDIPlus_GetImageThumbnail($image, $width, $height)
  Local $Ret = DllCall($ghGDIPDll, _
    'int',  'GdipGetImageThumbnail', _
    'ptr',  $image, _
    'int',  $width, _
    'int',  $height, _
    'ptr*', 0, _
    'ptr',  0, _
    'ptr',  0)
  If (@error) Or ($Ret[0]) Then
    Return SetError(1, 0, 0)
  EndIf
  Return $Ret[4]
EndFunc

Func GetCPUAndMemoryUsage($tracker)
  $percents = _CPUsUsageTracker_GetUsage($tracker)
  $total = $tracker[0][0]
  $ret = "CPU"
  For $i=0 To $total - 1
    $ret &= " " & Int($percents[$i]) & "%"
  Next
  $mem = MemGetStats()
  $ret &= " MEM " & $mem[0] & "%/" & Int(($mem[1] - $mem[2]) / 1024) & "MB"
  Return $ret
EndFunc

; http://www.autoitscript.com/forum/topic/151831-cpu-multi-processor-usage-wo-performance-counters/?p=1087981

Func _CPUsUsageTracker_GetUsage(ByRef $aCPUsUsage)
  If Not IsArray($aCPUsUsage) Or UBound($aCPUsUsage, 2) < 2 Then Return SetError(1, 0, "")

  Local $nTotalCPUs, $aUsage, $aCPUsCurInfo
  Local $nTotalActive, $nTotal
  Local $nOverallActive, $nOverallTotal

  $aCPUsCurInfo = _CPUsUsageTracker_Create()
  If @error Then Return SetError(@error, @extended, "")

  $nTotalCPUs = $aCPUsCurInfo[0][0]
  Dim $aUsage[$nTotalCPUs + 1]

  $nOverallActive = 0
  $nOverallTotal = 0

  For $i = 1 To $nTotalCPUs
    $nTotal = $aCPUsCurInfo[$i][0] - $aCPUsUsage[$i][0]
    $nTotalActive = $aCPUsCurInfo[$i][1] - $aCPUsUsage[$i][1]
    $aUsage[$i - 1] = Round($nTotalActive * 100 / $nTotal, 1)

    $nOverallActive += $nTotalActive
    $nOverallTotal += $nTotal
  Next
  $aUsage[$nTotalCPUs] = Round( ($nOverallActive / $nTotalCPUs) * 100 / ($nOverallTotal / $nTotalCPUs), 1)

  ; Replace current usage tracker info
  $aCPUsUsage = $aCPUsCurInfo

  Return SetExtended($nTotalCPUs, $aUsage)
EndFunc

Func _CPUsUsageTracker_Create()
  Local $nTotalCPUs, $aCPUTimes, $aCPUsUsage

  $aCPUTimes = _CPUGetIndividualProcessorTimes()
  If @error Then Return SetError(@error, @extended, "")

  $nTotalCPUs = @extended
  Dim $aCPUsUsage[$nTotalCPUs + 1][2]

  $aCPUsUsage[0][0] = $nTotalCPUs

  For $i = 1 To $nTotalCPUs
    ; Total
    $aCPUsUsage[$i][0] = $aCPUTimes[$i][1] + $aCPUTimes[$i][2]
    ; TotalActive (Kernel Time includes Idle time, so we need to subtract that)
    $aCPUsUsage[$i][1] = $aCPUTimes[$i][1] + $aCPUTimes[$i][2] - $aCPUTimes[$i][0]
  Next

  Return SetExtended($nTotalCPUs, $aCPUsUsage)
EndFunc

Func _CPUGetIndividualProcessorTimes()
  ; DPC = Deferred Procedure Calls
  Local $tagSYSTEM_PROCESSOR_TIMES = "int64 IdleTime;int64 KernelTime;int64 UserTime;int64 DpcTime;int64 InterruptTime;ulong InterruptCount;"

  Local $aRet, $stProcessorTimes, $stBuffer
  Local $i, $nTotalCPUStructs, $pStructPtr

  ; 256 [maximum CPU's] * 48 (structure size) = 12288
  $stBuffer = DllStructCreate("byte Buffer[12288];")

  ; SystemProcessorTimes = 8
  Local $aRet=DllCall("ntdll.dll", "long", "NtQuerySystemInformation", "int", 8, "ptr", DllStructGetPtr($stBuffer), "ulong", 12288, "ulong*", 0)
  If @error Then Return SetError(2, @error, "")

  ; NTSTATUS of something OTHER than success?
  If $aRet[0] Then Return SetError(3, $aRet[0], "")
  ; Length invalid?
  If $aRet[4] = 0 Or $aRet[0] > 12288 Or Mod($aRet[4], 48) <> 0 Then Return SetError(4, $aRet[4], "")

  $nTotalCPUStructs = $aRet[4] / 48
;~  ConsoleWrite("Returned buffer length = " & $aRet[4] & ", len/48 (struct size) = "& $nTotalCPUStructs & @CRLF)

  ; We are interested in Idle, Kernel, and User Times (3)
  Dim $aRet[$nTotalCPUStructs + 1][3]

  $aRet[0][0] = $nTotalCPUStructs

  ; Traversal Pointer for individual CPU structs
  $pStructPtr = DllStructGetPtr($stBuffer)

  For $i = 1 To $nTotalCPUStructs
    $stProcessorTimes = DllStructCreate($tagSYSTEM_PROCESSOR_TIMES, $pStructPtr)

    $aRet[$i][0] = DllStructGetData($stProcessorTimes, "IdleTime")
    $aRet[$i][1] = DllStructGetData($stProcessorTimes, "KernelTime")
    $aRet[$i][2] = DllStructGetData($stProcessorTimes, "UserTime")

    ; Next CPU structure
    $pStructPtr += 48
  Next

  Return SetExtended($nTotalCPUStructs, $aRet)
EndFunc
