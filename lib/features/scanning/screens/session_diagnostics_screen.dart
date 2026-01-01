import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:vronmobile2/features/scanning/services/session_investigation_service.dart';
import 'package:vronmobile2/features/scanning/models/session_diagnostics.dart';
import 'package:intl/intl.dart';

/// Screen displaying detailed session diagnostics from BlenderAPI investigation endpoint
///
/// Shows:
/// - Session metadata (ID, status, timestamps)
/// - File structure (input/output/logs directories)
/// - Error details for failed sessions
/// - Log summaries
/// - Full JSON diagnostic data
class SessionDiagnosticsScreen extends StatefulWidget {
  final String sessionId;
  final SessionInvestigationService investigationService;

  SessionDiagnosticsScreen({
    super.key,
    required this.sessionId,
    SessionInvestigationService? investigationService,
  }) : investigationService =
           investigationService ?? SessionInvestigationService();

  @override
  State<SessionDiagnosticsScreen> createState() =>
      _SessionDiagnosticsScreenState();
}

class _SessionDiagnosticsScreenState extends State<SessionDiagnosticsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  SessionDiagnostics? _diagnostics;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final diagnostics = await widget.investigationService.investigate(
        widget.sessionId,
      );
      setState(() {
        _diagnostics = diagnostics;
        _isLoading = false;
      });
    } on SessionInvestigationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Session Diagnostics',
          header: true,
          child: const Text('Session Diagnostics'),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading session diagnostics...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDiagnostics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_diagnostics == null) {
      return const Center(child: Text('No diagnostics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfo(),
          const SizedBox(height: 16),
          if (_diagnostics!.errorDetails != null) ...[
            _buildErrorDetails(),
            const SizedBox(height: 16),
          ],
          if (_diagnostics!.files != null) ...[
            _buildFilesSection(),
            const SizedBox(height: 16),
          ],
          if (_diagnostics!.logsSummary != null) ...[
            _buildLogsSummary(),
            const SizedBox(height: 16),
          ],
          _buildJsonViewer(),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    final diagnostics = _diagnostics!;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Semantics(
      label: 'Session Information',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              _buildInfoRow('Session ID', diagnostics.sessionId),
              _buildInfoRow(
                'Status: ${diagnostics.sessionStatus}',
                diagnostics.statusMessage,
              ),
              _buildInfoRow(
                'Created',
                dateFormat.format(diagnostics.createdAt.toLocal()),
              ),
              _buildInfoRow(
                'Expires',
                dateFormat.format(diagnostics.expiresAt.toLocal()),
              ),
              if (diagnostics.lastAccessed != null)
                _buildInfoRow(
                  'Last Accessed',
                  dateFormat.format(diagnostics.lastAccessed!.toLocal()),
                ),
              _buildInfoRow(
                'Workspace Exists',
                diagnostics.workspaceExists ? 'Yes' : 'No',
              ),
              if (diagnostics.isExpired)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Session has expired'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildErrorDetails() {
    final errorDetails = _diagnostics!.errorDetails!;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Card(
      color: Colors.red.shade50,
      child: ExpansionTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: const Text(
          'Error Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(errorDetails.errorMessage),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorDetails.errorCode != null)
                  _buildInfoRow('Error Code', errorDetails.errorCode!),
                if (errorDetails.processingStage != null)
                  _buildInfoRow('Stage', errorDetails.processingStage!),
                if (errorDetails.failedAt != null)
                  _buildInfoRow(
                    'Failed At',
                    dateFormat.format(errorDetails.failedAt!.toLocal()),
                  ),
                if (errorDetails.blenderExitCode != null)
                  _buildInfoRow(
                    'Exit Code',
                    errorDetails.blenderExitCode.toString(),
                  ),
                if (errorDetails.lastErrorLogs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Error Logs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: errorDetails.lastErrorLogs
                          .map(
                            (log) => Text(
                              log,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection() {
    final files = _diagnostics!.files!;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.folder),
        title: const Text(
          'Files',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...files.directories.entries.map(
                  (entry) => _buildDirectoryTile(entry.key, entry.value),
                ),
                if (files.rootFiles.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Root Files:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...files.rootFiles.map(_buildFileTile),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryTile(String name, DirectoryInfo directory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              directory.exists ? Icons.folder : Icons.folder_off,
              color: directory.exists ? null : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${directory.fileCount} files'),
          ],
        ),
        if (directory.exists && directory.files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32.0, top: 8.0),
            child: Column(
              children: directory.files.map(_buildFileTile).toList(),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFileTile(FileInfo file) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(file.name)),
          Text(
            file.sizeHumanReadable,
            style: const TextStyle(color: Colors.grey),
          ),
          if (file.modifiedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              dateFormat.format(file.modifiedAt!.toLocal()),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogsSummary() {
    final logs = _diagnostics!.logsSummary!;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.article),
        title: const Text(
          'Log Summary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${logs.totalLines} lines (${logs.errorCount} errors, ${logs.warningCount} warnings)',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Total Lines', logs.totalLines.toString()),
                _buildInfoRow('Errors', logs.errorCount.toString()),
                _buildInfoRow('Warnings', logs.warningCount.toString()),
                _buildInfoRow(
                  'File Size',
                  '${(logs.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                ),
                if (logs.lastLines.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Last Log Lines:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: logs.lastLines
                          .map(
                            (line) => Text(
                              line,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonViewer() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.code),
        title: const Text(
          'Full Diagnostic Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: JsonView.map(_diagnostics!.toJson()),
          ),
        ],
      ),
    );
  }
}
