/// Jeevan Sutra Wellness Knowledge Engine.
/// Provides structured, educational responses across everyday wellness topics.
class WellnessKnowledgeEngine {
  WellnessKnowledgeEngine._();

  static final WellnessKnowledgeEngine instance = WellnessKnowledgeEngine._();

  Stream<String> streamResponse({
    required String prompt,
    required List<Map<String, dynamic>> conversationHistory,
  }) async* {
    yield answerFor(prompt, conversationHistory: conversationHistory);
  }

  String answerFor(
    String prompt, {
    List<Map<String, dynamic>> conversationHistory = const [],
  }) {
    var question = _normalize(prompt);

    if (question.isEmpty) {
      return 'Please type a question and I will help you explore it.';
    }

    if (RegExp(
      r'^(tell me more|explain more|elaborate|more details|go deeper|why is that|how so)$',
    ).hasMatch(question)) {
      final previous = conversationHistory.reversed.firstWhere(
        (item) =>
            item['role'] == 'user' &&
            (item['text'] ?? '').toString().trim().isNotEmpty,
        orElse: () => <String, dynamic>{},
      );
      final previousQuestion = (previous['text'] ?? '').toString();
      if (previousQuestion.isNotEmpty) {
        question = _normalize(previousQuestion);
      }
    }

    if (question == 'hi' ||
        question == 'hello' ||
        question == 'hey' ||
        question == 'namaste') {
      return '''
## Namaste! 🌿

Welcome to Jeevan Sutra.

You can ask me about:
- Nutrition, meals and nutrients
- Ayurveda and the three doshas
- Daily routines and healthy habits
- Sleep, exercise and fitness
- Stress, concentration and relaxation
- Digestion, hydration and general health education
- Medicinal plants and traditional knowledge

What would you like to explore today?
''';
    }

    final ranked = _topics.map((topic) {
      var score = 0;
      for (final keyword in topic.keywords) {
        if (question.contains(keyword)) {
          score += keyword.split(' ').length + 1;
        }
      }
      return (topic: topic, score: score);
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    if (ranked.isEmpty || ranked.first.score == 0) {
      return _unknownAnswer(prompt);
    }

    return ranked.first.topic.answer;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _unknownAnswer(String question) {
    return '''
## Let's explore that together

I don't have a sufficiently reliable prepared explanation for that exact question yet.

You can try asking it in a more specific way, or explore one of these subjects:

- **Nutrition:** protein, balanced meals, breakfast and nutrients.
- **Ayurveda:** its principles, Vata, Pitta and Kapha.
- **Daily wellness:** routines, sleep, exercise and hydration.
- **Mental wellness:** concentration, relaxation and stress management.
- **Health education:** digestion, immunity and general body functions.
- **Nature:** medicinal plants and traditional botanical knowledge.

I would rather be clear about what I can explain reliably than invent an answer.
''';
  }

  static final List<_WellnessTopic> _topics = [
    _WellnessTopic(
      'protein',
      [
        'protein',
        'high protein',
        'protein rich',
        'protein-rich',
        'protein food',
        'protein meal',
        'protein diet',
        'sources of protein',
        'vegetarian protein',
        'muscle building food',
      ],
      '''
## Protein-rich meals 🥗

Protein is an essential nutrient. Your body uses it for growth, tissue maintenance, enzymes and many other functions.

### Vegetarian protein sources
- Dal, moong, masoor and other lentils.
- Chickpeas, rajma and other beans.
- Milk, curd and paneer.
- Soybeans, tofu and soy chunks.
- Peanuts, almonds and seeds.

### Other food sources
Eggs, fish and chicken can also provide protein.

### Example Indian meal
- **Breakfast:** Milk or curd with poha containing peanuts.
- **Lunch:** Roti or rice, dal, curd and a vegetable preparation.
- **Evening:** Roasted chana or a suitable nut snack.
- **Dinner:** Rajma or chole with rice, or paneer with roti.

### Helpful tips
1. Include a protein-containing food in your regular meals.
2. Combine different foods for variety.
3. Eat enough overall food to support your daily activities and growth.
4. Drink water regularly.

Protein needs differ with age, growth, activity and health. There is no single meal plan that suits everyone.
''',
    ),

    _WellnessTopic(
      'balanced meals',
      [
        'balanced diet',
        'balanced meal',
        'healthy meal',
        'healthy food',
        'what should i eat',
        'meal plan',
        'daily diet',
        'healthy eating',
        'nutrition',
      ],
      '''
## Understanding a balanced meal 🍽️

A balanced eating pattern provides energy and a variety of nutrients.

### Build variety into your meals
- **Grains:** Rice, roti, oats, millets and other grains.
- **Protein foods:** Dal, beans, chole, rajma, dairy, eggs, tofu or other suitable choices.
- **Vegetables:** Include different colours and varieties.
- **Fruits:** Choose seasonal fruits.
- **Dairy or alternatives:** Milk, curd or suitable fortified alternatives.
- **Healthy fats:** Nuts, seeds and normal cooking oils in appropriate amounts.

### Example day
- Breakfast: Idli with sambar.
- Lunch: Roti, dal, rice and curd.
- Snack: Fruit and roasted chana.
- Dinner: Khichdi with curd or another varied meal.

There is no need to follow a perfect menu every day. Variety, regular meals and sufficient nourishment matter.
''',
    ),

    _WellnessTopic(
      'breakfast',
      [
        'breakfast',
        'morning food',
        'what to eat in morning',
        'morning meal',
        'healthy breakfast',
      ],
      '''
## Healthy breakfast ideas 🌅

Breakfast can help provide energy after the overnight gap between meals.

Try different options:
1. Idli with sambar.
2. Vegetable poha with peanuts.
3. Besan chilla with curd.
4. Oats with milk and fruit.
5. Dosa with sambar.
6. Vegetable upma with curd.
7. Eggs with toast, if you eat eggs.

A useful breakfast combines energy-giving foods with protein and other nutrients. Choose a meal that suits your appetite and routine.
''',
    ),

    _WellnessTopic(
      'ayurveda',
      [
        'ayurveda',
        'what is ayurveda',
        'ayurvedic',
        'vedic medicine',
        'ancient indian medicine',
        'principles of ayurveda',
      ],
      '''
## What is Ayurveda? 🌿

Ayurveda is a traditional system of health knowledge that originated in India. The word is commonly explained through two Sanskrit roots: *Ayus* (life) and *Veda* (knowledge).

### Major ideas
- **Prakriti:** A traditional concept describing an individual's constitution.
- **Doshas:** Vata, Pitta and Kapha, used in Ayurvedic theory.
- **Dinacharya:** Traditional daily routine practices.
- **Ritucharya:** Seasonal routines.
- **Ahara:** Food and eating practices.
- **Vihara:** Lifestyle and daily habits.

### The three doshas
- Vata is traditionally associated with movement.
- Pitta is traditionally associated with transformation and metabolism.
- Kapha is traditionally associated with structure and stability.

### An important distinction
Ayurveda is an important part of India's traditional knowledge and cultural heritage. Traditional explanations are not automatically equivalent to modern scientific evidence. Some practices have limited research, and treatments should not replace appropriate medical care.

Avoid taking herbs or preparations without checking their safety with a qualified healthcare professional.
''',
    ),

    _WellnessTopic(
      'dosha',
      ['dosha', 'doshas', 'vata', 'pitta', 'kapha', 'prakriti', 'constitution'],
      '''
## Understanding Vata, Pitta and Kapha

In Ayurvedic tradition, doshas are three conceptual patterns used to describe bodily and mental tendencies.

### Vata
Traditionally associated with movement, communication and activity.

### Pitta
Traditionally associated with transformation, digestion and heat.

### Kapha
Traditionally associated with structure, stability and lubrication.

### What is Prakriti?
Prakriti is the traditional Ayurvedic concept of an individual's constitution.

Dosha descriptions are part of a traditional framework, not a scientifically validated medical diagnosis. They should not be used to diagnose illness or justify restrictive diets.
''',
    ),

    _WellnessTopic(
      'daily routine',
      [
        'daily routine',
        'daily schedule',
        'routine',
        'morning routine',
        'healthy routine',
        'dinacharya',
        'organize my day',
        'schedule my day',
      ],
      '''
## Creating a balanced daily routine ⏰

A useful routine balances learning, movement, meals, rest and personal time.

### Example routine
**Morning**
- Wake up at a consistent time.
- Freshen up and drink water.
- Eat breakfast.
- Prepare for school or work.

**Daytime**
- Eat regular meals.
- Take short movement breaks.
- Spend time learning and completing responsibilities.

**Evening**
- Enjoy outdoor activity or suitable exercise.
- Have a nourishing meal.
- Spend time with family or hobbies.

**Night**
- Reduce screen distractions before bed.
- Prepare for the next day.
- Keep a consistent bedtime.

### Make the routine sustainable
1. Start with a few consistent habits.
2. Allow time for meals and breaks.
3. Avoid filling every minute with tasks.
4. Adjust the schedule to your responsibilities and sleep needs.

A good routine should support your life, not make it exhausting.
''',
    ),

    _WellnessTopic(
      'sleep',
      [
        'sleep',
        'sleep schedule',
        'better sleep',
        'sleeping',
        'insomnia',
        'sleep routine',
        'why is sleep important',
      ],
      '''
## Why is sleep important? 🌙

Sleep supports learning, memory, mood, physical recovery and general health.

### Helpful sleep habits
- Maintain a regular bedtime and wake-up time.
- Keep the sleeping environment comfortable.
- Avoid stimulating activities immediately before bed.
- Get daylight and regular activity during the day.
- Avoid caffeine late in the day.
- Give yourself enough time to sleep.

Teenagers generally need around **8–10 hours of sleep** each night. Individual needs can vary.

If sleep difficulties continue or affect everyday life, discuss them with a healthcare professional.
''',
    ),

    _WellnessTopic(
      'exercise',
      [
        'exercise',
        'fitness',
        'workout',
        'physical activity',
        'stamina',
        'flexibility',
        'strength',
        'sports',
        'yoga',
      ],
      '''
## Movement and fitness 🏃

Regular physical activity supports heart health, bones, muscles, coordination, mood and general wellbeing.

### Different forms of activity
- **Aerobic:** Walking, cycling, swimming and sports.
- **Strength:** Age-appropriate bodyweight exercises.
- **Flexibility:** Gentle stretching and mobility work.
- **Balance:** Suitable balance exercises and movement practices.

### Getting started
1. Choose activities you enjoy.
2. Warm up before vigorous activity.
3. Increase activity gradually.
4. Include rest and recovery.
5. Eat and drink adequately.

For children and teenagers, a general public-health guideline is an average of at least 60 minutes of moderate-to-vigorous activity daily across the week. Adapt activity to your ability and health.
''',
    ),

    _WellnessTopic(
      'hydration',
      [
        'water',
        'hydration',
        'drink water',
        'dehydration',
        'how much water',
        'water intake',
      ],
      '''
## Hydration and the body 💧

Water helps regulate body temperature, transport nutrients, support digestion and maintain normal body functions.

### Practical habits
- Drink water regularly throughout the day.
- Keep water available during activity.
- Drink more when conditions are hot or activity makes you sweat.
- Include water-rich foods such as fruits and vegetables.
- Do not rely only on thirst during long periods of activity.

Fluid needs vary with age, activity, climate and health. There is no single exact amount that suits everyone.
''',
    ),

    _WellnessTopic(
      'stress',
      [
        'stress',
        'anxiety',
        'relax',
        'relaxation',
        'feeling stressed',
        'tension',
        'calm down',
        'overwhelmed',
      ],
      '''
## Understanding and managing stress 🧠

Stress is a response to demands or challenging situations. A little stress can sometimes help with motivation, but persistent stress can affect sleep, concentration and mood.

### Helpful strategies
1. Break a large task into smaller steps.
2. Take short breaks.
3. Try slow, comfortable breathing.
4. Spend time doing an enjoyable activity.
5. Maintain regular meals and sleep.
6. Talk to someone you trust.

If stress becomes overwhelming or continues to interfere with everyday life, seek support from a trusted adult or qualified professional.
''',
    ),

    _WellnessTopic(
      'concentration',
      [
        'concentration',
        'focus',
        'memory',
        'study better',
        'improve focus',
        'attention',
        'productivity',
        'brain power',
      ],
      '''
## Improving concentration 📚

Concentration is influenced by sleep, environment, interest, stress and physical wellbeing.

### Practical ideas
- Choose one task at a time.
- Divide work into manageable sections.
- Keep unnecessary notifications away.
- Take short breaks between focused sessions.
- Drink water and eat regular meals.
- Get enough sleep.
- Use active recall and practice instead of only rereading.

If concentration is difficult every day, consider whether sleep, stress, workload or other factors may be contributing.
''',
    ),

    _WellnessTopic(
      'digestion',
      [
        'digestion',
        'digestive system',
        'stomach',
        'gut health',
        'digestive health',
        'constipation',
        'digestive process',
      ],
      '''
## How does digestion work?

Digestion is the process through which the body breaks food into nutrients that can be absorbed and used.

### Main stages
1. **Mouth:** Chewing breaks food into smaller pieces. Saliva begins carbohydrate digestion.
2. **Stomach:** Food mixes with acid and digestive enzymes.
3. **Small intestine:** Most nutrient digestion and absorption takes place.
4. **Large intestine:** Water is absorbed and gut bacteria process some remaining material.
5. **Elimination:** Waste leaves the body.

### Supporting digestive health
- Eat a varied diet.
- Include fibre-containing foods.
- Drink water regularly.
- Be physically active.
- Maintain regular meal habits.

Persistent pain, vomiting, blood in stool or other concerning symptoms should be assessed by a healthcare professional.
''',
    ),

    _WellnessTopic(
      'immunity',
      [
        'immunity',
        'immune system',
        'immunity boost',
        'immune health',
        'prevent illness',
      ],
      '''
## Understanding the immune system

The immune system is a network of cells, tissues and organs that helps the body recognise and respond to harmful organisms.

### Supporting general health
- Eat a varied, nourishing diet.
- Get sufficient sleep.
- Stay physically active.
- Keep vaccinations up to date as recommended.
- Wash hands regularly.
- Seek appropriate healthcare when unwell.

No single food, herb or supplement can guarantee stronger immunity or prevent every infection.
''',
    ),

    _WellnessTopic(
      'iron',
      [
        'iron',
        'iron rich',
        'iron-rich',
        'iron deficiency',
        'haemoglobin',
        'hemoglobin',
      ],
      '''
## Iron and why it matters

Iron is a mineral used to make haemoglobin, a protein in red blood cells that carries oxygen.

### Food sources
- Lentils and beans.
- Chickpeas and rajma.
- Tofu and some fortified cereals.
- Nuts and seeds.
- Meat and seafood, for people who eat them.

Vitamin C-containing foods, such as citrus fruits, can help the body absorb iron from plant foods.

Iron deficiency requires proper assessment. Do not start iron supplements without professional guidance.
''',
    ),

    _WellnessTopic(
      'calcium',
      [
        'calcium',
        'bone health',
        'strong bones',
        'calcium rich',
        'calcium-rich',
      ],
      '''
## Calcium and bone health

Calcium is important for bones, teeth, muscle contraction and nerve signalling.

### Food sources
- Milk, curd and cheese.
- Calcium-fortified alternatives.
- Certain leafy vegetables.
- Tofu made with calcium salts.
- Some nuts and seeds.

Vitamin D also supports calcium absorption. A balanced diet, regular activity and adequate sleep support healthy development.
''',
    ),

    _WellnessTopic(
      'plants',
      [
        'medicinal plant',
        'medicinal plants',
        'herbal plant',
        'herbs',
        'tulsi',
        'neem',
        'aloe vera',
        'ashwagandha',
      ],
      '''
## Medicinal plants and traditional knowledge 🌱

Plants have been used in traditional health systems for food, cultural practices and medicinal preparations.

When exploring a plant, consider:
- Its common and scientific name.
- Which part of the plant is traditionally used.
- Its documented traditional uses.
- Available scientific research.
- Possible side effects and interactions.
- Correct identification and safe handling.

A traditional use does not prove that a plant treats a disease. Some plants can be toxic or interact with medicines. Never consume an unidentified plant or use a herbal preparation as a substitute for medical care.

You can ask about a particular plant by its name.
''',
    ),

    _WellnessTopic(
      'who are you',
      [
        'who are you',
        'what can you do',
        'what are you',
        'your capabilities',
        'help me',
      ],
      '''
## I am Jeevan Sutra AI Wellness Guide 🌿

I help explain topics related to everyday wellbeing and traditional knowledge.

I can help you explore:
- Nutrition and meal ideas.
- Ayurveda and doshas.
- Daily routines and healthy habits.
- Sleep, exercise and hydration.
- Stress management and concentration.
- General health education.
- Medicinal plants and traditional knowledge.

I provide educational information, not medical diagnoses or emergency care. You can ask a question in your own words.
''',
    ),
  ];
}

class _WellnessTopic {
  final String name;
  final List<String> keywords;
  final String answer;

  const _WellnessTopic(this.name, this.keywords, this.answer);
}
