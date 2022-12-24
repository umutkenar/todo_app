// ignore_for_file: prefer_collection_literals, unnecessary_new, unnecessary_this

class Task {
  int? id;
  String? title;
  String? category;
  String? note;
  int? isCompleted;
  String? date;
  String? startTime;
  String? endTime;
  int? color;
  int? remind;
  String? repeat;
  Task({
    this.id,
    this.color,
    this.date,
    this.endTime,
    this.isCompleted,
    this.note,
    this.remind,
    this.repeat,
    this.startTime,
    this.title,
    this.category,
  });

  Task.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    color = json['color'];
    date = json['date'];
    endTime = json['endTime'];
    isCompleted = json['isCompleted'];
    note = json['note'];
    remind = json['remind'];
    repeat = json['repeat'];
    startTime = json['startTime'];
    title = json['title'];
    category = json['category'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['color'] = this.color;
    data['date'] = this.date;
    data['endTime'] = this.endTime;
    data['isCompleted'] = this.isCompleted;
    data['note'] = this.note;
    data['remind'] = this.remind;
    data['repeat'] = this.repeat;
    data['startTime'] = this.startTime;
    data['title'] = this.title;
    data['category'] = this.category;
    return data;
  }
}
