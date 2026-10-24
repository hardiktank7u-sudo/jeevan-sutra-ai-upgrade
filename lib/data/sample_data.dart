// Authentic Sample Data for Jeevan Sutra
import '../models/wellness_models.dart';

class SampleData {
  static List<MealSuggestion> get mealSuggestions => meals;
  static List<SeasonInfo> get seasonInfos => seasons;
  static List<KnowledgeArticle> get knowledgeArticles => articles;
  static final UserProfile defaultProfile = UserProfile(
    name: "Hardik",
    ageGroup: "25–34",
    dominantPrakriti: "Pitta-Vata",
    goals: [
      "Circadian Alignment",
      "Digestive Agni Balance",
      "Stress Reduction via Pranayama",
      "Herbal Adaptogens",
    ],
    dietaryPreference: "Sattvic & Plant-Forward",
    preferredLanguage: "English (with Sanskrit terms)",
  );

  static final List<RoutineItem> dailyRoutines = [
    RoutineItem(
      id: "rt_1",
      title: "Brahma Muhurta Awakening",
      sanskritName: "ब्रह्म मुहूर्त",
      time: "05:30 AM",
      period: RoutineTimeOfDay.morning,
      description: "Rise 48 minutes before sunrise when sattvic ambient energy peaks, aligning the circadian pacemaker.",
      benefits: "Clarity of mind, enhanced neuroplasticity, optimal cortisol rhythm",
      balancingDosha: DoshaType.vata,
      isCompleted: true,
    ),
    RoutineItem(
      id: "rt_2",
      title: "Ushapan (Warm Water Cleanse)",
      sanskritName: "उषापान",
      time: "06:00 AM",
      period: RoutineTimeOfDay.morning,
      description: "Drink 2 cups of lukewarm water infused with ginger or copper vessel hydration to awaken gastrointestinal peristalsis.",
      benefits: "Stimulates Apana Vayu, eliminates metabolic toxins (Ama)",
      balancingDosha: DoshaType.tridoshic,
      isCompleted: true,
    ),
    RoutineItem(
      id: "rt_3",
      title: "Jivha Sodhana & Kavala (Oral Cleansing)",
      sanskritName: "जिह्वा शोधन",
      time: "06:15 AM",
      period: RoutineTimeOfDay.morning,
      description: "Copper tongue scraping followed by warm sesame oil pulling for 5 minutes.",
      benefits: "Removes oral biofilm, enhances gustatory taste receptor acuity",
      balancingDosha: DoshaType.kapha,
      isCompleted: true,
    ),
    RoutineItem(
      id: "rt_4",
      title: "Surya Namaskar & Asana",
      sanskritName: "सूर्य नमस्कार",
      time: "06:45 AM",
      period: RoutineTimeOfDay.morning,
      description: "12 rhythmic rounds honoring solar vitality paired with spinal extension and deep pelvic breathing.",
      benefits: "Cardiovascular resilience, lymphatic drainage, core stability",
      balancingDosha: DoshaType.kapha,
      isCompleted: false,
    ),
    RoutineItem(
      id: "rt_5",
      title: "Main Midday Meal (Sattvic Agni)",
      sanskritName: "मध्याह्न भोजन",
      time: "12:30 PM",
      period: RoutineTimeOfDay.daytime,
      description: "Principal meal of the day when solar energy and digestive fire (Jatharagni) peak simultaneously.",
      benefits: "Complete enzymatic nutrient assimilation, prevents post-prandial lethargy",
      balancingDosha: DoshaType.pitta,
      isCompleted: false,
    ),
    RoutineItem(
      id: "rt_6",
      title: "Nadi Shodhana Pranayama",
      sanskritName: "नाड़ी शोधन",
      time: "05:00 PM",
      period: RoutineTimeOfDay.evening,
      description: "Alternate nostril breathing with gentle 4-4-4 cadence to rebalance sympathetic and parasympathetic tone.",
      benefits: "Hemispheric brain synchronization, reduces evening anxiety",
      balancingDosha: DoshaType.vata,
      isCompleted: false,
    ),
    RoutineItem(
      id: "rt_7",
      title: "Padabhyanga (Foot Massage with Ghee)",
      sanskritName: "पादाभ्यङ्ग",
      time: "09:30 PM",
      period: RoutineTimeOfDay.night,
      description: "Warm cow ghee or sesame oil massaged into the soles of the feet to draw heat downward from the crown.",
      benefits: "Calms sensory overload, induces deep restorative slow-wave sleep",
      balancingDosha: DoshaType.vata,
      isCompleted: false,
    ),
  ];

