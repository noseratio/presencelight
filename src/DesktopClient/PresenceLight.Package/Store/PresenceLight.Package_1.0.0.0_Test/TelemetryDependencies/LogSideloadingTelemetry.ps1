﻿#
# This script handles common telemetry tasks for Install.ps1 and Add-AppDevPackage.ps1.
#

function IsVsTelemetryRegOptOutSet()
{
    $VsTelemetryRegOptOutKeys = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\SQM",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM",
        "HKLM:\SOFTWARE\Microsoft\VSCommon\16.0\SQM"
    )

    foreach ($optOutKey in $VsTelemetryRegOptOutKeys)
    {
        if (Test-Path $optOutKey)
        {
            # If any of these keys have the DWORD value OptIn set to 0 that means that the user
            # has explicitly opted out of logging telemetry from Visual Studio.
            $val = (Get-ItemProperty $optOutKey)."OptIn"
            if ($val -eq 0)
            {
                return $true
            }
        }
    }

    return $false
}

try
{
    $TelemetryOptedOut = IsVsTelemetryRegOptOutSet
    if (!$TelemetryOptedOut)
    {
        $TelemetryAssembliesFolder = $args[0]
        $EventName = $args[1]
        $ReturnCode = $args[2]
        $ProcessorArchitecture = $args[3]

        foreach ($file in Get-ChildItem $TelemetryAssembliesFolder -Filter "*.dll")
        {
            [Reflection.Assembly]::LoadFile((Join-Path $TelemetryAssembliesFolder $file)) | Out-Null
        }

        [Microsoft.VisualStudio.Telemetry.TelemetryService]::DefaultSession.IsOptedIn = $True
        [Microsoft.VisualStudio.Telemetry.TelemetryService]::DefaultSession.Start()

        $TelEvent = New-Object "Microsoft.VisualStudio.Telemetry.TelemetryEvent" -ArgumentList $EventName
        if ($null -ne $ReturnCode)
        {
            $TelEvent.Properties["VS.DesignTools.SideLoadingScript.ReturnCode"] = $ReturnCode
        }

        if ($null -ne $ProcessorArchitecture)
        {
            $TelEvent.Properties["VS.DesignTools.SideLoadingScript.ProcessorArchitecture"] = $ProcessorArchitecture
        }

        [Microsoft.VisualStudio.Telemetry.TelemetryService]::DefaultSession.PostEvent($TelEvent)
        [Microsoft.VisualStudio.Telemetry.TelemetryService]::DefaultSession.Dispose()
    }
}
catch
{
    # Ignore telemetry errors
}
# SIG # Begin signature block
# MIIhdwYJKoZIhvcNAQcCoIIhaDCCIWQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDJYj3WBgxKGoze
# wr0Sg8FHTlHGd5t93FeYNiZX9fYkC6CCC3IwggT6MIID4qADAgECAhMzAAADJUiy
# nQ5/xfQfAAAAAAMlMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTAwHhcNMjAwMzA0MTgyOTI5WhcNMjEwMzAzMTgyOTI5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCjpRI2NHmdF4E+oz+32gQNFWfiWA/gW26xpPqf0l47t99p7IIKd5CuTAMePNYW
# XHST8pFfb8yaTNWz6nECabhQTCIxAqtAzVpCNWXiuQDe18eEUoUFN2sgoMhpU7gb
# 0gZigbhvznmT0moq7orBEAMcrW6C88+9JyqWBgDK0MBbpxjIwBv0uPgj3R40ItML
# Qw9Lb0SBnriOEPQKGDCO2AI6MSi++xe5YXOkQZrLCDc6Tl/f/fTzn1Ci+JR7YJMd
# dq8f2Ne42ogsUVIW6JH8SKbLQXb9xOVn4fMiG9b6PgRugApS0IKAUI8OQQ2kSr2a
# 1BsKEY9B7MNUeFBXB74OrutZAgMBAAGjggF5MIIBdTAfBgNVHSUEGDAWBgorBgEE
# AYI3PQYBBggrBgEFBQcDAzAdBgNVHQ4EFgQULcKPAJ0r4hUrTVSYmpa5RA+uHnww
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzA4NjUrNDU4NDkzMB8GA1UdIwQYMBaAFOb8
# X3u7IgBY5HJOtfQhdCMy5u+sMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8yMDEw
# LTA3LTA2LmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzIwMTAtMDct
# MDYuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggEBAFxz4O+cWeBo
# 86e5EImiUeJXoJ5huJwH6l3YUBLhBt+t+uE6zDtBqmygeAq+qMs3otaucTmO6VEy
# LRACa7Yx8xxDLK7MAcnxwAY6SYjciErNsDf1tApeZkCIINFW/8S2QKMSQXf4OJol
# jWHo1TkniL9IRmzviN9l42NYNJB9i71ezxP+6ZN4PDWi8QVe70dGCLl9O2RxPQFh
# Ecl3jWdCu5C1FDRg6qMpcx3qseQR2QF4+d4EE/UQ1h3YeShbtuzxf0ksbBnQqVU2
# ZJ9E/GJUTWUSsYxsJnG8xg3G46Jz3ttfVE3coMLKh1fHqsI3XXIlVzT3BIx3N9nL
# g18hwONtu5kwggZwMIIEWKADAgECAgphDFJMAAAAAAADMA0GCSqGSIb3DQEBCwUA
# MIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQD
# EylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0x
# MDA3MDYyMDQwMTdaFw0yNTA3MDYyMDUwMTdaMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTAwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDpDmRQ
# eWe1xOP9CQBMnpSs91Zo6kTYz8VYT6mldnxtRbrTOZK0pB75+WWC5BfSj/1EnAjo
# ZZPOLFWEv30I4y4rqEErGLeiS25JTGsVB97R0sKJHnGUzbV/S7SvCNjMiNZrF5Q6
# k84mP+zm/jSYV9UdXUn2siou1YW7WT/4kLQrg3TKK7M7RuPwRknBF2ZUyRy9HcRV
# Yldy+Ge5JSA03l2mpZVeqyiAzdWynuUDtWPTshTIwciKJgpZfwfs/w7tgBI1TBKm
# vlJb9aba4IsLSHfWhUfVELnG6Krui2otBVxgxrQqW5wjHF9F4xoUHm83yxkzgGqJ
# TaNqZmN4k9Uwz5UfAgMBAAGjggHjMIIB3zAQBgkrBgEEAYI3FQEEAwIBADAdBgNV
# HQ4EFgQU5vxfe7siAFjkck619CF0IzLm76wwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# 1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2Ny
# bC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
# Ni0yMy5jcnQwgZ0GA1UdIASBlTCBkjCBjwYJKwYBBAGCNy4DMIGBMD0GCCsGAQUF
# BwIBFjFodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vUEtJL2RvY3MvQ1BTL2RlZmF1
# bHQuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAFAAbwBsAGkAYwB5
# AF8AUwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQAadO9X
# Tyl7xBaFeLhQ0yL8CZ2sgpf4NP8qLJeVEuXkv8+/k8jjNKnbgbjcHgC+0jVvr+V/
# eZV35QLU8evYzU4eG2GiwlojGvCMqGJRRWcI4z88HpP4MIUXyDlAptcOsyEp5aWh
# aYwik8x0mOehR0PyU6zADzBpf/7SJSBtb2HT3wfV2XIALGmGdj1R26Y5SMk3YW0H
# 3VMZy6fWYcK/4oOrD+Brm5XWfShRsIlKUaSabMi3H0oaDmmp19zBftFJcKq2rbty
# R2MX+qbWoqaG7KgQRJtjtrJpiQbHRoZ6GD/oxR0h1Xv5AiMtxUHLvx1MyBbvsZx/
# /CJLSYpuFeOmf3Zb0VN5kYWd1dLbPXM18zyuVLJSR2rAqhOV0o4R2plnXjKM+zeF
# 0dx1hZyHxlpXhcK/3Q2PjJst67TuzyfTtV5p+qQWBAGnJGdzz01Ptt4FVpd69+lS
# TfR3BU+FxtgL8Y7tQgnRDXbjI1Z4IiY2vsqxjG6qHeSF2kczYo+kyZEzX3EeQK+Y
# Zcki6EIhJYocLWDZN4lBiSoWD9dhPJRoYFLv1keZoIBA7hWBdz6c4FMYGlAdOJWb
# HmYzEyc5F3iHNs5Ow1+y9T1HU7bg5dsLYT0q15IszjdaPkBCMaQfEAjCVpy/JF1R
# Ap1qedIX09rBlI4HeyVxRKsGaubUxt8jmpZ1xTGCFVswghVXAgEBMIGVMH4xCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jv
# c29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTACEzMAAAMlSLKdDn/F9B8AAAAAAyUw
# DQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIP0IUOM
# BJw0eRiT2Osp18eCU/zvQ83hW8jMkUFKv3nYMEIGCisGAQQBgjcCAQwxNDAyoBSA
# EgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20w
# DQYJKoZIhvcNAQEBBQAEggEAG5eNqxvSGAFQJpgFpJbLjdrGq1ohokHJ3XRp6FrW
# fXZHOncLeXJXmyWjoYL113XL9C0vlqoUb5t/lBxKFA/vBVf8rQpawHJBvbw7Q6l3
# L1AsRKQc6sAj1yloXoXFwpM693Yi3VV1QCwpmg81ErAzHCfWsZc5xZBXCOplwJ2R
# AeDAlHUilptY8AVEyTNkOHLgAAiNkwGfyXLBmyrXxoOwz7tcOLNEqRBRUalzzht2
# A0AY9mvGu2UNRMUPFHuAg4+lYHl02hzdNau4S+l1WvhhP9ETtTRIe/t3bYM2SOwW
# wFwPYLfOOn79zQDNb33bElJqBAqtxjtEjJQbq0z6SNWDP6GCEuUwghLhBgorBgEE
# AYI3AwMBMYIS0TCCEs0GCSqGSIb3DQEHAqCCEr4wghK6AgEDMQ8wDQYJYIZIAWUD
# BAIBBQAwggFRBgsqhkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGEWQoD
# ATAxMA0GCWCGSAFlAwQCAQUABCBGzc+TCdSFkht3rmhLQiU1RusmgU3dHPyMFp53
# 0rNVzAIGXzqs86YoGBMyMDIwMDkwOTIyNDUyMy42MDJaMASAAgH0oIHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjo3QkYxLUUzRUEtQjgwODElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaCCDjwwggTxMIID2aADAgECAhMzAAABH04lzawK9LgfAAAAAAEf
# MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4X
# DTE5MTExMzIxNDA0MVoXDTIxMDIxMTIxNDA0MVowgcoxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNh
# IE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjdCRjEtRTNFQS1C
# ODA4MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApUwPzFb3PxyMf046MLWFCtFwlCpz
# u1wPi26cp0QYxa19ybbPnDF+1xljQ1p6pXj+hPLTQIgsV/xLAnDoKnRGmq37L4eS
# VSXgMmCTDaZLZUwJi3DysQgdCX8uwo+cnlfGfFCZ0OzTIVgjt4wa1oWtqkg0eJ+/
# h4CeiGfdSfrz9Ds9o/zn8VWpfzscW7vHFjAmT3XkATl3Z1UIVxibSDhOGS+fNEb8
# twd24Rn+qBpitRqVLbJGfLakIMj9cORXXhvYWGyCQfyuPmWPKaQ194iZiqWL/s/9
# CWW5+381++7ORa9aqtOmDyRCTVDvGtLTIZnsA/WID7SQVxXgq8u5YtsIswIDAQAB
# o4IBGzCCARcwHQYDVR0OBBYEFBWjHwA6MBNjBDdlIlsrwTaJ+uDAMB8GA1UdIwQY
# MBaAFNVjOlyKMZDzQ3t8RhvFM2hahW1VMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6
# Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1RpbVN0YVBD
# QV8yMDEwLTA3LTAxLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0
# dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljVGltU3RhUENBXzIw
# MTAtMDctMDEuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# DQYJKoZIhvcNAQELBQADggEBAJjRR8DcZOLKYqvJzonPUcQsC9l/Pwu94Mv+7l8X
# 1BW2+zKEqADT9ogJD3Op7cAg3x3x6baEL6qw4hwOCU3dWUEmxAS6hO6Wd8Fdi/oU
# ZlM4qesCiX91DZ5P9xXiEDz1UXQxbZkY/KgegJAI4COyQItpLylGgmmx58X1y5gY
# UUmlzEHYwCe3UYLCm6AE2qN+/TQ51hylim7BNR6s2wqIEJgFLGy11ZgSJOi5tQ5B
# qLOh+wItYRqroZR0QINNTZ0+KV0qymbanYqIMifGbc5M9fNc+f2RNnG4MZvMAfsI
# UVlq/3MhrWN/kDKgvt7vx0LI/Ofg1lcFPFPjwfuKzYtqbEQwggZxMIIEWaADAgEC
# AgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3MDEyMTM2NTVaFw0yNTA3MDEy
# MTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog7PwTl/X6f2mUa3RUENWlCgCC
# hfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9BGxqVHc4JE458YTBZsTBED/FgiIRU
# QwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRgMlhgRvJYR4YyhB50YWeRX4FU
# sc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScdJGcSchohiq9LZIlQYrFd/XcfPfBX
# day9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDaTgaRtogINeh4
# HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJRF1eFpwBBU8iTQIDAQABo4IB5jCC
# AeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDzQ3t8RhvFM2ha
# hW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYG
# A1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3Js
# L3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcB
# AQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kv
# Y2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGgBgNVHSABAf8EgZUw
# gZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEFBQcCAjA0
# HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUAbgB0
# AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aIUQ3ixuCYP4FxAz2do6Ehb7Prpsz1
# Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GCRBL7uVOMzPRg
# Eop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/Gf/I3fVo/HPKZeUqRUgCvOA8X
# 9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8ySif9Va8v/rbl
# jjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZSnFjnXshbcOco6I8+n99lmqQ
# eKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4tYCbIjggtSXlZOz39L9+Y1klD3ou
# OVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D8OE7cQnfXXSYIghh2rBQHm+9
# 8eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293qYHLpwmsObvsxsvYgrRyzR30uIUB
# HoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp9cAvVCch98isTtoouLGp25ay
# p0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZii8bxyGvWbWu3EQ8l1Bx16HSxVXj
# ad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzVs341Hgi62jbb
# 01+P3nSISRKhggLOMIICNwIBATCB+KGB0KSBzTCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046N0JGMS1FM0VBLUI4
# MDgxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAH
# BgUrDgMCGgMVANQvRJa2WvwYqkrR2BYDDosSXkkMoIGDMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQACBQDjA30lMCIYDzIw
# MjAwOTEwMDAxMTE3WhgPMjAyMDA5MTEwMDExMTdaMHcwPQYKKwYBBAGEWQoEATEv
# MC0wCgIFAOMDfSUCAQAwCgIBAAICHGYCAf8wBwIBAAICEbkwCgIFAOMEzqUCAQAw
# NgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgC
# AQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQAZZcQ8cMSPSyrm9WxkwwzjuwBJKvfn
# SEvp+2xrttFY+02Hbu3fmPc+cyRASZNHjuhUDxlo00cmw5zw8H/75c+WFOZvqbLh
# Q0KPgA7Pyqy2tQwHmWAd5+wpJ3aHO0r/jAg+Ti4/gyyHgjB0j/6U6JSdqEuYo24i
# Xb6vDoV5uSMrXDGCAw0wggMJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwAhMzAAABH04lzawK9LgfAAAAAAEfMA0GCWCGSAFlAwQCAQUAoIIBSjAa
# BgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEINjFU16n
# JIBHwu/lXi/JXOG9ifjz6RJ7eFk19kwE8QHBMIH6BgsqhkiG9w0BCRACLzGB6jCB
# 5zCB5DCBvQQgqqVw9wBbf/k7/9NxWOfj0eEILScmByNE1X7fVsE+g6UwgZgwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAR9OJc2sCvS4HwAA
# AAABHzAiBCCvwNknaBhKXolwZKq6BeEXMzYP4kgCtIfkf7zjdpMtRjANBgkqhkiG
# 9w0BAQsFAASCAQCUtz7BckpfzVWttflhxZ/B49H9EagL3kl9So1vM29d5y2bI2zf
# JKTZldHPWurbV3BaPKeQlwuCyhD3dW7t2bj8fqY3nqf0uyortJzAAK6YFcXF7hkk
# YYAoH9wYNR7Lj77N11k6QJtpHnXqSUdppz64loFdCIhRhBdvonHxuVB1JPKBPbOA
# 9w35bfjn7rxCK9Z3gTLHbRC0YU02JQTeAAy4CDTkgtL8Q/Ix68hvE/QjLxXjCb3Z
# mm3mddboeJPMIM5oPmDSpJ5y0Rj5r5eq4kRDOgiLr2tu8m/7w5zfTM6OgR7jReAD
# +l+eLdVcHEqcb08lDB9niQQMCpQLHFtSnJ5A
# SIG # End signature block
