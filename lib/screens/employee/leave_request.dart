import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

// void main() {
//   runApp(const LeaveApp());
// }

class LeaveRequest extends StatelessWidget {
  const LeaveRequest({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors tuned to match the screenshot
    const bg = Color(0xFFF6F8FB); // page background
    const text = Color(0xFF0D141C); // primary text
    const border = Color(0xFFD7E4F2); // input border
    const hint = Color(0xFF7FA2C4); // placeholder
    const primary = Color(0xFF0D80F2); // submit button
    const card = Colors.white;

    final inter = GoogleFonts.interTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Request Leave',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
        textTheme: inter.apply(bodyColor: text, displayColor: text),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          hintStyle: GoogleFonts.inter(color: hint, fontSize: 16, height: 1.25),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border, width: 1),
          ),
        ),
      ),
      home: const RequestLeaveScreen(),
    );
  }
}

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  String? leaveType;
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final commentsCtrl = TextEditingController();

  @override
  void dispose() {
    startCtrl.dispose();
    endCtrl.dispose();
    commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController c) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select Date',
    );
    if (d != null) {
      c.text =
          '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const pagePadding = EdgeInsets.symmetric(horizontal: 16);
    const sectionGap = SizedBox(height: 12);
    const fieldGap = SizedBox(height: 10);
    const labelStyle = TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, height: 1.25); // bold
    const subLabelStyle =
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600); // “Start Date”
    const inputHeight = 52.0; // matches screenshot

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back, size: 22),
                      splashRadius: 20,
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Request Leave',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 48), // to keep the title perfectly centered
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leave Type
                      Padding(
                        padding: pagePadding.add(const EdgeInsets.only(top: 8)),
                        child: const Text('Leave Type', style: labelStyle),
                      ),
                      sectionGap,
                      Padding(
                        padding: pagePadding,
                        child: _SelectField(
                          height: inputHeight,
                          hint: 'Select Leave Type',
                          value: leaveType,
                          onChanged: (v) => setState(() => leaveType = v),
                          items: const [
                            DropdownMenuItem(
                                value: 'one', child: Text('Select Leave Type')),
                            DropdownMenuItem(value: 'two', child: Text('two')),
                            DropdownMenuItem(
                                value: 'three', child: Text('three')),
                          ],
                        ),
                      ),

                      // Dates
                      sectionGap,
                      Padding(
                        padding: pagePadding.add(const EdgeInsets.only(top: 6)),
                        child: const Text('Dates', style: labelStyle),
                      ),
                      sectionGap,

                      // Start Date
                      Padding(
                        padding: pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Date', style: subLabelStyle),
                            fieldGap,
                            _DateField(
                              controller: startCtrl,
                              height: inputHeight,
                              onPick: () => _pickDate(startCtrl),
                            ),
                          ],
                        ),
                      ),

                      // End Date
                      sectionGap,
                      Padding(
                        padding: pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Date', style: subLabelStyle),
                            fieldGap,
                            _DateField(
                              controller: endCtrl,
                              height: inputHeight,
                              onPick: () => _pickDate(endCtrl),
                            ),
                          ],
                        ),
                      ),

                      // Comments
                      sectionGap,
                      Padding(
                        padding: pagePadding,
                        child: const Text('Comments', style: labelStyle),
                      ),
                      sectionGap,
                      Padding(
                        padding: pagePadding,
                        child: _CommentsField(
                          controller: commentsCtrl,
                          minHeight: 200, // visuals match screenshot box
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Submit
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  style: ButtonStyle(
                      shape: WidgetStateOutlinedBorder.resolveWith(
                    (states) => ContinuousRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(15)),
                  )),
                  onPressed: () {},
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown styled to match the screenshot: white fill, 12px radius, 1px light-blue border,
/// 52px height, right chevron inside.
class _SelectField extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final double height;

  const _SelectField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFD7E4F2);
    const hint = Color(0xFF7FA2C4);

    return SizedBox(
      height: height,
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: this.hint,
          hintStyle: TextStyle(color: Colors.black),
          suffixIcon: const Icon(Icons.expand_more, size: 20, color: hint),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            borderRadius: BorderRadius.circular(12),
            items: items,
            onChanged: onChanged,
            icon: const SizedBox.shrink(), // we use the suffixIcon above
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            dropdownColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Text field with a calendar icon *inside* the field on the right with a subtle
/// rounded square border, matching the screenshot.
class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final double height;
  final VoidCallback onPick;

  const _DateField({
    required this.controller,
    required this.height,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    const hint = Color(0xFF7FA2C4);
    const innerBorder = Color(0xFFD7E4F2);

    const calSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 256 256" fill="currentColor">
  <path d="M208,32H184V24a8,8,0,0,0-16,0v8H88V24a8,8,0,0,0-16,0v8H48A16,16,0,0,0,32,48V208a16,16,0,0,0,16,16H208a16,16,0,0,0,16-16V48A16,16,0,0,0,208,32ZM72,48v8a8,8,0,0,0,16,0V48h80v8a8,8,0,0,0,16,0V48h24V80H48V48ZM208,208H48V96H208V208Z"/>
</svg>
''';

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onPick,
        decoration: InputDecoration(
          hintText: 'Select Date',
          suffixIconConstraints:
              const BoxConstraints.tightFor(width: 48, height: 48),
          suffixIcon: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPick,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: innerBorder, width: 1),
                ),
                child: IconTheme(
                  data: const IconThemeData(color: hint, size: 18),
                  child: SvgPicture.string(calSvg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multiline comments box matching the screenshot with light-blue border and rounded corners.
class _CommentsField extends StatelessWidget {
  final TextEditingController controller;
  final double minHeight;

  const _CommentsField({required this.controller, required this.minHeight});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextField(
        controller: controller,
        minLines: 8,
        maxLines: null,
        decoration: const InputDecoration(
          hintText:
              'Add any additional comments or details about your leave request',
        ),
      ),
    );
  }
}