  static final List<MedicinalPlant> medicinalPlants = [
    MedicinalPlant(
      id: "plant_1",
      commonName: "Tulsi (Holy Basil)",
      botanicalName: "Ocimum sanctum",
      sanskritName: "तुलसी (Surasa)",
      category: "Adaptogen & Respiratory",
      primaryUses: "Respiratory clarity, cellular adaptogen, stress modulation",
      traditionalApplication: "Fresh leaf decoction or tea with black pepper and honey for seasonal transition immunity.",
      scientificEvidence: "Rich in eugenol and rosmarinic acid; clinical trials indicate reduced salivary cortisol and improved antioxidant parameters.",
      dosageAndPreparation: "500mg extract or 3–5 fresh leaves steeped in warm water daily.",
      precautions: "May lower blood glucose levels; consult practitioner if taking anticoagulants.",
      balancesDosha: [DoshaType.kapha, DoshaType.vata],
      rasa: "Tikta (Bitter), Katu (Pungent)",
      virya: "Ushna (Warm)",
      vipaka: "Katu (Pungent)",
      isBookmarked: true,
    ),
    MedicinalPlant(
      id: "plant_2",
      commonName: "Ashwagandha (Indian Ginseng)",
      botanicalName: "Withania somnifera",
      sanskritName: "अश्वगन्धा (Balya)",
      category: "Neuro-Endocrine & Strength",
      primaryUses: "Deep vitality, nervous system tonic, sleep architecture support",
      traditionalApplication: "Root powder blended with warm cow milk or almond milk, raw honey, and pinch of cardamom before sleep.",
      scientificEvidence: "Contains bioactive withanolides. Randomised double-blind trials demonstrate significant reduction in serum cortisol and enhanced restorative sleep.",
      dosageAndPreparation: "300–600mg standardized root extract (with 5% withanolides) in the evening.",
      precautions: "Avoid in active hyperthyroidism or pregnancy without professional supervision.",
      balancesDosha: [DoshaType.vata, DoshaType.kapha],
      rasa: "Tikta (Bitter), Kashaya (Astringent), Madhura (Sweet)",
      virya: "Ushna (Warm)",
      vipaka: "Madhura (Sweet)",
      isBookmarked: true,
    ),
    MedicinalPlant(
      id: "plant_3",
      commonName: "Haridra (Turmeric)",
      botanicalName: "Curcuma longa",
      sanskritName: "हरिद्रा (Kanchani)",
      category: "Anti-Inflammatory & Blood Purifier",
      primaryUses: "Systemic inflammation, joint flexibility, liver metabolic support",
      traditionalApplication: "Golden Milk (Haldi Doodh) infused with black pepper (piperine) and pure grass-fed ghee.",
      scientificEvidence: "Curcuminoids down-regulate NF-kB and COX-2 enzymes; piperine enhances curcumin bioavailability by up to 2000%.",
      dosageAndPreparation: "500–1000mg curcuminoid complex with bio-enhancers or 1 tsp raw organic powder with healthy fats.",
      precautions: "Use caution in acute gallstones or concurrent bile duct obstruction.",
      balancesDosha: [DoshaType.kapha, DoshaType.vata, DoshaType.pitta],
      rasa: "Tikta (Bitter), Katu (Pungent)",
      virya: "Ushna (Warm)",
      vipaka: "Katu (Pungent)",
      isBookmarked: false,
    ),
    MedicinalPlant(
      id: "plant_4",
      commonName: "Neem (Indian Lilac)",
      botanicalName: "Azadirachta indica",
      sanskritName: "निम्ब (Arishta)",
      category: "Dermatological & Detoxifier",
      primaryUses: "Blood purification, dermatological calm, oral microbiome balance",
      traditionalApplication: "Twigs chewed for oral health; leaves steeped for cooling purifying bath or skin pastes.",
      scientificEvidence: "Azadirachtin and nimbin exhibit potent broad-spectrum antimicrobial and anti-inflammatory properties.",
      dosageAndPreparation: "250–500mg standardized leaf powder under practitioner guidance; topical poultice for skin.",
      precautions: "Avoid in pregnancy, childhood, or extreme Vata emaciation due to strong cooling nature.",
      balancesDosha: [DoshaType.pitta, DoshaType.kapha],
      rasa: "Tikta (Bitter), Kashaya (Astringent)",
      virya: "Sheeta (Cold)",
      vipaka: "Katu (Pungent)",
      isBookmarked: false,
    ),
    MedicinalPlant(
      id: "plant_5",
      commonName: "Brahmi (Water Hyssop)",
      botanicalName: "Bacopa monnieri",
      sanskritName: "ब्राह्मी (Medhya)",
      category: "Nootropic & Cognitive Clarity",
      primaryUses: "Memory retention, neurotransmitter modulation, cognitive endurance",
      traditionalApplication: "Brahmi Ghrita (medicated ghee) taken on an empty stomach to penetrate the blood-brain barrier.",
      scientificEvidence: "Bacosides A & B promote synaptic communication and repair damaged neurons by enhancing kinase activity.",
      dosageAndPreparation: "300mg standardized extract (50% bacosides) taken with meals containing healthy lipids.",
      precautions: "May rarely cause mild GI upset if taken on an entirely empty stomach without fats.",
      balancesDosha: [DoshaType.tridoshic],
      rasa: "Tikta (Bitter), Kashaya (Astringent)",
      virya: "Sheeta (Cold)",
      vipaka: "Madhura (Sweet)",
      isBookmarked: true,
    ),
  ];

