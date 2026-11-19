import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_stepper/easy_stepper.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';

class MyTokenView extends StatelessWidget {
  const MyTokenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Live Queue Tracking',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Main Big Token Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'WAITING IN QUEUE',
                      style: TextStyle(
                        color: AppColors.adminPrimaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Token Number
                  const Text(
                    'YOUR TOKEN NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '#12',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Doctor & Hospital Info
                  const Text(
                    'Dr. Ahmed Raza',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cardiology · City General Hospital',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Patient: Ayesha Khan (you)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Queue Metrics (Row 1)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Now Serving',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '#10',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Patients Ahead',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '2',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.adminPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Queue Metrics (Row 2)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Approx Wait',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '~25 mins',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Room Number',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'OPD-04',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Horizontal Stepper (Using easy_stepper)
            _buildHorizontalStepper(),
            const SizedBox(height: 20),

            // 5. Live Queue List
            _buildLiveQueueSection(),
            const SizedBox(height: 24),

            // 6. Cancel Button (Using CustomButton)
            CustomButton(
              label: 'Cancel Token',
              height: 48,
              backgroundColor: AppColors.errorBg,
              textColor: AppColors.error,
              onPressed: () {
                Get.snackbar(
                  'Cancel Token',
                  'Cancel confirmation will be triggered here.',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.surface,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Easy Stepper Widget
  Widget _buildHorizontalStepper() {
    // Current step: 0 = Booked, 1 = Waiting, 2 = Serving, 3 = Done
    const int activeStep = 1;
    const teal = AppColors.adminPrimary;
    const grey = AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: EasyStepper(
        activeStep: activeStep,
        stepRadius: 13,
        showStepBorder: false,
        showLoadingAnimation: false,
        titlesAreLargerThanSteps: true,
        lineStyle: const LineStyle(
          lineLength: 48,
          lineThickness: 2.5,
          lineType: LineType.normal,
          defaultLineColor: AppColors.border,
          finishedLineColor: AppColors.adminPrimary,
        ),
        steps: [
          // Step 1: Booked
          const EasyStep(
            customStep: CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.adminPrimary,
              child: Icon(Icons.check, size: 16, color: AppColors.surface),
            ),
            title: 'Booked',
          ),

          // Step 2: Waiting
          EasyStep(
            customStep: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.adminPrimary, width: 2.5),
                color: activeStep >= 1 ? AppColors.surface : AppColors.border,
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.adminPrimary,
                ),
              ),
            ),
            title: 'Waiting',
          ),

          // Step 3: Serving
          const EasyStep(
            customStep: CircleAvatar(
              radius: 13,
              backgroundColor: activeStep >= 2 ? teal : grey,
            ),
            title: 'Serving',
          ),

          // Step 4: Done
          const EasyStep(
            customStep: CircleAvatar(
              radius: 13,
              backgroundColor: activeStep >= 3 ? teal : grey,
            ),
            title: 'Done',
          ),
        ],
      ),
    );
  }

  // Live Queue Section Matching Design
  Widget _buildLiveQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live queue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Queue Item 1: #10 Next to be called
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Text(
                '#10',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Next to be called',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.adminBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.adminBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Queue Item 2: #11 Waiting
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Text(
                '#11',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Waiting',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Queue Item 3: #12 Your token (Highlighted)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.adminPrimaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.adminPrimary, width: 1.2),
          ),
          child: const Row(
            children: [
              Text(
                '#12',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Your token',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Spacer(),
              Text(
                'You',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
