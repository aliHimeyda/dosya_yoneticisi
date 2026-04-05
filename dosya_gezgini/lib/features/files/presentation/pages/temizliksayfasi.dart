import 'package:dosya_gezgini/core/localization/l10n_extensions.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

class Temizliksayfasi extends StatefulWidget {
  const Temizliksayfasi({super.key});

  @override
  State<Temizliksayfasi> createState() => _TemizliksayfasiState();
}

class _TemizliksayfasiState extends State<Temizliksayfasi> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Dosyaislemleri>();
      provider.temizlenecekleritoplamaislemi(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dosyaIslemleri = context.watch<Dosyaislemleri>();

    return Center(
      child: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          dosyaIslemleri.loading
              ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                strokeWidth: 7,
                constraints: BoxConstraints(minWidth: 150, minHeight: 150),
              )
              : dosyaIslemleri.aramaloading
              ? Image.asset(
                'assets/risk.png',
                height: 150,
                width: 150,
              )
              : Animate(
                effects: [
                  FadeEffect(
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),
                  SlideEffect(
                    begin: Offset(-0.3, 0),
                    end: Offset(0, 0),
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),
                ],
                child: Image.asset(
                  'assets/true.png',
                  height: 150,
                  width: 150,
                ),
              ),
          SizedBox(height: 50),
          dosyaIslemleri.loading
              ? Text(
                l10n.cleanupInProgress,
                style: Theme.of(context).textTheme.bodyLarge,
              )
              : Text(
                l10n.operationCompleted,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.temporaryFilesCollected,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              dosyaIslemleri.gecicidosyalaralinmasi
                  ? Image.asset('assets/true.png', height: 15, width: 15)
                  : Text('....', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.cacheFilesCollected,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              dosyaIslemleri.onbellekdosyalarialinmasi
                  ? Image.asset('assets/true.png', height: 15, width: 15)
                  : Text('....', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          dosyaIslemleri.gecicidosyalaralinmasi &&
                  dosyaIslemleri.onbellekdosyalarialinmasi
              ? Column(
                spacing: 5,
                children: [
                  Text(
                    l10n.cleanupWillFree(
                      ((dosyaIslemleri.gereksizdosyalartoplamboyutu) /
                              (1024 * 1024))
                          .toStringAsFixed(2),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      context.read<Dosyaislemleri>().gereksizdosyalaritemizle();
                      await Future.delayed(Duration(seconds: 8));
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child:
                        dosyaIslemleri.gereksizdosyalar.isEmpty
                            ? Text(
                              l10n.ok,
                              style: Theme.of(context).textTheme.bodyLarge,
                            )
                            : Text(
                              l10n.clean,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                  ),
                ],
              )
              : SizedBox(),
        ],
      ),
    );
  }
}
