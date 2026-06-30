import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/network/api_client.dart';
import '../../data/publication_form_state.dart';
import '../../data/publication_notifier.dart';
import 'publish_step1.dart';
import 'publish_step2.dart';
import 'publish_step3.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PUBLISH SCREEN — Conteneur 3 étapes + Modal de paiement
// Reproduit le workflow asynchrone de Publication.jsx :
//   Étape 3 → "Passer au paiement" → Modal (saisie numéro)
//   → POST API (statut EN_ATTENTE) → Polling toutes les 5s
//   → ACTIVE = succès | REJETEE = erreur | timeout 5min
// ══════════════════════════════════════════════════════════════════════════════

enum PaymentStatus { idle, processing, pendingUssd, success, error }

class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key});
  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  int _step = 0;

  // ── État paiement ─────────────────────────────────────────────────────────
  bool _showPaymentModal = false;
  final _paymentNumberCtrl = TextEditingController();
  int _timeLeft = 300;
  PaymentStatus _paymentStatus = PaymentStatus.idle;
  String _apiError = '';
  int _redirectCount = 4;

  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Timer? _redirectTimer;

  void _next() => setState(() => _step++);
  void _prev() => setState(() => _step--);

  @override
  void dispose() {
    _paymentNumberCtrl.dispose();
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _redirectTimer?.cancel();
    super.dispose();
  }

  // ── Ouvrir modal ──────────────────────────────────────────────────────────
  void _openPaymentModal() {
    setState(() {
      _showPaymentModal = true;
      _timeLeft = 300;
      _paymentStatus = PaymentStatus.idle;
      _apiError = '';
      _redirectCount = 4;
    });
    _startCountdown();
  }

  void _closePaymentModal() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    setState(() => _showPaymentModal = false);
  }

  // ── Compte à rebours ──────────────────────────────────────────────────────
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_paymentStatus == PaymentStatus.success ||
          _paymentStatus == PaymentStatus.error) {
        _countdownTimer?.cancel();
        return;
      }
      if (_timeLeft <= 1) {
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
        setState(() {
          _paymentStatus = PaymentStatus.error;
          _apiError =
              "Le délai de 5 minutes est dépassé. Vérifiez vos messages USSD ou l'onglet 'Mes publications'.";
          _timeLeft = 0;
        });
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  // ── Polling statut toutes les 5s ──────────────────────────────────────────
  void _startPolling(String bienId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final response = await ref
            .read(apiClientProvider)
            .get('/PUBLICATION-SERVICE/api/biens/$bienId');
        final status = response?['statutPublication'] ??
            response?['data']?['statutPublication'];
        debugPrint('[Polling] Statut bien $bienId : $status');

        if (status == 'ACTIVE') {
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          setState(() {
            _paymentStatus = PaymentStatus.success;
            _redirectCount = 4;
          });
          _startRedirectCountdown();
        } else if (status == 'REJETEE') {
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          setState(() {
            _paymentStatus = PaymentStatus.error;
            _apiError =
                "Le paiement a été rejeté. Vérifiez votre solde ou votre code PIN.";
          });
        }
      } catch (e) {
        debugPrint('[Polling] Erreur : $e');
      }
    });
  }

  // ── Redirection auto après succès ─────────────────────────────────────────
  void _startRedirectCountdown() {
    _redirectTimer?.cancel();
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_redirectCount <= 1) {
        _redirectTimer?.cancel();
        setState(() => _showPaymentModal = false);
        context.go(AppRoutes.myPublications);
        return;
      }
      setState(() => _redirectCount--);
    });
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  String _fraisText() {
    final s = ref.read(publicationNotifierProvider);
    final prix = double.tryParse(s.prix) ?? 0;
    final frais = s.typePublication == 'VENTE' ? prix * 0.05 : 10000.0;
    return '${frais.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  String _fraisLabel() {
    final s = ref.read(publicationNotifierProvider);
    return s.typePublication == 'VENTE' ? 'Commission 5%' : 'Frais fixes';
  }

  // ── Soumission POST → EN_ATTENTE puis polling ─────────────────────────────
  Future<void> _handleFinalSubmit() async {
    final num = _paymentNumberCtrl.text.trim();
    if (num.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro valide à 9 chiffres.')),
      );
      return;
    }

    setState(() {
      _paymentStatus = PaymentStatus.processing;
      _apiError = '';
    });

    try {
      // Sauvegarde le numéro dans le state
      ref.read(publicationNotifierProvider.notifier).updateStep2(
        numeroPaiement: num,
      );

      // Pause pour s'assurer que le state est mis à jour avant soumission
      await Future.microtask(() {});

      final bienId = await ref
          .read(publicationNotifierProvider.notifier)
          .submitAndGetId();

      if (bienId != null && bienId.isNotEmpty) {
        setState(() => _paymentStatus = PaymentStatus.pendingUssd);
        _startPolling(bienId);
      } else {
        throw Exception(
            "L'annonce a été initiée mais l'ID de suivi est introuvable.");
      }
    } catch (e) {
      setState(() {
        _paymentStatus = PaymentStatus.error;
        _apiError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Publier une Annonce'),
        leading: _step > 0 && !_showPaymentModal
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _prev,
              )
            : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _StepperBar(currentStep: _step),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    PublishStep1(onNext: _next),
                    PublishStep2(onNext: _next, onPrev: _prev),
                    PublishStep3(
                      onRequestPayment: _openPaymentModal,
                      onPrev: _prev,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showPaymentModal) _buildPaymentModal(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODAL DE PAIEMENT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPaymentModal() {
    final canClose = _paymentStatus != PaymentStatus.processing &&
        _paymentStatus != PaymentStatus.success;
    final s = ref.read(publicationNotifierProvider);

    return GestureDetector(
      onTap: canClose ? _closePaymentModal : null,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton fermeture
                    if (canClose)
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: _closePaymentModal,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    _buildModalHeader(),
                    const SizedBox(height: 20),

                    // Ticket récapitulatif
                    if (_paymentStatus != PaymentStatus.success &&
                        _paymentStatus != PaymentStatus.pendingUssd)
                      _buildReceiptCard(s),

                    // Compte à rebours
                    if (_paymentStatus == PaymentStatus.idle ||
                        _paymentStatus == PaymentStatus.pendingUssd)
                      _buildCountdown(),

                    // Bloc statut
                    _buildStatusBlock(),
                    const SizedBox(height: 16),

                    // Formulaire numéro
                    if (_paymentStatus != PaymentStatus.success &&
                        _paymentStatus != PaymentStatus.pendingUssd)
                      _buildPaymentForm(),

                    // Lien reset
                    if (_paymentStatus == PaymentStatus.error)
                      TextButton(
                        onPressed: () => setState(() {
                          _paymentStatus = PaymentStatus.idle;
                          _timeLeft = 300;
                          _startCountdown();
                        }),
                        child: const Text(
                          'Changer de numéro ou modifier les informations',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.teal,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader() {
    Color bgColor;
    Color iconColor;

    switch (_paymentStatus) {
      case PaymentStatus.success:
        bgColor = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        break;
      case PaymentStatus.error:
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFDC2626);
        break;
      case PaymentStatus.pendingUssd:
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        break;
      default:
        bgColor = const Color(0xFFE0F2F1);
        iconColor = AppColors.teal;
    }

    String title;
    String subtitle;
    switch (_paymentStatus) {
      case PaymentStatus.success:
        title = 'Publication Activée ✅';
        subtitle =
            "Paiement validé ! L'annonce est visible sur le listing public.";
        break;
      case PaymentStatus.pendingUssd:
        title = 'En attente de votre PIN ⏳';
        subtitle = 'Vérifiez la demande de paiement sur votre mobile.';
        break;
      default:
        title = 'Frais de Publication';
        subtitle = "Finalisez votre annonce en effectuant le dépôt d'activation.";
    }

    return Column(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.credit_card_rounded, color: iconColor, size: 26),
      ),
      const SizedBox(height: 10),
      Text(title,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827))),
      const SizedBox(height: 6),
      Text(subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9CA3AF))),
    ]);
  }

  Widget _buildReceiptCard(PublicationFormState s) {
    final prix = double.tryParse(s.prix) ?? 0;
    final prixStr = prix
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        _receiptRow('Type d\'opération', s.typePublication),
        const SizedBox(height: 8),
        _receiptRow('Montant du bien', '$prixStr FCFA'),
        const Divider(height: 16, color: Color(0xFFE5E7EB)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Frais à payer (${_fraisLabel()})',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
            ),
            Text(
              _fraisText(),
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.teal),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _receiptRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF6B7280))),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(value,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
          ),
        ],
      );

  Widget _buildCountdown() {
    final urgent = _timeLeft <= 45;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        const Text('TEMPS DE VALIDATION RESTANT',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF9CA3AF))),
        const SizedBox(height: 4),
        Text(
          _formatTime(_timeLeft),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: urgent ? Colors.red : const Color(0xFF374151),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatusBlock() {
    switch (_paymentStatus) {
      case PaymentStatus.processing:
        return const Column(children: [
          CircularProgressIndicator(color: AppColors.teal, strokeWidth: 3),
          SizedBox(height: 10),
          Text('CRÉATION DE LA PUBLICATION...',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.teal)),
        ]);

      case PaymentStatus.pendingUssd:
        final num = _paymentNumberCtrl.text.trim();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: Border.all(color: const Color(0xFFFCD34D)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: Color(0xFFD97706), strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('DEMANDE INITIÉE AVEC SUCCÈS',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF92400E))),
              ]),
              const SizedBox(height: 10),
              Text(
                'Un message va apparaître sur le téléphone +2376$num.\n\n'
                '1. Saisissez votre code PIN pour valider.\n'
                '2. Si aucun message, vérifiez Momo (MTN) / Orange Money (OM).',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF78350F)),
              ),
            ],
          ),
        );

      case PaymentStatus.success:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Text('FÉLICITATIONS !',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xFF16A34A))),
            const SizedBox(height: 6),
            Text(
              'Paiement reçu. Redirection dans $_redirectCount s...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF15803D)),
            ),
          ]),
        );

      case PaymentStatus.error:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            border: Border.all(color: const Color(0xFFFECACA)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: Color(0xFFDC2626)),
                SizedBox(width: 6),
                Text('ÉCHEC DE L\'ACTIVATION',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Color(0xFFDC2626))),
              ]),
              const SizedBox(height: 8),
              Text(_apiError,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFB91C1C))),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPaymentForm() {
    final isProcessing = _paymentStatus == PaymentStatus.processing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NUMÉRO MOBILE MONEY (Orange / MTN)',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  left: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(12)),
              ),
              child: const Text('+237',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ),
            Expanded(
              child: TextFormField(
                controller: _paymentNumberCtrl,
                enabled: !isProcessing,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
                decoration: const InputDecoration(
                  hintText: '6XXXXXXXX',
                  hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFFD1D5DB),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0),
                  prefixIcon: Icon(Icons.smartphone_rounded,
                      size: 18, color: Color(0xFF9CA3AF)),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(12)),
                    borderSide:
                        BorderSide(color: AppColors.teal, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isProcessing ? null : _handleFinalSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isProcessing
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF1a2b3c),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Text(
              _paymentStatus == PaymentStatus.error
                  ? 'RÉESSAYER LE PAIEMENT'
                  : 'LANCER LA DEMANDE DE PAIEMENT',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stepper bar (inchangé) ─────────────────────────────────────────────────────
class _StepperBar extends StatelessWidget {
  final int currentStep;
  const _StepperBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.description_outlined, 'Description'),
      (Icons.photo_library_outlined, 'Complément'),
      (Icons.location_on_outlined, 'Position'),
    ];

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.teal
                    : AppColors.borderLight,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;

          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isDone || isActive ? AppColors.teal : AppColors.bgLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone || isActive
                      ? AppColors.teal
                      : AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.white, size: 16)
                    : Icon(steps[stepIndex].$1,
                        color: isActive
                            ? AppColors.white
                            : AppColors.textMuted,
                        size: 16),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex].$2,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? AppColors.teal : AppColors.textMuted,
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