  static final List<MealSuggestion> meals = [
    MealSuggestion(
      id: "meal_1",
      title: "Sprouted Ragi & Chia Dosa",
      mealType: "Breakfast",
      sanskritConcept: "लघु आहार (Light Ahara)",
      description: "Crisp fermented finger-millet crêpes accompanied by fresh coconut-mint chutney and roasted cumin sambar.",
      ingredients: ["Sprouted ragi flour", "Urad dal", "Chia seeds", "Fresh grated coconut", "Curry leaves", "Mustard seeds"],
      preparationTime: "20 mins",
      caloriesEst: "340 kcal",
      doshaEffect: "Balances Pitta & Kapha; grounding for Vata with ghee",
      benefits: ["High bioavailable iron & calcium", "Slow glycemic release", "Microbiome-nourishing fermentation"],
      isBookmarked: true,
    ),
    MealSuggestion(
      id: "meal_2",
      title: "Tridoshic Moong Dal Khichdi",
      mealType: "Lunch",
      sanskritConcept: "सत्त्विक पूर्णाहार (Sattvic Complete)",
      description: "Ancient balanced one-pot preparation of split yellow moong, aged basmati, ghee, cumin, turmeric, and tender seasonal gourds.",
      ingredients: ["Split moong lentils", "Basmati rice", "A2 Grass-fed Cow Ghee", "Jeera (cumin)", "Fresh ginger", "Turmeric"],
      preparationTime: "25 mins",
      caloriesEst: "480 kcal",
      doshaEffect: "Completely Tridoshic (Sama Agni)",
      benefits: ["Gentlest complete protein profile", "Zero digestive burden", "Restores cellular metabolic equilibrium"],
      isBookmarked: true,
    ),
    MealSuggestion(
      id: "meal_3",
      title: "Roasted Makhana & Herbal Chai",
      mealType: "Snack",
      sanskritConcept: "अल्पाहार (Midday Rejuvenation)",
      description: "Fox nuts lightly tossed in clarified butter with pink rock salt and cracked black pepper, served with Tulsi-Cardamom decoction.",
      ingredients: ["Fox nuts (Makhana)", "Pure ghee", "Sendha namak", "Black pepper", "Fresh tulsi", "Green cardamom"],
      preparationTime: "10 mins",
      caloriesEst: "180 kcal",
      doshaEffect: "Pacifies Vata; neutral to Pitta",
      benefits: ["Rich in magnesium and flavonoids", "Clean afternoon sustained energy without caffeine spike"],
      isBookmarked: false,
    ),
    MealSuggestion(
      id: "meal_4",
      title: "Moringa & Bottle Gourd Broth",
      mealType: "Dinner",
      sanskritConcept: "शामक आहार (Evening Wind-Down)",
      description: "Warm, light digestive soup made with fresh drumstick pulp, lauki (bottle gourd), toasted coriander, and a drizzle of lemon.",
      ingredients: ["Fresh moringa pods", "Bottle gourd", "Coriander seeds", "Ginger", "Hing (asafoetida)", "Lime juice"],
      preparationTime: "20 mins",
      caloriesEst: "210 kcal",
      doshaEffect: "Highly pacifying for Pitta & Kapha",
      benefits: ["Optimizes overnight autophagy", "Promotes light, sound sleep without nocturnal acid reflux"],
      isBookmarked: false,
    ),
  ];

