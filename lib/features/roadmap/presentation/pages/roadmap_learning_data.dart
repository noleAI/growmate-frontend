class RoadmapSubject {
  const RoadmapSubject({
    required this.title,
    required this.subtitle,
    required this.topics,
  });

  final String title;
  final String subtitle;
  final List<RoadmapTopic> topics;
}

class RoadmapTopic {
  const RoadmapTopic({
    required this.title,
    required this.subtitle,
    required this.subtopics,
  });

  final String title;
  final String subtitle;
  final List<RoadmapSubtopic> subtopics;
}

class RoadmapSubtopic {
  const RoadmapSubtopic({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.explanation,
    required this.formulas,
  });

  final String code;
  final String title;
  final String subtitle;
  final String explanation;
  final List<String> formulas;
}

const roadmapSubjects = <RoadmapSubject>[
  // ── Toán ────────────────────────────────────────────────────────────────
  RoadmapSubject(
    title: 'Toán',
    subtitle: 'Nền tảng giải tích THPT',
    topics: [
      RoadmapTopic(
        title: 'Đạo hàm',
        subtitle: 'Chủ đề trọng tâm học kỳ này',
        subtopics: [
          RoadmapSubtopic(
            code: 'H01',
            title: 'Đạo hàm lượng giác',
            subtitle: 'sin, cos, tan và các dạng cơ bản',
            explanation:
                'Tập trung nhận dạng dạng hàm và áp dụng đúng công thức đạo hàm lượng giác cơ bản.',
            formulas: [
              "(sin x)' = cos x",
              "(cos x)' = -sin x",
              "(tan x)' = 1/cos²(x)",
            ],
          ),
          RoadmapSubtopic(
            code: 'H02',
            title: 'Đạo hàm mũ và logarit',
            subtitle: 'e^x, a^x, ln x, log_a(x)',
            explanation:
                'Tách từng phần biểu thức để tránh nhầm lẫn giữa mũ tự nhiên và mũ cơ số a.',
            formulas: ["(e^x)' = e^x", "(a^x)' = a^x·ln(a)", "(ln x)' = 1/x"],
          ),
          RoadmapSubtopic(
            code: 'H03',
            title: 'Quy tắc dây chuyền',
            subtitle: 'Đạo hàm hàm hợp',
            explanation:
                'Làm rõ lớp ngoài và lớp trong của hàm hợp, đạo hàm ngoài trước trong sau.',
            formulas: ["(f(g(x)))' = f'(g(x))·g'(x)", "(sin(2x))' = 2cos(2x)"],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Nguyên hàm & Tích phân',
        subtitle: 'Tích phân xác định và bất định',
        subtopics: [
          RoadmapSubtopic(
            code: 'H04',
            title: 'Nguyên hàm cơ bản',
            subtitle: 'Bảng nguyên hàm thông dụng',
            explanation:
                'Nắm vững bảng nguyên hàm và các quy tắc tích phân từng phần.',
            formulas: ['∫xⁿ dx = xⁿ⁺¹/(n+1) + C', '∫eˣ dx = eˣ + C'],
          ),
          RoadmapSubtopic(
            code: 'H05',
            title: 'Tích phân từng phần',
            subtitle: '∫u dv = uv − ∫v du',
            explanation:
                'Chọn u và dv phù hợp để đơn giản hóa biểu thức tích phân.',
            formulas: ['∫u dv = uv − ∫v du', '∫x·eˣ dx = (x−1)eˣ + C'],
          ),
          RoadmapSubtopic(
            code: 'H06',
            title: 'Ứng dụng tích phân',
            subtitle: 'Diện tích và thể tích',
            explanation:
                'Tính diện tích hình phẳng và thể tích khối tròn xoay.',
            formulas: ['S = ∫ₐᵇ |f(x)| dx', 'V = π∫ₐᵇ [f(x)]² dx'],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Hàm số mũ & logarit',
        subtitle: 'Lũy thừa, logarit và ứng dụng',
        subtopics: [
          RoadmapSubtopic(
            code: 'H07',
            title: 'Hàm số lũy thừa',
            subtitle: 'y = aˣ, tính chất và đồ thị',
            explanation:
                'Phân biệt hàm số tăng/giảm theo cơ số a so sánh với 1.',
            formulas: ['y = aˣ (a > 0, a ≠ 1)', 'log_a(aˣ) = x'],
          ),
          RoadmapSubtopic(
            code: 'H08',
            title: 'Phương trình logarit',
            subtitle: 'Giải phương trình log',
            explanation:
                'Đưa về cùng cơ số hoặc đặt ẩn phụ để giải phương trình.',
            formulas: ['log_a(f(x)) = b ⟺ f(x) = aᵇ'],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Số phức',
        subtitle: 'Số phức và biểu diễn hình học',
        subtopics: [
          RoadmapSubtopic(
            code: 'H09',
            title: 'Dạng đại số số phức',
            subtitle: 'z = a + bi',
            explanation:
                'Nắm vững phép toán cộng, trừ, nhân, chia số phức dạng đại số.',
            formulas: ['z = a + bi', 'i² = −1', '|z| = √(a²+b²)'],
          ),
          RoadmapSubtopic(
            code: 'H10',
            title: 'Dạng lượng giác số phức',
            subtitle: 'z = r(cosθ + i·sinθ)',
            explanation:
                'Chuyển đổi giữa dạng đại số và dạng lượng giác, áp dụng công thức De Moivre.',
            formulas: ['zⁿ = rⁿ(cos nθ + i·sin nθ)'],
          ),
        ],
      ),
    ],
  ),

  // MVP: Chỉ hiển thị môn Toán. Các môn khác (Vật Lý, Hóa Học) sẽ được
  // bổ sung khi backend hỗ trợ đa môn.
];
