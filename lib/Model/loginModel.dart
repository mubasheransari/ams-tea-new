import 'dart:convert';

LoginModel loginModelFromJson(String str) => LoginModel.fromJson(json.decode(str));

String loginModelToJson(LoginModel data) => json.encode(data.toJson());

class LoginModel {
    String status;
    String message;
    Userinfo userinfo;
    List<Region> regions;
    String userDevice;

    LoginModel({
        required this.status,
        required this.message,
        required this.userinfo,
        required this.regions,
        required this.userDevice,
    });

    factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        status: json["status"],
        message: json["message"],
        userinfo: Userinfo.fromJson(json["userinfo"]),
        regions: List<Region>.from(json["regions"].map((x) => Region.fromJson(x))),
        userDevice: json["user_device"],
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "userinfo": userinfo.toJson(),
        "regions": List<dynamic>.from(regions.map((x) => x.toJson())),
        "user_device": userDevice,
    };
}

class Region {
    String name;

    Region({
        required this.name,
    });

    factory Region.fromJson(Map<String, dynamic> json) => Region(
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
    };
}

class Userinfo {
    String code;
    String empnam;
    String empfnam;
    String desnam;
    String descod;
    String depnam;
    String phone;
    String phone2;
    String adres1;
    String checkLocation;
    String checkPhoto;
    String markAttendance;
    String markExpense;
    String expenseReport;
    String leaveReport;
    String tracking;
    String trackingTime;
    String dsfStatus;
    String segment;
    String teaOrder;
    String oilOrder;
    String moduleId;
    dynamic attachment;
    String region;
    String flag;
    String dsfType;
    String attendRequest;
    String restrictMock;
    String auditForm;
    String restrictAttendance;
    String radiusAttendance;
    String screenshot;
    String attendMechanism;

    Userinfo({
        required this.code,
        required this.empnam,
        required this.empfnam,
        required this.desnam,
        required this.descod,
        required this.depnam,
        required this.phone,
        required this.phone2,
        required this.adres1,
        required this.checkLocation,
        required this.checkPhoto,
        required this.markAttendance,
        required this.markExpense,
        required this.expenseReport,
        required this.leaveReport,
        required this.tracking,
        required this.trackingTime,
        required this.dsfStatus,
        required this.segment,
        required this.teaOrder,
        required this.oilOrder,
        required this.moduleId,
        required this.attachment,
        required this.region,
        required this.flag,
        required this.dsfType,
        required this.attendRequest,
        required this.restrictMock,
        required this.auditForm,
        required this.restrictAttendance,
        required this.radiusAttendance,
        required this.screenshot,
        required this.attendMechanism,
    });

    factory Userinfo.fromJson(Map<String, dynamic> json) => Userinfo(
        code: json["code"],
        empnam: json["empnam"],
        empfnam: json["empfnam"],
        desnam: json["desnam"],
        descod: json["descod"],
        depnam: json["depnam"],
        phone: json["phone"],
        phone2: json["phone2"],
        adres1: json["adres1"],
        checkLocation: json["check_location"],
        checkPhoto: json["check_photo"],
        markAttendance: json["mark_attendance"],
        markExpense: json["mark_expense"],
        expenseReport: json["expense_report"],
        leaveReport: json["leave_report"],
        tracking: json["tracking"],
        trackingTime: json["tracking_time"],
        dsfStatus: json["dsf_status"],
        segment: json["segment"],
        teaOrder: json["tea_order"],
        oilOrder: json["oil_order"],
        moduleId: json["module_id"],
        attachment: json["attachment"],
        region: json["region"],
        flag: json["flag"],
        dsfType: json["dsf_type"],
        attendRequest: json["attend_request"],
        restrictMock: json["restrict_mock"],
        auditForm: json["audit_form"],
        restrictAttendance: json["restrict_attendance"],
        radiusAttendance: json["radius_attendance"],
        screenshot: json["screenshot"],
        attendMechanism: json["attend_mechanism"],
    );

    Map<String, dynamic> toJson() => {
        "code": code,
        "empnam": empnam,
        "empfnam": empfnam,
        "desnam": desnam,
        "descod": descod,
        "depnam": depnam,
        "phone": phone,
        "phone2": phone2,
        "adres1": adres1,
        "check_location": checkLocation,
        "check_photo": checkPhoto,
        "mark_attendance": markAttendance,
        "mark_expense": markExpense,
        "expense_report": expenseReport,
        "leave_report": leaveReport,
        "tracking": tracking,
        "tracking_time": trackingTime,
        "dsf_status": dsfStatus,
        "segment": segment,
        "tea_order": teaOrder,
        "oil_order": oilOrder,
        "module_id": moduleId,
        "attachment": attachment,
        "region": region,
        "flag": flag,
        "dsf_type": dsfType,
        "attend_request": attendRequest,
        "restrict_mock": restrictMock,
        "audit_form": auditForm,
        "restrict_attendance": restrictAttendance,
        "radius_attendance": radiusAttendance,
        "screenshot": screenshot,
        "attend_mechanism": attendMechanism,
    };
}
