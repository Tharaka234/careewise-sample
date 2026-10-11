class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String salary;
  final String jobType;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.salary,
    required this.jobType,
  });

  factory Job.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return Job(
      id: id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      salary: data['salary'] ?? '',
      jobType: data['jobType'] ?? '',
    );
  }
}