/// Models for SENTIENT's generated-report feature: report templates, the
/// reports produced from them, and the async generation job.
///
/// Deliberately separate from `report_models.dart`, which describes
/// ThingsBoard's unrelated dashboard-to-PDF export (`ReportParams` /
/// `ReportConfig`, POST /api/report/{dashboardId}/download).
library;

/// Lifecycle of a report generation job.
///
/// Serialized by the server as an upper-case string. Unrecognised values
/// degrade to [ReportStatus.unknown] rather than throwing, so a new server
/// status can never crash an older app build.
enum ReportStatus {
  pending,
  generating,
  completed,
  failed,
  unknown,
}

ReportStatus reportStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'PENDING':
      return ReportStatus.pending;
    case 'GENERATING':
      return ReportStatus.generating;
    case 'COMPLETED':
      return ReportStatus.completed;
    case 'FAILED':
      return ReportStatus.failed;
    default:
      return ReportStatus.unknown;
  }
}

extension ReportStatusInfoExt on ReportStatus {
  /// True while the job is still running, i.e. worth polling again.
  bool get isInProgress =>
      this == ReportStatus.pending || this == ReportStatus.generating;

  /// True when a file exists to view or download.
  bool get isDownloadable => this == ReportStatus.completed;
}

/// Pull a UUID out of a field that may be either a bare string or an EntityId
/// object.
///
/// The two list endpoints disagree: /api/reports returns `"id": "<uuid>"`
/// while /api/v2/reportInfos/all returns
/// `"id": {"entityType": "REPORT", "id": "<uuid>"}`. Reading one shape as the
/// other yields a silent null rather than an error, so both are handled here.
String? _idOf(dynamic value) {
  if (value is String) return value;
  if (value is Map) return value['id'] as String?;
  return null;
}

/// The template a report was generated from, as embedded in a report row.
class ReportTemplateRef {
  const ReportTemplateRef({this.id, required this.name});

  final String? id;
  final String name;

