import 'dart:convert';
import 'dart:math';

import 'id/audit_log_id.dart';
import 'id/customer_id.dart';
import 'id/entity_id.dart';

import 'base_data.dart';
import 'id/tenant_id.dart';
import 'id/user_id.dart';

enum ActionType {
  ADDED,
  DELETED,
  UPDATED,
  ATTRIBUTES_UPDATED,
  ATTRIBUTES_DELETED,
  RPC_CALL,
  CREDENTIALS_UPDATED,
  ASSIGNED_TO_CUSTOMER,
  UNASSIGNED_FROM_CUSTOMER,
  ACTIVATED,
  SUSPENDED,
  CREDENTIALS_READ,
  ATTRIBUTES_READ,
  ADDED_TO_ENTITY_GROUP,
  REMOVED_FROM_ENTITY_GROUP,
  RELATION_ADD_OR_UPDATE,
  RELATION_DELETED,
  RELATIONS_DELETED,
  ALARM_ACK,
  ALARM_CLEAR,
  ALARM_DELETE,
  ALARM_ASSIGNED,
  ALARM_UNASSIGNED,
  REST_API_RULE_ENGINE_CALL,
  MADE_PUBLIC,
  MADE_PRIVATE,
  LOGIN,
  LOGOUT,
  LOCKOUT,
  ASSIGNED_FROM_TENANT,
  ASSIGNED_TO_TENANT,
  PROVISION_SUCCESS,
  PROVISION_FAILURE,
  TIMESERIES_UPDATED,
  TIMESERIES_DELETED,
  CHANGE_OWNER,
  ASSIGNED_TO_EDGE,
  UNASSIGNED_FROM_EDGE,
  ADDED_COMMENT,
  UPDATED_COMMENT,
  DELETED_COMMENT,
  SMS_SENT,
  // SENTIENT emits this for a permission-denied action (see the server's
  // ActionType::Denied). Upstream ThingsBoard has no such value, so an
  // audit log containing one used to blow up the whole page.
  DENIED,
  // Anything this enum does not recognise. Never sent by a server — it is
  // what an unparseable value degrades to.
  UNKNOWN
}

ActionType actionTypeFromString(String value) {
  // orElse is deliberate. firstWhere without it THROWS on any value this enum
  // does not know, and because the whole page is parsed in one pass a single
  // unrecognised action type fails every row — the screen shows nothing but
  // "Something went wrong". A server that adds an action type must never be
  // able to break an older client that hard.
  return ActionType.values.firstWhere(
    (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase(),
    orElse: () => ActionType.UNKNOWN,
  );
}

extension ActionTypeToString on ActionType {
  String toShortString() {
    return toString().split('.').last;
  }
}

enum ActionStatus { SUCCESS, FAILURE }

ActionStatus actionStatusFromString(String value) {
  return ActionStatus.values.firstWhere(
      (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase());
}

extension ActionStatusToString on ActionStatus {
  String toShortString() {
    return toString().split('.').last;
  }
}

class AuditLog extends BaseData<AuditLogId> {
  TenantId tenantId;
  CustomerId? customerId;
  EntityId entityId;
  String? entityName;
  UserId userId;
  String userName;
  ActionType actionType;
  Map<String, dynamic> actionData;
  ActionStatus actionStatus;
  String? actionFailureDetails;

  AuditLog.fromJson(Map<String, dynamic> json)
      : tenantId = TenantId.fromJson(json['tenantId']),
        customerId = json['customerId'] != null
            ? CustomerId.fromJson(json['customerId'])
            : null,
        entityId = EntityId.fromJson(json['entityId']),
        entityName = json['entityName'],
        userId = UserId.fromJson(json['userId']),
        userName = json['userName'],
        actionType = actionTypeFromString(json['actionType']),
        actionData = json['actionData'],
        actionStatus = actionStatusFromString(json['actionStatus']),
        actionFailureDetails = json['actionFailureDetails'],
        super.fromJson(json, (id) => AuditLogId(id));

  @override
  String toString() {
    return 'AuditLog{${baseDataString('tenantId: $tenantId, customerId: $customerId, entityId: $entityId, '
        'entityName: $entityName, userId: $userId, userName: $userName, actionType: $actionType, '
        'actionData: ${actionDataToString()}, actionStatus: $actionStatus, actionFailureDetails: ${actionFailureDetailsToString()}')}}';
  }

  String actionDataToString() {
    var actionDataStr = jsonEncode(actionData);
    if (actionDataStr.length > 50) {
      actionDataStr =
          actionDataStr.substring(0, min(50, actionDataStr.length)) + '...';
    }
    return actionDataStr;
  }

  String actionFailureDetailsToString() {
    if (actionFailureDetails == null) {
      return 'null';
    }
    if (actionFailureDetails!.length > 50) {
      return actionFailureDetails!
              .substring(0, min(50, actionFailureDetails!.length)) +
          '...';
    }
    return actionFailureDetails!;
  }
}