  static final List<YogaMeditationSession> yogaSessions = [
    YogaMeditationSession(
      id: "yoga_1",
      title: "Sama Vritti & Nadi Shodhana",
      sanskritTitle: "नाड़ी शोधन प्राणायाम",
      category: "Pranayama",
      durationMinutes: 10,
      intensity: "Gentle",
      description: "Equal-ratio breath regulation with thumb and ring finger mudra to purify autonomic energetic pathways.",
      steps: [
        "Sit comfortably in Sukhasana with spine lengthened.",
        "Adopt Vishnu Mudra with your right hand.",
        "Close right nostril; inhale through left for 4 counts.",
        "Close both nostrils gently and hold for 4 counts.",
        "Exhale smoothly through right nostril for 4 counts.",
        "Repeat for 12 complete harmonious cycles.",
      ],
      modernBenefits: "Increases vagal nerve stimulation and improves heart rate variability (HRV).",
      isBookmarked: true,
    ),
    YogaMeditationSession(
      id: "yoga_2",
      title: "Classical Surya Namaskar",
      sanskritTitle: "द्वादश सूर्य नमस्कार",
      category: "Asana",
      durationMinutes: 15,
      intensity: "Moderate",
      description: "12 traditional solar postures linked with steady ujjayi breath to mobilize the spine and ignite internal warmth.",
      steps: [
        "Pranamasana (Prayer pose) with sun intention.",
        "Hasta Uttanasana (Raised arms spinal arch).",
        "Padahastasana (Forward fold with abdominal contact).",
        "Ashwa Sanchalanasana (Low equestrian lunge).",
        "Dandasana to Ashtanga Namaskara (Eight-point prostration).",
        "Bhujangasana (Gentle cobra with relaxed glutes).",
        "Adho Mukha Svanasana (Downward-facing dog).",
      ],
      modernBenefits: "Promotes whole-body joint synovial lubrication and lymphatic circulation.",
      isBookmarked: true,
    ),
    YogaMeditationSession(
      id: "yoga_3",
      title: "Yoga Nidra for Deep Restoration",
      sanskritTitle: "योग निद्रा",
      category: "Nidra",
      durationMinutes: 20,
      intensity: "Restorative",
      description: "Psychic sleep technique leading conscious awareness through 61 points of the physical and subtle body.",
      steps: [
        "Recline in Savasana with eyes gently covered.",
        "Formulate a heartfelt resolve (Sankalpa).",
        "Systematically rotate consciousness through fingers, joints, and organs.",
        "Experience dualities of heaviness and lightness.",
        "Rest in the peaceful witnessing space (Chidakasha).",
      ],
      modernBenefits: "Shifts brainwave activity into theta and delta states equivalent to 2 hours of deep sleep.",
      isBookmarked: false,
    ),
  ];

