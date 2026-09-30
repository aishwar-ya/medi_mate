import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() =>
      _HydrationScreenState();
}

class _HydrationScreenState
    extends State<HydrationScreen> {
  final supabase = Supabase.instance.client;

  static const Color purple =
      Color(0xFF7C3AED);

  static const Color purpleDark =
      Color(0xFF5B21B6);

  static const Color lavender =
      Color(0xFFF3EEFF);

  static const Color pageBackground =
      Color(0xFFF8F6FF);

  static const Color textDark =
      Color(0xFF211738);

  static const Color textMuted =
      Color(0xFF716A80);

  static const Color waterBlue =
      Color(0xFF4C9AF7);

  bool _isLoading = true;

  double _goalAmount = 2.0;

  double _currentAmount = 0.0;

  double _progress = 0.0;

  final _goalEditController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHydrationData();
  }

  String _getTodayDate() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadHydrationData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user =
          supabase.auth.currentUser;

      if (user == null) {
        _goalAmount = 2.0;
        _currentAmount = 0.0;
        _updateProgress();
        return;
      }

      final today = _getTodayDate();

      final data = await supabase
          .from('hydration_log')
          .select()
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      if (data != null) {
        _currentAmount =
            (data['current_amount'] as num)
                .toDouble();

        _goalAmount =
            (data['goal_amount'] as num)
                .toDouble();
      } else {
        _goalAmount = 2.0;
        _currentAmount = 0.0;
      }

      _updateProgress();

      _goalEditController.text =
          _goalAmount.toStringAsFixed(1);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load hydration data: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveHydrationData() async {
    try {
      final user =
          supabase.auth.currentUser;

      if (user == null) return;

      final today = _getTodayDate();

      await supabase
          .from('hydration_log')
          .upsert(
        {
          'user_id': user.id,
          'date': today,
          'current_amount':
              _currentAmount,
          'goal_amount': _goalAmount,
        },
        onConflict: 'user_id, date',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save hydration data: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateProgress() {
    final progress = _goalAmount <= 0
        ? 0.0
        : (_currentAmount / _goalAmount)
            .clamp(0.0, 1.0);

    if (mounted) {
      setState(() {
        _progress = progress;
      });
    } else {
      _progress = progress;
    }
  }

  void _addWater(double amount) {
    final wasGoalMet =
        _progress >= 1.0;

    setState(() {
      _currentAmount =
          (_currentAmount + amount)
              .clamp(0.0, _goalAmount);

      _progress = _goalAmount <= 0
          ? 0.0
          : (_currentAmount / _goalAmount)
              .clamp(0.0, 1.0);
    });

    if (_progress >= 1.0 &&
        !wasGoalMet) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                '🎉 Goal reached! Well done!',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration:
              Duration(seconds: 3),
        ),
      );
    }

    _saveHydrationData();
  }

  void _resetWater() {
    setState(() {
      _currentAmount = 0.0;
      _progress = 0.0;
    });

    _saveHydrationData();
  }

  void _showEditGoalDialog(
    BuildContext context,
  ) {
    _goalEditController.text =
        _goalAmount.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Edit Daily Goal',
            style: TextStyle(
              color: textDark,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: TextField(
            controller:
                _goalEditController,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            style: const TextStyle(
              color: textDark,
              fontWeight:
                  FontWeight.w600,
            ),
            decoration:
                InputDecoration(
              suffixText: 'L',
              labelText: 'Daily Goal',
              filled: true,
              fillColor: lavender,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE3D8F7),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color: purple,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: textMuted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newGoal =
                    double.tryParse(
                  _goalEditController
                      .text
                      .trim(),
                );

                if (newGoal != null &&
                    newGoal > 0) {
                  setState(() {
                    _goalAmount =
                        newGoal;

                    _currentAmount =
                        _currentAmount.clamp(
                      0.0,
                      _goalAmount,
                    );

                    _progress =
                        (_currentAmount /
                                _goalAmount)
                            .clamp(
                      0.0,
                      1.0,
                    );
                  });

                  _saveHydrationData();

                  Navigator.pop(
                    dialogContext,
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    purple,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _goalEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor:
            pageBackground,
        body: Center(
          child:
              CircularProgressIndicator(
            color: purple,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 430,
            ),
            child:
                SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                9,
                12,
                25,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),

                  const SizedBox(
                    height: 9,
                  ),

                  _buildHydrationHero(),

                  const SizedBox(
                    height: 13,
                  ),

                  _buildQuickAddSection(),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildProgressCard(),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildLogWaterSection(),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildTipCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(
              color: lavender,
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: purple,
              size: 15,
            ),
          ),

          const SizedBox(width: 7),

          const Text(
            'MediMate',
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const Spacer(),

          GestureDetector(
            onTap: () =>
                _showEditGoalDialog(
              context,
            ),
            child: Container(
              width: 29,
              height: 29,
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFE4D9F6,
                  ),
                ),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: purple,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHydrationHero() {
    final percent =
        (_progress * 100).toInt();

    return Container(
      height: 190,
      width: double.infinity,
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFFEFE8FF),
            Color(0xFFDCD1FF),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      clipBehavior:
          Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -24,
            child: Container(
              width: 92,
              height: 92,
              decoration:
                  BoxDecoration(
                color: Colors.white
                    .withOpacity(
                  0.24,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: -22,
            bottom: -38,
            child: Container(
              width: 95,
              height: 95,
              decoration:
                  BoxDecoration(
                color: purple
                    .withOpacity(
                  0.035,
                ),
                shape:
                    BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: 16,
            top: 17,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: const [
                Text(
                  'Hydration',
                  style:
                      TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Stay hydrated throughout the day',
                  style:
                      TextStyle(
                    color: textMuted,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 15,
            bottom: 13,
            child:
                _buildProgressRing(
              percent,
            ),
          ),

          Positioned(
            right: 2,
            bottom: -7,
            child: Image.asset(
              'assets/images/hydration_bottle.png',
              width: 158,
              height: 158,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) =>
                      const SizedBox.shrink(),
            ),
          ),

          Positioned(
            right: 115,
            top: 43,
            child: Icon(
              Icons.water_drop_outlined,
              color: purple.withOpacity(
                0.16,
              ),
              size: 18,
            ),
          ),

          Positioned(
            right: 93,
            top: 27,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: purple.withOpacity(
                0.14,
              ),
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(
    int percent,
  ) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment:
            Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child:
                CircularProgressIndicator(
              value: _progress,
              strokeWidth: 7,
              backgroundColor:
                  Colors.white
                      .withOpacity(
                0.70,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF6D63F5),
              ),
            ),
          ),

          Container(
            width: 81,
            height: 81,
            decoration:
                BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white
                  .withOpacity(
                0.58,
              ),
            ),
          ),

          Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: waterBlue,
                size: 16,
              ),

              const SizedBox(
                height: 1,
              ),

              Text(
                '$percent%',
                style:
                    const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              Text(
                '${_currentAmount.toStringAsFixed(1)}L / '
                '${_goalAmount.toStringAsFixed(1)}L',
                style:
                    const TextStyle(
                  color: textMuted,
                  fontSize: 7,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ADD
  // ============================================================

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Add',
          style: TextStyle(
            color: textDark,
            fontSize: 10,
            fontWeight:
                FontWeight.w900,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child:
                  _buildWaterButton(
                amount: 0.25,
                label: '250ml',
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child:
                  _buildWaterButton(
                amount: 0.50,
                label: '500ml',
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child:
                  _buildWaterButton(
                amount: 0.75,
                label: '750ml',
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child:
                  _buildWaterButton(
                amount: 1.0,
                label: '1L',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterButton({
    required double amount,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _addWater(amount),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: Ink(
          height: 55,
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color:
                  const Color(
                0xFFE4D9F6,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: waterBlue,
                size: 16,
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                label,
                style:
                    const TextStyle(
                  color: textDark,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 1,
              ),

              Text(
                amount == 1.0
                    ? '1000 ml'
                    : '${(amount * 1000).toInt()} ml',
                style:
                    const TextStyle(
                  color: textMuted,
                  fontSize: 5.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY'S PROGRESS
  // ============================================================

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(11),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE4D9F6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(
              0.035,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _progressTile(
                  icon:
                      Icons.water_drop_rounded,
                  value:
                      '${_currentAmount.toStringAsFixed(1)}L',
                  label:
                      'Consumed',
                  accent:
                      waterBlue,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    _progressTile(
                  icon:
                      Icons.track_changes_rounded,
                  value:
                      '${_goalAmount.toStringAsFixed(1)}L',
                  label:
                      'Daily Goal',
                  accent:
                      purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressTile({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration:
          BoxDecoration(
        color: lavender,
        borderRadius:
            BorderRadius.circular(
          11,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(
                0.75,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 16,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                value,
                style:
                    const TextStyle(
                  color: textDark,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              Text(
                label,
                style:
                    const TextStyle(
                  color: textMuted,
                  fontSize: 6.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOG WATER
  // ============================================================

  Widget _buildLogWaterSection() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(11),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE4D9F6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Log Water',
                  style:
                      TextStyle(
                    color: textDark,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),

              GestureDetector(
                onTap: _resetWater,
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color: lavender,
                    borderRadius:
                        BorderRadius
                            .circular(
                      8,
                    ),
                  ),
                  child:
                      const Text(
                    'Reset',
                    style:
                        TextStyle(
                      color: purple,
                      fontSize: 7,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          Container(
            height: 45,
            width: double.infinity,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 11,
            ),
            decoration:
                BoxDecoration(
              color: lavender,
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(
                      8,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .water_drop_rounded,
                    color: waterBlue,
                    size: 15,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    _currentAmount <= 0
                        ? 'No water logged yet today'
                        : '${_currentAmount.toStringAsFixed(1)}L consumed today',
                    style:
                        const TextStyle(
                      color: textDark,
                      fontSize: 8.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIP
  // ============================================================

  Widget _buildTipCard() {
    final remaining =
        (_goalAmount -
                _currentAmount)
            .clamp(
      0.0,
      double.infinity,
    );

    final message = remaining > 0
        ? 'Keep sipping water regularly. '
            '${remaining.toStringAsFixed(1)}L remaining today.'
        : 'Great job! You reached your daily hydration goal.';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration:
          BoxDecoration(
        color: lavender,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE3D8F7,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .lightbulb_outline_rounded,
              color: purple,
              size: 14,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                color: textMuted,
                fontSize: 7,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}