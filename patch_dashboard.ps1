$ErrorActionPreference = 'Stop'

$path = Join-Path $PSScriptRoot 'lib/screens/dashboard.dart'
$content = Get-Content -LiteralPath $path -Raw

# Remove stray broken line that causes duplicate_definition / expected_token
$content = $content -replace "\r?\n\s*final viewModel = context\.watch\s*\r?\n", "`r`n"

# Ensure imports
if ($content -notmatch "import '../models/environment_analysis.dart';") {
  $content = $content -replace "import '\.\./main\.dart'; // for DashboardViewModel\r?\n", "import '../main.dart'; // for DashboardViewModel`r`nimport '../models/environment_analysis.dart';`r`n"
}

# Normalize any partially-patched typed Environment Analysis card (from previous runs).
# NOTE: Use single-quoted PowerShell strings so $risk/$lighting/$e are not expanded by PowerShell.
$content = $content -replace "SnackBar\(content: Text\('Failed to send command: '\)\)", 'SnackBar(content: Text(''Failed to send command: $e''))'
$content = $content -replace "'Risk:\s*'", '''Risk: $risk'''
$content = $content -replace "'Lighting:\s*'", '''Lighting: $lighting'''
$content = $content -replace "'Hazards:\s*'", '''Hazards: ${(analysis?.hazards.length ?? 0)}'''
$content = $content -replace "hazardsText == '--' \? 'Hazards: --' : 'Hazards: '\s*\)", 'hazardsText == ''--'' ? ''Hazards: --'' : ''Hazards: $hazardsText'')'

# If a dynamic/old environment card implementation exists (from manual edits), replace it with
# a typed EnvironmentAnalysis implementation that matches our current models + services.
if ($content -match "Widget _buildEnvironmentAnalysisCard\(BuildContext context, dynamic analysis\)") {
  $replacement = @"
  Widget _buildEnvironmentAnalysisCard(
    BuildContext context,
    EnvironmentAnalysis? analysis,
  ) {
    final theme = Theme.of(context);

    final String risk = (analysis?.riskLevel?.isNotEmpty ?? false)
        ? analysis!.riskLevel!
        : '--';
    final String lighting = (analysis?.lighting?.isNotEmpty ?? false)
        ? analysis!.lighting!
        : '--';
    final String summary = (analysis?.summary?.isNotEmpty ?? false)
        ? analysis!.summary!
        : 'No environment analysis yet.';
    final String hazardsText = (analysis == null || analysis.hazards.isEmpty)
        ? '--'
        : analysis.hazards.join(', ');

    Future<void> onAnalyzePressed() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await DeviceCommandService().sendAnalyzeEnvironmentCommand();
        messenger.showSnackBar(
          const SnackBar(content: Text('Analyze My Environment command sent.')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to send command: $e')),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_outdoor, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Environment Analysis',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Risk: $risk',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lighting: $lighting',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Text(
                'Hazards: ${(analysis?.hazards.length ?? 0)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hazardsText == '--' ? 'Hazards: --' : 'Hazards: $hazardsText',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAnalyzePressed,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze My Environment'),
            ),
          ),
        ],
      ),
    );
  }
"@

  $content = [regex]::Replace(
    $content,
    "Widget _buildEnvironmentAnalysisCard\(BuildContext context, dynamic analysis\)[\s\S]*?\r?\n\}\r?\n\r?\n\s*String _wifiLabel",
    ($replacement + "`r`n`r`n  String _wifiLabel"),
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )
}

if ($content -notmatch "import '../services/device_command_service.dart';") {
  $content = $content -replace "import '\.\./models/environment_analysis\.dart';\r?\n", "import '../models/environment_analysis.dart';`r`nimport '../services/device_command_service.dart';`r`n"
}

# Wire latestEnv in build()
if ($content -notmatch "latestEnvironmentAnalysis") {
  $content = $content -replace "final isLoading = viewModel\.isLoading;\r?\n", "final isLoading = viewModel.isLoading;`r`n    final EnvironmentAnalysis? latestEnv = viewModel.latestEnvironmentAnalysis;`r`n"
}

# Insert Environment Analysis card after header
if ($content -notmatch "_buildEnvironmentAnalysisCard\(") {
  $content = $content -replace "_buildHeader\(context, snapshot, isLoading\),\r?\n\s*const SizedBox\(height: AppSpacing\.md\),\r?\n", "_buildHeader(context, snapshot, isLoading),`r`n              const SizedBox(height: AppSpacing.md),`r`n              _buildEnvironmentAnalysisCard(context, latestEnv),`r`n              const SizedBox(height: AppSpacing.md),`r`n"
}

# Remove Blynk wording
$content = $content -replace "Connecting to ESP32 / Blynk\.\.\.", "Connecting to ESP32 / Firebase..."
$content = $content -replace "command to Blynk/ESP32", "command to Firebase/ESP32"

# Add card method above _wifiLabel if missing
if ($content -notmatch "Widget _buildEnvironmentAnalysisCard") {
  $needle = "  String _wifiLabel"
  $method = @"
  Widget _buildEnvironmentAnalysisCard(
    BuildContext context,
    EnvironmentAnalysis? analysis,
  ) {
    final theme = Theme.of(context);

    final String summary = (analysis?.summary?.isNotEmpty ?? false)
        ? analysis!.summary!
        : 'No environment analysis yet.';

    final String lighting = (analysis?.lighting?.isNotEmpty ?? false)
        ? analysis!.lighting!
        : '--';

    final String risk = (analysis?.riskLevel?.isNotEmpty ?? false)
        ? analysis!.riskLevel!
        : '--';

    final String hazardsText = (analysis == null || analysis.hazards.isEmpty)
        ? '--'
        : analysis.hazards.join(', ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore, color: AppColors.accentBlue),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Environment Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Risk: $risk',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lighting: $lighting',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hazards: $hazardsText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await DeviceCommandService().sendAnalyzeEnvironmentCommand();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Analyze My Environment command sent.'),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to send command: $e'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analyze My Environment'),
            ),
          ),
        ],
      ),
    );
  }

"@

  $idx = $content.IndexOf($needle)
  if ($idx -lt 0) {
    throw "Could not find insertion point '$needle' in dashboard.dart"
  }

  $content = $content.Substring(0, $idx) + $method + $content.Substring($idx)
}

Set-Content -LiteralPath $path -Value $content -NoNewline
Write-Host "Patched $path"
