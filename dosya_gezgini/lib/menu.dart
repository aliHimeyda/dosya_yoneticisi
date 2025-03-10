import 'package:dosya_gezgini/localestoragebilgileri.dart';
import 'package:dosya_gezgini/renkler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için

class Pil {
  static final Battery pil = Battery();
}

class Menu extends StatelessWidget {
  const Menu({super.key});

  // Saat akışını (stream) oluştur
  Stream<String> zamanigetir() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1)); // Her saniye güncelle
      yield DateFormat('HH:mm:ss').format(DateTime.now()); // 24 saat formatında
    }
  }

  Stream<String> depolamaalanigetir() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1)); // Her saniye güncelle
      yield Battery().batteryLevel.toString();
    }
  }

  Stream<int> pildurumugetir() async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1)); // Her saniye güncelle
      int pildurumu = await Pil.pil.batteryLevel;
      yield pildurumu;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            child: Row(
              children: [
                saatbox(context),
                Depolamadurumubox(context),
                Pildurumubox(context),
              ],
            ),
          ),
          Wrap(
            children: [
              kareislemsecenegi(context, 'islem', Icons.abc),
              kareislemsecenegi(context, 'islem', Icons.abc),
              kareislemsecenegi(context, 'islem', Icons.abc),
              kareislemsecenegi(context, 'islem', Icons.abc),
            ],
          ),
          Animate(
            effects: [FadeEffect(duration: Duration(milliseconds: 100))],
            child: Container(
              width: MediaQuery.of(context).size.width - 20,
              height: MediaQuery.of(context).size.height / 10,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 0.3, color: AppColors.koyuGri),
                  top: BorderSide(width: 1, color: AppColors.koyuGri),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(context.watch<AppTheme>().temaiconu, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema Modu',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: context.watch<AppTheme>().isdarkmode,
                      onChanged: (value) {
                        Provider.of<AppTheme>(
                          context,
                          listen: false,
                        ).changetheme();
                      },
                      // value: widget.isDarkMode,
                      // onChanged: widget.onChanged, // Tema değiştirme fonksiyonunu çağırır
                      activeColor:
                          Theme.of(context).primaryColor, // Açık mod rengi
                      inactiveThumbColor:
                          Theme.of(context).primaryColor, // Karanlık mod rengi
                    ),
                  ],
                ),
              ),
            ),
          ),
          islemsecenegi(context, Icons.delete_sweep, 'Derin Temizleme'),
          islemsecenegi(context, Icons.lock, 'Ozel Dosyalar'),
          islemsecenegi(context, Icons.favorite, 'favorilenen Dosyalar'),
        ],
      ),
    );
  }

  Container saatbox(BuildContext context) {
    return Container(
                width: MediaQuery.of(context).size.width / 4,
                height: 50,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      width: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                child: Center(
                  child: StreamBuilder<String>(
                    stream: zamanigetir(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ); // İlk değer gelene kadar yükleme göstergesi
                      }
                      return Text(
                        snapshot.data!, // Güncellenen saat
                        style: TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              );
  }

  Container Depolamadurumubox(BuildContext context) {
    return Container(
                width: MediaQuery.of(context).size.width / 2,
                height: 50,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      width: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                child:
                    context.watch<Localestoragebilgileri>().usedspace != 0
                        ? Stack(
                          children: [
                            LinearProgressIndicator(
                              value:
                                  context
                                      .watch<Localestoragebilgileri>()
                                      .usedspace /
                                  context
                                      .watch<Localestoragebilgileri>()
                                      .totalspace,
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor, // Boş kısmın rengi
                              color:
                                  Theme.of(
                                    context,
                                  ).secondaryHeaderColor, // Dolan kısmın rengi
                              minHeight: 50, // Çubuğun kalınlığı
                            ).animate().custom(
                              duration: 1.seconds, // Animasyon süresi
                              begin: 0.0, // Başlangıç değeri
                              end:
                                  context
                                      .watch<Localestoragebilgileri>()
                                      .usedspace /
                                  context
                                      .watch<Localestoragebilgileri>()
                                      .totalspace, // Hedef değer
                              builder:
                                  (context, value, child) =>
                                      LinearProgressIndicator(
                                        value: value, // Animasyonlu değer
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                        color:
                                            Theme.of(
                                              context,
                                            ).secondaryHeaderColor,
                                        minHeight: 50,
                                      ),
                            ),
                            Center(
                              child: Text(
                                '${context.watch<Localestoragebilgileri>().usedspace.toStringAsFixed(2)} | ${context.watch<Localestoragebilgileri>().totalspace.toStringAsFixed(2)} GB',
                              ),
                            ),
                          ],
                        )
                        : CircularProgressIndicator(),
              );
  }

  SizedBox Pildurumubox(BuildContext context) {
    return SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: 50,
                child: Center(
                  child: StreamBuilder<int>(
                    stream: pildurumugetir(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ); // İlk değer gelene kadar yükleme göstergesi
                      }
                      return Stack(
                        children: [
                          LinearProgressIndicator(
                            value:
                                snapshot.data! /
                                100, // Pil seviyesini 0.0 - 1.0 aralığına getir
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).scaffoldBackgroundColor, // Boş kısmın rengi
                            color:
                                Theme.of(
                                  context,
                                ).secondaryHeaderColor, // Dolan kısmın rengi
                            minHeight: 50, // Çubuğun kalınlığı
                          ).animate().custom(
                            duration: 1.seconds, // Animasyon süresi
                            begin: 0.0, // Başlangıç değeri
                            end: snapshot.data! / 100, // Hedef değer
                            builder:
                                (context, value, child) =>
                                    LinearProgressIndicator(
                                      value: value, // Animasyonlu değer
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                      color:
                                          Theme.of(
                                            context,
                                          ).secondaryHeaderColor,
                                      minHeight: 50,
                                    ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.earbuds_battery),
                                Text(
                                  snapshot.data!
                                      .toString(), // Güncellenen pildurumu
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
  }

  GestureDetector kareislemsecenegi(
    BuildContext context,
    String islem,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        // context.push(Paths.ensongezilenler); // Sayfaya nesneyi geçir)
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width / 2 - 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(
              width: 0.8,
              color: Theme.of(context).iconTheme.color!,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                spacing: 4,
                children: [
                  Icon(icon, size: 30),
                  Expanded(
                    child: Text(
                      islem,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector islemsecenegi(
    BuildContext context,
    IconData icon,
    String hizmet,
  ) {
    return GestureDetector(
      onTap: () {
        debugPrint('tiklandi');
      },
      child: Animate(
        effects: [FadeEffect(duration: Duration(milliseconds: 100))],
        child: Container(
          width: MediaQuery.of(context).size.width - 20,
          height: MediaQuery.of(context).size.height / 10,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 0.3,
                color: Theme.of(context).iconTheme.color!,
              ),
              top: BorderSide(
                width: 1,
                color: Theme.of(context).iconTheme.color!,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(icon, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hizmet,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
