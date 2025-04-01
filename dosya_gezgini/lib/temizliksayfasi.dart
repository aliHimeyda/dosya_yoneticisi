import 'package:dosya_gezgini/dosyaislemleri.dart';
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
    return Center(
      child: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          context.watch<Dosyaislemleri>().loading
              ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                strokeWidth: 7,
                constraints: BoxConstraints(minWidth: 150, minHeight: 150),
              )
              : context.watch<Dosyaislemleri>().aramaloading
              ? Image.asset(
                'assets/risk.png', // Görselinin yolu
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
                    begin: Offset(-0.3, 0), // soldan başla
                    end: Offset(0, 0), // merkeze gel
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),
                ],
                child: Image.asset(
                  'assets/true.png', // Görselinin yolu
                  height: 150,
                  width: 150,
                ),
              ),

          SizedBox(height: 50),
          context.watch<Dosyaislemleri>().loading
              ? Text(
                'Temizlik Devam Ediyor ...',
                style: Theme.of(context).textTheme.bodyLarge,
              )
              : Text(
                'Islem Sonlandi :)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gecici Dosyalar Bellekten Alinmasi ',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              context.watch<Dosyaislemleri>().gecicidosyalaralinmasi
                  ? Image.asset('assets/true.png', height: 15, width: 15)
                  : Text('....', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text(
                'OnBellek Dosyalarin Alinmasi ',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              context.watch<Dosyaislemleri>().onbellekdosyalarialinmasi
                  ? Image.asset('assets/true.png', height: 15, width: 15)
                  : Text('....', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          context.watch<Dosyaislemleri>().gecicidosyalaralinmasi &&
                  context.watch<Dosyaislemleri>().onbellekdosyalarialinmasi
              ? Column(
                spacing: 5,
                children: [
                  Text(
                    '${((context.watch<Dosyaislemleri>().gereksizdosyalartoplamboyutu) / (1024 * 1024)).toStringAsFixed(2)} MB Bosaltilacak',
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Provider.of<Dosyaislemleri>(
                        context,
                        listen: false,
                      ).gereksizdosyalaritemizle();
                      await Future.delayed(Duration(seconds: 8));
                      Navigator.pop(context);
                    },
                    child:
                        context.watch<Dosyaislemleri>().gereksizdosyalar.isEmpty
                            ? Text(
                              'Tamam',
                              style: Theme.of(context).textTheme.bodyLarge,
                            )
                            : Text(
                              'Temizle',
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
