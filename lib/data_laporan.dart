class DataLaporan {
  String deskripsi;
  String lokasi;
  double lokasiLat;
  double lokasiLng;
  String pelaku;
  String pengawas;
  String status;
  String tglLapor;
  String laporanId;

  DataLaporan(
      {required this.deskripsi,
      required this.lokasi,
      required this.lokasiLat,
      required this.lokasiLng,
      required this.pelaku,
      required this.pengawas,
      required this.status,
      required this.tglLapor,
      required this.laporanId});
}
