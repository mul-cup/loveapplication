import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(StudyRestPages());
}

class StudyRestPages extends StatefulWidget {
  const StudyRestPages({super.key});

  @override
  StudyRestPagesState createState() => StudyRestPagesState();
}

class StudyRestPagesState extends State<StudyRestPages> {
  List<Map<String, String>> trackDetails = [];
  List<Map<String, String>> studyLogs = [];

  void updateTracks(List<dynamic> data) {
    setState(() {
      trackDetails =
          data.map((track) {
            return {
              'name': (track['name'] ?? 'Unknown').toString(),
              'albumName': (track['albumName'] ?? 'Unknown Album').toString(),
              'albumImage': (track['albumImage'] ?? '').toString(),
              'artists': (track['artists'] ?? 'Unknown Artist').toString(),
            };
          }).toList();
    });
  }

  Future<void> addStudyLog(
    String timerName,
    String date,
    int planet,
    String time,
  ) async {
    final response = await http.post(
      Uri.parse('http://smhanabi.synology.me:5555/studylogs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'timer_name': timerName,
        'date': date,
        'planet': planet,
        'time': time,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        studyLogs.add({'timer_name': timerName, 'total_time': time});
      });
      debugPrint('스터디 로그 추가 성공');
    } else {
      debugPrint('스터디 로그 추가 실패: ${response.body}');
    }
  }

  Future<void> deleteStudyLog(String timerName) async {
    final response = await http.delete(
      Uri.parse('http://smhanabi.synology.me:5555/studylogs/$timerName'),
    );

    if (response.statusCode == 200) {
      setState(() {
        studyLogs.removeWhere((log) => log['timer_name'] == timerName);
      });
      debugPrint('스터디 로그 삭제 성공');
    } else {
      debugPrint('스터디 로그 삭제 실패: ${response.body}');
    }
  }

  Future<void> fetchStudyLogSummary(String startDate, String endDate) async {
    final response = await http.get(
      Uri.parse(
        'http://smhanabi.synology.me:5555/studylogs/summary?start=$startDate&end=$endDate',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        studyLogs =
            data.map((log) {
              return {
                'timer_name': log['timer_name'].toString(),
                'total_time': log['total_time'].toString(),
              };
            }).toList();
      });
      debugPrint('스터디 로그 요약: ${response.body}');
    } else {
      debugPrint('스터디 로그 요약 조회 실패: ${response.body}');
    }
  }

  Future<void> fetchRecommendedTracks() async {
    final response = await http.get(
      Uri.parse(
        'http://smhanabi.synology.me:5555/spotify/api/getRecommendTrack',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final trackIds = List<String>.from(
        data['trackUris'],
      ).map((uri) => uri.split(':')[2]).join(',');
      fetchTrackDetails(trackIds);
    } else {
      debugPrint('추천 트랙 조회 실패: ${response.body}');
    }
  }

  Future<void> fetchTrackDetails(String trackIds) async {
    final response = await http.get(
      Uri.parse(
        'http://smhanabi.synology.me:5555/spotify/api/getTracksInfo/$trackIds',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      updateTracks(data);
    } else {
      debugPrint('트랙 정보 조회 실패: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Track & Study Log Summary")),
        body: Column(
          children: [
            ElevatedButton(
              onPressed:
                  () => addStudyLog("Focus Session", "2025-04-02", 1, "60m"),
              child: Text("Add Study Log"),
            ),
            ElevatedButton(
              onPressed: () => deleteStudyLog("Focus Session"),
              child: Text("Delete Study Log"),
            ),
            ElevatedButton(
              onPressed: () => fetchStudyLogSummary("2025-04-01", "2025-04-02"),
              child: Text("Fetch Study Log Summary"),
            ),
            ElevatedButton(
              onPressed: fetchRecommendedTracks,
              child: Text("Fetch Recommended Tracks"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: studyLogs.length,
                itemBuilder: (context, index) {
                  final log = studyLogs[index];
                  return ListTile(
                    title: Text(
                      log['timer_name']!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('총 공부 시간: ${log['total_time']}'),
                    leading: Icon(Icons.timer, color: Colors.blue),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: trackDetails.length,
                itemBuilder: (context, index) {
                  final track = trackDetails[index];
                  return ListTile(
                    leading:
                        track['albumImage']!.isNotEmpty
                            ? Image.network(track['albumImage']!)
                            : Icon(Icons.music_note),
                    title: Text(track['name']!),
                    subtitle: Text(
                      '${track['artists']} - ${track['albumName']}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
