function Write-SafeLog {
            param($Message, $Level)
            
            if ($logFunction.Name -eq 'Write-Log') {
                & $logFunction -Message $Message -Level $Level
            }
            else {
                # Map log levels to Write-SimpleLog format
                $simpleLevel = switch ($Level) {
                    'Info' { 'INFO' }
                    'Warning' { 'Warning' }
                    'Error' { 'ERROR' }
                    'Success' { 'SUCCESS' }
                    default { 'INFO' }
                }
                & $logFunction -Message $Message -Level $simpleLevel
            }
        }