  static final List<SeasonInfo> seasons = [
    SeasonInfo(
      type: SeasonType.shishira,
      name: "Late Winter",
      sanskritName: "शिशिर ऋतु (Shishira)",
      months: "Mid-January to Mid-March",
      dominantElement: "Vayu & Akasha (Air & Space)",
      doshaState: "Cold environment concentrates digestive fire (Agni); Vata accumulation begins if unprotected.",
      dietaryAdvice: "Emphasize nourishing unctuous foods: sesame oil, warm broths, sweet root vegetables, hot milk with saffron.",
      lifestyleAdvice: "Warm sun exposure, vigorous massage with sesame oil, moderate indoor yoga, avoid cold drafts.",
      recommendedHerbs: ["Ashwagandha", "Ginger", "Pippali", "Chyavanprash"],
      avoidances: ["Cold beverages", "Raw cold salads", "Fasting", "Excessive exposure to frost"],
    ),
    SeasonInfo(
      type: SeasonType.vasanta,
      name: "Spring",
      sanskritName: "वसन्त ऋतु (Vasanta)",
      months: "Mid-March to Mid-May",
      dominantElement: "Prithvi & Jala (Earth & Water liquefying)",
      doshaState: "Liquefaction of accumulated Kapha due to increasing solar warmth; allergies and sluggishness can peak.",
      dietaryAdvice: "Favor bitter, pungent, and astringent tastes: barley, honey, dry-roasted grains, steamed greens, ginger tea.",
      lifestyleAdvice: "Daily dry powder massage (Udvartana), brisk walks, Nasya nasal drops, dynamic Surya Namaskar.",
      recommendedHerbs: ["Tulsi", "Neem", "Triphala", "Haridra"],
      avoidances: ["Heavy dairy", "Daytime naps", "Oily fried foods", "Sweet chilled desserts"],
    ),
    SeasonInfo(
      type: SeasonType.grishma,
      name: "Summer",
      sanskritName: "ग्रीष्म ऋतु (Grishma)",
      months: "Mid-May to Mid-July",
      dominantElement: "Agni & Vayu (Fire & Air)",
      doshaState: "Solar rays deplete bodily fluids; Agni weakens while Pitta gathers heat.",
      dietaryAdvice: "Cooling sweet and liquid preparations: coconut water, sattu, sweet mango, cilantro, mint, pomegranate.",
      lifestyleAdvice: "Moonlight walking (Chandra Sparsha), cool jasmine aromas, gentle Yin yoga, swimming.",
      recommendedHerbs: ["Amla", "Shatavari", "Chandan", "Fennel"],
      avoidances: ["Pungent chili", "Alcohol", "Intense midday sun", "Strenuous physical overexertion"],
    ),
    SeasonInfo(
      type: SeasonType.varsha,
      name: "Monsoon",
      sanskritName: "वर्षा ऋतु (Varsha)",
      months: "Mid-July to Mid-September",
      dominantElement: "Jala & Agni (Water & Clouded Fire)",
      doshaState: "Vata aggravation occurs due to cold damp breezes; digestive fire remains delicate.",
      dietaryAdvice: "Warm boiled water, rock salt, light soups, freshly prepared hot foods with ghee and cumin.",
      lifestyleAdvice: "Keep living spaces dry; wear dry warm natural fabrics; avoid getting soaked in rain.",
      recommendedHerbs: ["Ginger", "Coriander", "Ajwain", "Tulsi"],
      avoidances: ["Raw leafy vegetables", "Stale leftovers", "Daytime sleeping", "Stagnant puddles"],
    ),
    SeasonInfo(
      type: SeasonType.sharad,
      name: "Autumn",
      sanskritName: "शरद् ऋतु (Sharad)",
      months: "Mid-September to Mid-November",
      dominantElement: "Agni & Jala (Clearing Sun)",
      doshaState: "Sudden clear skies and intense sun cause aggravated Pitta to manifest as skin outbreaks or acidity.",
      dietaryAdvice: "Ghee, bitter gourds, sweet fruits, cooling rice gruel, clean spring water.",
      lifestyleAdvice: "Virechana detoxification, evening strolls under the clear autumn moon (Hansodaka water).",
      recommendedHerbs: ["Neem", "Manjistha", "Guduchi", "Sandalwood"],
      avoidances: ["Sour curd", "Excessive sea salt", "Fermented alcohol", "Hot midday sun"],
    ),
    SeasonInfo(
      type: SeasonType.hemanta,
      name: "Early Winter",
      sanskritName: "हेमन्त ऋतु (Hemanta)",
      months: "Mid-November to Mid-January",
      dominantElement: "Prithvi & Jala (Nourishing Cold)",
      doshaState: "Strongest digestive fire of the year; optimal season for rejuvenation (Rasayana) and building Ojas.",
      dietaryAdvice: "Substantial nourishing whole foods: dates, nuts, cold-pressed sesame oil, whole grains, dairy if tolerated.",
      lifestyleAdvice: "Abhyanga with warmed herb-infused oils, resistance exercises, warm sunbathing.",
      recommendedHerbs: ["Bala", "Ashwagandha", "Amla", "Kesar"],
      avoidances: ["Light starvation diets", "Pungent drying crackers", "Cold showers"],
    ),
  ];

