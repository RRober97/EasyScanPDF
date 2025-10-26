class Limits {
  const Limits._();

  static const int normalMaxPagesPerPdf = 10;
  static const int normalMaxSavedPdfs = 5;
  static const int proMaxPagesPerPdf = 99999;
  static const int proMaxSavedPdfs = 20;
}

class PricingText {
  const PricingText._();

  static const String normal = 'Incluido con tu cuenta';
  static const String pro = '2,99 € / mes (IVA incl.)';
}
