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
	1.	Login atau Registrasi: Pengguna dapat login atau mendaftar menggunakan email atau akun sosial jika Firebase Authentication mendukung.
	2.	Panggilan: Mulai panggilan suara atau video dengan pengguna lain.
	3.	Pesan: Kirim pesan teks secara real-time.
	4.	Notifikasi: Dapatkan notifikasi untuk pesan dan panggilan masuk.

# **To-Do List dan Progress**
**Setup Awal Proyek**
1. [ ] Membuat struktur folder dan file proyek
2. [ ] Inisialisasi proyek Flutter
3. [ ] Pembuatan logo aplikasi
4. [ ] Membuat color palette dan theme aplikasi
5. [ ] Desain mockup UI aplikasi

**Mulai Tahapan Dasar**
1. [ ] Implementasi desain UI halaman beranda
2. [ ] Menambahkan navigasi ke halaman lain
3. [ ] Integrasi Firebase Authentication
4. [ ] Menambahkan validasi form login dan registrasi
5. [ ] Menambahkan fitur login dengan Google/Email
6. [ ] Implementasi fitur voice call menggunakan API
7. [ ] Desain UI untuk layar menelpon
8. [ ] Penanganan error saat menelpon gagal

**Fitur Tambahan**
1. [ ] Membuat layar SplashScreen
2. [ ] Menambahkan animasi transisi antara halaman
3. [ ] Membuat halaman pengaturan
4. [ ] Konfigurasi database Firebase untuk penyimpanan data pengguna
5. [ ] Integrasi cloud functions jika diperlukan

**Tahap Akhir**
1. [ ] Testing dan Debugging
2. [ ] Testing unit pada tiap fitur
3. [ ] Debugging dan optimalisasi performa
4. [ ] Optimasi ukuran APK/AAB
5. [ ] Testing di berbagai perangkat