  factory ReportTemplateRef.fromJson(Map<String, dynamic> json) {
    return ReportTemplateRef(
      id: _idOf(json['id']),
      name: json['name'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ReportTemplateRef(id: $id, name: $name)';
}

/// A single generated report (a row of GET /api/reports).
class GeneratedReport {
  const GeneratedReport({
    this.id,
    this.createdTime,
    this.tenantId,
    this.reportTemplateId,
    this.schedulerEventId,
    this.userId,
    this.userName,
    this.name,
    this.format,
    this.fileName,
    this.fileSize,
    this.status = ReportStatus.unknown,
    this.errorMessage,
    this.contentType,
    this.templateInfo,
  });

  final String? id;
  final int? createdTime;
  final String? tenantId;
  final String? reportTemplateId;

  /// Set when the report was produced by a schedule rather than on demand.
  final String? schedulerEventId;
  final String? userId;

  /// The generating user's email, despite the name.
  final String? userName;
  final String? name;

  /// 'PDF' or 'CSV'.
  final String? format;
  final String? fileName;
  final int? fileSize;
  final ReportStatus status;
  final String? errorMessage;
  final String? contentType;
  final ReportTemplateRef? templateInfo;

  factory GeneratedReport.fromJson(Map<String, dynamic> json) {
    final template = json['templateInfo'];
    return GeneratedReport(
      id: _idOf(json['id']),
      createdTime: json['createdTime'] as int?,
      tenantId: _idOf(json['tenantId']),
      reportTemplateId: _idOf(json['reportTemplateId']),
      schedulerEventId: _idOf(json['schedulerEventId']),
      userId: _idOf(json['userId']),
      userName: json['userName'] as String?,
      name: json['name'] as String?,
      format: json['format'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      status: reportStatusFromString(json['status'] as String?),
      errorMessage: json['errorMessage'] as String?,
      contentType: json['contentType'] as String?,
      templateInfo: template is Map<String, dynamic>
          ? ReportTemplateRef.fromJson(template)
          : null,
    );
  }

  @override
  String toString() =>
      'GeneratedReport(id: $id, name: $name, status: $status, format: $format)';
}

/// A report template the user may generate from
/// (a row of GET /api/reportTemplateInfos/all).
class ReportTemplateInfo {
  const ReportTemplateInfo({
    this.id,
    this.createdTime,
    required this.name,
    required this.format,
    this.templateType,
    this.description,
    this.customerTitle,
    this.ownerName,
  });

  final String? id;
  final int? createdTime;
  final String name;

  /// 'PDF' or 'CSV'.
  final String format;

  /// Server field is `type` ('REPORT' / 'SUBREPORT').
  final String? templateType;
  final String? description;
  final String? customerTitle;
  final String? ownerName;

  factory ReportTemplateInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return ReportTemplateInfo(
      id: rawId is Map ? rawId['id'] as String? : rawId as String?,
      createdTime: json['createdTime'] as int?,
      name: json['name'] as String? ?? '',
      format: json['format'] as String? ?? 'PDF',
      templateType: json['type'] as String?,
      description: json['description'] as String?,
      customerTitle: json['customerTitle'] as String?,
      ownerName: json['ownerName'] as String?,
    );
  }

  @override
  String toString() => 'ReportTemplateInfo(id: $id, name: $name)';
}

/// Progress of a generation job (GET /api/report/{reportId}/status).
class ReportGenerationStatus {
  const ReportGenerationStatus({
    this.reportId,
    this.status = ReportStatus.unknown,
    this.progress = 0,
    this.progressMessage,
    this.errorMessage,
    this.fileName,
    this.fileSize,
  });

  final String? reportId;
  final ReportStatus status;

  /// 0-100.
  final int progress;
  final String? progressMessage;
  final String? errorMessage;
  final String? fileName;
  final int? fileSize;

  factory ReportGenerationStatus.fromJson(Map<String, dynamic> json) {
    return ReportGenerationStatus(
      reportId: json['reportId'] as String?,
      status: reportStatusFromString(json['status'] as String?),
      progress: json['progress'] as int? ?? 0,
      progressMessage: json['progressMessage'] as String?,
      errorMessage: json['errorMessage'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }

  @override
  String toString() =>
      'ReportGenerationStatus(status: $status, progress: $progress)';
}

/// Time range a report covers (POST /api/report/generate).
class ReportTimeWindow {
  const ReportTimeWindow({
    required this.type,
    this.interval,
    this.startTime,
    this.endTime,
  });

  /// e.g. 'REALTIME' or 'HISTORY'.
  final String type;

  /// Relative window length in ms, for realtime windows.
  final int? interval;

  /// Absolute bounds in ms since epoch, for history windows.
  final int? startTime;
  final int? endTime;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (interval != null) json['interval'] = interval;
    if (startTime != null) json['startTime'] = startTime;
    if (endTime != null) json['endTime'] = endTime;
    return json;
  }
}

/// Body of POST /api/report/generate.
class GenerateReportRequest {
  const GenerateReportRequest({
    required this.templateId,
    this.entityFilter,
    this.timeWindow,
    this.timezone,
  });

  final String templateId;
  final Map<String, dynamic>? entityFilter;
  final ReportTimeWindow? timeWindow;

  /// IANA zone (e.g. 'Asia/Kolkata'); the server uses it to name the report.
  final String? timezone;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'templateId': templateId};
    if (entityFilter != null) json['entityFilter'] = entityFilter;
    if (timeWindow != null) json['timeWindow'] = timeWindow!.toJson();
    if (timezone != null) json['timezone'] = timezone;
    return json;
  }
}

/// Acknowledgement of POST /api/report/generate. Generation is asynchronous:
/// the returned [reportId] must be polled via
/// `ReportService.getReportGenerationStatus`.
class GenerateReportResponse {
  const GenerateReportResponse({
    this.reportId,
    this.templateId,
    this.status = ReportStatus.unknown,
  });

  final String? reportId;
  final String? templateId;
  final ReportStatus status;

  factory GenerateReportResponse.fromJson(Map<String, dynamic> json) {
    return GenerateReportResponse(
      reportId: json['reportId'] as String?,
      templateId: json['templateId'] as String?,
      status: reportStatusFromString(json['status'] as String?),
    );
  }
}
