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

  // ── Vật Lý ──────────────────────────────────────────────────────────────
  RoadmapSubject(
    title: 'Vật Lý',
    subtitle: 'Cơ học và điện học THPT',
    topics: [
      RoadmapTopic(
        title: 'Dao động điều hòa',
        subtitle: 'Con lắc lò xo, con lắc đơn',
        subtopics: [
          RoadmapSubtopic(
            code: 'P01',
            title: 'Phương trình dao động',
            subtitle: 'x = A·cos(ωt + φ)',
            explanation:
                'Xác định biên độ A, tần số góc ω và pha ban đầu φ từ điều kiện đầu.',
            formulas: ['x = A·cos(ωt + φ)', 'ω = 2πf = 2π/T'],
          ),
          RoadmapSubtopic(
            code: 'P02',
            title: 'Năng lượng dao động',
            subtitle: 'Thế năng và động năng',
            explanation:
                'Cơ năng toàn phần bảo toàn trong dao động điều hòa không ma sát.',
            formulas: ['W = ½kA²', 'Wđ + Wt = const'],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Sóng cơ học',
        subtitle: 'Sóng ngang, sóng dọc và giao thoa',
        subtopics: [
          RoadmapSubtopic(
            code: 'P03',
            title: 'Phương trình sóng',
            subtitle: 'u = A·cos(ωt − kx)',
            explanation:
                'Phân biệt bước sóng λ, tốc độ truyền sóng v và tần số f.',
            formulas: ['v = λ·f', 'u = A·cos(2π(t/T − x/λ))'],
          ),
          RoadmapSubtopic(
            code: 'P04',
            title: 'Giao thoa sóng',
            subtitle: 'Cực đại và cực tiểu giao thoa',
            explanation:
                'Điều kiện giao thoa tăng cường và triệt tiêu dựa trên hiệu đường đi.',
            formulas: ['Δd = kλ (cực đại)', 'Δd = (k+½)λ (cực tiểu)'],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Điện xoay chiều',
        subtitle: 'Mạch RLC và công suất',
        subtopics: [
          RoadmapSubtopic(
            code: 'P05',
            title: 'Mạch RLC nối tiếp',
            subtitle: 'Tổng trở và cộng hưởng',
            explanation:
                'Tính tổng trở Z, cường độ hiệu dụng và điều kiện cộng hưởng.',
            formulas: ['Z = √(R²+(ZL−ZC)²)', 'Cộng hưởng: ZL = ZC'],
          ),
          RoadmapSubtopic(
            code: 'P06',
            title: 'Công suất mạch điện',
            subtitle: 'Hệ số công suất cos φ',
            explanation:
                'Phân biệt công suất tác dụng P, công suất biểu kiến S và hệ số công suất.',
            formulas: ['P = UI·cos φ', 'cos φ = R/Z'],
          ),
        ],
      ),
    ],
  ),

  // ── Hóa Học ─────────────────────────────────────────────────────────────
  RoadmapSubject(
    title: 'Hóa Học',
    subtitle: 'Hóa hữu cơ nâng cao',
    topics: [
      RoadmapTopic(
        title: 'Este - Lipit',
        subtitle: 'Cấu tạo và phản ứng thủy phân',
        subtopics: [
          RoadmapSubtopic(
            code: 'C01',
            title: 'Cấu tạo este',
            subtitle: 'RCOOR\' và danh pháp',
            explanation:
                'Gọi tên este từ axit và ancol tương ứng, viết công thức cấu tạo.',
            formulas: [
              'Este: RCOOR\'',
              'Thủy phân: RCOOR\' + H₂O ⇌ RCOOH + R\'OH',
            ],
          ),
          RoadmapSubtopic(
            code: 'C02',
            title: 'Phản ứng xà phòng hóa',
            subtitle: 'Este tác dụng với NaOH',
            explanation:
                'Phản ứng xà phòng hóa không thuận nghịch, sản phẩm là muối và ancol.',
            formulas: ['RCOOR\' + NaOH → RCOONa + R\'OH'],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Cacbohydrat',
        subtitle: 'Glucozơ, saccarozơ, tinh bột',
        subtopics: [
          RoadmapSubtopic(
            code: 'C03',
            title: 'Glucozơ',
            subtitle: 'C₆H₁₂O₆ và tính chất',
            explanation:
                'Glucozơ có phản ứng tráng bạc (nhóm -CHO) và lên men rượu.',
            formulas: [
              'C₆H₁₂O₆ + 2AgNO₃ + 2NH₃ → Ag↓',
              'C₆H₁₂O₆ → 2C₂H₅OH + 2CO₂',
            ],
          ),
          RoadmapSubtopic(
            code: 'C04',
            title: 'Tinh bột và xenlulozơ',
            subtitle: 'Polysaccarit và ứng dụng',
            explanation:
                'Phân biệt tinh bột (xanh với I₂) và xenlulozơ (không tan trong nước).',
            formulas: ['(C₆H₁₀O₅)n + nH₂O → nC₆H₁₂O₆'],
          ),
        ],
      ),
      RoadmapTopic(
        title: 'Amin & Amino axit',
        subtitle: 'Tính chất lưỡng tính và peptit',
        subtopics: [
          RoadmapSubtopic(
            code: 'C05',
            title: 'Amin',
            subtitle: 'Phân loại và tính bazơ',
            explanation:
                'Amin có tính bazơ, bậc amin ảnh hưởng đến độ mạnh tính bazơ.',
            formulas: ['R-NH₂ + HCl → R-NH₃Cl', 'CH₃NH₂ > NH₃ > C₆H₅NH₂'],
          ),
          RoadmapSubtopic(
            code: 'C06',
            title: 'Amino axit và peptit',
            subtitle: 'Liên kết peptit -CO-NH-',
            explanation:
                'Amino axit lưỡng tính, tạo peptit qua phản ứng trùng ngưng.',
            formulas: ['H₂N-CH(R)-COOH', 'Peptit: -CO-NH- (liên kết peptit)'],
          ),
        ],
      ),
    ],
  ),
];
