import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: JournalPage(),
    );
  }
}

class JournalPage extends StatefulWidget {
  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, dynamic>> journals = [];
  List<Map<String, dynamic>> filteredJournals = [];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  final String baseUrl = 'http://localhost:8080/jurnal/jurnal';

  @override
  void initState() {
    super.initState();
    _fetchJournals();
  }

  Future<void> _fetchJournals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get.php'));
      print("Respons API: ${response.body}"); // Log respons API

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['status'] == 'success') {
          print("Data dari API: ${responseBody['data']}"); // Log data mentah

          setState(() {
            print("Sebelum update journals: $journals");
            print("Sebelum update filteredJournals: $filteredJournals");

            journals = (responseBody['data'] as List)
                .map((item) => {
                      'id': item['id'],
                      'title': item['judul'],
                      'content': item['isi'],
                    })
                .toList();
            filteredJournals = List.from(journals);

            print("Setelah update journals: $journals");
            print("Setelah update filteredJournals: $filteredJournals");
          });
        } else {
          _showError(responseBody['message'] ?? 'Failed to fetch journals');
        }
      } else {
        _showError('Failed to fetch journals');
      }
    } catch (e) {
      _showError('Error fetching data: $e');
    }
  }

  Future<void> _addJournal(Map<String, dynamic> journal) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create.php'),
        headers: {
          'Content-Type':
              'application/json', // Pastikan content-type adalah JSON
        },
        body: json.encode({
          'judul': journal['title'],
          'isi': journal['content'],
        }), // Kirimkan body sebagai JSON
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body); // Decode response body
        if (responseBody['status'] == 'success') {
          _fetchJournals(); // Refresh daftar jurnal setelah berhasil
        } else {
          _showError(responseBody['message'] ?? 'Failed to add journal');
        }
      } else {
        _showError('Failed to add journal');
      }
    } catch (e) {
      _showError('Error adding journal: $e');
    }
  }

  Future<void> _updateJournal(Map<String, dynamic> updatedJournal) async {
    try {
      print(
          "Mengirim data update jurnal: $updatedJournal"); // Log data yang dikirim

      final response = await http.put(
        Uri.parse('$baseUrl/update.php'), // Ubah URL jika id tidak perlu di URL
        headers: {
          'Content-Type': 'application/json', // Tentukan tipe konten JSON
        },
        body: json.encode({
          'id': updatedJournal['id'], // Kirim id dalam body jika diperlukan
          'judul': updatedJournal['title'],
          'isi': updatedJournal['content'],
        }),
      );

      print(
          "Respons API update jurnal: ${response.body}"); // Log respons dari server

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print("Response body: $responseBody"); // Log response body

        if (responseBody['status'] == 'success') {
          _fetchJournals(); // Refresh daftar jurnal setelah berhasil update
          print("Jurnal berhasil diperbarui");
        } else {
          _showError(responseBody['message'] ?? 'Failed to update journal');
        }
      } else {
        _showError('Failed to update journal');
      }
    } catch (e) {
      _showError('Error updating journal: $e');
      print("Error updating journal: $e"); // Log error jika gagal
    }
  }

  void _deleteJournal(Map<String, dynamic> journal) async {
    try {
      final journalId = journal['id'].toString(); // Pastikan ID sebagai string
      print(
          "Sebelum penghapusan: $filteredJournals"); // Log sebelum penghapusan
      print("Menghapus jurnal dengan ID: $journalId");

      final response = await http.delete(
        Uri.parse('$baseUrl/delete.php?id=$journalId'),
      );

      print("Respons API untuk hapus jurnal: ${response.body}");

      if (response.statusCode == 200) {
        _fetchJournals(); // Refresh daftar jurnal setelah berhasil
        print(
            "Setelah penghapusan: $filteredJournals"); // Log setelah penghapusan
      } else {
        _showError('Failed to delete journal');
      }
    } catch (e) {
      _showError('Error deleting journal: $e');
    }
  }

  void _confirmDeleteJournal(Map<String, dynamic> journal) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus jurnal ini?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Menutup dialog tanpa menghapus
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _deleteJournal(journal); // Melakukan penghapusan
              Navigator.pop(context); // Menutup dialog setelah penghapusan
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(Map<String, dynamic> journal) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(200, 100, 0, 0), // Atur posisi menu
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        // Navigasi ke halaman Edit Jurnal dengan membawa data jurnal
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditJournalPage(
              journal: journal,
              onSubmit: _updateJournal,
            ),
          ),
        );
      } else if (value == 'delete') {
        _confirmDeleteJournal(journal); // Panggil konfirmasi hapus
      }
    });
  }

  void _filterJournals() {
    setState(() {
      if (searchController.text.isEmpty) {
        filteredJournals = List.from(journals);
      } else {
        filteredJournals = journals
            .where((journal) => journal['title']
                .toLowerCase()
                .contains(searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari jurnal...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => _filterJournals(),
              )
            : const Text(
                'Jurnal',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  _filterJournals();
                }
              });
            },
          ),
        ],
      ),
      body: filteredJournals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gambar yang akan ditampilkan
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.red],
                      ),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Icon(
                      Icons.book,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mulai Penjurnalan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Buat jurnal pribadi anda.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Ketuk tombol plus untuk memulai.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filteredJournals.length,
              itemBuilder: (context, index) {
                final journal = filteredJournals[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(journal['title'] ?? 'No Title'),
                    subtitle: Text(
                      journal['content'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      // Navigasi ke halaman detail jurnal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReadJournalPage(journal: journal),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showMoreOptions(
                            journal); // Menampilkan menu opsi lebih
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newJournal = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WriteJournalPage(onSubmit: _addJournal),
            ),
          );
          if (newJournal != null) {
            _addJournal(newJournal);
          }
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WriteJournalPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onSubmit;

  WriteJournalPage({required this.onSubmit});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Jurnal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Isi Jurnal'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  onSubmit({
                    'title': titleController.text,
                    'content': contentController.text,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditJournalPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic> journal;

  EditJournalPage({required this.onSubmit, required this.journal});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    titleController.text = journal['title'] ?? '';
    contentController.text = journal['content'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Jurnal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Isi Jurnal'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  // Log data yang akan disubmit
                  print("Data yang akan disubmit: ");
                  print("Judul: ${titleController.text}");
                  print("Isi: ${contentController.text}");

                  // Kirimkan data yang telah diedit
                  onSubmit({
                    'id': journal['id'], // Mengirimkan ID jurnal untuk update
                    'title': titleController.text,
                    'content': contentController.text,
                  });
                  Navigator.pop(
                      context); // Kembali ke halaman sebelumnya setelah disubmit
                } else {
                  print("Form tidak lengkap!"); // Log jika form tidak lengkap
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReadJournalPage extends StatelessWidget {
  final Map<String, dynamic> journal;

  ReadJournalPage({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baca Jurnal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              journal['title'] ?? 'No Title',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              journal['content'] ?? 'No Content',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
