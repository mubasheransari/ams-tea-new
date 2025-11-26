class JourneyPlanSupervisor {
  String name;
  String lat;
  String lng;
  bool isVisited;

  JourneyPlanSupervisor({
    required this.name,
    required this.lat,
    required this.lng,
    this.isVisited = false,
  });
}

// Hard-coded journey plan for now
final List<JourneyPlanSupervisor> kJourneyPlan = [
  JourneyPlanSupervisor(
    name: 'Imtiaz – Karachi',
    lat: '24.8829',
    lng: '67.0660',
  ),
  JourneyPlanSupervisor(
    name: 'Imtiaz – Defence',
    lat: '24.8129',
    lng: '67.0648',
  ),
  JourneyPlanSupervisor(
    name: 'Naheed – Bahadurabad',
    lat: '24.8822',
    lng: '67.0729',
  ),
  JourneyPlanSupervisor(
    name: 'Imtiaz  – Gulshan',
    lat: '24.9180',
    lng: '67.0971',
  ),
  JourneyPlanSupervisor(
    name: 'Imtiaz – Defence 2',
    lat: '24.8075',
    lng: '67.0675',
  ),
];
