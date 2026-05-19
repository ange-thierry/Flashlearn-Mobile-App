// Assessment & Exam MCQ data — completely separate from study card data
// 5 questions per level per field + 10-question final exam mixing all levels

const Map<String, Map<String, List<Map<String, dynamic>>>> assessmentData = {
  'math': {
    'easy': [
      {'q': 'What is 7 × 8?', 'a': '56', 'opts': ['48', '54', '56', '64']},
      {'q': 'Square root of 144?', 'a': '12', 'opts': ['11', '12', '13', '14']},
      {'q': 'Degrees in a right angle?', 'a': '90°', 'opts': ['45°', '60°', '90°', '180°']},
      {'q': 'What is 15% of 200?', 'a': '30', 'opts': ['25', '30', '35', '40']},
      {'q': 'What is 2³?', 'a': '8', 'opts': ['6', '8', '9', '16']},
    ],
    'normal': [
      {'q': 'Area of circle r=7 (π≈3.14)?', 'a': '153.86', 'opts': ['43.96', '153.86', '87.92', '200.1']},
      {'q': 'Solve: 3x − 5 = 16', 'a': 'x=7', 'opts': ['x=5', 'x=6', 'x=7', 'x=8']},
      {'q': 'Slope of y = 3x + 2?', 'a': '3', 'opts': ['2', '3', '5', '6']},
      {'q': '5! (5 factorial)?', 'a': '120', 'opts': ['60', '100', '120', '240']},
      {'q': 'LCM of 4 and 6?', 'a': '12', 'opts': ['8', '10', '12', '24']},
    ],
    'hard': [
      {'q': 'Derivative of x³ + 2x²?', 'a': '3x²+4x', 'opts': ['3x+4', '3x²+4x', 'x³+4x', '3x²+2x']},
      {'q': '∫(2x+3)dx?', 'a': 'x²+3x+C', 'opts': ['2x²+3x+C', 'x²+3x+C', 'x+3+C', '2x+C']},
      {'q': 'Solve: x² − 5x + 6 = 0', 'a': 'x=2 or x=3', 'opts': ['x=1,x=6', 'x=2 or x=3', 'x=3,x=4', 'x=−2,−3']},
      {'q': 'det([[2,3],[1,4]])?', 'a': '5', 'opts': ['5', '11', '6', '8']},
      {'q': 'lim(x0) sin(x)/x?', 'a': '1', 'opts': ['0', '1', '∞', 'undefined']},
    ],
  },
  'science': {
    'easy': [
      {'q': 'Closest planet to the Sun?', 'a': 'Mercury', 'opts': ['Venus', 'Earth', 'Mercury', 'Mars']},
      {'q': 'Powerhouse of the cell?', 'a': 'Mitochondria', 'opts': ['Nucleus', 'Ribosome', 'Mitochondria', 'Golgi body']},
      {'q': 'Chemical symbol for water?', 'a': 'H₂O', 'opts': ['HO', 'H₂O', 'OH', 'H₂O₂']},
      {'q': 'Unit of electric current?', 'a': 'Ampere', 'opts': ['Volt', 'Ohm', 'Watt', 'Ampere']},
      {'q': 'Water freezing temperature?', 'a': '0°C', 'opts': ['−10°C', '0°C', '4°C', '100°C']},
    ],
    'normal': [
      {'q': "Newton's Second Law?", 'a': 'F=ma', 'opts': ['F=mv', 'F=ma', 'E=mc²', 'P=mv']},
      {'q': 'pH of pure water?', 'a': '7', 'opts': ['5', '6', '7', '8']},
      {'q': 'Atomic number of Carbon?', 'a': '6', 'opts': ['4', '6', '8', '12']},
      {'q': 'Kinetic energy formula?', 'a': 'KE=½mv²', 'opts': ['KE=mv', 'KE=½mv²', 'KE=mv²', 'KE=2mv']},
      {"q": "Avogadro's number?", 'a': '6.022×10²³', 'opts': ['6.022×10²¹', '6.022×10²³', '6.022×10²⁵', '3.14×10²³']},
    ],
    'hard': [
      {'q': 'Heisenberg Uncertainty Principle?', 'a': "Can't know position & momentum precisely", 'opts': ['Energy quantized', 'Light is a wave', "Can't know position & momentum precisely", 'Mass=energy']},
      {'q': 'Gibbs Free Energy equation?', 'a': 'G=H−TS', 'opts': ['G=H+TS', 'G=H−TS', 'G=U+PV', 'G=E−TS']},
      {'q': 'Mediator of electromagnetic force?', 'a': 'Photon', 'opts': ['Gluon', 'Graviton', 'Photon', 'W boson']},
      {'q': 'Stefan-Boltzmann law?', 'a': 'P=σAT⁴', 'opts': ['P=σAT²', 'P=σAT³', 'P=σAT⁴', 'P=AT⁴']},
      {'q': 'Role of ATP in cells?', 'a': 'Energy currency of cells', 'opts': ['Genetic storage', 'Protein builder', 'Energy currency of cells', 'Cell membrane']},
    ],
  },
  'history': {
    'easy': [
      {'q': 'Year WWII ended?', 'a': '1945', 'opts': ['1940', '1943', '1945', '1948']},
      {'q': 'First US President?', 'a': 'George Washington', 'opts': ['Thomas Jefferson', 'Abraham Lincoln', 'George Washington', 'Ben Franklin']},
      {'q': 'Year men first walked on Moon?', 'a': '1969', 'opts': ['1963', '1967', '1969', '1972']},
      {'q': 'Year the Berlin Wall fell?', 'a': '1989', 'opts': ['1985', '1987', '1989', '1991']},
      {'q': 'First country to give women the vote?', 'a': 'New Zealand', 'opts': ['USA', 'France', 'UK', 'New Zealand']},
    ],
    'normal': [
      {'q': 'Treaty ending WWI?', 'a': 'Treaty of Versailles', 'opts': ['Treaty of Paris', 'Treaty of Rome', 'Treaty of Versailles', 'Treaty of Vienna']},
      {'q': 'African country never colonized?', 'a': 'Ethiopia', 'opts': ['Nigeria', 'Ghana', 'Ethiopia', 'South Africa']},
      {'q': 'What was apartheid?', 'a': 'Racial segregation in South Africa', 'opts': ['SA war', 'Racial segregation in South Africa', 'Independence movement', 'Colonial taxation']},
      {'q': 'Last Pharaoh of Egypt?', 'a': 'Cleopatra VII', 'opts': ['Nefertiti', 'Ramesses II', 'Cleopatra VII', 'Tutankhamun']},
      {'q': 'Western Roman Empire fell in?', 'a': '476 AD', 'opts': ['350 AD', '476 AD', '528 AD', '600 AD']},
    ],
    'hard': [
      {'q': 'Sykes-Picot Agreement?', 'a': '1916 plan dividing Middle East: UK & France', 'opts': ['WWI peace deal', '1916 plan dividing Middle East: UK & France', 'Colonial charter', 'League of Nations']},
      {"q": "Mao Zedong's ideology?", 'a': 'Marxism-Leninism/Maoism', 'opts': ['Fascism', 'Democratic socialism', 'Marxism-Leninism/Maoism', 'Nationalism']},
      {'q': 'Marshall Plan?', 'a': 'US aid to rebuild post-WWII Europe', 'opts': ['NATO founding', 'US aid to rebuild post-WWII Europe', 'Korean War strategy', 'UN mission']},
      {'q': 'First UN Secretary-General?', 'a': 'Trygve Lie', 'opts': ['Hammarskjöld', 'Kofi Annan', 'Trygve Lie', 'Waldheim']},
      {'q': 'Scramble for Africa?', 'a': 'European colonization 1880s–1900s', 'opts': ['African civil wars', 'Pan-African movement', 'European colonization 1880s–1900s', 'Trans-Saharan trade']},
    ],
  },
  'geography': {
    'easy': [
      {'q': 'Largest continent?', 'a': 'Asia', 'opts': ['Africa', 'Asia', 'North America', 'Europe']},
      {'q': 'Longest river?', 'a': 'Nile', 'opts': ['Amazon', 'Yangtze', 'Nile', 'Mississippi']},
      {'q': 'Capital of Rwanda?', 'a': 'Kigali', 'opts': ['Butare', 'Gitarama', 'Kigali', 'Ruhengeri']},
      {'q': 'Number of continents?', 'a': '7', 'opts': ['5', '6', '7', '8']},
      {'q': 'Smallest country?', 'a': 'Vatican City', 'opts': ['Monaco', 'San Marino', 'Vatican City', 'Liechtenstein']},
    ],
    'normal': [
      {'q': 'What is the Ring of Fire?', 'a': 'Pacific volcanic/seismic zone', 'opts': ['Island chain', 'Pacific volcanic/seismic zone', 'Underwater mountains', 'Forest belt']},
      {'q': 'Tropic of Cancer?', 'a': '23.5°N latitude', 'opts': ['Equator', 'Arctic Circle', '23.5°N latitude', '30°N']},
      {'q': 'Country with most time zones?', 'a': 'France', 'opts': ['Russia', 'USA', 'China', 'France']},
      {'q': 'What is a fjord?', 'a': 'Long narrow sea inlet with steep sides', 'opts': ['Mountain plateau', 'Long narrow sea inlet with steep sides', 'Sand dune', 'River delta']},
      {'q': 'What is an isthmus?', 'a': 'Narrow land strip connecting two areas', 'opts': ['Wide plain', 'Narrow land strip connecting two areas', 'River mouth', 'Island chain']},
    ],
    'hard': [
      {'q': 'Coriolis effect?', 'a': "Deflection due to Earth's rotation", 'opts': ['Ocean tide', "Deflection due to Earth's rotation", 'Gravity variation', 'Pressure gradient']},
      {'q': 'Plates forming Himalayas?', 'a': 'Indian and Eurasian', 'opts': ['Pacific & N American', 'Arabian & African', 'Indian and Eurasian', 'Nazca & S American']},
      {'q': 'What causes El Niño?', 'a': 'Unusual Pacific Ocean surface warming', 'opts': ['Hurricane', 'Arctic melt', 'Unusual Pacific Ocean surface warming', 'Monsoon reversal']},
      {'q': '180° meridian significance?', 'a': 'International Date Line', 'opts': ['Prime Meridian', 'Equator', 'International Date Line', 'Polar axis']},
      {'q': 'Most UNESCO sites in Africa?', 'a': 'Ethiopia', 'opts': ['Egypt', 'South Africa', 'Morocco', 'Ethiopia']},
    ],
  },
  'literature': {
    'easy': [
      {'q': "Who wrote 'Romeo and Juliet'?", 'a': 'Shakespeare', 'opts': ['Dickens', 'Austen', 'Shakespeare', 'Twain']},
      {'q': "Who wrote '1984'?", 'a': 'George Orwell', 'opts': ['Huxley', 'George Orwell', 'Bradbury', 'H.G. Wells']},
      {'q': "Who wrote 'Pride and Prejudice'?", 'a': 'Jane Austen', 'opts': ['Charlotte Brontë', 'Mary Shelley', 'Jane Austen', 'Virginia Woolf']},
      {'q': "Who wrote 'Things Fall Apart'?", 'a': 'Chinua Achebe', 'opts': ['Soyinka', 'Ngugi', 'Chinua Achebe', 'Ben Okri']},
      {'q': "Who wrote 'The Great Gatsby'?", 'a': 'F. Scott Fitzgerald', 'opts': ['Hemingway', 'F. Scott Fitzgerald', 'Steinbeck', 'Faulkner']},
    ],
    'normal': [
      {'q': '"Wind whispered" is?', 'a': 'Personification', 'opts': ['Simile', 'Metaphor', 'Personification', 'Alliteration']},
      {'q': "Who coined 'Lost Generation'?", 'a': 'Gertrude Stein', 'opts': ['Hemingway', 'Fitzgerald', 'Gertrude Stein', 'Ezra Pound']},
      {'q': "Who wrote '100 Years of Solitude'?", 'a': 'García Márquez', 'opts': ['Borges', 'Neruda', 'García Márquez', 'Allende']},
      {'q': 'What is a Bildungsroman?', 'a': 'Coming-of-age novel', 'opts': ['Political novel', 'Coming-of-age novel', 'War narrative', 'Gothic horror']},
      {'q': 'What is dramatic irony?', 'a': "Audience knows what characters don't", 'opts': ['Situational', 'Verbal irony', "Audience knows what characters don't", 'Sarcasm']},
    ],
    'hard': [
      {'q': "Who wrote 'Death of the Author'?", 'a': 'Roland Barthes', 'opts': ['Derrida', 'Foucault', 'Roland Barthes', 'Kristeva']},
      {'q': 'What is intertextuality?', 'a': 'Texts referencing each other', 'opts': ['Chapter cross-ref', 'Texts referencing each other', 'Author bio in text', 'Translation theory']},
      {'q': 'Who developed New Criticism?', 'a': 'I.A. Richards & Cleanth Brooks', 'opts': ['Barthes', 'I.A. Richards & Cleanth Brooks', 'Derrida', 'Foucault']},
      {'q': 'Free indirect discourse?', 'a': 'Narrator adopts character voice without marking', 'opts': ['Stream of consciousness', 'Narrator adopts character voice without marking', 'Interior monologue', '3rd person narration']},
      {'q': 'What defines absurdist literature?', 'a': 'Explores meaninglessness in irrational world', 'opts': ['Existential heroism', 'Dark humor fiction', 'Explores meaninglessness in irrational world', 'Nihilistic poetry']},
    ],
  },
  'cs': {
    'easy': [
      {'q': 'CPU stands for?', 'a': 'Central Processing Unit', 'opts': ['Central Program Unit', 'Computer Processing Unit', 'Central Processing Unit', 'Core Utility']},
      {'q': 'RAM stands for?', 'a': 'Random Access Memory', 'opts': ['Read Access Memory', 'Random Access Memory', 'Rapid Access Module', 'Read And Modify']},
      {'q': 'HTML stands for?', 'a': 'HyperText Markup Language', 'opts': ['High Transfer ML', 'HyperText Markup Language', 'Hyperlink Text Mgmt', 'High-Tech ML']},
      {'q': 'Binary system uses?', 'a': 'Base-2 (0s and 1s)', 'opts': ['Base-8', 'Base-2 (0s and 1s)', 'Base-16', 'Hexadecimal']},
      {'q': 'What is a pixel?', 'a': 'Smallest unit of a digital image', 'opts': ['Color code', 'Smallest unit of a digital image', 'Resolution unit', 'Bitmap format']},
    ],
    'normal': [
      {'q': 'Big O notation?', 'a': 'Describes algorithm time/space complexity', 'opts': ['A sorting method', 'Describes algorithm time/space complexity', 'Binary operation', 'OOP notation']},
      {'q': 'Stack vs Queue?', 'a': 'Stack=LIFO; Queue=FIFO', 'opts': ['Stack=FIFO; Queue=LIFO', 'Stack=LIFO; Queue=FIFO', 'Both LIFO', 'Both FIFO']},
      {'q': 'What is recursion?', 'a': 'A function that calls itself', 'opts': ['A loop', 'A function that calls itself', 'Array iteration', 'Nested class']},
      {'q': 'REST API?', 'a': 'Web service architecture using HTTP methods', 'opts': ['DB protocol', 'Web service architecture using HTTP methods', 'A language', 'Frontend framework']},
      {'q': 'Hash function purpose?', 'a': 'Maps data to fixed-size for fast lookup', 'opts': ['Encrypts permanently', 'Maps data to fixed-size for fast lookup', 'Compresses files', 'Sorts arrays']},
    ],
    'hard': [
      {'q': 'Dynamic programming?', 'a': 'Caching overlapping subproblem results', 'opts': ['Recursive backtracking', 'Caching overlapping subproblem results', 'Greedy algorithm', 'Divide & conquer without caching']},
      {'q': 'CAP theorem?', 'a': 'Pick 2 of: Consistency, Availability, Partition tolerance', 'opts': ['Cryptography standard', 'Pick 2 of: Consistency, Availability, Partition tolerance', 'DB indexing rule', 'Network latency formula']},
      {'q': 'What is a deadlock?', 'a': "Processes waiting for each other's resources", 'opts': ['Memory overflow', "Processes waiting for each other's resources", 'CPU overload', 'Thread failure']},
      {'q': 'Public-key cryptography?', 'a': 'Public key encrypts; private key decrypts', 'opts': ['Symmetric encryption', 'Public key encrypts; private key decrypts', 'Hash encoding', 'Password hashing']},
      {'q': 'Halting problem?', 'a': 'No algorithm determines if all programs halt', 'opts': ['Loop detection', 'No algorithm determines if all programs halt', 'NP-complete problem', 'Memory leak issue']},
    ],
  },
};

// Final exam: 4 easy + 3 normal + 3 hard = 10 questions per field
Map<String, List<Map<String, dynamic>>> getFinalExamQuestions(String fieldId) {
  final data = assessmentData[fieldId] ?? assessmentData['math']!;
  return {
    'questions': [
      ...data['easy']!.take(4),
      ...data['normal']!.take(3),
      ...data['hard']!.take(3),
    ]
  };
}