  static final List<KnowledgeArticle> articles = [
    KnowledgeArticle(
      id: "art_1",
      title: "The Molecular Science of Dinacharya: Circadian Genes & Doshas",
      subtitle: "Bridging 3,000-year-old biological clocks with modern Nobel prize-winning circadian medicine.",
      category: "Scientific Wellness",
      readingTimeMinutes: 6,
      author: "Dr. Ananya Sharma, MD (Integrative Medicine)",
      excerpt: "When the Charaka Samhita documented waking in Brahma Muhurta, it anticipated the molecular transcription-translation feedback loop governing CLOCK and BMAL1 genes.",
      fullContent: """
The fundamental postulate of Ayurvedic Dinacharya is that human physiological functions oscillate in synchrony with diurnal terrestrial cycles.

Modern chronobiology validated this in 2017 when the Nobel Prize in Physiology was awarded for elucidating the molecular mechanisms controlling the circadian rhythm.

Every organ in the human body expresses cell-autonomous circadian clocks. The master pacemaker, situated in the suprachiasmatic nucleus (SCN) of the hypothalamus, is entrained primarily by early morning photon stimulation of melanopsin-containing retinal ganglion cells.

By waking during the Brahma Muhurta (approximately 48 to 96 minutes before sunrise), the human nervous system transitions from melatonin dominance to physiological cortisol release under minimal ambient noise and electromagnetic interference.

In this article, we examine:
1. The 4-hour cycle of Vata, Pitta, and Kapha across the 24-hour day.
2. Why Jatharagni (digestive fire) precisely mirrors insulin sensitivity curves peaking at midday.
3. How the simple act of Ushapan (morning hydration) triggers the gastrocolic reflex mediated by parasympathetic innervation.
""",
      tags: ["Circadian", "Chronobiology", "Dinacharya", "Genetics"],
      isBookmarked: true,
    ),
    KnowledgeArticle(
      id: "art_2",
      title: "Ojas, Tejas, and Prana: The Tri-Energetic Reserve of Vitality",
      subtitle: "Understanding immunity and cellular resilience through the finest essence of tissue metabolism.",
      category: "Ayurveda & Traditional Wisdom",
      readingTimeMinutes: 8,
      author: "Vaidya R. K. Bhattacharya",
      excerpt: "Ojas is not an abstract concept; it represents the ultimate biological culmination of the seven Dhatus, corresponding directly to immunological competence and mitochondrial health.",
      fullContent: """
In classical Ayurvedic pathophysiology, the human body is supported by seven bodily tissues (Sapta Dhatus): Rasa (plasma), Rakta (blood), Mamsa (muscle), Meda (adipose), Asthi (bone), Majja (nerve & marrow), and Shukra (reproductive essence).

When digestive fire (Agni) is balanced and devoid of Ama (metabolic toxins), each tissue sequentially nourishes the next over an approximate 30-day metabolic cycle.

The supreme refined nectar that remains after this sequential alchemy is termed **Ojas**.

Ojas is described in Charaka Samhita as having the aroma of ghee, the sweetness of pure honey, and the color of clarified butter. When Ojas is abundant:
- The sensory organs operate with high fidelity and calm focus.
- The immune system exhibits targeted surveillance without autoimmune overreaction.
- The skin emits an organic healthy luster (Prabha).

To cultivate Ojas, prioritize deep sleep before 10:30 PM, consume fresh sattvic foods like dates, almonds soaked overnight, pure A2 ghee, and practice gentle daily breathwork.
""",
      tags: ["Ojas", "Immunity", "Metabolism", "Dhatus"],
      isBookmarked: false,
    ),
    KnowledgeArticle(
      id: "art_3",
      title: "Pranayama & Autonomic Tone: Heart Rate Variability Analysis",
      subtitle: "How alternating nostril pressure modulates vagal nerve stimulation and cerebral blood flow.",
      category: "Yoga & Meditation",
      readingTimeMinutes: 5,
      author: "Prof. Vikramaditya Joshi, PhD",
      excerpt: "Nadi Shodhana is not merely breath-holding; it is a biofeedback mechanism that synchronizes parasympathetic vagal tone with left-right cerebral hemispheric dominance.",
      fullContent: """
The human autonomic nervous system continuously balances the sympathetic ("fight-or-flight") and parasympathetic ("rest-and-digest") pathways.

Electroencephalographic (EEG) and electrocardiographic (ECG) studies demonstrate that practicing Nadi Shodhana for just 10 minutes leads to significant increases in high-frequency (HF) heart rate variability, a gold-standard biomarker of physiological adaptability and vagal nerve tone.

Furthermore, the Ultradian Nasal Cycle—wherein nasal airflow alternates between the left and right nostrils every 90 to 180 minutes—is directly tied to contralateral hemispheric brain activity.

Inhaling through the left nostril (Ida Nadi) correlates with right-hemispheric intuitive processing and parasympathetic deceleration, whereas inhaling through the right nostril (Pingala Nadi) stimulates sympathetic alertness and left-hemispheric analytical focus.
""",
      tags: ["Pranayama", "Heart Rate Variability", "Neuroscience", "Breathwork"],
      isBookmarked: true,
    ),
  ];
}
