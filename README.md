# **Juscang**

Juscang adalah aplikasi komunikasi antar perangkat yang memungkinkan pengguna untuk berkomunikasi
secara efisien menggunakan teknologi real-time. Aplikasi ini mendukung berbagai fitur komunikasi
yang intuitif dan ramah pengguna, sehingga memudahkan interaksi dan pertukaran informasi antar perangkat.

# **Fitur Utama**
	•	Panggilan Suara dan Video: Lakukan panggilan suara dan video berkualitas tinggi antar perangkat.
	•	Pesan Teks Real-time: Kirim pesan teks dengan cepat dan aman.
	•	Notifikasi Push: Dapatkan notifikasi push untuk panggilan dan pesan masuk.
	•	Riwayat Panggilan: Melihat riwayat panggilan yang pernah dilakukan, termasuk panggilan terjawab dan tidak terjawab.
	•	Autentikasi Firebase: Sistem login dan registrasi pengguna menggunakan Firebase Authentication.
	•	Pengelolaan Profil: Pengguna dapat mengatur nama, status, dan avatar.

# **Teknologi yang Digunakan**
	•	Flutter: Framework untuk membuat aplikasi lintas platform (iOS & Android).
	•	Firebase:
	    Firebase Authentication: Untuk login dan registrasi pengguna.
	    Firebase Realtime Database: Menyimpan data pengguna, pesan, dan riwayat panggilan secara real-time.
	    Firebase Cloud Messaging (FCM): Untuk mengirim notifikasi push ke pengguna.
	•	Agora SDK: Untuk panggilan suara dan video berkualitas tinggi.
	•	CocoaPods: Manajer dependensi untuk integrasi iOS.

# **Struktur Folder**
	•	lib: Berisi kode sumber aplikasi, termasuk UI, logika bisnis, dan layanan backend.
	•	android: Konfigurasi proyek Android.
	•	ios: Konfigurasi proyek iOS.
	•	assets: Berisi gambar, ikon, dan file statis lainnya.
	•	firebase-messaging-sw.js: Service worker untuk notifikasi push di web.

# **Penggunaan**
1. Login atau Registrasi: Pengguna dapat login atau mendaftar menggunakan email atau akun sosial jika Firebase Authentication mendukung.
2. Panggilan: Mulai panggilan suara atau video dengan pengguna lain.
3. Pesan: Kirim pesan teks secara real-time.
4. Notifikasi: Dapatkan notifikasi untuk pesan dan panggilan masuk.

# **To-Do List dan Progress**
**Setup Awal Proyek**
[x] Membuat struktur folder dan file proyek
[x] Inisialisasi proyek Flutter
[x] Pembuatan logo aplikasi
[x] Membuat color palette dan theme aplikasi
[x] Desain mockup UI aplikasi

**Mulai Tahapan Dasar**
[x] Implementasi desain UI halaman beranda
[x] Menambahkan navigasi ke halaman lain
[x] Integrasi Firebase Authentication
[x] Menambahkan validasi form login dan registrasi
[ ] Implementasi fitur voice call menggunakan API
[x] Desain UI untuk layar menelpon
[ ] Penanganan error saat menelpon gagal

**Fitur Tambahan**
[x] Membuat layar SplashScreen
[x] Menambahkan animasi transisi antara halaman
[x] Membuat halaman pengaturan
[x] Konfigurasi database Firebase untuk penyimpanan data pengguna

**Tahap Akhir**
[ ] Testing dan Debugging
[ ] Testing unit pada tiap fitur
[ ] Debugging dan optimalisasi performa
[ ] Optimasi ukuran APK/AAB
[ ] Testing di berbagai perangkat