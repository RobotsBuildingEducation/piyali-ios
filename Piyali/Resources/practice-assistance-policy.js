var OriginalPracticeAssistance = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // <stdin>
  var stdin_exports = {};
  __export(stdin_exports, {
    api: () => api
  });

  // ../nosabos/nosabos/src/utils/sentenceDetectiveI18n.js
  var SENTENCE_DETECTIVE_COPY = Object.freeze({
    en: {
      title: "Sentence Detective",
      description: "First find the word that breaks the sentence. Then choose the repair.",
      stepOfTwo: "Step {step} of 2",
      findMistake: "Find the mistake",
      repairIt: "Repair it",
      findTitle: "Which word doesn\u2019t belong?",
      findHelp: "Tap the one word or phrase that makes the sentence sound wrong.",
      foundTitle: "You found it!",
      brokenPart: "\u201C{token}\u201D is the broken part.",
      wrongTitle: "That word works here.",
      wrongHelp: "Try another word\u2014the broken one changes the sentence\u2019s meaning or grammar.",
      chooseRepair: "Choose the repair",
      replaceWith: "Replace \u201C{token}\u201D with the option that makes the whole sentence work.",
      repairedSentence: "Your repaired sentence",
      askForHelp: "Ask for help",
      helpRequest: "Help me understand what to look for in this sentence without giving me the answer: \u201C{sentence}\u201D",
      clue: "Clue",
      checking: "Checking\u2026",
      skip: "Skip",
      submit: "Submit",
      checkRepair: "Check my repair",
      chooseRepairAbove: "Choose a repair above",
      caseSolved: "Case solved!",
      notQuite: "Not quite\u2014here\u2019s the pattern.",
      tryAgain: "Try again",
      nextQuestion: "Next question",
      seeResults: "See results",
      quizComplete: "Quiz complete!",
      keepExploring: "Keep exploring the patterns",
      correctCount: "{correct} of {total} correct",
      continue: "Continue",
      building: "Building sentence detective\u2026",
      noClearCase: "No clear case was generated",
      generationFailed: "We couldn't build a clear Sentence Detective question this time.",
      tryAnother: "Try another case",
      generateAnother: "Generate another example",
      testingGate: "Testing gate",
      testingGrammar: "Only Sentence Detective renders while we refine its grammar experience.",
      testingVocabulary: "Only Sentence Detective renders while we refine its vocabulary experience."
    },
    es: {
      title: "Detective de oraciones",
      description: "Primero encuentra la palabra que rompe la oraci\xF3n. Luego elige la correcci\xF3n.",
      stepOfTwo: "Paso {step} de 2",
      findMistake: "Encuentra el error",
      repairIt: "Corr\xEDgelo",
      findTitle: "\xBFQu\xE9 palabra no encaja?",
      findHelp: "Toca la \xFAnica palabra o frase que hace que la oraci\xF3n suene mal.",
      foundTitle: "\xA1La encontraste!",
      brokenPart: "\xAB{token}\xBB es la parte incorrecta.",
      wrongTitle: "Esa palabra s\xED encaja aqu\xED.",
      wrongHelp: "Prueba otra palabra; la incorrecta cambia el significado o la gram\xE1tica de la oraci\xF3n.",
      chooseRepair: "Elige la correcci\xF3n",
      replaceWith: "Sustituye \xAB{token}\xBB por la opci\xF3n que hace que toda la oraci\xF3n funcione.",
      repairedSentence: "Tu oraci\xF3n corregida",
      askForHelp: "Pedir ayuda",
      helpRequest: "Ay\xFAdame a entender qu\xE9 debo buscar en esta oraci\xF3n sin decirme la respuesta: \xAB{sentence}\xBB",
      clue: "Pista",
      checking: "Comprobando\u2026",
      skip: "Saltar",
      submit: "Comprobar",
      checkRepair: "Comprobar mi correcci\xF3n",
      chooseRepairAbove: "Elige una correcci\xF3n arriba",
      caseSolved: "\xA1Caso resuelto!",
      notQuite: "Casi; aqu\xED est\xE1 el patr\xF3n.",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta",
      seeResults: "Ver resultados",
      quizComplete: "\xA1Cuestionario completado!",
      keepExploring: "Sigue explorando los patrones",
      correctCount: "{correct} de {total} correctas",
      continue: "Continuar",
      building: "Creando el caso de la oraci\xF3n\u2026",
      noClearCase: "No se gener\xF3 un caso claro",
      generationFailed: "Esta vez no pudimos crear una pregunta clara de Detective de oraciones.",
      tryAnother: "Probar otro caso",
      generateAnother: "Generar otro ejemplo",
      testingGate: "Entorno de prueba",
      testingGrammar: "Solo aparece Detective de oraciones mientras refinamos su experiencia de gram\xE1tica.",
      testingVocabulary: "Solo aparece Detective de oraciones mientras refinamos su experiencia de vocabulario."
    },
    pt: {
      title: "Detetive de frases",
      description: "Primeiro, encontre a palavra que deixa a frase errada. Depois, escolha a corre\xE7\xE3o.",
      stepOfTwo: "Etapa {step} de 2",
      findMistake: "Encontre o erro",
      repairIt: "Corrija",
      findTitle: "Qual palavra n\xE3o se encaixa?",
      findHelp: "Toque na \xFAnica palavra ou express\xE3o que faz a frase parecer errada.",
      foundTitle: "Voc\xEA encontrou!",
      brokenPart: "\u201C{token}\u201D \xE9 a parte incorreta.",
      wrongTitle: "Essa palavra funciona aqui.",
      wrongHelp: "Tente outra palavra; a incorreta muda o sentido ou a gram\xE1tica da frase.",
      chooseRepair: "Escolha a corre\xE7\xE3o",
      replaceWith: "Substitua \u201C{token}\u201D pela op\xE7\xE3o que faz a frase inteira funcionar.",
      repairedSentence: "Sua frase corrigida",
      askForHelp: "Pedir ajuda",
      helpRequest: "Ajude-me a entender o que devo procurar nesta frase sem revelar a resposta: \u201C{sentence}\u201D",
      clue: "Pista",
      checking: "Verificando\u2026",
      skip: "Pular",
      submit: "Enviar",
      checkRepair: "Verificar minha corre\xE7\xE3o",
      chooseRepairAbove: "Escolha uma corre\xE7\xE3o acima",
      caseSolved: "Caso resolvido!",
      notQuite: "Ainda n\xE3o; veja o padr\xE3o.",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta",
      seeResults: "Ver resultados",
      quizComplete: "Question\xE1rio conclu\xEDdo!",
      keepExploring: "Continue explorando os padr\xF5es",
      correctCount: "{correct} de {total} corretas",
      continue: "Continuar",
      building: "Criando o caso da frase\u2026",
      noClearCase: "Nenhum caso claro foi gerado",
      generationFailed: "N\xE3o conseguimos criar uma pergunta clara de Detetive de frases desta vez.",
      tryAnother: "Tentar outro caso",
      generateAnother: "Gerar outro exemplo",
      testingGate: "Ambiente de teste",
      testingGrammar: "Apenas o Detetive de frases aparece enquanto refinamos a experi\xEAncia de gram\xE1tica.",
      testingVocabulary: "Apenas o Detetive de frases aparece enquanto refinamos a experi\xEAncia de vocabul\xE1rio."
    },
    it: {
      title: "Detective della frase",
      description: "Prima trova la parola che rende sbagliata la frase. Poi scegli la correzione.",
      stepOfTwo: "Passaggio {step} di 2",
      findMistake: "Trova l\u2019errore",
      repairIt: "Correggilo",
      findTitle: "Quale parola non va bene?",
      findHelp: "Tocca l\u2019unica parola o espressione che fa sembrare sbagliata la frase.",
      foundTitle: "L\u2019hai trovata!",
      brokenPart: "\xAB{token}\xBB \xE8 la parte sbagliata.",
      wrongTitle: "Questa parola va bene qui.",
      wrongHelp: "Prova un\u2019altra parola: quella sbagliata cambia il significato o la grammatica della frase.",
      chooseRepair: "Scegli la correzione",
      replaceWith: "Sostituisci \xAB{token}\xBB con l\u2019opzione che rende corretta l\u2019intera frase.",
      repairedSentence: "La frase corretta",
      askForHelp: "Chiedi aiuto",
      helpRequest: "Aiutami a capire cosa devo cercare in questa frase senza darmi la risposta: \xAB{sentence}\xBB",
      clue: "Indizio",
      checking: "Controllo\u2026",
      skip: "Salta",
      submit: "Invia",
      checkRepair: "Controlla la correzione",
      chooseRepairAbove: "Scegli una correzione qui sopra",
      caseSolved: "Caso risolto!",
      notQuite: "Non proprio: ecco lo schema.",
      tryAgain: "Riprova",
      nextQuestion: "Domanda successiva",
      seeResults: "Vedi i risultati",
      quizComplete: "Quiz completato!",
      keepExploring: "Continua a esplorare gli schemi",
      correctCount: "{correct} su {total} corrette",
      continue: "Continua",
      building: "Creazione del caso\u2026",
      noClearCase: "Non \xE8 stato generato un caso chiaro",
      generationFailed: "Questa volta non siamo riusciti a creare una domanda chiara.",
      tryAnother: "Prova un altro caso",
      generateAnother: "Genera un altro esempio",
      testingGate: "Ambiente di prova",
      testingGrammar: "Mostriamo solo Detective della frase mentre perfezioniamo l\u2019esperienza di grammatica.",
      testingVocabulary: "Mostriamo solo Detective della frase mentre perfezioniamo l\u2019esperienza di vocabolario."
    },
    fr: {
      title: "D\xE9tective de phrases",
      description: "Trouvez d\u2019abord le mot qui rend la phrase incorrecte, puis choisissez la correction.",
      stepOfTwo: "\xC9tape {step} sur 2",
      findMistake: "Trouver l\u2019erreur",
      repairIt: "La corriger",
      findTitle: "Quel mot ne convient pas ?",
      findHelp: "Touchez le seul mot ou groupe de mots qui rend la phrase incorrecte.",
      foundTitle: "Vous l\u2019avez trouv\xE9 !",
      brokenPart: "\xAB {token} \xBB est la partie incorrecte.",
      wrongTitle: "Ce mot convient ici.",
      wrongHelp: "Essayez un autre mot : celui qui est incorrect change le sens ou la grammaire de la phrase.",
      chooseRepair: "Choisir la correction",
      replaceWith: "Remplacez \xAB {token} \xBB par l\u2019option qui rend toute la phrase correcte.",
      repairedSentence: "Votre phrase corrig\xE9e",
      askForHelp: "Demander de l\u2019aide",
      helpRequest: "Aidez-moi \xE0 comprendre ce que je dois chercher dans cette phrase sans me donner la r\xE9ponse : \xAB {sentence} \xBB",
      clue: "Indice",
      checking: "V\xE9rification\u2026",
      skip: "Passer",
      submit: "Valider",
      checkRepair: "V\xE9rifier ma correction",
      chooseRepairAbove: "Choisissez une correction ci-dessus",
      caseSolved: "Affaire r\xE9solue !",
      notQuite: "Pas tout \xE0 fait : voici la r\xE8gle.",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante",
      seeResults: "Voir les r\xE9sultats",
      quizComplete: "Quiz termin\xE9 !",
      keepExploring: "Continuez \xE0 explorer les r\xE8gles",
      correctCount: "{correct} bonnes r\xE9ponses sur {total}",
      continue: "Continuer",
      building: "Cr\xE9ation du cas\u2026",
      noClearCase: "Aucun cas clair n\u2019a \xE9t\xE9 g\xE9n\xE9r\xE9",
      generationFailed: "Nous n\u2019avons pas pu cr\xE9er une question claire cette fois-ci.",
      tryAnother: "Essayer un autre cas",
      generateAnother: "G\xE9n\xE9rer un autre exemple",
      testingGate: "Environnement de test",
      testingGrammar: "Seul D\xE9tective de phrases appara\xEEt pendant que nous affinons l\u2019exp\xE9rience de grammaire.",
      testingVocabulary: "Seul D\xE9tective de phrases appara\xEEt pendant que nous affinons l\u2019exp\xE9rience de vocabulaire."
    },
    de: {
      title: "Satzdetektiv",
      description: "Finde zuerst das Wort, das den Satz falsch macht. W\xE4hle dann die Korrektur.",
      stepOfTwo: "Schritt {step} von 2",
      findMistake: "Fehler finden",
      repairIt: "Korrigieren",
      findTitle: "Welches Wort passt nicht?",
      findHelp: "Tippe auf das eine Wort oder den Ausdruck, durch den der Satz falsch klingt.",
      foundTitle: "Gefunden!",
      brokenPart: "\u201E{token}\u201C ist die fehlerhafte Stelle.",
      wrongTitle: "Dieses Wort passt hier.",
      wrongHelp: "Probiere ein anderes Wort. Das fehlerhafte Wort ver\xE4ndert die Bedeutung oder Grammatik des Satzes.",
      chooseRepair: "Korrektur w\xE4hlen",
      replaceWith: "Ersetze \u201E{token}\u201C durch die Option, die den ganzen Satz richtig macht.",
      repairedSentence: "Dein korrigierter Satz",
      askForHelp: "Um Hilfe bitten",
      helpRequest: "Hilf mir zu verstehen, worauf ich in diesem Satz achten soll, ohne mir die Antwort zu verraten: \u201E{sentence}\u201C",
      clue: "Hinweis",
      checking: "Wird gepr\xFCft\u2026",
      skip: "\xDCberspringen",
      submit: "Absenden",
      checkRepair: "Korrektur pr\xFCfen",
      chooseRepairAbove: "W\xE4hle oben eine Korrektur",
      caseSolved: "Fall gel\xF6st!",
      notQuite: "Noch nicht ganz \u2013 hier ist die Regel.",
      tryAgain: "Erneut versuchen",
      nextQuestion: "N\xE4chste Frage",
      seeResults: "Ergebnisse anzeigen",
      quizComplete: "Quiz abgeschlossen!",
      keepExploring: "Erkunde die Regeln weiter",
      correctCount: "{correct} von {total} richtig",
      continue: "Weiter",
      building: "Satzfall wird erstellt\u2026",
      noClearCase: "Es wurde kein eindeutiger Fall erstellt",
      generationFailed: "Diesmal konnte keine eindeutige Satzdetektiv-Frage erstellt werden.",
      tryAnother: "Anderen Fall versuchen",
      generateAnother: "Weiteres Beispiel erstellen",
      testingGate: "Testumgebung",
      testingGrammar: "W\xE4hrend wir die Grammatikaufgabe verbessern, wird nur der Satzdetektiv angezeigt.",
      testingVocabulary: "W\xE4hrend wir die Wortschatzaufgabe verbessern, wird nur der Satzdetektiv angezeigt."
    },
    ja: {
      title: "\u6587\u306E\u63A2\u5075",
      description: "\u307E\u305A\u6587\u3092\u304A\u304B\u3057\u304F\u3057\u3066\u3044\u308B\u8A9E\u3092\u898B\u3064\u3051\u3001\u6B21\u306B\u6B63\u3057\u3044\u8A9E\u3092\u9078\u3073\u307E\u3059\u3002",
      stepOfTwo: "\u30B9\u30C6\u30C3\u30D7 {step}/2",
      findMistake: "\u307E\u3061\u304C\u3044\u3092\u898B\u3064\u3051\u308B",
      repairIt: "\u6587\u3092\u76F4\u3059",
      findTitle: "\u3069\u306E\u8A9E\u304C\u5408\u3063\u3066\u3044\u307E\u305B\u3093\u304B\uFF1F",
      findHelp: "\u6587\u3092\u304A\u304B\u3057\u304F\u3057\u3066\u3044\u308B\u8A9E\u307E\u305F\u306F\u8868\u73FE\u30921\u3064\u30BF\u30C3\u30D7\u3057\u3066\u304F\u3060\u3055\u3044\u3002",
      foundTitle: "\u898B\u3064\u3051\u307E\u3057\u305F\uFF01",
      brokenPart: "\u300C{token}\u300D\u304C\u307E\u3061\u304C\u3063\u3066\u3044\u308B\u90E8\u5206\u3067\u3059\u3002",
      wrongTitle: "\u3053\u306E\u8A9E\u306F\u3053\u3053\u3067\u4F7F\u3048\u307E\u3059\u3002",
      wrongHelp: "\u5225\u306E\u8A9E\u3092\u8A66\u3057\u3066\u304F\u3060\u3055\u3044\u3002\u307E\u3061\u304C\u3063\u305F\u8A9E\u306F\u6587\u306E\u610F\u5473\u307E\u305F\u306F\u6587\u6CD5\u3092\u5909\u3048\u3066\u3057\u307E\u3044\u307E\u3059\u3002",
      chooseRepair: "\u6B63\u3057\u3044\u8A9E\u3092\u9078\u3076",
      replaceWith: "\u300C{token}\u300D\u3092\u6587\u5168\u4F53\u304C\u6B63\u3057\u304F\u306A\u308B\u9078\u629E\u80A2\u306B\u7F6E\u304D\u63DB\u3048\u3066\u304F\u3060\u3055\u3044\u3002",
      repairedSentence: "\u76F4\u3057\u305F\u6587",
      askForHelp: "\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u7B54\u3048\u3092\u8A00\u308F\u305A\u306B\u3001\u3053\u306E\u6587\u306E\u3069\u3053\u306B\u6CE8\u76EE\u3059\u308C\u3070\u3088\u3044\u304B\u6559\u3048\u3066\u304F\u3060\u3055\u3044\uFF1A\u300C{sentence}\u300D",
      clue: "\u30D2\u30F3\u30C8",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u9001\u4FE1",
      checkRepair: "\u76F4\u3057\u305F\u6587\u3092\u78BA\u8A8D",
      chooseRepairAbove: "\u4E0A\u304B\u3089\u6B63\u3057\u3044\u8A9E\u3092\u9078\u3093\u3067\u304F\u3060\u3055\u3044",
      caseSolved: "\u89E3\u6C7A\u3057\u307E\u3057\u305F\uFF01",
      notQuite: "\u3082\u3046\u5C11\u3057\u3067\u3059\u3002\u898F\u5247\u3092\u78BA\u8A8D\u3057\u307E\u3057\u3087\u3046\u3002",
      tryAgain: "\u3082\u3046\u4E00\u5EA6",
      nextQuestion: "\u6B21\u306E\u554F\u984C",
      seeResults: "\u7D50\u679C\u3092\u898B\u308B",
      quizComplete: "\u30AF\u30A4\u30BA\u5B8C\u4E86\uFF01",
      keepExploring: "\u898F\u5247\u3092\u3055\u3089\u306B\u7DF4\u7FD2\u3057\u307E\u3057\u3087\u3046",
      correctCount: "{total}\u554F\u4E2D{correct}\u554F\u6B63\u89E3",
      continue: "\u7D9A\u3051\u308B",
      building: "\u554F\u984C\u3092\u4F5C\u6210\u4E2D\u2026",
      noClearCase: "\u660E\u78BA\u306A\u554F\u984C\u3092\u4F5C\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F",
      generationFailed: "\u4ECA\u56DE\u306F\u660E\u78BA\u306A\u6587\u306E\u63A2\u5075\u554F\u984C\u3092\u4F5C\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002",
      tryAnother: "\u5225\u306E\u554F\u984C\u3092\u8A66\u3059",
      generateAnother: "\u5225\u306E\u4F8B\u3092\u4F5C\u6210",
      testingGate: "\u30C6\u30B9\u30C8\u74B0\u5883",
      testingGrammar: "\u6587\u6CD5\u4F53\u9A13\u306E\u8ABF\u6574\u4E2D\u306F\u3001\u6587\u306E\u63A2\u5075\u3060\u3051\u3092\u8868\u793A\u3057\u307E\u3059\u3002",
      testingVocabulary: "\u8A9E\u5F59\u4F53\u9A13\u306E\u8ABF\u6574\u4E2D\u306F\u3001\u6587\u306E\u63A2\u5075\u3060\u3051\u3092\u8868\u793A\u3057\u307E\u3059\u3002"
    },
    hi: {
      title: "\u0935\u093E\u0915\u094D\u092F \u091C\u093E\u0938\u0942\u0938",
      description: "\u092A\u0939\u0932\u0947 \u0935\u0939 \u0936\u092C\u094D\u0926 \u0922\u0942\u0901\u0922\u0947\u0902 \u091C\u094B \u0935\u093E\u0915\u094D\u092F \u0915\u094B \u0917\u0932\u0924 \u092C\u0928\u093E\u0924\u093E \u0939\u0948\u0964 \u092B\u093F\u0930 \u0938\u0939\u0940 \u0936\u092C\u094D\u0926 \u091A\u0941\u0928\u0947\u0902\u0964",
      stepOfTwo: "\u091A\u0930\u0923 {step}/2",
      findMistake: "\u0917\u0932\u0924\u0940 \u0922\u0942\u0901\u0922\u0947\u0902",
      repairIt: "\u0907\u0938\u0947 \u0938\u0941\u0927\u093E\u0930\u0947\u0902",
      findTitle: "\u0915\u094C\u0928-\u0938\u093E \u0936\u092C\u094D\u0926 \u092F\u0939\u093E\u0901 \u0920\u0940\u0915 \u0928\u0939\u0940\u0902 \u0939\u0948?",
      findHelp: "\u0909\u0938 \u090F\u0915 \u0936\u092C\u094D\u0926 \u092F\u093E \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u092A\u0930 \u091F\u0948\u092A \u0915\u0930\u0947\u0902 \u091C\u093F\u0938\u0938\u0947 \u0935\u093E\u0915\u094D\u092F \u0917\u0932\u0924 \u0932\u0917\u0924\u093E \u0939\u0948\u0964",
      foundTitle: "\u0906\u092A\u0928\u0947 \u0922\u0942\u0901\u0922 \u0932\u093F\u092F\u093E!",
      brokenPart: "\u201C{token}\u201D \u0917\u0932\u0924 \u0939\u093F\u0938\u094D\u0938\u093E \u0939\u0948\u0964",
      wrongTitle: "\u092F\u0939 \u0936\u092C\u094D\u0926 \u092F\u0939\u093E\u0901 \u0938\u0939\u0940 \u0939\u0948\u0964",
      wrongHelp: "\u0915\u094B\u0908 \u0926\u0942\u0938\u0930\u093E \u0936\u092C\u094D\u0926 \u0906\u091C\u093C\u092E\u093E\u090F\u0901\u0964 \u0917\u0932\u0924 \u0936\u092C\u094D\u0926 \u0935\u093E\u0915\u094D\u092F \u0915\u0947 \u0905\u0930\u094D\u0925 \u092F\u093E \u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u0915\u094B \u092C\u0926\u0932\u0924\u093E \u0939\u0948\u0964",
      chooseRepair: "\u0938\u0939\u0940 \u0936\u092C\u094D\u0926 \u091A\u0941\u0928\u0947\u0902",
      replaceWith: "\u201C{token}\u201D \u0915\u0940 \u091C\u0917\u0939 \u0935\u0939 \u0935\u093F\u0915\u0932\u094D\u092A \u091A\u0941\u0928\u0947\u0902 \u091C\u093F\u0938\u0938\u0947 \u092A\u0942\u0930\u093E \u0935\u093E\u0915\u094D\u092F \u0938\u0939\u0940 \u0939\u094B \u091C\u093E\u090F\u0964",
      repairedSentence: "\u0906\u092A\u0915\u093E \u0938\u0941\u0927\u093E\u0930\u093E \u0939\u0941\u0906 \u0935\u093E\u0915\u094D\u092F",
      askForHelp: "\u092E\u0926\u0926 \u092E\u093E\u0901\u0917\u0947\u0902",
      helpRequest: "\u0909\u0924\u094D\u0924\u0930 \u092C\u0924\u093E\u090F \u092C\u093F\u0928\u093E \u092F\u0939 \u0938\u092E\u091D\u0928\u0947 \u092E\u0947\u0902 \u092E\u0947\u0930\u0940 \u092E\u0926\u0926 \u0915\u0930\u0947\u0902 \u0915\u093F \u0907\u0938 \u0935\u093E\u0915\u094D\u092F \u092E\u0947\u0902 \u092E\u0941\u091D\u0947 \u0915\u094D\u092F\u093E \u0926\u0947\u0916\u0928\u093E \u091A\u093E\u0939\u093F\u090F: \u201C{sentence}\u201D",
      clue: "\u0938\u0902\u0915\u0947\u0924",
      checking: "\u091C\u093E\u0901\u091A \u0939\u094B \u0930\u0939\u0940 \u0939\u0948\u2026",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u092E\u093E \u0915\u0930\u0947\u0902",
      checkRepair: "\u0938\u0941\u0927\u093E\u0930 \u0915\u0940 \u091C\u093E\u0901\u091A \u0915\u0930\u0947\u0902",
      chooseRepairAbove: "\u090A\u092A\u0930 \u0938\u0947 \u0938\u0939\u0940 \u0936\u092C\u094D\u0926 \u091A\u0941\u0928\u0947\u0902",
      caseSolved: "\u092E\u093E\u092E\u0932\u093E \u0939\u0932 \u0939\u094B \u0917\u092F\u093E!",
      notQuite: "\u0905\u092D\u0940 \u092A\u0942\u0930\u0940 \u0924\u0930\u0939 \u0928\u0939\u0940\u0902\u2014\u092F\u0939 \u0928\u093F\u092F\u092E \u0926\u0947\u0916\u0947\u0902\u0964",
      tryAgain: "\u092B\u093F\u0930 \u0915\u094B\u0936\u093F\u0936 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928",
      seeResults: "\u092A\u0930\u093F\u0923\u093E\u092E \u0926\u0947\u0916\u0947\u0902",
      quizComplete: "\u0915\u094D\u0935\u093F\u091C\u093C \u092A\u0942\u0930\u093E \u0939\u0941\u0906!",
      keepExploring: "\u0928\u093F\u092F\u092E\u094B\u0902 \u0915\u094B \u0938\u092E\u091D\u0928\u0947 \u0915\u093E \u0905\u092D\u094D\u092F\u093E\u0938 \u091C\u093E\u0930\u0940 \u0930\u0916\u0947\u0902",
      correctCount: "{total} \u092E\u0947\u0902 \u0938\u0947 {correct} \u0938\u0939\u0940",
      continue: "\u091C\u093E\u0930\u0940 \u0930\u0916\u0947\u0902",
      building: "\u0935\u093E\u0915\u094D\u092F \u0915\u093E \u092E\u093E\u092E\u0932\u093E \u092C\u0928\u093E\u092F\u093E \u091C\u093E \u0930\u0939\u093E \u0939\u0948\u2026",
      noClearCase: "\u0938\u094D\u092A\u0937\u094D\u091F \u092E\u093E\u092E\u0932\u093E \u0928\u0939\u0940\u0902 \u092C\u0928 \u0938\u0915\u093E",
      generationFailed: "\u0907\u0938 \u092C\u093E\u0930 \u0938\u094D\u092A\u0937\u094D\u091F \u0935\u093E\u0915\u094D\u092F \u091C\u093E\u0938\u0942\u0938 \u092A\u094D\u0930\u0936\u094D\u0928 \u0928\u0939\u0940\u0902 \u092C\u0928 \u0938\u0915\u093E\u0964",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u092E\u093E\u092E\u0932\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0901",
      generateAnother: "\u090F\u0915 \u0914\u0930 \u0909\u0926\u093E\u0939\u0930\u0923 \u092C\u0928\u093E\u090F\u0901",
      testingGate: "\u092A\u0930\u0940\u0915\u094D\u0937\u0923 \u092A\u0930\u093F\u0935\u0947\u0936",
      testingGrammar: "\u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u0905\u0928\u0941\u092D\u0935 \u0915\u094B \u092C\u0947\u0939\u0924\u0930 \u092C\u0928\u093E\u0924\u0947 \u0938\u092E\u092F \u0915\u0947\u0935\u0932 \u0935\u093E\u0915\u094D\u092F \u091C\u093E\u0938\u0942\u0938 \u0926\u093F\u0916\u093E\u092F\u093E \u091C\u093E\u0924\u093E \u0939\u0948\u0964",
      testingVocabulary: "\u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u0905\u0928\u0941\u092D\u0935 \u0915\u094B \u092C\u0947\u0939\u0924\u0930 \u092C\u0928\u093E\u0924\u0947 \u0938\u092E\u092F \u0915\u0947\u0935\u0932 \u0935\u093E\u0915\u094D\u092F \u091C\u093E\u0938\u0942\u0938 \u0926\u093F\u0916\u093E\u092F\u093E \u091C\u093E\u0924\u093E \u0939\u0948\u0964"
    },
    ar: {
      title: "\u0645\u062D\u0642\u0651\u0642 \u0627\u0644\u062C\u0645\u0644\u0629",
      description: "\u0627\u0628\u062D\u062B \u0623\u0648\u0644\u064B\u0627 \u0639\u0646 \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u062A\u064A \u062A\u062C\u0639\u0644 \u0627\u0644\u062C\u0645\u0644\u0629 \u062E\u0627\u0637\u0626\u0629\u060C \u062B\u0645 \u0627\u062E\u062A\u0631 \u0627\u0644\u062A\u0635\u062D\u064A\u062D.",
      stepOfTwo: "\u0627\u0644\u062E\u0637\u0648\u0629 {step} \u0645\u0646 2",
      findMistake: "\u0627\u0643\u062A\u0634\u0641 \u0627\u0644\u062E\u0637\u0623",
      repairIt: "\u0635\u062D\u0651\u062D\u0647",
      findTitle: "\u0623\u064A \u0643\u0644\u0645\u0629 \u0644\u0627 \u062A\u0646\u0627\u0633\u0628 \u0627\u0644\u062C\u0645\u0644\u0629\u061F",
      findHelp: "\u0627\u0636\u063A\u0637 \u0639\u0644\u0649 \u0627\u0644\u0643\u0644\u0645\u0629 \u0623\u0648 \u0627\u0644\u0639\u0628\u0627\u0631\u0629 \u0627\u0644\u0648\u062D\u064A\u062F\u0629 \u0627\u0644\u062A\u064A \u062A\u062C\u0639\u0644 \u0627\u0644\u062C\u0645\u0644\u0629 \u062E\u0627\u0637\u0626\u0629.",
      foundTitle: "\u0648\u062C\u062F\u062A\u0647\u0627!",
      brokenPart: "\xAB{token}\xBB \u0647\u064A \u0627\u0644\u062C\u0632\u0621 \u0627\u0644\u062E\u0637\u0623.",
      wrongTitle: "\u0647\u0630\u0647 \u0627\u0644\u0643\u0644\u0645\u0629 \u0645\u0646\u0627\u0633\u0628\u0629 \u0647\u0646\u0627.",
      wrongHelp: "\u062C\u0631\u0651\u0628 \u0643\u0644\u0645\u0629 \u0623\u062E\u0631\u0649\u061B \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u062E\u0637\u0623 \u062A\u063A\u064A\u0651\u0631 \u0645\u0639\u0646\u0649 \u0627\u0644\u062C\u0645\u0644\u0629 \u0623\u0648 \u0642\u0648\u0627\u0639\u062F\u0647\u0627.",
      chooseRepair: "\u0627\u062E\u062A\u0631 \u0627\u0644\u062A\u0635\u062D\u064A\u062D",
      replaceWith: "\u0627\u0633\u062A\u0628\u062F\u0644 \xAB{token}\xBB \u0628\u0627\u0644\u062E\u064A\u0627\u0631 \u0627\u0644\u0630\u064A \u064A\u062C\u0639\u0644 \u0627\u0644\u062C\u0645\u0644\u0629 \u0643\u0644\u0647\u0627 \u0635\u062D\u064A\u062D\u0629.",
      repairedSentence: "\u0627\u0644\u062C\u0645\u0644\u0629 \u0628\u0639\u062F \u0627\u0644\u062A\u0635\u062D\u064A\u062D",
      askForHelp: "\u0627\u0637\u0644\u0628 \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629",
      helpRequest: "\u0633\u0627\u0639\u062F\u0646\u064A \u0639\u0644\u0649 \u0641\u0647\u0645 \u0645\u0627 \u0627\u0644\u0630\u064A \u064A\u062C\u0628 \u0623\u0646 \u0623\u0628\u062D\u062B \u0639\u0646\u0647 \u0641\u064A \u0647\u0630\u0647 \u0627\u0644\u062C\u0645\u0644\u0629 \u0645\u0646 \u062F\u0648\u0646 \u0625\u0639\u0637\u0627\u0626\u064A \u0627\u0644\u0625\u062C\u0627\u0628\u0629: \xAB{sentence}\xBB",
      clue: "\u062A\u0644\u0645\u064A\u062D",
      checking: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      skip: "\u062A\u062E\u0637\u0651\u064A",
      submit: "\u0625\u0631\u0633\u0627\u0644",
      checkRepair: "\u062A\u062D\u0642\u0651\u0642 \u0645\u0646 \u0627\u0644\u062A\u0635\u062D\u064A\u062D",
      chooseRepairAbove: "\u0627\u062E\u062A\u0631 \u0627\u0644\u062A\u0635\u062D\u064A\u062D \u0645\u0646 \u0627\u0644\u0623\u0639\u0644\u0649",
      caseSolved: "\u062A\u0645 \u062D\u0644\u0651 \u0627\u0644\u0642\u0636\u064A\u0629!",
      notQuite: "\u0644\u064A\u0633 \u062A\u0645\u0627\u0645\u064B\u0627\u2014\u0625\u0644\u064A\u0643 \u0627\u0644\u0642\u0627\u0639\u062F\u0629.",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A",
      seeResults: "\u0639\u0631\u0636 \u0627\u0644\u0646\u062A\u0627\u0626\u062C",
      quizComplete: "\u0627\u0643\u062A\u0645\u0644 \u0627\u0644\u0627\u062E\u062A\u0628\u0627\u0631!",
      keepExploring: "\u0648\u0627\u0635\u0644 \u0627\u0633\u062A\u0643\u0634\u0627\u0641 \u0627\u0644\u0642\u0648\u0627\u0639\u062F",
      correctCount: "{correct} \u0645\u0646 {total} \u0635\u062D\u064A\u062D\u0629",
      continue: "\u0645\u062A\u0627\u0628\u0639\u0629",
      building: "\u062C\u0627\u0631\u064D \u0625\u0646\u0634\u0627\u0621 \u0642\u0636\u064A\u0629 \u0627\u0644\u062C\u0645\u0644\u0629\u2026",
      noClearCase: "\u0644\u0645 \u064A\u062A\u0645 \u0625\u0646\u0634\u0627\u0621 \u0642\u0636\u064A\u0629 \u0648\u0627\u0636\u062D\u0629",
      generationFailed: "\u0644\u0645 \u0646\u062A\u0645\u0643\u0646 \u0645\u0646 \u0625\u0646\u0634\u0627\u0621 \u0633\u0624\u0627\u0644 \u0648\u0627\u0636\u062D \u0647\u0630\u0647 \u0627\u0644\u0645\u0631\u0629.",
      tryAnother: "\u062C\u0631\u0651\u0628 \u0642\u0636\u064A\u0629 \u0623\u062E\u0631\u0649",
      generateAnother: "\u0623\u0646\u0634\u0626 \u0645\u062B\u0627\u0644\u064B\u0627 \u0622\u062E\u0631",
      testingGate: "\u0628\u064A\u0626\u0629 \u0627\u0644\u0627\u062E\u062A\u0628\u0627\u0631",
      testingGrammar: "\u064A\u0638\u0647\u0631 \u0645\u062D\u0642\u0651\u0642 \u0627\u0644\u062C\u0645\u0644\u0629 \u0641\u0642\u0637 \u0623\u062B\u0646\u0627\u0621 \u062A\u062D\u0633\u064A\u0646 \u062A\u062C\u0631\u0628\u0629 \u0627\u0644\u0642\u0648\u0627\u0639\u062F.",
      testingVocabulary: "\u064A\u0638\u0647\u0631 \u0645\u062D\u0642\u0651\u0642 \u0627\u0644\u062C\u0645\u0644\u0629 \u0641\u0642\u0637 \u0623\u062B\u0646\u0627\u0621 \u062A\u062D\u0633\u064A\u0646 \u062A\u062C\u0631\u0628\u0629 \u0627\u0644\u0645\u0641\u0631\u062F\u0627\u062A."
    },
    zh: {
      title: "\u53E5\u5B50\u4FA6\u63A2",
      description: "\u5148\u627E\u51FA\u8BA9\u53E5\u5B50\u51FA\u9519\u7684\u8BCD\u8BED\uFF0C\u7136\u540E\u9009\u62E9\u6B63\u786E\u7684\u66FF\u6362\u9879\u3002",
      stepOfTwo: "\u7B2C {step} \u6B65\uFF0C\u5171 2 \u6B65",
      findMistake: "\u627E\u51FA\u9519\u8BEF",
      repairIt: "\u4FEE\u6B63\u53E5\u5B50",
      findTitle: "\u54EA\u4E2A\u8BCD\u4E0D\u5408\u9002\uFF1F",
      findHelp: "\u70B9\u51FB\u552F\u4E00\u4E00\u4E2A\u8BA9\u53E5\u5B50\u542C\u8D77\u6765\u4E0D\u5BF9\u7684\u8BCD\u6216\u77ED\u8BED\u3002",
      foundTitle: "\u627E\u5230\u4E86\uFF01",
      brokenPart: "\u201C{token}\u201D\u662F\u9519\u8BEF\u7684\u90E8\u5206\u3002",
      wrongTitle: "\u8FD9\u4E2A\u8BCD\u5728\u8FD9\u91CC\u662F\u6B63\u786E\u7684\u3002",
      wrongHelp: "\u8BD5\u8BD5\u522B\u7684\u8BCD\uFF1B\u9519\u8BEF\u7684\u8BCD\u4F1A\u6539\u53D8\u53E5\u5B50\u7684\u542B\u4E49\u6216\u8BED\u6CD5\u3002",
      chooseRepair: "\u9009\u62E9\u6B63\u786E\u7684\u8BCD",
      replaceWith: "\u7528\u80FD\u8BA9\u6574\u4E2A\u53E5\u5B50\u6B63\u786E\u7684\u9009\u9879\u66FF\u6362\u201C{token}\u201D\u3002",
      repairedSentence: "\u4FEE\u6B63\u540E\u7684\u53E5\u5B50",
      askForHelp: "\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u8BF7\u5E2E\u52A9\u6211\u7406\u89E3\u8FD9\u53E5\u8BDD\u4E2D\u5E94\u8BE5\u6CE8\u610F\u4EC0\u4E48\uFF0C\u4F46\u4E0D\u8981\u544A\u8BC9\u6211\u7B54\u6848\uFF1A\u201C{sentence}\u201D",
      clue: "\u63D0\u793A",
      checking: "\u6B63\u5728\u68C0\u67E5\u2026",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checkRepair: "\u68C0\u67E5\u6211\u7684\u4FEE\u6539",
      chooseRepairAbove: "\u8BF7\u5728\u4E0A\u65B9\u9009\u62E9\u6B63\u786E\u7684\u8BCD",
      caseSolved: "\u6848\u4EF6\u89E3\u51B3\uFF01",
      notQuite: "\u8FD8\u4E0D\u5B8C\u5168\u6B63\u786E\uFF0C\u8BF7\u770B\u8FD9\u4E2A\u89C4\u5F8B\u3002",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898",
      seeResults: "\u67E5\u770B\u7ED3\u679C",
      quizComplete: "\u6D4B\u9A8C\u5B8C\u6210\uFF01",
      keepExploring: "\u7EE7\u7EED\u63A2\u7D22\u8FD9\u4E9B\u89C4\u5F8B",
      correctCount: "\u7B54\u5BF9 {correct}/{total} \u9898",
      continue: "\u7EE7\u7EED",
      building: "\u6B63\u5728\u521B\u5EFA\u53E5\u5B50\u6848\u4EF6\u2026",
      noClearCase: "\u672A\u80FD\u751F\u6210\u660E\u786E\u7684\u95EE\u9898",
      generationFailed: "\u8FD9\u6B21\u65E0\u6CD5\u521B\u5EFA\u660E\u786E\u7684\u53E5\u5B50\u4FA6\u63A2\u95EE\u9898\u3002",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A\u6848\u4EF6",
      generateAnother: "\u751F\u6210\u53E6\u4E00\u4E2A\u793A\u4F8B",
      testingGate: "\u6D4B\u8BD5\u73AF\u5883",
      testingGrammar: "\u8C03\u6574\u8BED\u6CD5\u4F53\u9A8C\u65F6\uFF0C\u4EC5\u663E\u793A\u53E5\u5B50\u4FA6\u63A2\u3002",
      testingVocabulary: "\u8C03\u6574\u8BCD\u6C47\u4F53\u9A8C\u65F6\uFF0C\u4EC5\u663E\u793A\u53E5\u5B50\u4FA6\u63A2\u3002"
    }
  });
  function getSentenceDetectiveCopy(language = "en") {
    return SENTENCE_DETECTIVE_COPY[language] || SENTENCE_DETECTIVE_COPY.en;
  }
  function formatSentenceDetectiveCopy(template, variables = {}) {
    return String(template || "").replace(
      /\{(\w+)\}/g,
      (_, key) => variables[key] == null ? `{${key}}` : String(variables[key])
    );
  }

  // ../nosabos/nosabos/src/utils/dialogueForkI18n.js
  var DIALOGUE_FORK_COPY = Object.freeze({
    en: {
      title: "Dialogue Fork",
      instruction: "Choose the natural response to continue the conversation.",
      askForHelp: "Ask for help",
      helpRequest: "Help me understand what would be a natural reply to \u201C{speaker}: {line}\u201D without giving me the answer.",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question",
      generationFailed: "We couldn't build a clear Dialogue Fork question this time.",
      tryAnother: "Try another dialogue"
    },
    es: {
      title: "Bifurcaci\xF3n de di\xE1logo",
      instruction: "Elige la respuesta natural para continuar la conversaci\xF3n.",
      askForHelp: "Pedir ayuda",
      helpRequest: "Ay\xFAdame a entender cu\xE1l ser\xEDa una respuesta natural a \xAB{speaker}: {line}\xBB sin darme la respuesta.",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta",
      generationFailed: "No pudimos crear una pregunta de di\xE1logo clara esta vez.",
      tryAnother: "Probar otro di\xE1logo"
    },
    fr: {
      title: "Bifurcation de dialogue",
      instruction: "Choisissez la r\xE9ponse naturelle pour poursuivre la conversation.",
      askForHelp: "Demander de l'aide",
      helpRequest: "Aidez-moi \xE0 comprendre quelle serait une r\xE9ponse naturelle \xE0 \xAB {speaker} : {line} \xBB sans me donner la r\xE9ponse.",
      skip: "Passer",
      submit: "Valider",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante",
      generationFailed: "Nous n'avons pas pu g\xE9n\xE9rer une question de dialogue claire cette fois-ci.",
      tryAnother: "Essayer un autre dialogue"
    },
    de: {
      title: "Dialog-Gabelung",
      instruction: "W\xE4hle die passende Antwort, um das Gespr\xE4ch fortzusetzen.",
      askForHelp: "Um Hilfe bitten",
      helpRequest: "Hilf mir zu verstehen, was eine nat\xFCrliche Antwort auf \u201E{speaker}: {line}\u201C w\xE4re, ohne mir die L\xF6sung zu verraten.",
      skip: "\xDCberspringen",
      submit: "Einreichen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Nochmal versuchen",
      nextQuestion: "N\xE4chste Frage",
      generationFailed: "Wir konnten diesmal keine eindeutige Dialog-Frage erstellen.",
      tryAnother: "Anderen Dialog probieren"
    },
    it: {
      title: "Bivio di dialogo",
      instruction: "Scegli la risposta naturale per continuare la conversazione.",
      askForHelp: "Chiedi aiuto",
      helpRequest: "Aiutami a capire quale sarebbe una risposta naturale a \xAB{speaker}: {line}\xBB senza darmi la soluzione.",
      skip: "Salta",
      submit: "Invia",
      checking: "Controllo in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda",
      generationFailed: "Non siamo riusciti a creare una domanda di dialogo chiara questa volta.",
      tryAnother: "Prova un altro dialogo"
    },
    pt: {
      title: "Bifurca\xE7\xE3o de di\xE1logo",
      instruction: "Escolha a resposta natural para continuar a conversa.",
      askForHelp: "Pedir ajuda",
      helpRequest: "Ajude-me a entender qual seria uma resposta natural a \xAB{speaker}: {line}\xBB sem me dar a resposta.",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta",
      generationFailed: "N\xE3o foi poss\xEDvel gerar uma pergunta de di\xE1logo clara desta vez.",
      tryAnother: "Tentar outro di\xE1logo"
    },
    ja: {
      title: "\u30C0\u30A4\u30A2\u30ED\u30B0\u30FB\u30D5\u30A9\u30FC\u30AF",
      instruction: "\u4F1A\u8A71\u3092\u7D9A\u3051\u308B\u306E\u306B\u6700\u3082\u81EA\u7136\u306A\u8FD4\u7B54\u3092\u9078\u3093\u3067\u304F\u3060\u3055\u3044\u3002",
      askForHelp: "\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u300C{speaker}: {line}\u300D\u306B\u5BFE\u3059\u308B\u81EA\u7136\u306A\u8FD4\u7B54\u306E\u30D2\u30F3\u30C8\u3092\u3001\u7B54\u3048\u3092\u8A00\u308F\u305A\u306B\u6559\u3048\u3066\u304F\u3060\u3055\u3044\u3002",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3092\u9001\u4FE1",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C",
      generationFailed: "\u5BFE\u8A71\u306E\u8CEA\u554F\u3092\u4F5C\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002",
      tryAnother: "\u5225\u306E\u5BFE\u8A71\u3092\u8A66\u3059"
    },
    ru: {
      title: "\u0420\u0430\u0437\u0432\u0438\u043B\u043A\u0430 \u0434\u0438\u0430\u043B\u043E\u0433\u0430",
      instruction: "\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u0435\u0441\u0442\u0435\u0441\u0442\u0432\u0435\u043D\u043D\u044B\u0439 \u043E\u0442\u0432\u0435\u0442, \u0447\u0442\u043E\u0431\u044B \u043F\u0440\u043E\u0434\u043E\u043B\u0436\u0438\u0442\u044C \u0434\u0438\u0430\u043B\u043E\u0433.",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443",
      helpRequest: "\u041F\u043E\u043C\u043E\u0433\u0438\u0442\u0435 \u043C\u043D\u0435 \u043F\u043E\u043D\u044F\u0442\u044C, \u043A\u0430\u043A\u043E\u0439 \u043E\u0442\u0432\u0435\u0442 \u0431\u0443\u0434\u0435\u0442 \u0435\u0441\u0442\u0435\u0441\u0442\u0432\u0435\u043D\u043D\u044B\u043C \u043D\u0430 \xAB{speaker}: {line}\xBB, \u043D\u0435 \u0440\u0430\u0441\u043A\u0440\u044B\u0432\u0430\u044F \u043E\u0442\u0432\u0435\u0442.",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041E\u0442\u043F\u0440\u0430\u0432\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u043F\u043E\u043D\u044F\u0442\u043D\u044B\u0439 \u0434\u0438\u0430\u043B\u043E\u0433 \u0432 \u044D\u0442\u043E\u0442 \u0440\u0430\u0437.",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0439 \u0434\u0438\u0430\u043B\u043E\u0433"
    },
    el: {
      title: "\u0394\u03B9\u03B1\u03BA\u03BB\u03AC\u03B4\u03C9\u03C3\u03B7 \u03B4\u03B9\u03B1\u03BB\u03CC\u03B3\u03BF\u03C5",
      instruction: "\u0395\u03C0\u03B9\u03BB\u03AD\u03BE\u03C4\u03B5 \u03C4\u03B7 \u03C6\u03C5\u03C3\u03B9\u03BA\u03AE \u03B1\u03C0\u03AC\u03BD\u03C4\u03B7\u03C3\u03B7 \u03B3\u03B9\u03B1 \u03BD\u03B1 \u03C3\u03C5\u03BD\u03B5\u03C7\u03AF\u03C3\u03B5\u03C4\u03B5 \u03C4\u03B7 \u03C3\u03C5\u03BD\u03BF\u03BC\u03B9\u03BB\u03AF\u03B1.",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1",
      helpRequest: "\u0392\u03BF\u03B7\u03B8\u03AE\u03C3\u03C4\u03B5 \u03BC\u03B5 \u03BD\u03B1 \u03BA\u03B1\u03C4\u03B1\u03BB\u03AC\u03B2\u03C9 \u03C0\u03BF\u03B9\u03B1 \u03B8\u03B1 \u03AE\u03C4\u03B1\u03BD \u03BC\u03B9\u03B1 \u03C6\u03C5\u03C3\u03B9\u03BA\u03AE \u03B1\u03C0\u03AC\u03BD\u03C4\u03B7\u03C3\u03B7 \u03C3\u03C4\u03BF \xAB{speaker}: {line}\xBB \u03C7\u03C9\u03C1\u03AF\u03C2 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03C4\u03B7 \u03BB\u03CD\u03C3\u03B7.",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7\u03C2 \u03B4\u03B9\u03B1\u03BB\u03CC\u03B3\u03BF\u03C5 \u03B1\u03C5\u03C4\u03AE \u03C4\u03B7 \u03C6\u03BF\u03C1\u03AC.",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03BF\u03BD \u03B4\u03B9\u03AC\u03BB\u03BF\u03B3\u03BF"
    },
    nl: {
      title: "Dialoogsplitsing",
      instruction: "Kies het natuurlijke antwoord om het gesprek voort te zetten.",
      askForHelp: "Vraag om hulp",
      helpRequest: "Help me begrijpen wat een natuurlijk antwoord zou zijn op \u201C{speaker}: {line}\u201D zonder het antwoord te verklappen.",
      skip: "Overslaan",
      submit: "Indienen",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag",
      generationFailed: "We konden deze keer geen duidelijke dialoogvraag genereren.",
      tryAnother: "Probeer een andere dialoog"
    },
    pl: {
      title: "Rozwidlenie dialogu",
      instruction: "Wybierz naturaln\u0105 odpowied\u017A, aby kontynuowa\u0107 rozmow\u0119.",
      askForHelp: "Popro\u015B o pomoc",
      helpRequest: "Pom\xF3\u017C mi zrozumie\u0107, jaka by\u0142aby naturalna odpowied\u017A na \u201E{speaker}: {line}\u201D bez zdradzania rozwi\u0105zania.",
      skip: "Pomi\u0144",
      submit: "Wy\u015Blij",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie",
      generationFailed: "Nie uda\u0142o si\u0119 tym rawem wygenerowa\u0107 pytania dialogowego.",
      tryAnother: "Wypr\xF3buj inny dialog"
    },
    ga: {
      title: "Gabhal Comhr\xE1",
      instruction: "Roghnaigh an freagra n\xE1d\xFArtha chun an comhr\xE1 a lean\xFAint.",
      askForHelp: "Iarr cabhair",
      helpRequest: "Cabhraigh liom freagra n\xE1d\xFArtha ar \u201C{speaker}: {line}\u201D a thuiscint gan an freagra a thabhairt dom.",
      skip: "Scipe\xE1il",
      submit: "Cuir isteach",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile",
      generationFailed: "N\xEDorbh fh\xE9idir ceist chomhr\xE1 shoil\xE9ir a ghini\xFAint an uair seo.",
      tryAnother: "Bain triail as comhr\xE1 eile"
    },
    ar: {
      title: "\u0645\u0641\u062A\u0631\u0642 \u0627\u0644\u062D\u0648\u0627\u0631",
      instruction: "\u0627\u062E\u062A\u0631 \u0627\u0644\u0631\u062F \u0627\u0644\u0637\u0628\u064A\u0639\u064A \u0644\u0645\u0648\u0627\u0635\u0644\u0629 \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629.",
      askForHelp: "\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629",
      helpRequest: "\u0633\u0627\u0639\u062F\u0646\u064A \u0641\u064A \u0641\u0647\u0645 \u0627\u0644\u0631\u062F \u0627\u0644\u0637\u0628\u064A\u0639\u064A \u0639\u0644\u0649 \xAB{speaker}: {line}\xBB \u062F\u0648\u0646 \u0625\u0639\u0637\u0627\u0626\u064A \u0627\u0644\u0625\u062C\u0627\u0628\u0629.",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u0625\u0631\u0633\u0627\u0644",
      checking: "\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A",
      generationFailed: "\u062A\u0639\u0630\u0631 \u0625\u0646\u0634\u0627\u0621 \u0633\u0624\u0627\u0644 \u062D\u0648\u0627\u0631 \u0648\u0627\u0636\u062D \u0647\u0630\u0647 \u0627\u0644\u0645\u0631\u0629.",
      tryAnother: "\u062C\u0631\u0628 \u062D\u0648\u0627\u0631\u064B\u0627 \u0622\u062E\u0631"
    },
    hi: {
      title: "\u0938\u0902\u0935\u093E\u0926 \u0915\u093E \u092E\u094B\u0921\u093C",
      instruction: "\u092C\u093E\u0924\u091A\u0940\u0924 \u091C\u093E\u0930\u0940 \u0930\u0916\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0909\u0924\u094D\u0924\u0930 \u091A\u0941\u0928\u0947\u0902\u0964",
      askForHelp: "\u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u092C\u093F\u0928\u093E \u0909\u0924\u094D\u0924\u0930 \u092C\u0924\u093E\u090F \u092E\u0941\u091D\u0947 \u092F\u0939 \u0938\u092E\u091D\u0928\u0947 \u092E\u0947\u0902 \u092E\u0926\u0926 \u0915\u0930\u0947\u0902 \u0915\u093F \u201C{speaker}: {line}\u201D \u0915\u093E \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0909\u0924\u094D\u0924\u0930 \u0915\u094D\u092F\u093E \u0939\u094B\u0917\u093E\u0964",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u092E\u093E \u0915\u0930\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928",
      generationFailed: "\u0907\u0938 \u092C\u093E\u0930 \u0938\u094D\u092A\u0937\u094D\u091F \u0938\u0902\u0935\u093E\u0926 \u092A\u094D\u0930\u0936\u094D\u0928 \u0928\u0939\u0940\u0902 \u092C\u0928\u093E\u092F\u093E \u091C\u093E \u0938\u0915\u093E\u0964",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u0938\u0902\u0935\u093E\u0926 \u0906\u091C\u093C\u092E\u093E\u090F\u0902"
    },
    zh: {
      title: "\u5BF9\u8BDD\u5206\u652F",
      instruction: "\u9009\u62E9\u6700\u81EA\u7136\u7684\u56DE\u7B54\u4EE5\u7EE7\u7EED\u5BF9\u8BDD\u3002",
      askForHelp: "\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u8BF7\u5E2E\u52A9\u6211\u7406\u89E3\u201C{speaker}: {line}\u201D\u7684\u6700\u81EA\u7136\u56DE\u590D\uFF0C\u4F46\u4E0D\u8981\u544A\u8BC9\u6211\u7B54\u6848\u3002",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u6B63\u5728\u68C0\u67E5\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898",
      generationFailed: "\u8FD9\u6B21\u65E0\u6CD5\u521B\u5EFA\u660E\u786E\u7684\u5BF9\u8BDD\u95EE\u9898\u3002",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A\u5BF9\u8BDD"
    }
  });
  function getDialogueForkCopy(language = "en") {
    return DIALOGUE_FORK_COPY[language] || DIALOGUE_FORK_COPY.en;
  }
  function formatDialogueForkCopy(template, variables = {}) {
    return String(template || "").replace(
      /\{(\w+)\}/g,
      (_, key) => variables[key] == null ? `{${key}}` : String(variables[key])
    );
  }

  // ../nosabos/nosabos/src/utils/sentenceShapeshifterI18n.js
  var SENTENCE_SHAPESHIFTER_COPY = Object.freeze({
    en: {
      title: "Sentence Shapeshifter",
      instruction: "Transform the sentence according to the rule.",
      placeholder: "Type the transformed sentence\u2026",
      askForHelp: "Ask for help",
      helpRequest: "Help me understand how to transform \u201C{source}\u201D using the constraint \u201C{constraint}\u201D without giving me the answer.",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question",
      generationFailed: "We couldn't build a clear Sentence Shapeshifter question this time.",
      tryAnother: "Try another sentence"
    },
    es: {
      title: "Transformador de oraciones",
      instruction: "Transforma la oraci\xF3n seg\xFAn la regla indicada.",
      placeholder: "Escribe la oraci\xF3n transformada\u2026",
      askForHelp: "Pedir ayuda",
      helpRequest: "Ay\xFAdame a entender c\xF3mo transformar \xAB{source}\xBB seg\xFAn la regla \xAB{constraint}\xBB sin darme la respuesta.",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta",
      generationFailed: "No pudimos crear una pregunta de transformaci\xF3n clara esta vez.",
      tryAnother: "Probar otra oraci\xF3n"
    },
    fr: {
      title: "M\xE9tamorphose de phrase",
      instruction: "Transformez la phrase selon la r\xE8gle indiqu\xE9e.",
      placeholder: "\xC9crivez la phrase transform\xE9e\u2026",
      askForHelp: "Demander de l'aide",
      helpRequest: "Aidez-moi \xE0 comprendre comment transformer \xAB {source} \xBB selon la consigne \xAB {constraint} \xBB sans me donner la r\xE9ponse.",
      skip: "Passer",
      submit: "Valider",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante",
      generationFailed: "Nous n'avons pas pu g\xE9n\xE9rer une question de transformation claire cette fois-ci.",
      tryAnother: "Essayer une autre phrase"
    },
    de: {
      title: "Satz-Verwandlung",
      instruction: "Wandle den Satz nach der angegebenen Regel um.",
      placeholder: "Schreibe den umgewandelten Satz\u2026",
      askForHelp: "Um Hilfe bitten",
      helpRequest: "Hilf mir zu verstehen, wie ich \u201E{source}\u201C nach der Regel \u201E{constraint}\u201C umwandeln kann, ohne mir die L\xF6sung zu verraten.",
      skip: "\xDCberspringen",
      submit: "Einreichen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Nochmal versuchen",
      nextQuestion: "N\xE4chste Frage",
      generationFailed: "Wir konnten diesmal keine eindeutige Satzverwandlungs-Aufgabe erstellen.",
      tryAnother: "Anderen Satz probieren"
    },
    it: {
      title: "Trasformazione di frasi",
      instruction: "Trasforma la frase secondo la regola indicata.",
      placeholder: "Scrivi la frase trasformata\u2026",
      askForHelp: "Chiedi aiuto",
      helpRequest: "Aiutami a capire come trasformare \xAB{source}\xBB secondo il vincolo \xAB{constraint}\xBB senza darmi la soluzione.",
      skip: "Salta",
      submit: "Invia",
      checking: "Controllo in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda",
      generationFailed: "Non siamo riusciti a creare un esercizio di trasformazione chiaro questa volta.",
      tryAnother: "Prova un'altra frase"
    },
    pt: {
      title: "Metamorfose de frases",
      instruction: "Transforme a frase de acordo com a regra indicada.",
      placeholder: "Escreva a frase transformada\u2026",
      askForHelp: "Pedir ajuda",
      helpRequest: "Ajude-me a entender como transformar \xAB{source}\xBB usando a regra \xAB{constraint}\xBB sem me dar a resposta.",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta",
      generationFailed: "N\xE3o foi poss\xEDvel gerar um exerc\xEDcio de transforma\xE7\xE3o claro desta vez.",
      tryAnother: "Tentar outra frase"
    },
    ja: {
      title: "\u6587\u306E\u5909\u5F62",
      instruction: "\u6307\u793A\u3055\u308C\u305F\u30EB\u30FC\u30EB\u306B\u5F93\u3063\u3066\u6587\u3092\u5909\u5F62\u3057\u3066\u304F\u3060\u3055\u3044\u3002",
      placeholder: "\u5909\u5F62\u3057\u305F\u6587\u3092\u5165\u529B\u2026",
      askForHelp: "\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u300C{source}\u300D\u3092\u300C{constraint}\u300D\u306E\u6761\u4EF6\u3067\u5909\u5F62\u3059\u308B\u30D2\u30F3\u30C8\u3092\u3001\u7B54\u3048\u3092\u8A00\u308F\u305A\u306B\u6559\u3048\u3066\u304F\u3060\u3055\u3044\u3002",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3092\u9001\u4FE1",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C",
      generationFailed: "\u6587\u306E\u5909\u5F62\u554F\u984C\u3092\u4F5C\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002",
      tryAnother: "\u5225\u306E\u6587\u3092\u8A66\u3059"
    },
    ru: {
      title: "\u0422\u0440\u0430\u043D\u0441\u0444\u043E\u0440\u043C\u0430\u0446\u0438\u044F \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u044F",
      instruction: "\u041F\u0440\u0435\u043E\u0431\u0440\u0430\u0437\u0443\u0439\u0442\u0435 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435 \u0432 \u0441\u043E\u043E\u0442\u0432\u0435\u0442\u0441\u0442\u0432\u0438\u0438 \u0441 \u043F\u0440\u0430\u0432\u0438\u043B\u043E\u043C.",
      placeholder: "\u041D\u0430\u043F\u0438\u0448\u0438\u0442\u0435 \u0438\u0437\u043C\u0435\u043D\u0451\u043D\u043D\u043E\u0435 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435\u2026",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443",
      helpRequest: "\u041F\u043E\u043C\u043E\u0433\u0438\u0442\u0435 \u043C\u043D\u0435 \u043F\u043E\u043D\u044F\u0442\u044C, \u043A\u0430\u043A \u043F\u0440\u0435\u043E\u0431\u0440\u0430\u0437\u043E\u0432\u0430\u0442\u044C \xAB{source}\xBB \u043F\u043E \u043F\u0440\u0430\u0432\u0438\u043B\u0443 \xAB{constraint}\xBB, \u043D\u0435 \u0440\u0430\u0441\u043A\u0440\u044B\u0432\u0430\u044F \u043E\u0442\u0432\u0435\u0442.",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041E\u0442\u043F\u0440\u0430\u0432\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u043F\u043E\u043D\u044F\u0442\u043D\u043E\u0435 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u0435 \u043D\u0430 \u0442\u0440\u0430\u043D\u0441\u0444\u043E\u0440\u043C\u0430\u0446\u0438\u044E \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u044F.",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0435 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435"
    },
    el: {
      title: "\u039C\u03B5\u03C4\u03B1\u03C3\u03C7\u03B7\u03BC\u03B1\u03C4\u03B9\u03C3\u03BC\u03CC\u03C2 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7\u03C2",
      instruction: "\u039C\u03B5\u03C4\u03B1\u03C3\u03C7\u03B7\u03BC\u03B1\u03C4\u03AF\u03C3\u03C4\u03B5 \u03C4\u03B7\u03BD \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7 \u03C3\u03CD\u03BC\u03C6\u03C9\u03BD\u03B1 \u03BC\u03B5 \u03C4\u03BF\u03BD \u03BA\u03B1\u03BD\u03CC\u03BD\u03B1.",
      placeholder: "\u03A0\u03BB\u03B7\u03BA\u03C4\u03C1\u03BF\u03BB\u03BF\u03B3\u03AE\u03C3\u03C4\u03B5 \u03C4\u03B7 \u03BC\u03B5\u03C4\u03B1\u03C3\u03C7\u03B7\u03BC\u03B1\u03C4\u03B9\u03C3\u03BC\u03AD\u03BD\u03B7 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7\u2026",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1",
      helpRequest: "\u0392\u03BF\u03B7\u03B8\u03AE\u03C3\u03C4\u03B5 \u03BC\u03B5 \u03BD\u03B1 \u03BA\u03B1\u03C4\u03B1\u03BB\u03AC\u03B2\u03C9 \u03C0\u03CE\u03C2 \u03BD\u03B1 \u03BC\u03B5\u03C4\u03B1\u03C3\u03C7\u03B7\u03BC\u03B1\u03C4\u03AF\u03C3\u03C9 \u03C4\u03BF \xAB{source}\xBB \u03BC\u03B5 \u03B2\u03AC\u03C3\u03B7 \u03C4\u03BF\u03BD \u03BA\u03B1\u03BD\u03CC\u03BD\u03B1 \xAB{constraint}\xBB \u03C7\u03C9\u03C1\u03AF\u03C2 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03C4\u03B7 \u03BB\u03CD\u03C3\u03B7.",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03AC\u03C3\u03BA\u03B7\u03C3\u03B7\u03C2 \u03BC\u03B5\u03C4\u03B1\u03C3\u03C7\u03B7\u03BC\u03B1\u03C4\u03B9\u03C3\u03BC\u03BF\u03CD \u03B1\u03C5\u03C4\u03AE \u03C4\u03B7 \u03C6\u03BF\u03C1\u03AC.",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7"
    },
    nl: {
      title: "Zinstransformatie",
      instruction: "Vorm de zin om volgens de aangegeven regel.",
      placeholder: "Typ de omgevormde zin\u2026",
      askForHelp: "Vraag om hulp",
      helpRequest: "Help me begrijpen hoe ik \u201C{source}\u201D kan omvormen volgens de regel \u201C{constraint}\u201D zonder het antwoord te verklappen.",
      skip: "Overslaan",
      submit: "Indienen",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag",
      generationFailed: "We konden deze keer geen duidelijke zinstransformatie-opgave maken.",
      tryAnother: "Probeer een andere zin"
    },
    pl: {
      title: "Przekszta\u0142cenie zdania",
      instruction: "Przekszta\u0142\u0107 zdanie zgodnie z podan\u0105 regu\u0142\u0105.",
      placeholder: "Wpisz przekszta\u0142cone zdanie\u2026",
      askForHelp: "Popro\u015B o pomoc",
      helpRequest: "Pom\xF3\u017C mi zrozumie\u0107, jak przekszta\u0142ci\u0107 \u201E{source}\u201D zgodnie z regu\u0142\u0105 \u201E{constraint}\u201D bez zdradzania rozwi\u0105zania.",
      skip: "Pomi\u0144",
      submit: "Wy\u015Blij",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie",
      generationFailed: "Nie uda\u0142o si\u0119 tym razem wygenerowa\u0107 zadania przekszta\u0142cania zdania.",
      tryAnother: "Wypr\xF3buj inne zdanie"
    },
    ga: {
      title: "Claochl\xFA Abairte",
      instruction: "Athraigh an abairt de r\xE9ir an rialach\xE1in.",
      placeholder: "Cl\xF3scr\xEDobh an abairt claochlaithe\u2026",
      askForHelp: "Iarr cabhair",
      helpRequest: "Cabhraigh liom a thuiscint conas \u201C{source}\u201D a athr\xFA de r\xE9ir na rialach \u201C{constraint}\u201D gan an freagra a thabhairt dom.",
      skip: "Scipe\xE1il",
      submit: "Cuir isteach",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile",
      generationFailed: "N\xEDorbh fh\xE9idir ceist claochlaithe abairte shoil\xE9ir a ghini\xFAint an uair seo.",
      tryAnother: "Bain triail as abairt eile"
    },
    ar: {
      title: "\u062A\u062D\u0648\u064A\u0644 \u0627\u0644\u062C\u0645\u0644\u0629",
      instruction: "\u0642\u0645 \u0628\u062A\u062D\u0648\u064A\u0644 \u0627\u0644\u062C\u0645\u0644\u0629 \u0648\u0641\u0642\u064B\u0627 \u0644\u0644\u0642\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u062D\u062F\u062F\u0629.",
      placeholder: "\u0627\u0643\u062A\u0628 \u0627\u0644\u062C\u0645\u0644\u0629 \u0628\u0639\u062F \u0627\u0644\u062A\u062D\u0648\u064A\u0644\u2026",
      askForHelp: "\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629",
      helpRequest: "\u0633\u0627\u0639\u062F\u0646\u064A \u0641\u064A \u0641\u0647\u0645 \u0643\u064A\u0641\u064A\u0629 \u062A\u062D\u0648\u064A\u0644 \xAB{source}\xBB \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0627\u0644\u0642\u0627\u0639\u062F\u0629 \xAB{constraint}\xBB \u062F\u0648\u0646 \u0625\u0639\u0637\u0627\u0626\u064A \u0627\u0644\u0625\u062C\u0627\u0628\u0629.",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u0625\u0631\u0633\u0627\u0644",
      checking: "\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A",
      generationFailed: "\u062A\u0639\u0630\u0631 \u0625\u0646\u0634\u0627\u0621 \u062A\u0645\u0631\u064A\u0646 \u062A\u062D\u0648\u064A\u0644 \u062C\u0645\u0644\u0629 \u0648\u0627\u0636\u062D \u0647\u0630\u0647 \u0627\u0644\u0645\u0631\u0629.",
      tryAnother: "\u062C\u0631\u0628 \u062C\u0645\u0644\u0629 \u0623\u062E\u0631\u0649"
    },
    hi: {
      title: "\u0935\u093E\u0915\u094D\u092F \u0930\u0942\u092A\u093E\u0902\u0924\u0930\u0923",
      instruction: "\u0926\u093F\u090F \u0917\u090F \u0928\u093F\u092F\u092E \u0915\u0947 \u0905\u0928\u0941\u0938\u093E\u0930 \u0935\u093E\u0915\u094D\u092F \u0915\u093E \u0930\u0942\u092A\u093E\u0902\u0924\u0930\u0923 \u0915\u0930\u0947\u0902\u0964",
      placeholder: "\u0930\u0942\u092A\u093E\u0902\u0924\u0930\u093F\u0924 \u0935\u093E\u0915\u094D\u092F \u0932\u093F\u0916\u0947\u0902\u2026",
      askForHelp: "\u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u092C\u093F\u0928\u093E \u0909\u0924\u094D\u0924\u0930 \u092C\u0924\u093E\u090F \u092E\u0941\u091D\u0947 \u092F\u0939 \u0938\u092E\u091D\u0928\u0947 \u092E\u0947\u0902 \u092E\u0926\u0926 \u0915\u0930\u0947\u0902 \u0915\u093F \u0928\u093F\u092F\u092E \u201C{constraint}\u201D \u0915\u0947 \u0905\u0928\u0941\u0938\u093E\u0930 \u201C{source}\u201D \u0915\u093E \u0930\u0942\u092A\u093E\u0902\u0924\u0930\u0923 \u0915\u0948\u0938\u0947 \u0915\u0930\u0947\u0902\u0964",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u092E\u093E \u0915\u0930\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928",
      generationFailed: "\u0907\u0938 \u092C\u093E\u0930 \u0938\u094D\u092A\u0937\u094D\u091F \u0935\u093E\u0915\u094D\u092F \u0930\u0942\u092A\u093E\u0902\u0924\u0930\u0923 \u092A\u094D\u0930\u0936\u094D\u0928 \u0928\u0939\u0940\u0902 \u092C\u0928\u093E\u092F\u093E \u091C\u093E \u0938\u0915\u093E\u0964",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u0935\u093E\u0915\u094D\u092F \u0906\u091C\u093C\u092E\u093E\u090F\u0902"
    },
    zh: {
      title: "\u53E5\u5B50\u53D8\u5F62",
      instruction: "\u6839\u636E\u7ED9\u5B9A\u7684\u89C4\u5219\u53D8\u6362\u53E5\u5B50\u3002",
      placeholder: "\u8F93\u5165\u53D8\u6362\u540E\u7684\u53E5\u5B50\u2026",
      askForHelp: "\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u8BF7\u5E2E\u52A9\u6211\u7406\u89E3\u5982\u4F55\u6839\u636E\u89C4\u5219\u201C{constraint}\u201D\u53D8\u6362\u201C{source}\u201D\uFF0C\u4F46\u4E0D\u8981\u544A\u8BC9\u6211\u7B54\u6848\u3002",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u6B63\u5728\u68C0\u67E5\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898",
      generationFailed: "\u8FD9\u6B21\u65E0\u6CD5\u521B\u5EFA\u660E\u786E\u7684\u53E5\u5B50\u53D8\u5F62\u95EE\u9898\u3002",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A\u53E5\u5B50"
    },
    nah: {
      title: "Tlahtolcuepaliztli",
      instruction: "Xikcuepa in tlahtolli yuhqui tlanahuatilli.",
      placeholder: "Xikyihcuilo in yancuic tlahtolli\u2026",
      askForHelp: "Xiktlahtlani tepalewiliztli",
      helpRequest: "Xinechpalehuili yuhqui tlahtolcuepaliztli: \u201C{source}\u201D ica \u201C{constraint}\u201D.",
      skip: "Xikpano",
      submit: "Titia",
      checking: "Motlatlatia\u2026",
      tryAgain: "Ocsepa xikyehyeco",
      nextQuestion: "Ocse tlahtolli",
      generationFailed: "Ahmo huelic omoyancuic-chih tlahtolli.",
      tryAnother: "Ocse tlahtolli"
    },
    yua: {
      title: "K'\xE9exel T'aan",
      instruction: "K'ex le t'aano' je'el bix u ya'alike'.",
      placeholder: "Ts'\xEDibt le t\xFAumben t'aano'\u2026",
      askForHelp: "K'\xE1at \xE1antaj",
      helpRequest: "\xC1anten in na'at bix ken in k'ex \xAB{source}\xBB y\xE9etel \xAB{constraint}\xBB.",
      skip: "M\xE1anen",
      submit: "T\xFAuxte",
      checking: "T\xFAun yilik\u2026",
      tryAgain: "Ka'a y\xF3olte",
      nextQuestion: "U l\xE1ak' k'\xE1atchi'",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le k'\xE9exel t'aana'.",
      tryAnother: "Y\xF3olt u l\xE1ak' t'aan"
    }
  });
  function getSentenceShapeshifterCopy(language = "en") {
    return SENTENCE_SHAPESHIFTER_COPY[language] || SENTENCE_SHAPESHIFTER_COPY.en;
  }
  function formatSentenceShapeshifterCopy(template, variables = {}) {
    return String(template || "").replace(
      /\{(\w+)\}/g,
      (_, key) => variables[key] == null ? `{${key}}` : String(variables[key])
    );
  }

  // ../nosabos/nosabos/src/utils/wordNeighborhoodsI18n.js
  var WORD_NEIGHBORHOODS_COPY = Object.freeze({
    en: {
      title: "Word Neighborhoods",
      instruction: "Sort each word into its matching neighborhood.",
      wordBank: "Word bank \xB7 tap a word, then its neighborhood",
      allAssigned: "Every word has a home.",
      tapToReturn: "Tap a placed word to return it to the bank",
      askForHelp: "Ask for help",
      helpRequest: "Help me understand how these words relate to each group without giving me the exact sorting: {groups}",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question",
      generationFailed: "We couldn't build a clear Word Neighborhoods exercise this time.",
      tryAnother: "Try another set",
      testingVocabulary: "Testing lexical relationships & categories",
      testingGrammar: "Testing grammatical structures & patterns",
      dropPlaceholder: "Drag a word here or tap to place",
      tapToPlace: "Tap to place \u201C{word}\u201D"
    },
    es: {
      title: "Vecindarios de palabras",
      instruction: "Clasifica cada palabra en su vecindario correspondiente.",
      wordBank: "Banco de palabras \xB7 toca una palabra y luego su vecindario",
      allAssigned: "Todas las palabras est\xE1n ubicadas.",
      tapToReturn: "Toca una palabra asignada para devolverla al banco",
      askForHelp: "Pedir ayuda",
      helpRequest: "Ay\xFAdame a entender c\xF3mo se relacionan estas palabras con cada grupo sin darme la clasificaci\xF3n exacta: {groups}",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta",
      generationFailed: "No pudimos crear un ejercicio de clasificaci\xF3n claro esta vez.",
      tryAnother: "Probar otro conjunto",
      testingVocabulary: "Evaluando categor\xEDas y relaciones l\xE9xicas",
      testingGrammar: "Evaluando patrones y estructuras gramaticales",
      dropPlaceholder: "Arrastra una palabra aqu\xED o toca para colocar",
      tapToPlace: "Toca para colocar \xAB{word}\xBB"
    },
    fr: {
      title: "Quartiers de mots",
      instruction: "Classez chaque mot dans son quartier correspondant.",
      wordBank: "Banque de mots \xB7 touchez un mot, puis son quartier",
      allAssigned: "Chaque mot a trouv\xE9 sa place.",
      tapToReturn: "Touchez un mot plac\xE9 pour le remettre dans la banque",
      askForHelp: "Demander de l'aide",
      helpRequest: "Aidez-moi \xE0 comprendre les liens entre ces mots et chaque groupe sans me donner le classement : {groups}",
      skip: "Passer",
      submit: "Valider",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante",
      generationFailed: "Nous n'avons pas pu g\xE9n\xE9rer un exercice de tri clair cette fois-ci.",
      tryAnother: "Essayer un autre ensemble",
      testingVocabulary: "\xC9valuation des cat\xE9gories et relations lexicales",
      testingGrammar: "\xC9valuation des structures et r\xE9gularit\xE9s grammaticales",
      dropPlaceholder: "Glissez un mot ici ou touchez pour placer",
      tapToPlace: "Touchez pour placer \xAB {word} \xBB"
    },
    de: {
      title: "Wort-Nachbarschaften",
      instruction: "Ordne jedes Wort seiner passenden Nachbarschaft zu.",
      wordBank: "Wortspeicher \xB7 tippe ein Wort an, dann seine Gruppe",
      allAssigned: "Jedes Wort ist zugeordnet.",
      tapToReturn: "Tippe ein platziertes Wort an, um es zur\xFCckzulegen",
      askForHelp: "Um Hilfe bitten",
      helpRequest: "Hilf mir zu verstehen, wie diese W\xF6rter zu den Gruppen passen, ohne mir die L\xF6sung zu verraten: {groups}",
      skip: "\xDCberspringen",
      submit: "Einreichen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Nochmal versuchen",
      nextQuestion: "N\xE4chste Frage",
      generationFailed: "Wir konnten diesmal keine eindeutige Wortgruppen-Aufgabe erstellen.",
      tryAnother: "Anderes Set probieren",
      testingVocabulary: "Pr\xFCfung von Wortfeldern und Kategorien",
      testingGrammar: "Pr\xFCfung grammatischer Muster und Strukturen",
      dropPlaceholder: "Ziehe ein Wort hierher oder tippe zum Platzieren",
      tapToPlace: "Tippe, um \u201E{word}\u201C zu platzieren"
    },
    it: {
      title: "Quartieri di parole",
      instruction: "Ordina ogni parola nel suo quartiere corrispondente.",
      wordBank: "Banca delle parole \xB7 tocca una parola, poi il suo gruppo",
      allAssigned: "Tutte le parole sono state assegnate.",
      tapToReturn: "Tocca una parola posizionata per rimetterla nella banca",
      askForHelp: "Chiedi aiuto",
      helpRequest: "Aiutami a capire come queste parole si collegano ai gruppi senza rivelarmi la soluzione: {groups}",
      skip: "Salta",
      submit: "Invia",
      checking: "Controllo in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda",
      generationFailed: "Non siamo riusciti a creare un esercizio di classificazione chiaro questa volta.",
      tryAnother: "Prova un altro gruppo",
      testingVocabulary: "Verifica di categorie e relazioni lessicali",
      testingGrammar: "Verifica di schemi e strutture grammaticali",
      dropPlaceholder: "Trascina una parola qui o tocca per posizionarla",
      tapToPlace: "Tocca per posizionare \xAB{word}\xBB"
    },
    pt: {
      title: "Bairros de palavras",
      instruction: "Organize cada palavra em seu bairro correspondente.",
      wordBank: "Banco de palavras \xB7 toque em uma palavra e depois no grupo",
      allAssigned: "Todas as palavras foram acomodadas.",
      tapToReturn: "Toque em uma palavra posicionada para devolv\xEA-la ao banco",
      askForHelp: "Pedir ajuda",
      helpRequest: "Ajude-me a entender como essas palavras se relacionam com cada grupo sem dar a resposta exata: {groups}",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta",
      generationFailed: "N\xE3o foi poss\xEDvel gerar um exerc\xEDcio de agrupamento claro desta vez.",
      tryAnother: "Tentar outro conjunto",
      testingVocabulary: "Avaliando categorias e rela\xE7\xF5es lexicais",
      testingGrammar: "Avaliando padr\xF5es e estruturas gramaticais",
      dropPlaceholder: "Arraste uma palavra aqui ou toque para posicionar",
      tapToPlace: "Toque para posicionar \u201C{word}\u201D"
    },
    ja: {
      title: "\u8A00\u8449\u306E\u30B0\u30EB\u30FC\u30D7\u5206\u3051",
      instruction: "\u305D\u308C\u305E\u308C\u306E\u5358\u8A9E\u3092\u6B63\u3057\u3044\u30B0\u30EB\u30FC\u30D7\u306B\u632F\u308A\u5206\u3051\u3066\u304F\u3060\u3055\u3044\u3002",
      wordBank: "\u5358\u8A9E\u4E00\u89A7 \xB7 \u5358\u8A9E\u3092\u30BF\u30C3\u30D7\u3057\u3066\u304B\u3089\u30B0\u30EB\u30FC\u30D7\u3092\u9078\u629E",
      allAssigned: "\u3059\u3079\u3066\u306E\u5358\u8A9E\u304C\u914D\u7F6E\u3055\u308C\u307E\u3057\u305F\u3002",
      tapToReturn: "\u914D\u7F6E\u6E08\u307F\u306E\u5358\u8A9E\u3092\u30BF\u30C3\u30D7\u3059\u308B\u3068\u4E00\u89A7\u306B\u623B\u308A\u307E\u3059",
      askForHelp: "\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u7B54\u3048\u3092\u6559\u3048\u305A\u306B\u3001\u3053\u308C\u3089\u306E\u5358\u8A9E\u304C\u5404\u30B0\u30EB\u30FC\u30D7\u306B\u3069\u3046\u95A2\u9023\u3057\u3066\u3044\u308B\u304B\u30D2\u30F3\u30C8\u3092\u304F\u3060\u3055\u3044: {groups}",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3092\u9001\u4FE1",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C",
      generationFailed: "\u5358\u8A9E\u30B0\u30EB\u30FC\u30D7\u5206\u3051\u554F\u984C\u3092\u4F5C\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002",
      tryAnother: "\u5225\u306E\u7D44\u307F\u5408\u308F\u305B\u3092\u8A66\u3059",
      testingVocabulary: "\u8A9E\u5F59\u306E\u610F\u5473\u95A2\u4FC2\u3068\u30AB\u30C6\u30B4\u30EA\u30FC\u306E\u78BA\u8A8D",
      testingGrammar: "\u6587\u6CD5\u69CB\u9020\u3068\u30D1\u30BF\u30FC\u30F3\u306E\u78BA\u8A8D",
      dropPlaceholder: "\u5358\u8A9E\u3092\u30C9\u30E9\u30C3\u30B0\u307E\u305F\u306F\u30BF\u30C3\u30D7\u3057\u3066\u914D\u7F6E",
      tapToPlace: "\u30BF\u30C3\u30D7\u3057\u3066\u300C{word}\u300D\u3092\u914D\u7F6E"
    },
    ru: {
      title: "\u0413\u0440\u0443\u043F\u043F\u044B \u0441\u043B\u043E\u0432",
      instruction: "\u0420\u0430\u0441\u043F\u0440\u0435\u0434\u0435\u043B\u0438\u0442\u0435 \u043A\u0430\u0436\u0434\u043E\u0435 \u0441\u043B\u043E\u0432\u043E \u0432 \u043F\u043E\u0434\u0445\u043E\u0434\u044F\u0449\u0443\u044E \u043A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u044E.",
      wordBank: "\u0411\u0430\u043D\u043A \u0441\u043B\u043E\u0432 \xB7 \u043D\u0430\u0436\u043C\u0438\u0442\u0435 \u043D\u0430 \u0441\u043B\u043E\u0432\u043E, \u0437\u0430\u0442\u0435\u043C \u043D\u0430 \u043D\u0443\u0436\u043D\u0443\u044E \u0433\u0440\u0443\u043F\u043F\u0443",
      allAssigned: "\u0412\u0441\u0435 \u0441\u043B\u043E\u0432\u0430 \u0440\u0430\u0441\u043F\u0440\u0435\u0434\u0435\u043B\u0435\u043D\u044B.",
      tapToReturn: "\u041D\u0430\u0436\u043C\u0438\u0442\u0435 \u043D\u0430 \u0441\u043B\u043E\u0432\u043E \u0432 \u0433\u0440\u0443\u043F\u043F\u0435, \u0447\u0442\u043E\u0431\u044B \u0432\u0435\u0440\u043D\u0443\u0442\u044C \u0435\u0433\u043E \u0432 \u0431\u0430\u043D\u043A",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443",
      helpRequest: "\u041F\u043E\u043C\u043E\u0433\u0438\u0442\u0435 \u043C\u043D\u0435 \u043F\u043E\u043D\u044F\u0442\u044C \u0441\u0432\u044F\u0437\u044C \u044D\u0442\u0438\u0445 \u0441\u043B\u043E\u0432 \u0441 \u0433\u0440\u0443\u043F\u043F\u0430\u043C\u0438, \u043D\u0435 \u0440\u0430\u0441\u043A\u0440\u044B\u0432\u0430\u044F \u0442\u043E\u0447\u043D\u044B\u0439 \u043E\u0442\u0432\u0435\u0442: {groups}",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041E\u0442\u043F\u0440\u0430\u0432\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u043F\u043E\u043D\u044F\u0442\u043D\u043E\u0435 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u0435 \u043D\u0430 \u043A\u043B\u0430\u0441\u0441\u0438\u0444\u0438\u043A\u0430\u0446\u0438\u044E \u0441\u043B\u043E\u0432.",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0439 \u043D\u0430\u0431\u043E\u0440",
      testingVocabulary: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u043B\u0435\u043A\u0441\u0438\u0447\u0435\u0441\u043A\u0438\u0445 \u043A\u0430\u0442\u0435\u0433\u043E\u0440\u0438\u0439 \u0438 \u0441\u0432\u044F\u0437\u0435\u0439",
      testingGrammar: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0433\u0440\u0430\u043C\u043C\u0430\u0442\u0438\u0447\u0435\u0441\u043A\u0438\u0445 \u0441\u0442\u0440\u0443\u043A\u0442\u0443\u0440 \u0438 \u043C\u043E\u0434\u0435\u043B\u0435\u0439",
      dropPlaceholder: "\u041F\u0435\u0440\u0435\u0442\u0430\u0449\u0438\u0442\u0435 \u0441\u043B\u043E\u0432\u043E \u0441\u044E\u0434\u0430 \u0438\u043B\u0438 \u043D\u0430\u0436\u043C\u0438\u0442\u0435, \u0447\u0442\u043E\u0431\u044B \u0440\u0430\u0437\u043C\u0435\u0441\u0442\u0438\u0442\u044C",
      tapToPlace: "\u041D\u0430\u0436\u043C\u0438\u0442\u0435, \u0447\u0442\u043E\u0431\u044B \u0440\u0430\u0437\u043C\u0435\u0441\u0442\u0438\u0442\u044C \xAB{word}\xBB"
    },
    el: {
      title: "\u0393\u03B5\u03B9\u03C4\u03BF\u03BD\u03B9\u03AD\u03C2 \u03BB\u03AD\u03BE\u03B5\u03C9\u03BD",
      instruction: "\u03A4\u03B1\u03BE\u03B9\u03BD\u03BF\u03BC\u03AE\u03C3\u03C4\u03B5 \u03BA\u03AC\u03B8\u03B5 \u03BB\u03AD\u03BE\u03B7 \u03C3\u03C4\u03B7\u03BD \u03B1\u03BD\u03C4\u03AF\u03C3\u03C4\u03BF\u03B9\u03C7\u03B7 \u03BA\u03B1\u03C4\u03B7\u03B3\u03BF\u03C1\u03AF\u03B1.",
      wordBank: "\u03A4\u03C1\u03AC\u03C0\u03B5\u03B6\u03B1 \u03BB\u03AD\u03BE\u03B5\u03C9\u03BD \xB7 \u03C0\u03B1\u03C4\u03AE\u03C3\u03C4\u03B5 \u03BC\u03B9\u03B1 \u03BB\u03AD\u03BE\u03B7 \u03BA\u03B1\u03B9 \u03BC\u03B5\u03C4\u03AC \u03C4\u03B7\u03BD \u03BF\u03BC\u03AC\u03B4\u03B1 \u03C4\u03B7\u03C2",
      allAssigned: "\u038C\u03BB\u03B5\u03C2 \u03BF\u03B9 \u03BB\u03AD\u03BE\u03B5\u03B9\u03C2 \u03AD\u03C7\u03BF\u03C5\u03BD \u03C4\u03BF\u03C0\u03BF\u03B8\u03B5\u03C4\u03B7\u03B8\u03B5\u03AF.",
      tapToReturn: "\u03A0\u03B1\u03C4\u03AE\u03C3\u03C4\u03B5 \u03BC\u03B9\u03B1 \u03C4\u03BF\u03C0\u03BF\u03B8\u03B5\u03C4\u03B7\u03BC\u03AD\u03BD\u03B7 \u03BB\u03AD\u03BE\u03B7 \u03B3\u03B9\u03B1 \u03B5\u03C0\u03B9\u03C3\u03C4\u03C1\u03BF\u03C6\u03AE \u03C3\u03C4\u03B7\u03BD \u03C4\u03C1\u03AC\u03C0\u03B5\u03B6\u03B1",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1",
      helpRequest: "\u0392\u03BF\u03B7\u03B8\u03AE\u03C3\u03C4\u03B5 \u03BC\u03B5 \u03BD\u03B1 \u03BA\u03B1\u03C4\u03B1\u03BB\u03AC\u03B2\u03C9 \u03C0\u03CE\u03C2 \u03C3\u03C5\u03BD\u03B4\u03AD\u03BF\u03BD\u03C4\u03B1\u03B9 \u03B1\u03C5\u03C4\u03AD\u03C2 \u03BF\u03B9 \u03BB\u03AD\u03BE\u03B5\u03B9\u03C2 \u03BC\u03B5 \u03C4\u03B9\u03C2 \u03BF\u03BC\u03AC\u03B4\u03B5\u03C2 \u03C7\u03C9\u03C1\u03AF\u03C2 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03C4\u03B7 \u03BB\u03CD\u03C3\u03B7: {groups}",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03AC\u03C3\u03BA\u03B7\u03C3\u03B7\u03C2 \u03C4\u03B1\u03BE\u03B9\u03BD\u03CC\u03BC\u03B7\u03C3\u03B7\u03C2 \u03B1\u03C5\u03C4\u03AE \u03C4\u03B7 \u03C6\u03BF\u03C1\u03AC.",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03BF \u03C3\u03CD\u03BD\u03BF\u03BB\u03BF",
      testingVocabulary: "\u0391\u03BE\u03B9\u03BF\u03BB\u03CC\u03B3\u03B7\u03C3\u03B7 \u03BB\u03B5\u03BE\u03B9\u03BB\u03BF\u03B3\u03B9\u03BA\u03CE\u03BD \u03BA\u03B1\u03C4\u03B7\u03B3\u03BF\u03C1\u03B9\u03CE\u03BD \u03BA\u03B1\u03B9 \u03C3\u03C7\u03AD\u03C3\u03B5\u03C9\u03BD",
      testingGrammar: "\u0391\u03BE\u03B9\u03BF\u03BB\u03CC\u03B3\u03B7\u03C3\u03B7 \u03B3\u03C1\u03B1\u03BC\u03BC\u03B1\u03C4\u03B9\u03BA\u03CE\u03BD \u03BC\u03BF\u03C4\u03AF\u03B2\u03C9\u03BD \u03BA\u03B1\u03B9 \u03B4\u03BF\u03BC\u03CE\u03BD",
      dropPlaceholder: "\u03A3\u03CD\u03C1\u03B5\u03C4\u03B5 \u03BC\u03B9\u03B1 \u03BB\u03AD\u03BE\u03B7 \u03B5\u03B4\u03CE \u03AE \u03C0\u03B1\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B3\u03B9\u03B1 \u03C4\u03BF\u03C0\u03BF\u03B8\u03AD\u03C4\u03B7\u03C3\u03B7",
      tapToPlace: "\u03A0\u03B1\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B3\u03B9\u03B1 \u03C4\u03BF\u03C0\u03BF\u03B8\u03AD\u03C4\u03B7\u03C3\u03B7 \u03C4\u03BF\u03C5 \xAB{word}\xBB"
    },
    nl: {
      title: "Woordbuurten",
      instruction: "Sorteer elk woord in de bijbehorende categorie.",
      wordBank: "Woordenbank \xB7 tik op een woord en dan op de juiste groep",
      allAssigned: "Elk woord heeft een plek gevonden.",
      tapToReturn: "Tik op een geplaatst woord om het terug te zetten",
      askForHelp: "Vraag om hulp",
      helpRequest: "Help me begrijpen hoe deze woorden bij de groepen horen zonder het antwoord te verklappen: {groups}",
      skip: "Overslaan",
      submit: "Indienen",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag",
      generationFailed: "We konden deze keer geen duidelijke sorteeroefening maken.",
      tryAnother: "Probeer een andere set",
      testingVocabulary: "Toetsing van woordvelden en categorie\xEBn",
      testingGrammar: "Toetsing van grammaticale structuren en patronen",
      dropPlaceholder: "Sleep een woord hierheen of tik om te plaatsen",
      tapToPlace: "Tik om \u201C{word}\u201D te plaatsen"
    },
    pl: {
      title: "S\u0105siedztwa s\u0142\xF3w",
      instruction: "Przyporz\u0105dkuj ka\u017Cde s\u0142owo do odpowiedniej grupy.",
      wordBank: "Bank s\u0142\xF3w \xB7 dotknij s\u0142owa, a nast\u0119pnie jego grupy",
      allAssigned: "Wszystkie s\u0142owa zosta\u0142y przypisane.",
      tapToReturn: "Dotknij przypisanego s\u0142owa, aby cofn\u0105\u0107 je do banku",
      askForHelp: "Popro\u015B o pomoc",
      helpRequest: "Pom\xF3\u017C mi zrozumie\u0107, jak te s\u0142owa \u0142\u0105cz\u0105 si\u0119 z grupami, bez zdradzania gotowego rozwi\u0105zania: {groups}",
      skip: "Pomi\u0144",
      submit: "Wy\u015Blij",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie",
      generationFailed: "Nie uda\u0142o si\u0119 tym razem wygenerowa\u0107 zadania z podzia\u0142em s\u0142\xF3w.",
      tryAnother: "Wypr\xF3buj inny zestaw",
      testingVocabulary: "Ocena kategorii i powi\u0105za\u0144 leksykalnych",
      testingGrammar: "Ocena struktur i wzorc\xF3w gramatycznych",
      dropPlaceholder: "Przeci\u0105gnij s\u0142owo tutaj lub dotknij, aby umie\u015Bci\u0107",
      tapToPlace: "Dotknij, aby umie\u015Bci\u0107 \u201E{word}\u201D"
    },
    ga: {
      title: "Comharsanachta\xED Focal",
      instruction: "S\xF3rt\xE1il gach focal isteach ina ghr\xFApa cu\xED.",
      wordBank: "Banc focal \xB7 tap\xE1il focal agus ansin a ghr\xFApa",
      allAssigned: "T\xE1 \xE1it faighte ag gach focal.",
      tapToReturn: "Tap\xE1il focal suite chun \xE9 a sheoladh ar ais go dt\xED an banc",
      askForHelp: "Iarr cabhair",
      helpRequest: "Cabhraigh liom an gaol idir na focail seo agus na gr\xFApa\xED a thuiscint gan an r\xE9iteach a thabhairt dom: {groups}",
      skip: "Scipe\xE1il",
      submit: "Cuir isteach",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile",
      generationFailed: "N\xEDorbh fh\xE9idir ceist shoil\xE9ir s\xF3rt\xE1la focal a ghini\xFAint an uair seo.",
      tryAnother: "Bain triail as sraith eile",
      testingVocabulary: "T\xE1st\xE1il ar r\xE9ims\xED agus catag\xF3ir\xED focl\xF3ra",
      testingGrammar: "T\xE1st\xE1il ar phatr\xFAin agus strucht\xFAir ghramada\xED",
      dropPlaceholder: "Tarraing focal anseo n\xF3 tap\xE1il le cur ann",
      tapToPlace: "Tap\xE1il chun \u201C{word}\u201D a chur ann"
    },
    ar: {
      title: "\u0645\u062C\u0645\u0648\u0639\u0627\u062A \u0627\u0644\u0643\u0644\u0645\u0627\u062A",
      instruction: "\u0642\u0645 \u0628\u0641\u0631\u0632 \u0643\u0644 \u0643\u0644\u0645\u0629 \u0641\u064A \u0645\u062C\u0645\u0648\u0639\u062A\u0647\u0627 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629.",
      wordBank: "\u0628\u0646\u0643 \u0627\u0644\u0643\u0644\u0645\u0627\u062A \xB7 \u0627\u0636\u063A\u0637 \u0639\u0644\u0649 \u0627\u0644\u0643\u0644\u0645\u0629 \u062B\u0645 \u0639\u0644\u0649 \u0645\u062C\u0645\u0648\u0639\u062A\u0647\u0627",
      allAssigned: "\u062A\u0645 \u0648\u0636\u0639 \u062C\u0645\u064A\u0639 \u0627\u0644\u0643\u0644\u0645\u0627\u062A \u0641\u064A \u0623\u0645\u0627\u0643\u0646\u0647\u0627.",
      tapToReturn: "\u0627\u0636\u063A\u0637 \u0639\u0644\u0649 \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u062D\u062F\u062F\u0629 \u0644\u0625\u0639\u0627\u062F\u062A\u0647\u0627 \u0625\u0644\u0649 \u0627\u0644\u0628\u0646\u0643",
      askForHelp: "\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629",
      helpRequest: "\u0633\u0627\u0639\u062F\u0646\u064A \u0641\u064A \u0641\u0647\u0645 \u0643\u064A\u0641\u064A\u0629 \u0627\u0631\u062A\u0628\u0627\u0637 \u0647\u0630\u0647 \u0627\u0644\u0643\u0644\u0645\u0627\u062A \u0628\u0643\u0644 \u0645\u062C\u0645\u0648\u0639\u0629 \u062F\u0648\u0646 \u0625\u0639\u0637\u0627\u0626\u064A \u0627\u0644\u062A\u0631\u062A\u064A\u0628 \u0627\u0644\u0645\u0628\u0627\u0634\u0631: {groups}",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u0625\u0631\u0633\u0627\u0644",
      checking: "\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A",
      generationFailed: "\u062A\u0639\u0630\u0631 \u0625\u0646\u0634\u0627\u0621 \u062A\u0645\u0631\u064A\u0646 \u062A\u0635\u0646\u064A\u0641 \u0643\u0644\u0645\u0627\u062A \u0648\u0627\u0636\u062D \u0647\u0630\u0647 \u0627\u0644\u0645\u0631\u0629.",
      tryAnother: "\u062C\u0631\u0628 \u0645\u062C\u0645\u0648\u0639\u0629 \u0623\u062E\u0631\u0649",
      testingVocabulary: "\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u0641\u0626\u0627\u062A \u0648\u0627\u0644\u0639\u0644\u0627\u0642\u0627\u062A \u0627\u0644\u0645\u0639\u062C\u0645\u064A\u0629",
      testingGrammar: "\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u062A\u0631\u0627\u0643\u064A\u0628 \u0648\u0627\u0644\u0623\u0646\u0645\u0627\u0637 \u0627\u0644\u0646\u062D\u0648\u064A\u0629",
      dropPlaceholder: "\u0627\u0633\u062D\u0628 \u0643\u0644\u0645\u0629 \u0647\u0646\u0627 \u0623\u0648 \u0627\u0636\u063A\u0637 \u0644\u0648\u0636\u0639\u0647\u0627",
      tapToPlace: "\u0627\u0636\u063A\u0637 \u0644\u0648\u0636\u0639 \xAB{word}\xBB"
    },
    hi: {
      title: "\u0936\u092C\u094D\u0926 \u0938\u092E\u0942\u0939",
      instruction: "\u092A\u094D\u0930\u0924\u094D\u092F\u0947\u0915 \u0936\u092C\u094D\u0926 \u0915\u094B \u0909\u0938\u0915\u0947 \u0938\u0939\u0940 \u0938\u092E\u0942\u0939 \u092E\u0947\u0902 \u0930\u0916\u0947\u0902\u0964",
      wordBank: "\u0936\u092C\u094D\u0926 \u092C\u0948\u0902\u0915 \xB7 \u090F\u0915 \u0936\u092C\u094D\u0926 \u092A\u0930 \u091F\u0948\u092A \u0915\u0930\u0947\u0902, \u092B\u093F\u0930 \u0909\u0938\u0915\u0947 \u0938\u092E\u0942\u0939 \u092A\u0930",
      allAssigned: "\u0938\u092D\u0940 \u0936\u092C\u094D\u0926 \u0935\u094D\u092F\u0935\u0938\u094D\u0925\u093F\u0924 \u0939\u094B \u0917\u090F \u0939\u0948\u0902\u0964",
      tapToReturn: "\u0936\u092C\u094D\u0926 \u0915\u094B \u0935\u093E\u092A\u0938 \u092C\u0948\u0902\u0915 \u092E\u0947\u0902 \u092D\u0947\u091C\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0909\u0938 \u092A\u0930 \u091F\u0948\u092A \u0915\u0930\u0947\u0902",
      askForHelp: "\u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u092C\u093F\u0928\u093E \u0909\u0924\u094D\u0924\u0930 \u092C\u0924\u093E\u090F \u092F\u0939 \u0938\u092E\u091D\u0928\u0947 \u092E\u0947\u0902 \u092E\u0926\u0926 \u0915\u0930\u0947\u0902 \u0915\u093F \u092F\u0947 \u0936\u092C\u094D\u0926 \u092A\u094D\u0930\u0924\u094D\u092F\u0947\u0915 \u0938\u092E\u0942\u0939 \u0938\u0947 \u0915\u0948\u0938\u0947 \u0938\u0902\u092C\u0902\u0927\u093F\u0924 \u0939\u0948\u0902: {groups}",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u092E\u093E \u0915\u0930\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928",
      generationFailed: "\u0907\u0938 \u092C\u093E\u0930 \u0938\u094D\u092A\u0937\u094D\u091F \u0936\u092C\u094D\u0926 \u0935\u0930\u094D\u0917\u0940\u0915\u0930\u0923 \u092A\u094D\u0930\u0936\u094D\u0928 \u0928\u0939\u0940\u0902 \u092C\u0928\u093E\u092F\u093E \u091C\u093E \u0938\u0915\u093E\u0964",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u0938\u0947\u091F \u0906\u091C\u093C\u092E\u093E\u090F\u0902",
      testingVocabulary: "\u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u0936\u094D\u0930\u0947\u0923\u093F\u092F\u094B\u0902 \u0914\u0930 \u0938\u0902\u092C\u0902\u0927\u094B\u0902 \u0915\u093E \u092A\u0930\u0940\u0915\u094D\u0937\u0923",
      testingGrammar: "\u0935\u094D\u092F\u093E\u0915\u0930\u0923\u093F\u0915 \u0938\u0902\u0930\u091A\u0928\u093E\u0913\u0902 \u0914\u0930 \u092A\u0948\u091F\u0930\u094D\u0928\u094B\u0902 \u0915\u093E \u092A\u0930\u0940\u0915\u094D\u0937\u0923",
      dropPlaceholder: "\u092F\u0939\u093E\u0901 \u090F\u0915 \u0936\u092C\u094D\u0926 \u0916\u0940\u0902\u091A\u0947\u0902 \u092F\u093E \u0930\u0916\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u091F\u0948\u092A \u0915\u0930\u0947\u0902",
      tapToPlace: "\u201C{word}\u201D \u0930\u0916\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u091F\u0948\u092A \u0915\u0930\u0947\u0902"
    },
    zh: {
      title: "\u8BCD\u6C47\u5206\u7C7B",
      instruction: "\u5C06\u6BCF\u4E2A\u8BCD\u5F52\u7C7B\u5230\u76F8\u5E94\u7684\u7EC4\u522B\u4E2D\u3002",
      wordBank: "\u8BCD\u5E93 \xB7 \u70B9\u51FB\u4E00\u4E2A\u8BCD\uFF0C\u7136\u540E\u70B9\u51FB\u5176\u6240\u5C5E\u7EC4\u522B",
      allAssigned: "\u6240\u6709\u8BCD\u6C47\u5DF2\u5B8C\u6210\u5F52\u7C7B\u3002",
      tapToReturn: "\u70B9\u51FB\u5DF2\u653E\u7F6E\u7684\u8BCD\u6C47\u53EF\u5C06\u5176\u8FD4\u56DE\u8BCD\u5E93",
      askForHelp: "\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u8BF7\u5E2E\u52A9\u6211\u7406\u89E3\u8FD9\u4E9B\u8BCD\u4E0E\u5404\u5206\u7C7B\u4E4B\u95F4\u7684\u5173\u8054\uFF0C\u4F46\u4E0D\u8981\u76F4\u63A5\u544A\u8BC9\u6211\u7B54\u6848\uFF1A{groups}",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u6B63\u5728\u68C0\u67E5\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898",
      generationFailed: "\u8FD9\u6B21\u65E0\u6CD5\u521B\u5EFA\u660E\u786E\u7684\u8BCD\u6C47\u5206\u7C7B\u95EE\u9898\u3002",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u7EC4",
      testingVocabulary: "\u6D4B\u8BD5\u8BCD\u6C47\u7C7B\u522B\u4E0E\u8BED\u4E49\u5173\u8054",
      testingGrammar: "\u6D4B\u8BD5\u8BED\u6CD5\u7ED3\u6784\u4E0E\u53E5\u6CD5\u6A21\u5F0F",
      dropPlaceholder: "\u62D6\u653E\u8BCD\u6C47\u81F3\u6B64\u5904\u6216\u70B9\u51FB\u653E\u7F6E",
      tapToPlace: "\u70B9\u51FB\u653E\u7F6E\u201C{word}\u201D"
    },
    nah: {
      title: "Tlahtolcenquizaliztli",
      instruction: "Xikcecenquiztili in tlahtolli yuhqui tlanahuatilli.",
      wordBank: "Tlahtolcentiliztli \xB7 xikpachiuh ce tlahtolli ihuan icualcan",
      allAssigned: "Mochintin tlahtolli quipiah incal.",
      tapToReturn: "Xikpachiuh in tlahtolli inic mocuepas",
      askForHelp: "Xiktlahtlani tepalewiliztli",
      helpRequest: "Xinechpalehuili yuhqui tlahtolcenquizaliztli: {groups}",
      skip: "Xikpano",
      submit: "Titia",
      checking: "Motlatlatia\u2026",
      tryAgain: "Ocsepa xikyehyeco",
      nextQuestion: "Ocse tlahtolli",
      generationFailed: "Ahmo huelic omoyancuic-chih tlahtolli.",
      tryAnother: "Ocse tlahtolli",
      testingVocabulary: "Yehyecoliztli tlahtolmatiliztli",
      testingGrammar: "Yehyecoliztli tlahtolmelahualiztli",
      dropPlaceholder: "Xikhuilana ce tlahtolli nican noso xikpachiuh",
      tapToPlace: "Xikpachiuh inic tictlalis \u201C{word}\u201D"
    },
    yua: {
      title: "Much'kabil T'aano'ob",
      instruction: "Tsool tul\xE1akal t'aan ti' u much'kabil.",
      wordBank: "K'uubil t'aano'ob \xB7 ch'a' jump'\xE9el t'aan ka ts'\xE1a ti' u much'",
      allAssigned: "Tul\xE1akal t'aano'ob ts'o'ok u k'uchul tu yotoch.",
      tapToReturn: "Mach le t'aano' utia'al u suut tu k'uubil",
      askForHelp: "K'\xE1at \xE1antaj",
      helpRequest: "\xC1anten in na'at bix u m\xFAuch'ul le t'aana': {groups}",
      skip: "M\xE1anen",
      submit: "T\xFAuxte",
      checking: "T\xFAun yilik\u2026",
      tryAgain: "Ka'a y\xF3olte",
      nextQuestion: "U l\xE1ak' k'\xE1atchi'",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le tsool t'aana'.",
      tryAnother: "Y\xF3olt u l\xE1ak' t'aan",
      testingVocabulary: "Xak'al tsoolil t'aano'ob",
      testingGrammar: "Xak'al nu'ukbesajil t'aano'ob",
      dropPlaceholder: "Jats' jump'\xE9el t'aan waye' wa mach utia'al a ts'\xE1aik",
      tapToPlace: "Mach utia'al a ts'\xE1aik \u201C{word}\u201D"
    }
  });
  function getWordNeighborhoodsCopy(language = "en") {
    return WORD_NEIGHBORHOODS_COPY[language] || WORD_NEIGHBORHOODS_COPY.en;
  }
  function formatWordNeighborhoodsCopy(template, variables = {}) {
    return String(template || "").replace(
      /\{(\w+)\}/g,
      (_, key) => variables[key] == null ? `{${key}}` : String(variables[key])
    );
  }

  // ../nosabos/nosabos/src/utils/morphologyForgeI18n.js
  var MORPHOLOGY_FORGE_I18N = {
    en: {
      title: "Morphology Forge",
      instruction: "Build the missing word piece by piece.",
      forgeSlot: "Forged word",
      emptyForge: "Drag or tap pieces below to forge the missing word",
      pieceBank: "Available pieces",
      allPiecesUsed: "All pieces placed.",
      tapToRemove: "Tap to remove piece",
      askForHelp: "Ask assistant for help",
      helpRequest: "Can you give me a small hint about the structure of the missing word in this sentence?",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question \u2192",
      generationFailed: "We couldn't forge this question. Try another one!",
      tryAnother: "Try another",
      testingVocabulary: "Testing vocabulary",
      testingGrammar: "Testing grammar"
    },
    es: {
      title: "Forja morfol\xF3gica",
      instruction: "Construye la palabra que falta pieza por pieza.",
      forgeSlot: "Palabra forjada",
      emptyForge: "Arrastra o toca las piezas abajo para forjar la palabra faltante",
      pieceBank: "Piezas disponibles",
      allPiecesUsed: "Todas las piezas est\xE1n colocadas.",
      tapToRemove: "Toca para quitar la pieza",
      askForHelp: "Pedir ayuda al asistente",
      helpRequest: "\xBFPuedes darme una peque\xF1a pista sobre la estructura de la palabra que falta en esta oraci\xF3n?",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta \u2192",
      generationFailed: "No pudimos forjar esta pregunta. \xA1Prueba con otra!",
      tryAnother: "Probar otra",
      testingVocabulary: "Evaluando vocabulario",
      testingGrammar: "Evaluando gram\xE1tica"
    },
    fr: {
      title: "Forge morphologique",
      instruction: "Construisez le mot manquant pi\xE8ce par pi\xE8ce.",
      forgeSlot: "Mot forg\xE9",
      emptyForge: "Faites glisser ou touchez les pi\xE8ces ci-dessous pour forger le mot manquant",
      pieceBank: "Pi\xE8ces disponibles",
      allPiecesUsed: "Toutes les pi\xE8ces sont plac\xE9es.",
      tapToRemove: "Touchez pour retirer la pi\xE8ce",
      askForHelp: "Demander de l'aide \xE0 l'assistant",
      helpRequest: "Pouvez-vous me donner un petit indice sur la structure du mot manquant dans cette phrase ?",
      skip: "Passer",
      submit: "V\xE9rifier",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante \u2192",
      generationFailed: "Impossible de forger cette question. Essayez-en une autre !",
      tryAnother: "Essayer une autre",
      testingVocabulary: "\xC9valuation du vocabulaire",
      testingGrammar: "\xC9valuation de la grammaire"
    },
    de: {
      title: "Morphologie-Schmiede",
      instruction: "Baue das fehlende Wort St\xFCck f\xFCr St\xFCck zusammen.",
      forgeSlot: "Geschmiedetes Wort",
      emptyForge: "Ziehe oder tippe Bausteine unten an, um das fehlende Wort zu schmieden",
      pieceBank: "Verf\xFCgbare Bausteine",
      allPiecesUsed: "Alle Bausteine wurden platziert.",
      tapToRemove: "Tippen zum Entfernen",
      askForHelp: "Assistenten um Hilfe bitten",
      helpRequest: "Kannst du mir einen kleinen Hinweis zur Struktur des fehlenden Wortes in diesem Satz geben?",
      skip: "\xDCberspringen",
      submit: "\xDCberpr\xFCfen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Erneut versuchen",
      nextQuestion: "N\xE4chste Frage \u2192",
      generationFailed: "Diese Frage konnte nicht erstellt werden. Versuche eine andere!",
      tryAnother: "Andere versuchen",
      testingVocabulary: "Wortschatz-Test",
      testingGrammar: "Grammatik-Test"
    },
    it: {
      title: "Forgia morfologica",
      instruction: "Costruisci la parola mancante pezzo per pezzo.",
      forgeSlot: "Parola forgiata",
      emptyForge: "Trascina o tocca i pezzi sottostanti per forgiare la parola mancante",
      pieceBank: "Pezzi disponibili",
      allPiecesUsed: "Tutti i pezzi sono posizionati.",
      tapToRemove: "Tocca per rimuovere il pezzo",
      askForHelp: "Chiedi aiuto all'assistente",
      helpRequest: "Puoi darmi un piccolo indizio sulla struttura della parola mancante in questa frase?",
      skip: "Salta",
      submit: "Verifica",
      checking: "Verifica in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda \u2192",
      generationFailed: "Impossibile forgiare questa domanda. Provane un'altra!",
      tryAnother: "Provane un'altra",
      testingVocabulary: "Verifica del vocabolario",
      testingGrammar: "Verifica della grammatica"
    },
    pt: {
      title: "Forja Morfol\xF3gica",
      instruction: "Construa a palavra que falta pe\xE7a por pe\xE7a.",
      forgeSlot: "Palavra forjada",
      emptyForge: "Arraste ou toque nas pe\xE7as abaixo para forjar a palavra ausente",
      pieceBank: "Pe\xE7as dispon\xEDveis",
      allPiecesUsed: "Todas as pe\xE7as foram colocadas.",
      tapToRemove: "Toque para remover a pe\xE7a",
      askForHelp: "Pedir ajuda ao assistente",
      helpRequest: "Pode me dar uma pequena dica sobre a estrutura da palavra que falta nesta frase?",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta \u2192",
      generationFailed: "N\xE3o foi poss\xEDvel forjar esta pergunta. Tente outra!",
      tryAnother: "Tentar outra",
      testingVocabulary: "Testando vocabul\xE1rio",
      testingGrammar: "Testando gram\xE1tica"
    },
    ja: {
      title: "\u8A9E\u5F62\u30D5\u30A9\u30FC\u30B8",
      instruction: "\u30D1\u30FC\u30C4\u3092\u7D44\u307F\u5408\u308F\u305B\u3066\u6B20\u3051\u3066\u3044\u308B\u5358\u8A9E\u3092\u4F5C\u308A\u307E\u3057\u3087\u3046\u3002",
      forgeSlot: "\u4F5C\u6210\u3057\u305F\u5358\u8A9E",
      emptyForge: "\u4E0B\u306E\u30D1\u30FC\u30C4\u3092\u30C9\u30E9\u30C3\u30B0\u307E\u305F\u306F\u30BF\u30C3\u30D7\u3057\u3066\u5358\u8A9E\u3092\u4F5C\u6210\u3057\u3066\u304F\u3060\u3055\u3044",
      pieceBank: "\u5229\u7528\u53EF\u80FD\u306A\u30D1\u30FC\u30C4",
      allPiecesUsed: "\u3059\u3079\u3066\u306E\u30D1\u30FC\u30C4\u304C\u914D\u7F6E\u3055\u308C\u307E\u3057\u305F\u3002",
      tapToRemove: "\u30BF\u30C3\u30D7\u3057\u3066\u30D1\u30FC\u30C4\u3092\u524A\u9664",
      askForHelp: "\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8\u306B\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u3053\u306E\u6587\u3067\u6B20\u3051\u3066\u3044\u308B\u5358\u8A9E\u306E\u8A9E\u5F62\u69CB\u9020\u306B\u3064\u3044\u3066\u30D2\u30F3\u30C8\u3092\u6559\u3048\u3066\u304F\u308C\u307E\u3059\u304B\uFF1F",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3059\u308B",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C\u3078 \u2192",
      generationFailed: "\u3053\u306E\u554F\u984C\u3092\u751F\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002\u5225\u306E\u554F\u984C\u3092\u304A\u8A66\u3057\u304F\u3060\u3055\u3044\u3002",
      tryAnother: "\u5225\u306E\u554F\u984C\u3092\u8A66\u3059",
      testingVocabulary: "\u8A9E\u5F59\u30C6\u30B9\u30C8",
      testingGrammar: "\u6587\u6CD5\u30C6\u30B9\u30C8"
    },
    ru: {
      title: "\u041A\u0443\u0437\u043D\u0438\u0446\u0430 \u043C\u043E\u0440\u0444\u043E\u043B\u043E\u0433\u0438\u0438",
      instruction: "\u0421\u043E\u0431\u0435\u0440\u0438\u0442\u0435 \u043F\u0440\u043E\u043F\u0443\u0449\u0435\u043D\u043D\u043E\u0435 \u0441\u043B\u043E\u0432\u043E \u043F\u043E \u0447\u0430\u0441\u0442\u044F\u043C.",
      forgeSlot: "\u0421\u043E\u0431\u0440\u0430\u043D\u043D\u043E\u0435 \u0441\u043B\u043E\u0432\u043E",
      emptyForge: "\u041F\u0435\u0440\u0435\u0442\u0430\u0449\u0438\u0442\u0435 \u0438\u043B\u0438 \u043D\u0430\u0436\u043C\u0438\u0442\u0435 \u043D\u0430 \u0444\u0440\u0430\u0433\u043C\u0435\u043D\u0442\u044B \u0432\u043D\u0438\u0437\u0443, \u0447\u0442\u043E\u0431\u044B \u0441\u043E\u0431\u0440\u0430\u0442\u044C \u0441\u043B\u043E\u0432\u043E",
      pieceBank: "\u0414\u043E\u0441\u0442\u0443\u043F\u043D\u044B\u0435 \u0444\u0440\u0430\u0433\u043C\u0435\u043D\u0442\u044B",
      allPiecesUsed: "\u0412\u0441\u0435 \u0444\u0440\u0430\u0433\u043C\u0435\u043D\u0442\u044B \u0440\u0430\u0437\u043C\u0435\u0449\u0435\u043D\u044B.",
      tapToRemove: "\u041D\u0430\u0436\u043C\u0438\u0442\u0435, \u0447\u0442\u043E\u0431\u044B \u0443\u0431\u0440\u0430\u0442\u044C \u0444\u0440\u0430\u0433\u043C\u0435\u043D\u0442",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u043C\u043E\u0449\u0438 \u0443 \u0430\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442\u0430",
      helpRequest: "\u041C\u043E\u0436\u0435\u0442\u0435 \u0434\u0430\u0442\u044C \u043D\u0435\u0431\u043E\u043B\u044C\u0448\u0443\u044E \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443 \u043E \u0441\u0442\u0440\u0443\u043A\u0442\u0443\u0440\u0435 \u043F\u0440\u043E\u043F\u0443\u0449\u0435\u043D\u043D\u043E\u0433\u043E \u0441\u043B\u043E\u0432\u0430 \u0432 \u044D\u0442\u043E\u043C \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0438?",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441 \u2192",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u044D\u0442\u043E\u0442 \u0432\u043E\u043F\u0440\u043E\u0441. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0434\u0440\u0443\u0433\u043E\u0439!",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0439",
      testingVocabulary: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0441\u043B\u043E\u0432\u0430\u0440\u043D\u043E\u0433\u043E \u0437\u0430\u043F\u0430\u0441\u0430",
      testingGrammar: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0433\u0440\u0430\u043C\u043C\u0430\u0442\u0438\u043A\u0438"
    },
    el: {
      title: "\u039C\u03BF\u03C1\u03C6\u03BF\u03BB\u03BF\u03B3\u03B9\u03BA\u03CC \u0395\u03C1\u03B3\u03B1\u03C3\u03C4\u03AE\u03C1\u03B9",
      instruction: "\u03A6\u03C4\u03B9\u03AC\u03BE\u03C4\u03B5 \u03C4\u03B7 \u03BB\u03AD\u03BE\u03B7 \u03C0\u03BF\u03C5 \u03BB\u03B5\u03AF\u03C0\u03B5\u03B9 \u03BA\u03BF\u03BC\u03BC\u03AC\u03C4\u03B9-\u03BA\u03BF\u03BC\u03BC\u03AC\u03C4\u03B9.",
      forgeSlot: "\u03A3\u03C7\u03B7\u03BC\u03B1\u03C4\u03B9\u03C3\u03BC\u03AD\u03BD\u03B7 \u03BB\u03AD\u03BE\u03B7",
      emptyForge: "\u03A3\u03CD\u03C1\u03B5\u03C4\u03B5 \u03AE \u03C0\u03B1\u03C4\u03AE\u03C3\u03C4\u03B5 \u03C4\u03B1 \u03BA\u03BF\u03BC\u03BC\u03AC\u03C4\u03B9\u03B1 \u03C0\u03B1\u03C1\u03B1\u03BA\u03AC\u03C4\u03C9 \u03B3\u03B9\u03B1 \u03BD\u03B1 \u03C3\u03C7\u03B7\u03BC\u03B1\u03C4\u03AF\u03C3\u03B5\u03C4\u03B5 \u03C4\u03B7 \u03BB\u03AD\u03BE\u03B7 \u03C0\u03BF\u03C5 \u03BB\u03B5\u03AF\u03C0\u03B5\u03B9",
      pieceBank: "\u0394\u03B9\u03B1\u03B8\u03AD\u03C3\u03B9\u03BC\u03B1 \u03BA\u03BF\u03BC\u03BC\u03AC\u03C4\u03B9\u03B1",
      allPiecesUsed: "\u038C\u03BB\u03B1 \u03C4\u03B1 \u03BA\u03BF\u03BC\u03BC\u03AC\u03C4\u03B9\u03B1 \u03AD\u03C7\u03BF\u03C5\u03BD \u03C4\u03BF\u03C0\u03BF\u03B8\u03B5\u03C4\u03B7\u03B8\u03B5\u03AF.",
      tapToRemove: "\u03A0\u03B1\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B3\u03B9\u03B1 \u03B1\u03C6\u03B1\u03AF\u03C1\u03B5\u03C3\u03B7 \u03BA\u03BF\u03BC\u03BC\u03B1\u03C4\u03B9\u03BF\u03CD",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1 \u03B1\u03C0\u03CC \u03C4\u03BF\u03BD \u03B2\u03BF\u03B7\u03B8\u03CC",
      helpRequest: "\u039C\u03C0\u03BF\u03C1\u03B5\u03AF\u03C4\u03B5 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03AD\u03BD\u03B1 \u03BC\u03B9\u03BA\u03C1\u03CC \u03C3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03BF \u03B3\u03B9\u03B1 \u03C4\u03B7 \u03B4\u03BF\u03BC\u03AE \u03C4\u03B7\u03C2 \u03BB\u03AD\u03BE\u03B7\u03C2 \u03C0\u03BF\u03C5 \u03BB\u03B5\u03AF\u03C0\u03B5\u03B9 \u03C3\u03B5 \u03B1\u03C5\u03C4\u03AE\u03BD \u03C4\u03B7\u03BD \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7;",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7 \u2192",
      generationFailed: "\u0394\u03B5\u03BD \u03BC\u03C0\u03BF\u03C1\u03AD\u03C3\u03B1\u03BC\u03B5 \u03BD\u03B1 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AE\u03C3\u03BF\u03C5\u03BC\u03B5 \u03B1\u03C5\u03C4\u03AE\u03BD \u03C4\u03B7\u03BD \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7. \u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7!",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7",
      testingVocabulary: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2 \u03BB\u03B5\u03BE\u03B9\u03BB\u03BF\u03B3\u03AF\u03BF\u03C5",
      testingGrammar: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2 \u03B3\u03C1\u03B1\u03BC\u03BC\u03B1\u03C4\u03B9\u03BA\u03AE\u03C2"
    },
    nl: {
      title: "Morfologie-Smederij",
      instruction: "Bouw het ontbrekende woord stukje voor stukje op.",
      forgeSlot: "Gesmeed woord",
      emptyForge: "Sleep of tik op de onderstaande stukjes om het ontbrekende woord te smeden",
      pieceBank: "Beschikbare stukjes",
      allPiecesUsed: "Alle stukjes zijn geplaatst.",
      tapToRemove: "Tik om stukje te verwijderen",
      askForHelp: "Vraag assistent om hulp",
      helpRequest: "Kun je me een kleine hint geven over de structuur van het ontbrekende woord in deze zin?",
      skip: "Overslaan",
      submit: "Controleren",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag \u2192",
      generationFailed: "We konden deze vraag niet smeden. Probeer een andere!",
      tryAnother: "Probeer een andere",
      testingVocabulary: "Woordenschat testen",
      testingGrammar: "Grammatica testen"
    },
    pl: {
      title: "Ku\u017Ania morfologii",
      instruction: "Zbuduj brakuj\u0105ce s\u0142owo kawa\u0142ek po kawa\u0142ku.",
      forgeSlot: "Wykute s\u0142owo",
      emptyForge: "Przeci\u0105gnij lub dotknij elementy poni\u017Cej, aby u\u0142o\u017Cy\u0107 brakuj\u0105ce s\u0142owo",
      pieceBank: "Dost\u0119pne elementy",
      allPiecesUsed: "Wszystkie elementy zosta\u0142y umieszczone.",
      tapToRemove: "Dotknij, aby usun\u0105\u0107 element",
      askForHelp: "Popro\u015B asystenta o pomoc",
      helpRequest: "Czy mo\u017Cesz da\u0107 mi ma\u0142\u0105 wskaz\xF3wk\u0119 dotycz\u0105c\u0105 struktury brakuj\u0105cego s\u0142owa w tym zdaniu?",
      skip: "Pomi\u0144",
      submit: "Sprawd\u017A",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie \u2192",
      generationFailed: "Nie uda\u0142o si\u0119 stworzy\u0107 tego pytania. Spr\xF3buj innego!",
      tryAnother: "Spr\xF3buj innego",
      testingVocabulary: "Test s\u0142ownictwa",
      testingGrammar: "Test gramatyki"
    },
    ga: {
      title: "Ce\xE1rta Moirfeola\xEDochta",
      instruction: "T\xF3g an focal at\xE1 ar iarraidh cuid ar chuid.",
      forgeSlot: "Focal cruthaithe",
      emptyForge: "Tarraing n\xF3 tap\xE1il na p\xEDosa\xED th\xEDos chun an focal at\xE1 ar iarraidh a chruth\xFA",
      pieceBank: "P\xEDosa\xED ar f\xE1il",
      allPiecesUsed: "T\xE1 gach p\xEDosa curtha isteach.",
      tapToRemove: "Tap\xE1il chun p\xEDosa a bhaint",
      askForHelp: "Iarr cabhair ar an gc\xFAnt\xF3ir",
      helpRequest: "An f\xE9idir leat leid bheag a thabhairt dom faoi strucht\xFAr an fhocail at\xE1 ar iarraidh san abairt seo?",
      skip: "Scipe\xE1il",
      submit: "Seol",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile \u2192",
      generationFailed: "N\xEDorbh fh\xE9idir an cheist seo a chruth\xFA. Bain triail as ceann eile!",
      tryAnother: "Bain triail as ceann eile",
      testingVocabulary: "Ag t\xE1st\xE1il focl\xF3ra",
      testingGrammar: "Ag t\xE1st\xE1il gramada\xED"
    },
    ar: {
      title: "\u0645\u0633\u0628\u0643 \u0627\u0644\u0635\u0631\u0641 \u0648\u0627\u0644\u0627\u0634\u062A\u0642\u0627\u0642",
      instruction: "\u0642\u0645 \u0628\u0628\u0646\u0627\u0621 \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0641\u0642\u0648\u062F\u0629 \u0642\u0637\u0639\u0629 \u0628\u0639\u062F \u0642\u0637\u0639\u0629.",
      forgeSlot: "\u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0635\u0648\u063A\u0629",
      emptyForge: "\u0627\u0633\u062D\u0628 \u0623\u0648 \u0627\u0646\u0642\u0631 \u0639\u0644\u0649 \u0627\u0644\u0645\u0642\u0627\u0637\u0639 \u0623\u062F\u0646\u0627\u0647 \u0644\u0635\u064A\u0627\u063A\u0629 \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0641\u0642\u0648\u062F\u0629",
      pieceBank: "\u0627\u0644\u0645\u0642\u0627\u0637\u0639 \u0627\u0644\u0645\u062A\u0627\u062D\u0629",
      allPiecesUsed: "\u062A\u0645 \u0648\u0636\u0639 \u062C\u0645\u064A\u0639 \u0627\u0644\u0645\u0642\u0627\u0637\u0639.",
      tapToRemove: "\u0627\u0646\u0642\u0631 \u0644\u0625\u0632\u0627\u0644\u0629 \u0627\u0644\u0645\u0642\u0637\u0639",
      askForHelp: "\u0627\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u0633\u0627\u0639\u062F",
      helpRequest: "\u0647\u0644 \u064A\u0645\u0643\u0646\u0643 \u0625\u0639\u0637\u0627\u0626\u064A \u062A\u0644\u0645\u064A\u062D\u064B\u0627 \u0628\u0633\u064A\u0637\u064B\u0627 \u062D\u0648\u0644 \u0628\u0646\u064A\u0629 \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0641\u0642\u0648\u062F\u0629 \u0641\u064A \u0647\u0630\u0647 \u0627\u0644\u062C\u0645\u0644\u0629\u061F",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u062A\u062D\u0642\u0642",
      checking: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A \u2190",
      generationFailed: "\u062A\u0639\u0630\u0631 \u0635\u064A\u0627\u063A\u0629 \u0647\u0630\u0627 \u0627\u0644\u0633\u0624\u0627\u0644. \u062C\u0631\u0628 \u0633\u0624\u0627\u0644\u0627\u064B \u0622\u062E\u0631!",
      tryAnother: "\u062C\u0631\u0628 \u0633\u0624\u0627\u0644\u0627\u064B \u0622\u062E\u0631",
      testingVocabulary: "\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u0645\u0641\u0631\u062F\u0627\u062A",
      testingGrammar: "\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u0642\u0648\u0627\u0639\u062F"
    },
    hi: {
      title: "\u0936\u092C\u094D\u0926 \u0930\u091A\u0928\u093E \u0936\u093E\u0932\u093E",
      instruction: "\u0932\u093E\u092A\u0924\u093E \u0936\u092C\u094D\u0926 \u0915\u094B \u090F\u0915-\u090F\u0915 \u0939\u093F\u0938\u094D\u0938\u0947 \u0938\u0947 \u091C\u094B\u0921\u093C\u0915\u0930 \u092C\u0928\u093E\u090F\u0902\u0964",
      forgeSlot: "\u0930\u091A\u093E \u0917\u092F\u093E \u0936\u092C\u094D\u0926",
      emptyForge: "\u0932\u093E\u092A\u0924\u093E \u0936\u092C\u094D\u0926 \u092C\u0928\u093E\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0928\u0940\u091A\u0947 \u0926\u093F\u090F \u0917\u090F \u091F\u0941\u0915\u0921\u093C\u094B\u0902 \u0915\u094B \u0916\u0940\u0902\u091A\u0947\u0902 \u092F\u093E \u091F\u0948\u092A \u0915\u0930\u0947\u0902",
      pieceBank: "\u0909\u092A\u0932\u092C\u094D\u0927 \u091F\u0941\u0915\u0921\u093C\u0947",
      allPiecesUsed: "\u0938\u092D\u0940 \u091F\u0941\u0915\u0921\u093C\u0947 \u0930\u0916\u0947 \u0917\u090F \u0939\u0948\u0902\u0964",
      tapToRemove: "\u091F\u0941\u0915\u0921\u093C\u093E \u0939\u091F\u093E\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u091F\u0948\u092A \u0915\u0930\u0947\u0902",
      askForHelp: "\u0938\u0939\u093E\u092F\u0915 \u0938\u0947 \u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u0915\u094D\u092F\u093E \u0906\u092A \u0907\u0938 \u0935\u093E\u0915\u094D\u092F \u092E\u0947\u0902 \u0917\u093E\u092F\u092C \u0936\u092C\u094D\u0926 \u0915\u0940 \u0938\u0902\u0930\u091A\u0928\u093E \u0915\u0947 \u092C\u093E\u0930\u0947 \u092E\u0947\u0902 \u0925\u094B\u0921\u093C\u093E \u0938\u0902\u0915\u0947\u0924 \u0926\u0947 \u0938\u0915\u0924\u0947 \u0939\u0948\u0902?",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u093E\u0902\u091A\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u2192",
      generationFailed: "\u092F\u0939 \u092A\u094D\u0930\u0936\u094D\u0928 \u0924\u0948\u092F\u093E\u0930 \u0928\u0939\u0940\u0902 \u0939\u094B \u0938\u0915\u093E\u0964 \u0915\u0943\u092A\u092F\u093E \u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902!",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902",
      testingVocabulary: "\u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u092A\u0930\u0940\u0915\u094D\u0937\u0923",
      testingGrammar: "\u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u092A\u0930\u0940\u0915\u094D\u0937\u0923"
    },
    zh: {
      title: "\u8BCD\u5F62\u5DE5\u574A",
      instruction: "\u9010\u5757\u6784\u5EFA\u7F3A\u5931\u7684\u5355\u8BCD\u3002",
      forgeSlot: "\u5DF2\u6784\u5EFA\u7684\u8BCD\u8BED",
      emptyForge: "\u62D6\u62FD\u6216\u70B9\u51FB\u4E0B\u65B9\u90E8\u4EF6\u4EE5\u6784\u5EFA\u7F3A\u5931\u7684\u5355\u8BCD",
      pieceBank: "\u53EF\u7528\u90E8\u4EF6",
      allPiecesUsed: "\u6240\u6709\u90E8\u4EF6\u5747\u5DF2\u653E\u7F6E\u3002",
      tapToRemove: "\u70B9\u51FB\u79FB\u9664\u90E8\u4EF6",
      askForHelp: "\u5411\u52A9\u624B\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u4F60\u80FD\u5C31\u672C\u53E5\u4E2D\u7F3A\u5931\u5355\u8BCD\u7684\u6784\u8BCD\u7ED3\u6784\u7ED9\u6211\u4E00\u4E2A\u5C0F\u63D0\u793A\u5417\uFF1F",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u68C0\u67E5\u4E2D\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898 \u2192",
      generationFailed: "\u65E0\u6CD5\u751F\u6210\u6B64\u95EE\u9898\u3002\u8BF7\u5C1D\u8BD5\u53E6\u4E00\u4E2A\uFF01",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A",
      testingVocabulary: "\u8BCD\u6C47\u6D4B\u8BD5",
      testingGrammar: "\u8BED\u6CD5\u6D4B\u8BD5"
    },
    nah: {
      title: "Tlahtolchihualoyan",
      instruction: "Xikchihua in tlahtolli tlen polihui sehse.",
      forgeSlot: "Tlahtolli tlen omochihchiuh",
      emptyForge: "Xiktlali tlatilantli noso xikpatskili poyotl tlatilantli",
      pieceBank: "Poyomeh tlen onkah",
      allPiecesUsed: "Mochi poyomeh omotlalihkeh.",
      tapToRemove: "Xikpatskili para xikixti poyotl",
      askForHelp: "Xiktlahtlani tepalehuilli in tepalehuiani",
      helpRequest: "\xBFHuelis tinechmaka se tlamantli itech quen motlalia in tlahtolli tlen polihui?",
      skip: "Xikpano",
      submit: "Xikyehyeko",
      checking: "Moyehyekoa\u2026",
      tryAgain: "Okseppa xikchihua",
      nextQuestion: "Okse tlahtlanilli \u2192",
      generationFailed: "Ahmo ohuel omochihchiuh nin tlahtlanilli. \xA1Xikyehyeko okse!",
      tryAnother: "Xikyehyeko okse",
      testingVocabulary: "Tlatemoliztli itech tlahtolli",
      testingGrammar: "Tlatemoliztli itech tlatlahtolnemiliztli"
    },
    yua: {
      title: "U Tuuxil T'aan",
      instruction: "Meent le t'aan ku bin jun-p'\xE9elil ti' jun-p'\xE9elil.",
      forgeSlot: "T'aan meenta'an",
      emptyForge: "Jeche' wa je'el a loxik le xot'o'obo' utia'al a meentik le t'aano'",
      pieceBank: "Xot'o'ob yaan",
      allPiecesUsed: "Tul\xE1akal xot'o'ob ts'o'ok u ts'a'abalo'ob.",
      tapToRemove: "Pats' utia'al a lu'sik le xot'o'",
      askForHelp: "K'\xE1at \xE1antaj ti' le j-\xE1antajo'",
      helpRequest: "\xBFJe'el wa a ts'\xE1aik ten junp'\xEDit \xE1antaj yo'olal bix u meenta'al le t'aan ku bino'?",
      skip: "M\xE1ansik",
      submit: "T\xFAuxtik",
      checking: "U yila'al\u2026",
      tryAgain: "Ka'a meentej",
      nextQuestion: "U l\xE1ak' k'\xE1atchi' \u2192",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le k'\xE1atchi'a'. \xA1Je'el u p\xE1ajtal a w\xF3otik ul\xE1ak'!",
      tryAnother: "Y\xF3ot ul\xE1ak'",
      testingVocabulary: "U yila'al t'aano'ob",
      testingGrammar: "U yila'al gram\xE1tica"
    }
  };
  var DEFAULT_SUPPORT_LANG = "en";
  function getMorphologyForgeCopy(supportLang = DEFAULT_SUPPORT_LANG) {
    const normalized = String(supportLang || "").toLowerCase().trim();
    return MORPHOLOGY_FORGE_I18N[normalized] || MORPHOLOGY_FORGE_I18N.en;
  }

  // ../nosabos/nosabos/src/utils/threeClueMysteryI18n.js
  var THREE_CLUE_MYSTERY_I18N = {
    en: {
      title: "Three-Clue Mystery",
      instruction: "Deduce the mystery word using as few clues as possible.",
      clueBadge: "Clue {index}",
      revealNext: "Reveal next clue",
      allCluesRevealed: "All 3 clues revealed",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Type your answer\u2026",
      askForHelp: "Ask assistant for help",
      helpRequest: "Can you tell me the answer and explain the reasoning behind the clues?",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question \u2192",
      generationFailed: "We couldn't generate this mystery. Try another!",
      tryAnother: "Try another",
      testingVocabulary: "Testing vocabulary",
      testingGrammar: "Testing grammar",
      example: "Example sentence"
    },
    es: {
      title: "Misterio de tres pistas",
      instruction: "Deduce la palabra misteriosa usando la menor cantidad de pistas posible.",
      clueBadge: "Pista {index}",
      revealNext: "Revelar siguiente pista",
      allCluesRevealed: "Las 3 pistas reveladas",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Escribe tu respuesta\u2026",
      askForHelp: "Pedir ayuda al asistente",
      helpRequest: "\xBFPuedes decirme la respuesta y explicar el razonamiento detr\xE1s de las pistas?",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta \u2192",
      generationFailed: "No pudimos generar este misterio. \xA1Prueba con otro!",
      tryAnother: "Probar otro",
      testingVocabulary: "Evaluando vocabulario",
      testingGrammar: "Evaluando gram\xE1tica",
      example: "Oraci\xF3n de ejemplo"
    },
    fr: {
      title: "Myst\xE8re aux trois indices",
      instruction: "D\xE9duisez le mot myst\xE8re en utilisant le moins d'indices possible.",
      clueBadge: "Indice {index}",
      revealNext: "R\xE9v\xE9ler l'indice suivant",
      allCluesRevealed: "Les 3 indices sont r\xE9v\xE9l\xE9s",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Tapez votre r\xE9ponse\u2026",
      askForHelp: "Demander de l'aide \xE0 l'assistant",
      helpRequest: "Pouvez-vous me donner la r\xE9ponse et m'expliquer le raisonnement derri\xE8re les indices ?",
      skip: "Passer",
      submit: "V\xE9rifier",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante \u2192",
      generationFailed: "Impossible de g\xE9n\xE9rer ce myst\xE8re. Essayez-en un autre !",
      tryAnother: "Essayer un autre",
      testingVocabulary: "\xC9valuation du vocabulaire",
      testingGrammar: "\xC9valuation de la grammaire",
      example: "Phrase d'exemple"
    },
    de: {
      title: "Drei-Hinweise-R\xE4tsel",
      instruction: "Errate das Geheimwort mit so wenigen Hinweisen wie m\xF6glich.",
      clueBadge: "Hinweis {index}",
      revealNext: "N\xE4chsten Hinweis aufdecken",
      allCluesRevealed: "Alle 3 Hinweise aufgedeckt",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Schreibe deine Antwort\u2026",
      askForHelp: "Assistenten um Hilfe bitten",
      helpRequest: "Kannst du mir die Antwort nennen und erkl\xE4ren, wie die Hinweise darauf hinweisen?",
      skip: "\xDCberspringen",
      submit: "\xDCberpr\xFCfen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Erneut versuchen",
      nextQuestion: "N\xE4chste Frage \u2192",
      generationFailed: "Dieses R\xE4tsel konnte nicht erstellt werden. Versuche ein anderes!",
      tryAnother: "Anderes versuchen",
      testingVocabulary: "Wortschatz-Test",
      testingGrammar: "Grammatik-Test",
      example: "Beispielsatz"
    },
    it: {
      title: "Mistero a tre indizi",
      instruction: "Deduci la parola misteriosa usando il minor numero di indizi possibile.",
      clueBadge: "Indizio {index}",
      revealNext: "Rivela il prossimo indizio",
      allCluesRevealed: "Tutti e 3 gli indizi rivelati",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Scrivi la tua risposta\u2026",
      askForHelp: "Chiedi aiuto all'assistente",
      helpRequest: "Puoi dirmi la risposta e spiegarmi il ragionamento dietro agli indizi?",
      skip: "Salta",
      submit: "Verifica",
      checking: "Verifica in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda \u2192",
      generationFailed: "Impossibile generare questo mistero. Provane un altro!",
      tryAnother: "Provane un altro",
      testingVocabulary: "Verifica del vocabolario",
      testingGrammar: "Verifica della grammatica",
      example: "Frase di esempio"
    },
    pt: {
      title: "Mist\xE9rio das Tr\xEAs Pistas",
      instruction: "Descubra a palavra misteriosa usando o menor n\xFAmero de pistas poss\xEDvel.",
      clueBadge: "Pista {index}",
      revealNext: "Revelar pr\xF3xima pista",
      allCluesRevealed: "Todas as 3 pistas reveladas",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Digite sua resposta\u2026",
      askForHelp: "Pedir ajuda ao assistente",
      helpRequest: "Pode me dizer a resposta e explicar o racioc\xEDnio por tr\xE1s das pistas?",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta \u2192",
      generationFailed: "N\xE3o foi poss\xEDvel gerar este mist\xE9rio. Tente outro!",
      tryAnother: "Tentar outro",
      testingVocabulary: "Testando vocabul\xE1rio",
      testingGrammar: "Testando gram\xE1tica",
      example: "Frase de exemplo"
    },
    ja: {
      title: "3\u3064\u306E\u624B\u304C\u304B\u308A\u306E\u8B0E",
      instruction: "\u3067\u304D\u308B\u3060\u3051\u5C11\u306A\u3044\u624B\u304C\u304B\u308A\u3067\u8B0E\u306E\u5358\u8A9E\u3092\u5F53\u3066\u307E\u3057\u3087\u3046\u3002",
      clueBadge: "\u624B\u304C\u304B\u308A {index}",
      revealNext: "\u6B21\u306E\u624B\u304C\u304B\u308A\u3092\u898B\u308B",
      allCluesRevealed: "3\u3064\u306E\u624B\u304C\u304B\u308A\u3092\u3059\u3079\u3066\u516C\u958B\u4E2D",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "\u7B54\u3048\u3092\u5165\u529B\u2026",
      askForHelp: "\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8\u306B\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u7B54\u3048\u3068\u3001\u624B\u304C\u304B\u308A\u304C\u306A\u305C\u305D\u306E\u7B54\u3048\u306B\u306A\u308B\u306E\u304B\u306E\u7406\u7531\u3092\u6559\u3048\u3066\u304F\u308C\u307E\u3059\u304B\uFF1F",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3059\u308B",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C\u3078 \u2192",
      generationFailed: "\u3053\u306E\u554F\u984C\u3092\u751F\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002\u5225\u306E\u554F\u984C\u3092\u304A\u8A66\u3057\u304F\u3060\u3055\u3044\u3002",
      tryAnother: "\u5225\u306E\u554F\u984C\u3092\u8A66\u3059",
      testingVocabulary: "\u8A9E\u5F59\u30C6\u30B9\u30C8",
      testingGrammar: "\u6587\u6CD5\u30C6\u30B9\u30C8",
      example: "\u4F8B\u6587"
    },
    ru: {
      title: "\u0422\u0430\u0439\u043D\u0430 \u0442\u0440\u0451\u0445 \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043E\u043A",
      instruction: "\u041E\u0442\u0433\u0430\u0434\u0430\u0439\u0442\u0435 \u0437\u0430\u0433\u0430\u0434\u0430\u043D\u043D\u043E\u0435 \u0441\u043B\u043E\u0432\u043E, \u0438\u0441\u043F\u043E\u043B\u044C\u0437\u0443\u044F \u043A\u0430\u043A \u043C\u043E\u0436\u043D\u043E \u043C\u0435\u043D\u044C\u0448\u0435 \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043E\u043A.",
      clueBadge: "\u041F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0430 {index}",
      revealNext: "\u041F\u043E\u043A\u0430\u0437\u0430\u0442\u044C \u0441\u043B\u0435\u0434\u0443\u044E\u0449\u0443\u044E \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443",
      allCluesRevealed: "\u0412\u0441\u0435 3 \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0438 \u043E\u0442\u043A\u0440\u044B\u0442\u044B",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0432\u0430\u0448 \u043E\u0442\u0432\u0435\u0442\u2026",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u043C\u043E\u0449\u0438 \u0443 \u0430\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442\u0430",
      helpRequest: "\u041C\u043E\u0436\u0435\u0442\u0435 \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u0430\u0442\u044C \u043E\u0442\u0432\u0435\u0442 \u0438 \u043E\u0431\u044A\u044F\u0441\u043D\u0438\u0442\u044C \u043B\u043E\u0433\u0438\u043A\u0443 \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043E\u043A?",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441 \u2192",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u044D\u0442\u0443 \u0437\u0430\u0433\u0430\u0434\u043A\u0443. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0434\u0440\u0443\u0433\u0443\u044E!",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u0443\u044E",
      testingVocabulary: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0441\u043B\u043E\u0432\u0430\u0440\u043D\u043E\u0433\u043E \u0437\u0430\u043F\u0430\u0441\u0430",
      testingGrammar: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430 \u0433\u0440\u0430\u043C\u043C\u0430\u0442\u0438\u043A\u0438",
      example: "\u041F\u0440\u0438\u043C\u0435\u0440 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u044F"
    },
    el: {
      title: "\u039C\u03C5\u03C3\u03C4\u03AE\u03C1\u03B9\u03BF \u03A4\u03C1\u03B9\u03CE\u03BD \u03A3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03C9\u03BD",
      instruction: "\u039C\u03B1\u03BD\u03C4\u03AD\u03C8\u03C4\u03B5 \u03C4\u03B7 \u03BC\u03C5\u03C3\u03C4\u03B9\u03BA\u03AE \u03BB\u03AD\u03BE\u03B7 \u03C7\u03C1\u03B7\u03C3\u03B9\u03BC\u03BF\u03C0\u03BF\u03B9\u03CE\u03BD\u03C4\u03B1\u03C2 \u03CC\u03C3\u03BF \u03C4\u03BF \u03B4\u03C5\u03BD\u03B1\u03C4\u03CC\u03BD \u03BB\u03B9\u03B3\u03CC\u03C4\u03B5\u03C1\u03B1 \u03C3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03B1.",
      clueBadge: "\u03A3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03BF {index}",
      revealNext: "\u0391\u03C0\u03BF\u03BA\u03AC\u03BB\u03C5\u03C8\u03B7 \u03B5\u03C0\u03CC\u03BC\u03B5\u03BD\u03BF\u03C5 \u03C3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03BF\u03C5",
      allCluesRevealed: "\u039A\u03B1\u03B9 \u03C4\u03B1 3 \u03C3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03B1 \u03B1\u03C0\u03BF\u03BA\u03B1\u03BB\u03CD\u03C6\u03B8\u03B7\u03BA\u03B1\u03BD",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "\u03A0\u03BB\u03B7\u03BA\u03C4\u03C1\u03BF\u03BB\u03BF\u03B3\u03AE\u03C3\u03C4\u03B5 \u03C4\u03B7\u03BD \u03B1\u03C0\u03AC\u03BD\u03C4\u03B7\u03C3\u03AE \u03C3\u03B1\u03C2\u2026",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1 \u03B1\u03C0\u03CC \u03C4\u03BF\u03BD \u03B2\u03BF\u03B7\u03B8\u03CC",
      helpRequest: "\u039C\u03C0\u03BF\u03C1\u03B5\u03AF\u03C4\u03B5 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03C0\u03B5\u03AF\u03C4\u03B5 \u03C4\u03B7\u03BD \u03B1\u03C0\u03AC\u03BD\u03C4\u03B7\u03C3\u03B7 \u03BA\u03B1\u03B9 \u03BD\u03B1 \u03B5\u03BE\u03B7\u03B3\u03AE\u03C3\u03B5\u03C4\u03B5 \u03C4\u03B7 \u03BB\u03BF\u03B3\u03B9\u03BA\u03AE \u03C0\u03AF\u03C3\u03C9 \u03B1\u03C0\u03CC \u03C4\u03B1 \u03C3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03B1;",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7 \u2192",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03B1\u03C5\u03C4\u03BF\u03CD \u03C4\u03BF\u03C5 \u03BC\u03C5\u03C3\u03C4\u03B7\u03C1\u03AF\u03BF\u03C5. \u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03BF!",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03BF",
      testingVocabulary: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2 \u03BB\u03B5\u03BE\u03B9\u03BB\u03BF\u03B3\u03AF\u03BF\u03C5",
      testingGrammar: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2 \u03B3\u03C1\u03B1\u03BC\u03BC\u03B1\u03C4\u03B9\u03BA\u03AE\u03C2",
      example: "\u03A0\u03B1\u03C1\u03AC\u03B4\u03B5\u03B9\u03B3\u03BC\u03B1 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7\u03C2"
    },
    nl: {
      title: "Drie-Aanwijzingen Mysterie",
      instruction: "Leid het mysteriewoord af met zo min mogelijk aanwijzingen.",
      clueBadge: "Aanwijzing {index}",
      revealNext: "Volgende aanwijzing onthullen",
      allCluesRevealed: "Alle 3 aanwijzingen onthuld",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Typ je antwoord\u2026",
      askForHelp: "Vraag assistent om hulp",
      helpRequest: "Kun je me het antwoord geven en de redenering achter de aanwijzingen uitleggen?",
      skip: "Overslaan",
      submit: "Controleren",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag \u2192",
      generationFailed: "We konden dit mysterie niet maken. Probeer een ander!",
      tryAnother: "Probeer een ander",
      testingVocabulary: "Woordenschat testen",
      testingGrammar: "Grammatica testen",
      example: "Voorbeeldzin"
    },
    pl: {
      title: "Tajemnica trzech wskaz\xF3wek",
      instruction: "Odgadnij tajemnicze s\u0142owo, u\u017Cywaj\u0105c jak najmniejszej liczby wskaz\xF3wek.",
      clueBadge: "Wskaz\xF3wka {index}",
      revealNext: "Odkryj kolejn\u0105 wskaz\xF3wk\u0119",
      allCluesRevealed: "Wszystkie 3 wskaz\xF3wki odkryte",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Wpisz swoj\u0105 odpowied\u017A\u2026",
      askForHelp: "Popro\u015B asystenta o pomoc",
      helpRequest: "Czy mo\u017Cesz poda\u0107 mi odpowied\u017A i wyja\u015Bni\u0107 logik\u0119 kryj\u0105c\u0105 si\u0119 za wskaz\xF3wkami?",
      skip: "Pomi\u0144",
      submit: "Sprawd\u017A",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie \u2192",
      generationFailed: "Nie uda\u0142o si\u0119 wygenerowa\u0107 tej zagadki. Spr\xF3buj innej!",
      tryAnother: "Spr\xF3buj innej",
      testingVocabulary: "Test s\u0142ownictwa",
      testingGrammar: "Test gramatyki",
      example: "Przyk\u0142adowe zdanie"
    },
    ga: {
      title: "R\xFAn Tr\xED Leid",
      instruction: "Bain amach an focal r\xFAndiamhair le chomh beag leideanna agus is f\xE9idir.",
      clueBadge: "Leid {index}",
      revealNext: "Taispe\xE1in an ch\xE9ad leid eile",
      allCluesRevealed: "Gach ceann den 3 leid taispe\xE1nta",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Cl\xF3scr\xEDobh do fhreagra\u2026",
      askForHelp: "Iarr cabhair ar an gc\xFAnt\xF3ir",
      helpRequest: "An f\xE9idir leat an freagra a thabhairt dom agus an r\xE9as\xFAna\xEDocht taobh thiar de na leideanna a mh\xEDni\xFA?",
      skip: "Scipe\xE1il",
      submit: "Seol",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile \u2192",
      generationFailed: "N\xEDorbh fh\xE9idir an r\xFAn seo a ghini\xFAint. Bain triail as ceann eile!",
      tryAnother: "Bain triail as ceann eile",
      testingVocabulary: "Ag t\xE1st\xE1il focl\xF3ra",
      testingGrammar: "Ag t\xE1st\xE1il gramada\xED",
      example: "Sampla abairte"
    },
    ar: {
      title: "\u0644\u063A\u0632 \u0627\u0644\u0642\u0631\u0627\u0626\u0646 \u0627\u0644\u062B\u0644\u0627\u062B",
      instruction: "\u0627\u0633\u062A\u0646\u062A\u062C \u0627\u0644\u0643\u0644\u0645\u0629 \u0627\u0644\u063A\u0627\u0645\u0636\u0629 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0623\u0642\u0644 \u0639\u062F\u062F \u0645\u0645\u0643\u0646 \u0645\u0646 \u0627\u0644\u0642\u0631\u0627\u0626\u0646.",
      clueBadge: "\u0642\u0631\u064A\u0646\u0629 {index}",
      revealNext: "\u0643\u0634\u0641 \u0627\u0644\u0642\u0631\u064A\u0646\u0629 \u0627\u0644\u062A\u0627\u0644\u064A\u0629",
      allCluesRevealed: "\u062A\u0645 \u0643\u0634\u0641 \u0627\u0644\u0642\u0631\u0627\u0626\u0646 \u0627\u0644\u062B\u0644\u0627\u062B \u0643\u0627\u0645\u0644\u0629",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "\u0627\u0643\u062A\u0628 \u0625\u062C\u0627\u0628\u062A\u0643\u2026",
      askForHelp: "\u0627\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u0633\u0627\u0639\u062F",
      helpRequest: "\u0647\u0644 \u064A\u0645\u0643\u0646\u0643 \u0625\u062E\u0628\u0627\u0631\u064A \u0628\u0627\u0644\u0625\u062C\u0627\u0628\u0629 \u0648\u0634\u0631\u062D \u0627\u0644\u0645\u0646\u0637\u0642 \u0627\u0644\u0643\u0627\u0645\u0646 \u0648\u0631\u0627\u0621 \u0627\u0644\u0642\u0631\u0627\u0626\u0646\u061F",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u062A\u062D\u0642\u0642",
      checking: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A \u2190",
      generationFailed: "\u062A\u0639\u0630\u0631 \u062A\u0648\u0644\u064A\u062F \u0647\u0630\u0627 \u0627\u0644\u0644\u063A\u0632. \u062C\u0631\u0628 \u0644\u063A\u0632\u0627\u064B \u0622\u062E\u0631!",
      tryAnother: "\u062C\u0631\u0628 \u0644\u063A\u0632\u0627\u064B \u0622\u062E\u0631",
      testingVocabulary: "\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u0645\u0641\u0631\u062F\u0627\u062A",
      testingGrammar: "\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u0642\u0648\u0627\u0639\u062F",
      example: "\u062C\u0645\u0644\u0629 \u062A\u0648\u0636\u064A\u062D\u064A\u0629"
    },
    hi: {
      title: "\u0924\u0940\u0928 \u0938\u0902\u0915\u0947\u0924\u094B\u0902 \u0915\u093E \u0930\u0939\u0938\u094D\u092F",
      instruction: "\u0915\u092E \u0938\u0947 \u0915\u092E \u0938\u0902\u0915\u0947\u0924\u094B\u0902 \u0915\u093E \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0915\u0947 \u0930\u0939\u0938\u094D\u092F\u092E\u092F\u0940 \u0936\u092C\u094D\u0926 \u0915\u093E \u0905\u0928\u0941\u092E\u093E\u0928 \u0932\u0917\u093E\u090F\u0902\u0964",
      clueBadge: "\u0938\u0902\u0915\u0947\u0924 {index}",
      revealNext: "\u0905\u0917\u0932\u093E \u0938\u0902\u0915\u0947\u0924 \u0926\u0947\u0916\u0947\u0902",
      allCluesRevealed: "\u0938\u092D\u0940 3 \u0938\u0902\u0915\u0947\u0924 \u0926\u0947\u0916 \u0932\u093F\u090F \u0917\u090F \u0939\u0948\u0902",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "\u0905\u092A\u0928\u093E \u0909\u0924\u094D\u0924\u0930 \u0932\u093F\u0916\u0947\u0902\u2026",
      askForHelp: "\u0938\u0939\u093E\u092F\u0915 \u0938\u0947 \u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u0915\u094D\u092F\u093E \u0906\u092A \u092E\u0941\u091D\u0947 \u0909\u0924\u094D\u0924\u0930 \u092C\u0924\u093E \u0938\u0915\u0924\u0947 \u0939\u0948\u0902 \u0914\u0930 \u0938\u0902\u0915\u0947\u0924\u094B\u0902 \u0915\u0947 \u092A\u0940\u091B\u0947 \u0915\u0947 \u0924\u0930\u094D\u0915 \u0915\u094B \u0938\u092E\u091D\u093E \u0938\u0915\u0924\u0947 \u0939\u0948\u0902?",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u093E\u0902\u091A\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u2192",
      generationFailed: "\u092F\u0939 \u0930\u0939\u0938\u094D\u092F \u092A\u094D\u0930\u0936\u094D\u0928 \u0924\u0948\u092F\u093E\u0930 \u0928\u0939\u0940\u0902 \u0939\u094B \u0938\u0915\u093E\u0964 \u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902!",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902",
      testingVocabulary: "\u0936\u092C\u094D\u0926\u093E\u0935\u0932\u0940 \u092A\u0930\u0940\u0915\u094D\u0937\u0923",
      testingGrammar: "\u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u092A\u0930\u0940\u0915\u094D\u0937\u0923",
      example: "\u0909\u0926\u093E\u0939\u0930\u0923 \u0935\u093E\u0915\u094D\u092F"
    },
    zh: {
      title: "\u4E09\u6761\u7EBF\u7D22\u4E4B\u8C1C",
      instruction: "\u5C3D\u91CF\u4F7F\u7528\u8F83\u5C11\u7684\u7EBF\u7D22\u63A8\u65AD\u51FA\u795E\u79D8\u5355\u8BCD\u3002",
      clueBadge: "\u7EBF\u7D22 {index}",
      revealNext: "\u63ED\u6653\u4E0B\u4E00\u6761\u7EBF\u7D22",
      allCluesRevealed: "\u5168\u90E8 3 \u6761\u7EBF\u7D22\u5DF2\u63ED\u6653",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "\u8F93\u5165\u4F60\u7684\u7B54\u6848\u2026",
      askForHelp: "\u5411\u52A9\u624B\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u4F60\u80FD\u544A\u8BC9\u6211\u7B54\u6848\u5E76\u89E3\u91CA\u8FD9\u4E9B\u7EBF\u7D22\u80CC\u540E\u7684\u539F\u56E0\u5417\uFF1F",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u68C0\u67E5\u4E2D\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898 \u2192",
      generationFailed: "\u65E0\u6CD5\u751F\u6210\u6B64\u7EBF\u7D22\u4E4B\u8C1C\u3002\u8BF7\u5C1D\u8BD5\u53E6\u4E00\u4E2A\uFF01",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A",
      testingVocabulary: "\u8BCD\u6C47\u6D4B\u8BD5",
      testingGrammar: "\u8BED\u6CD5\u6D4B\u8BD5",
      example: "\u793A\u4F8B\u53E5\u5B50"
    },
    nah: {
      title: "Yeyi Tlamachiliztli Tlatlatilli",
      instruction: "Xikmachioti in tlahtolli ika tlen achi tlamachiliztli.",
      clueBadge: "Tlamachiliztli {index}",
      revealNext: "Xiknexti okse tlamachiliztli",
      allCluesRevealed: "Mochi yeyi tlamachiliztli omocnextihkeh",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Xikihcuilo motlahtolcuepaliz\u2026",
      askForHelp: "Xiktlahtlani tepalehuilli in tepalehuiani",
      helpRequest: "\xBFHuelis tinechmaka in tlahtolcuepaliztli huan tinechmelahuilia in tlamachiliztli?",
      skip: "Xikpano",
      submit: "Xikyehyeko",
      checking: "Moyehyekoa\u2026",
      tryAgain: "Okseppa xikchihua",
      nextQuestion: "Okse tlahtlanilli \u2192",
      generationFailed: "Ahmo ohuel omochihchiuh nin tlatlatilli. \xA1Xikyehyeko okse!",
      tryAnother: "Xikyehyeko okse",
      testingVocabulary: "Tlatemoliztli itech tlahtolli",
      testingGrammar: "Tlatemoliztli itech tlatlahtolnemiliztli",
      example: "Machiyotl tlatlahtolli"
    },
    yua: {
      title: "U Muk'yajil \xD3oxp'\xE9el Na'at",
      instruction: "Na'at le t'aan y\xE9etel u p'\xE9elil na'ato'ob je'el bixik.",
      clueBadge: "Na'at {index}",
      revealNext: "Chikbes ul\xE1ak' na'at",
      allCluesRevealed: "Tul\xE1akal le 3 na'ato'ob ts'o'ok u chikbesa'alo'ob",
      potentialXp: "+{xp} XP",
      inputPlaceholder: "Ts'\xEDibt a n\xFAukik\u2026",
      askForHelp: "K'\xE1at \xE1antaj ti' le j-\xE1antajo'",
      helpRequest: "\xBFJe'el wa a ts'\xE1aik ten le n\xFAukiko' y\xE9etel a tsolik bix u na'atal le na'ato'obo'?",
      skip: "M\xE1ansik",
      submit: "T\xFAuxtik",
      checking: "U yila'al\u2026",
      tryAgain: "Ka'a meentej",
      nextQuestion: "U l\xE1ak' k'\xE1atchi' \u2192",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le na'ata'. \xA1Je'el u p\xE1ajtal a w\xF3otik ul\xE1ak'!",
      tryAnother: "Y\xF3ot ul\xE1ak'",
      testingVocabulary: "U yila'al t'aano'ob",
      testingGrammar: "U yila'al gram\xE1tica",
      example: "Bix u ya'ala'al"
    }
  };
  var DEFAULT_SUPPORT_LANG2 = "en";
  function getThreeClueMysteryCopy(supportLang = DEFAULT_SUPPORT_LANG2) {
    const normalized = String(supportLang || "").toLowerCase().trim();
    return THREE_CLUE_MYSTERY_I18N[normalized] || THREE_CLUE_MYSTERY_I18N.en;
  }
  function formatThreeClueMysteryCopy(template = "", variables = {}) {
    return String(template || "").replace(
      /\{(\w+)\}/g,
      (match, key) => variables[key] !== void 0 ? String(variables[key]) : match
    );
  }

  // ../nosabos/nosabos/src/utils/listenDifferenceI18n.js
  var LISTEN_DIFFERENCE_I18N = {
    en: {
      title: "Listen for the Difference",
      instruction: "Listen carefully. Which sentence did you hear?",
      playAudio: "Play audio",
      playingAudio: "Playing\u2026",
      askForHelp: "Ask assistant for help",
      helpRequest: "Can you give me a subtle hint on what phonetic difference or grammatical clue to listen for?",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question \u2192",
      generationFailed: "We couldn't generate this listening question. Try another!",
      tryAnother: "Try another",
      contrastLabel: "Key difference"
    },
    es: {
      title: "Escucha la diferencia",
      instruction: "Escucha con atenci\xF3n. \xBFQu\xE9 frase escuchaste?",
      playAudio: "Reproducir audio",
      playingAudio: "Reproduciendo\u2026",
      askForHelp: "Pedir ayuda al asistente",
      helpRequest: "\xBFPuedes darme una pista sutil sobre qu\xE9 diferencia de pronunciaci\xF3n o gram\xE1tica debo escuchar?",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta \u2192",
      generationFailed: "No pudimos generar esta pregunta de audio. \xA1Prueba con otra!",
      tryAnother: "Probar otra",
      contrastLabel: "Diferencia clave"
    },
    fr: {
      title: "\xC9coutez la diff\xE9rence",
      instruction: "\xC9coutez attentivement. Quelle phrase avez-vous entendue ?",
      playAudio: "\xC9couter l'audio",
      playingAudio: "Lecture en cours\u2026",
      askForHelp: "Demander de l'aide \xE0 l'assistant",
      helpRequest: "Pouvez-vous me donner un indice subtil sur la nuance phon\xE9tique ou grammaticale \xE0 \xE9couter ?",
      skip: "Passer",
      submit: "V\xE9rifier",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante \u2192",
      generationFailed: "Impossible de g\xE9n\xE9rer cette question d'\xE9coute. Essayez-en une autre !",
      tryAnother: "Essayer une autre",
      contrastLabel: "Diff\xE9rence cl\xE9"
    },
    de: {
      title: "H\xF6re den Unterschied",
      instruction: "H\xF6re genau hin. Welchen Satz hast du geh\xF6rt?",
      playAudio: "Audio abspielen",
      playingAudio: "Wird abgespielt\u2026",
      askForHelp: "Assistenten um Hilfe bitten",
      helpRequest: "Kannst du mir einen subtilen Tipp geben, auf welchen Laut oder grammatikalischen Unterschied ich achten soll?",
      skip: "\xDCberspringen",
      submit: "\xDCberpr\xFCfen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Erneut versuchen",
      nextQuestion: "N\xE4chste Frage \u2192",
      generationFailed: "Diese H\xF6rverstehensaufgabe konnte nicht erstellt werden. Versuche eine andere!",
      tryAnother: "Andere versuchen",
      contrastLabel: "Hauptunterschied"
    },
    it: {
      title: "Ascolta la differenza",
      instruction: "Ascolta attentamente. Quale frase hai sentito?",
      playAudio: "Ascolta l'audio",
      playingAudio: "Riproduzione in corso\u2026",
      askForHelp: "Chiedi aiuto all'assistente",
      helpRequest: "Puoi darmi un piccolo indizio su quale sfumatura di pronuncia o grammatica dovrei ascoltare?",
      skip: "Salta",
      submit: "Verifica",
      checking: "Verifica in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda \u2192",
      generationFailed: "Impossibile generare questa domanda d'ascolto. Provane un'altra!",
      tryAnother: "Provane un'altra",
      contrastLabel: "Differenza chiave"
    },
    pt: {
      title: "Ou\xE7a a Diferen\xE7a",
      instruction: "Ou\xE7a com aten\xE7\xE3o. Qual frase voc\xEA ouviu?",
      playAudio: "Ouvir \xE1udio",
      playingAudio: "Reproduzindo\u2026",
      askForHelp: "Pedir ajuda ao assistente",
      helpRequest: "Pode me dar uma dica sutil sobre qual detalhe de pron\xFAncia ou gram\xE1tica devo escutar?",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta \u2192",
      generationFailed: "N\xE3o foi poss\xEDvel gerar esta pergunta de \xE1udio. Tente outra!",
      tryAnother: "Tentar outra",
      contrastLabel: "Diferen\xE7a principal"
    },
    ja: {
      title: "\u9055\u3044\u3092\u805E\u304D\u53D6\u308D\u3046",
      instruction: "\u6CE8\u610F\u6DF1\u304F\u805E\u3044\u3066\u304F\u3060\u3055\u3044\u3002\u3069\u306E\u6587\u304C\u805E\u3053\u3048\u307E\u3057\u305F\u304B\uFF1F",
      playAudio: "\u97F3\u58F0\u3092\u518D\u751F",
      playingAudio: "\u518D\u751F\u4E2D\u2026",
      askForHelp: "\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8\u306B\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u3069\u306E\u767A\u97F3\u3084\u6587\u6CD5\u306E\u9055\u3044\u306B\u6CE8\u610F\u3057\u3066\u805E\u3051\u3070\u3044\u3044\u304B\u3001\u63A7\u3048\u3081\u306A\u30D2\u30F3\u30C8\u3092\u6559\u3048\u3066\u304F\u308C\u307E\u3059\u304B\uFF1F",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3059\u308B",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C\u3078 \u2192",
      generationFailed: "\u3053\u306E\u30EA\u30B9\u30CB\u30F3\u30B0\u554F\u984C\u3092\u751F\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002\u5225\u306E\u554F\u984C\u3092\u304A\u8A66\u3057\u304F\u3060\u3055\u3044\u3002",
      tryAnother: "\u5225\u306E\u554F\u984C\u3092\u8A66\u3059",
      contrastLabel: "\u4E3B\u306A\u9055\u3044"
    },
    ru: {
      title: "\u0423\u0441\u043B\u044B\u0448\u044C\u0442\u0435 \u0440\u0430\u0437\u043D\u0438\u0446\u0443",
      instruction: "\u0421\u043B\u0443\u0448\u0430\u0439\u0442\u0435 \u0432\u043D\u0438\u043C\u0430\u0442\u0435\u043B\u044C\u043D\u043E. \u041A\u0430\u043A\u043E\u0435 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435 \u043F\u0440\u043E\u0437\u0432\u0443\u0447\u0430\u043B\u043E?",
      playAudio: "\u0412\u043E\u0441\u043F\u0440\u043E\u0438\u0437\u0432\u0435\u0441\u0442\u0438 \u0430\u0443\u0434\u0438\u043E",
      playingAudio: "\u0412\u043E\u0441\u043F\u0440\u043E\u0438\u0437\u0432\u0435\u0434\u0435\u043D\u0438\u0435\u2026",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u043C\u043E\u0449\u0438 \u0443 \u0430\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442\u0430",
      helpRequest: "\u041C\u043E\u0436\u0435\u0442\u0435 \u0434\u0430\u0442\u044C \u0442\u043E\u043D\u043A\u0438\u0439 \u043D\u0430\u043C\u0435\u043A, \u043D\u0430 \u043A\u0430\u043A\u043E\u0435 \u0440\u0430\u0437\u043B\u0438\u0447\u0438\u0435 \u0432 \u0437\u0432\u0443\u043A\u0430\u0445 \u0438\u043B\u0438 \u0433\u0440\u0430\u043C\u043C\u0430\u0442\u0438\u043A\u0435 \u043E\u0431\u0440\u0430\u0442\u0438\u0442\u044C \u0432\u043D\u0438\u043C\u0430\u043D\u0438\u0435?",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441 \u2192",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u0432\u043E\u043F\u0440\u043E\u0441 \u043D\u0430 \u0430\u0443\u0434\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u0435. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0434\u0440\u0443\u0433\u043E\u0439!",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0439",
      contrastLabel: "\u041A\u043B\u044E\u0447\u0435\u0432\u043E\u0435 \u043E\u0442\u043B\u0438\u0447\u0438\u0435"
    },
    el: {
      title: "\u0391\u03BA\u03BF\u03CD\u03C3\u03C4\u03B5 \u03C4\u03B7 \u03B4\u03B9\u03B1\u03C6\u03BF\u03C1\u03AC",
      instruction: "\u0391\u03BA\u03BF\u03CD\u03C3\u03C4\u03B5 \u03C0\u03C1\u03BF\u03C3\u03B5\u03BA\u03C4\u03B9\u03BA\u03AC. \u03A0\u03BF\u03B9\u03B1 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7 \u03B1\u03BA\u03BF\u03CD\u03C3\u03B1\u03C4\u03B5;",
      playAudio: "\u0391\u03BD\u03B1\u03C0\u03B1\u03C1\u03B1\u03B3\u03C9\u03B3\u03AE \u03AE\u03C7\u03BF\u03C5",
      playingAudio: "\u0391\u03BD\u03B1\u03C0\u03B1\u03C1\u03B1\u03B3\u03C9\u03B3\u03AE\u2026",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1 \u03B1\u03C0\u03CC \u03C4\u03BF\u03BD \u03B2\u03BF\u03B7\u03B8\u03CC",
      helpRequest: "\u039C\u03C0\u03BF\u03C1\u03B5\u03AF\u03C4\u03B5 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03AD\u03BD\u03B1 \u03B4\u03B9\u03B1\u03BA\u03C1\u03B9\u03C4\u03B9\u03BA\u03CC \u03C3\u03C4\u03BF\u03B9\u03C7\u03B5\u03AF\u03BF \u03B3\u03B9\u03B1 \u03C4\u03BF \u03C0\u03BF\u03B9\u03B1 \u03B4\u03B9\u03B1\u03C6\u03BF\u03C1\u03AC \u03C3\u03C4\u03B7\u03BD \u03C0\u03C1\u03BF\u03C6\u03BF\u03C1\u03AC \u03AE \u03C4\u03B7 \u03B3\u03C1\u03B1\u03BC\u03BC\u03B1\u03C4\u03B9\u03BA\u03AE \u03BD\u03B1 \u03C0\u03C1\u03BF\u03C3\u03AD\u03BE\u03C9;",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7 \u2192",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03B1\u03C5\u03C4\u03AE\u03C2 \u03C4\u03B7\u03C2 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7\u03C2 \u03B1\u03BA\u03C1\u03CC\u03B1\u03C3\u03B7\u03C2. \u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7!",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7",
      contrastLabel: "\u0392\u03B1\u03C3\u03B9\u03BA\u03AE \u03B4\u03B9\u03B1\u03C6\u03BF\u03C1\u03AC"
    },
    nl: {
      title: "Hoor het verschil",
      instruction: "Luister goed. Welke zin hoorde je?",
      playAudio: "Audio afspelen",
      playingAudio: "Afspelen\u2026",
      askForHelp: "Vraag assistent om hulp",
      helpRequest: "Kun je me een subtiele hint geven op welk uitspraak- of grammaticaverschil ik moet letten?",
      skip: "Overslaan",
      submit: "Controleren",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag \u2192",
      generationFailed: "We konden deze luistervraag niet maken. Probeer een andere!",
      tryAnother: "Probeer een andere",
      contrastLabel: "Belangrijkste verschil"
    },
    pl: {
      title: "Us\u0142ysz r\xF3\u017Cnic\u0119",
      instruction: "Pos\u0142uchaj uwa\u017Cnie. Kt\xF3re zdanie us\u0142ysza\u0142e\u015B?",
      playAudio: "Odtw\xF3rz nagranie",
      playingAudio: "Odtwarzanie\u2026",
      askForHelp: "Popro\u015B asystenta o pomoc",
      helpRequest: "Czy mo\u017Cesz da\u0107 mi subteln\u0105 wskaz\xF3wk\u0119, na jak\u0105 r\xF3\u017Cnic\u0119 w wymowie lub gramatyce warto zwr\xF3ci\u0107 uwag\u0119?",
      skip: "Pomi\u0144",
      submit: "Sprawd\u017A",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie \u2192",
      generationFailed: "Nie uda\u0142o si\u0119 wygenerowa\u0107 tego pytania ze s\u0142uchu. Spr\xF3buj innego!",
      tryAnother: "Spr\xF3buj innego",
      contrastLabel: "Kluczowa r\xF3\u017Cnica"
    },
    ga: {
      title: "\xC9ist leis an Difr\xEDocht",
      instruction: "\xC9ist go c\xFAramach. C\xE9n abairt a chuala t\xFA?",
      playAudio: "Seinn fuaim",
      playingAudio: "Ag seinm\u2026",
      askForHelp: "Iarr cabhair ar an gc\xFAnt\xF3ir",
      helpRequest: "An f\xE9idir leat leid chaolch\xFAiseach a thabhairt dom faoin difr\xEDocht fuaime n\xF3 gramada\xED ar ch\xF3ir dom \xE9isteacht l\xE9i?",
      skip: "Scipe\xE1il",
      submit: "Seol",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile \u2192",
      generationFailed: "N\xEDorbh fh\xE9idir an cheist \xE9isteachta seo a ghini\xFAint. Bain triail as ceann eile!",
      tryAnother: "Bain triail as ceann eile",
      contrastLabel: "Pr\xEDomhdhifr\xEDocht"
    },
    ar: {
      title: "\u0627\u0633\u062A\u0645\u0639 \u0625\u0644\u0649 \u0627\u0644\u0641\u0631\u0642",
      instruction: "\u0627\u0633\u062A\u0645\u0639 \u0628\u0639\u0646\u0627\u064A\u0629. \u0623\u064A \u062C\u0645\u0644\u0629 \u0633\u0645\u0639\u062A\u061F",
      playAudio: "\u062A\u0634\u063A\u064A\u0644 \u0627\u0644\u0635\u0648\u062A",
      playingAudio: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u0634\u063A\u064A\u0644\u2026",
      askForHelp: "\u0627\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u0633\u0627\u0639\u062F",
      helpRequest: "\u0647\u0644 \u064A\u0645\u0643\u0646\u0643 \u0625\u0639\u0637\u0627\u0626\u064A \u062A\u0644\u0645\u064A\u062D\u064B\u0627 \u062E\u0641\u064A\u0641\u064B\u0627 \u062D\u0648\u0644 \u0627\u0644\u0641\u0631\u0642 \u0627\u0644\u0635\u0648\u062A\u064A \u0623\u0648 \u0627\u0644\u0646\u062D\u0648\u064A \u0627\u0644\u0630\u064A \u064A\u062C\u0628 \u0623\u0646 \u0623\u0633\u062A\u0645\u0639 \u0625\u0644\u064A\u0647\u061F",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u062A\u062D\u0642\u0642",
      checking: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A \u2190",
      generationFailed: "\u062A\u0639\u0630\u0631 \u062A\u0648\u0644\u064A\u062F \u0633\u0624\u0627\u0644 \u0627\u0644\u0627\u0633\u062A\u0645\u0627\u0639 \u0647\u0630\u0627. \u062C\u0631\u0628 \u0633\u0624\u0627\u0644\u0627\u064B \u0622\u062E\u0631!",
      tryAnother: "\u062C\u0631\u0628 \u0633\u0624\u0627\u0644\u0627\u064B \u0622\u062E\u0631",
      contrastLabel: "\u0627\u0644\u0641\u0631\u0642 \u0627\u0644\u0631\u0626\u064A\u0633\u064A"
    },
    hi: {
      title: "\u0905\u0902\u0924\u0930 \u0938\u0941\u0928\u0947\u0902",
      instruction: "\u0927\u094D\u092F\u093E\u0928 \u0938\u0947 \u0938\u0941\u0928\u0947\u0902\u0964 \u0906\u092A\u0928\u0947 \u0915\u094C\u0928 \u0938\u093E \u0935\u093E\u0915\u094D\u092F \u0938\u0941\u0928\u093E?",
      playAudio: "\u0911\u0921\u093F\u092F\u094B \u091A\u0932\u093E\u090F\u0902",
      playingAudio: "\u091A\u0932 \u0930\u0939\u093E \u0939\u0948\u2026",
      askForHelp: "\u0938\u0939\u093E\u092F\u0915 \u0938\u0947 \u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u0915\u094D\u092F\u093E \u0906\u092A \u092E\u0941\u091D\u0947 \u090F\u0915 \u0938\u0942\u0915\u094D\u0937\u094D\u092E \u0938\u0902\u0915\u0947\u0924 \u0926\u0947 \u0938\u0915\u0924\u0947 \u0939\u0948\u0902 \u0915\u093F \u092E\u0941\u091D\u0947 \u0915\u093F\u0938 \u0909\u091A\u094D\u091A\u093E\u0930\u0923 \u092F\u093E \u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u0915\u0947 \u0905\u0902\u0924\u0930 \u092A\u0930 \u0927\u094D\u092F\u093E\u0928 \u0926\u0947\u0928\u093E \u091A\u093E\u0939\u093F\u090F?",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u093E\u0902\u091A\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u2192",
      generationFailed: "\u092F\u0939 \u0938\u0941\u0928\u0928\u0947 \u0935\u093E\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u0924\u0948\u092F\u093E\u0930 \u0928\u0939\u0940\u0902 \u0939\u094B \u0938\u0915\u093E\u0964 \u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902!",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902",
      contrastLabel: "\u092E\u0941\u0916\u094D\u092F \u0905\u0902\u0924\u0930"
    },
    zh: {
      title: "\u8FA8\u522B\u542C\u529B\u5DEE\u5F02",
      instruction: "\u8BF7\u4ED4\u7EC6\u542C\u3002\u4F60\u542C\u5230\u4E86\u54EA\u53E5\u8BDD\uFF1F",
      playAudio: "\u64AD\u653E\u97F3\u9891",
      playingAudio: "\u64AD\u653E\u4E2D\u2026",
      askForHelp: "\u5411\u52A9\u624B\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u4F60\u80FD\u7ED9\u6211\u4E00\u4E2A\u5FAE\u5999\u7684\u63D0\u793A\uFF0C\u544A\u8BC9\u6211\u8BE5\u6CE8\u610F\u542C\u54EA\u4E2A\u53D1\u97F3\u6216\u8BED\u6CD5\u5DEE\u5F02\u5417\uFF1F",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u68C0\u67E5\u4E2D\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898 \u2192",
      generationFailed: "\u65E0\u6CD5\u751F\u6210\u6B64\u542C\u529B\u95EE\u9898\u3002\u8BF7\u5C1D\u8BD5\u53E6\u4E00\u4E2A\uFF01",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A",
      contrastLabel: "\u5173\u952E\u533A\u522B"
    },
    nah: {
      title: "Xiccaqui in Tlatlamantli",
      instruction: "Xiccaqui ika cuidado. \xBFTlen tlahtolli oticcac?",
      playAudio: "Xiccac tlatzotzonaliztli",
      playingAudio: "Mocactoc\u2026",
      askForHelp: "Xiktlahtlani tepalehuilli in tepalehuiani",
      helpRequest: "\xBFHuelis tinechmaka se tlatlatilli tepalehuiliztli itech tlen tlatlamantli tlahtolli moneki nikcaquis?",
      skip: "Xikpano",
      submit: "Xikyehyeko",
      checking: "Moyehyekoa\u2026",
      tryAgain: "Okseppa xikchihua",
      nextQuestion: "Okse tlahtlanilli \u2192",
      generationFailed: "Ahmo ohuel omochihchiuh nin tlahtolli. \xA1Xikyehyeko okse!",
      tryAnother: "Xikyehyeko okse",
      contrastLabel: "Tlen tlatlamantli"
    },
    yua: {
      title: "U'uy u Jela'anil",
      instruction: "U'uy tu beel. \xBFBa'ax t'aanil ta wu'uyaj?",
      playAudio: "U'uy u juum",
      playingAudio: "U yu'uba'al\u2026",
      askForHelp: "K'\xE1at \xE1antaj ti' le j-\xE1antajo'",
      helpRequest: "\xBFJe'el wa a ts'\xE1aik ten junp'\xEDit \xE1antaj ti' ba'ax jela'anil unaj in wu'uyik?",
      skip: "M\xE1ansik",
      submit: "T\xFAuxtik",
      checking: "U yila'al\u2026",
      tryAgain: "Ka'a meentej",
      nextQuestion: "U l\xE1ak' k'\xE1atchi' \u2192",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le k'\xE1atchi'a'. \xA1Je'el u p\xE1ajtal a w\xF3otik ul\xE1ak'!",
      tryAnother: "Y\xF3ot ul\xE1ak'",
      contrastLabel: "Ba'ax jela'an"
    }
  };
  var DEFAULT_SUPPORT_LANG3 = "en";
  function getListenDifferenceCopy(supportLang = DEFAULT_SUPPORT_LANG3) {
    const normalized = String(supportLang || "").toLowerCase().trim();
    return LISTEN_DIFFERENCE_I18N[normalized] || LISTEN_DIFFERENCE_I18N.en;
  }

  // ../nosabos/nosabos/src/utils/threeWordChallengeI18n.js
  var THREE_WORD_CHALLENGE_I18N = {
    en: {
      title: "Three-Word Challenge",
      instruction: "Create an original sentence using all three words.",
      inputPlaceholder: "Write your sentence here\u2026",
      semanticTip: "Original answers are judged for meaning and grammar, not exact wording.",
      askForHelp: "Ask assistant for help",
      helpRequest: "Can you give me ideas or hints on how to connect these three words into a sentence without writing the sentence for me?",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question \u2192",
      generationFailed: "We couldn't generate a Three-Word Challenge this time. Try another!",
      tryAnother: "Try another challenge"
    },
    es: {
      title: "Desaf\xEDo de tres palabras",
      instruction: "Crea una oraci\xF3n original usando las tres palabras.",
      inputPlaceholder: "Escribe tu oraci\xF3n aqu\xED\u2026",
      semanticTip: "Las respuestas originales se juzgan por significado y gram\xE1tica, no por coincidencia exacta.",
      askForHelp: "Pedir ayuda al asistente",
      helpRequest: "\xBFPuedes darme ideas o pistas sobre c\xF3mo conectar estas tres palabras en una oraci\xF3n sin escribirla por m\xED?",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta \u2192",
      generationFailed: "No pudimos generar este desaf\xEDo de tres palabras. \xA1Prueba con otro!",
      tryAnother: "Probar otro desaf\xEDo"
    },
    fr: {
      title: "D\xE9fi de trois mots",
      instruction: "Cr\xE9ez une phrase originale en utilisant les trois mots.",
      inputPlaceholder: "\xC9crivez votre phrase ici\u2026",
      semanticTip: "Les r\xE9ponses originales sont \xE9valu\xE9es selon le sens et la grammaire, pas le mot \xE0 mot exact.",
      askForHelp: "Demander de l'aide \xE0 l'assistant",
      helpRequest: "Pouvez-vous me donner des id\xE9es ou des pistes pour relier ces trois mots dans une phrase sans l'\xE9crire pour moi ?",
      skip: "Passer",
      submit: "Valider",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante \u2192",
      generationFailed: "Impossible de g\xE9n\xE9rer ce d\xE9fi de trois mots. Essayez-en un autre !",
      tryAnother: "Essayer un autre d\xE9fi"
    },
    de: {
      title: "Drei-W\xF6rter-Challenge",
      instruction: "Bilde einen eigenen Satz mit allen drei W\xF6rtern.",
      inputPlaceholder: "Schreibe deinen Satz hier\u2026",
      semanticTip: "Eigene Antworten werden nach Sinn und Grammatik bewertet, nicht nach exakter Wort\xFCbereinstimmung.",
      askForHelp: "Assistenten um Hilfe bitten",
      helpRequest: "Kannst du mir Ideen oder Tipps geben, wie ich diese drei W\xF6rter verbinden kann, ohne den Satz f\xFCr mich zu schreiben?",
      skip: "\xDCberspringen",
      submit: "\xDCberpr\xFCfen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Erneut versuchen",
      nextQuestion: "N\xE4chste Frage \u2192",
      generationFailed: "Diese Drei-W\xF6rter-Aufgabe konnte nicht erstellt werden. Versuche eine andere!",
      tryAnother: "Andere Challenge versuchen"
    },
    it: {
      title: "Sfida delle tre parole",
      instruction: "Crea una frase originale usando tutte e tre le parole.",
      inputPlaceholder: "Scrivi qui la tua frase\u2026",
      semanticTip: "Le risposte originali sono valutate in base a significato e grammatica, non alla corrispondenza esatta.",
      askForHelp: "Chiedi aiuto all'assistente",
      helpRequest: "Puoi darmi idee o suggerimenti su come collegare queste tre parole in una frase senza scriverla per me?",
      skip: "Salta",
      submit: "Verifica",
      checking: "Verifica in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda \u2192",
      generationFailed: "Impossibile generare questa sfida delle tre parole. Provane un'altra!",
      tryAnother: "Prova un'altra sfida"
    },
    pt: {
      title: "Desafio de Tr\xEAs Palavras",
      instruction: "Crie uma frase original usando todas as tr\xEAs palavras.",
      inputPlaceholder: "Escreva sua frase aqui\u2026",
      semanticTip: "Respostas originais s\xE3o avaliadas pelo significado e pela gram\xE1tica, n\xE3o pela exata correspond\xEAncia de palavras.",
      askForHelp: "Pedir ajuda ao assistente",
      helpRequest: "Pode me dar ideias ou dicas sobre como conectar estas tr\xEAs palavras em uma frase sem escrev\xEA-la por mim?",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta \u2192",
      generationFailed: "N\xE3o foi poss\xEDvel gerar este desafio de tr\xEAs palavras. Tente outro!",
      tryAnother: "Tentar outro desafio"
    },
    ja: {
      title: "3\u5358\u8A9E\u30C1\u30E3\u30EC\u30F3\u30B8",
      instruction: "3\u3064\u306E\u5358\u8A9E\u3092\u3059\u3079\u3066\u4F7F\u3063\u3066\u30AA\u30EA\u30B8\u30CA\u30EB\u306E\u6587\u3092\u4F5C\u308A\u307E\u3057\u3087\u3046\u3002",
      inputPlaceholder: "\u3053\u3053\u306B\u6587\u3092\u5165\u529B\u3057\u3066\u304F\u3060\u3055\u3044\u2026",
      semanticTip: "\u4F5C\u6210\u3057\u305F\u6587\u306F\u3001\u4E00\u5B57\u4E00\u53E5\u306E\u5B8C\u5168\u4E00\u81F4\u3067\u306F\u306A\u304F\u3001\u610F\u5473\u3068\u6587\u6CD5\u304C\u901A\u3063\u3066\u3044\u308B\u304B\u3067\u5224\u5B9A\u3055\u308C\u307E\u3059\u3002",
      askForHelp: "\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8\u306B\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u7B54\u3048\u3092\u76F4\u63A5\u66F8\u304B\u305A\u306B\u3001\u3053\u308C\u30893\u3064\u306E\u5358\u8A9E\u3092\u3069\u306E\u3088\u3046\u306B\u6587\u306B\u7E4B\u3052\u308B\u304B\u306E\u30D2\u30F3\u30C8\u3084\u30A2\u30A4\u30C7\u30A2\u3092\u6559\u3048\u3066\u304F\u308C\u307E\u3059\u304B\uFF1F",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3059\u308B",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C\u3078 \u2192",
      generationFailed: "\u3053\u306E3\u5358\u8A9E\u30C1\u30E3\u30EC\u30F3\u30B8\u3092\u751F\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002\u5225\u306E\u554F\u984C\u3092\u304A\u8A66\u3057\u304F\u3060\u3055\u3044\u3002",
      tryAnother: "\u5225\u306E\u30C1\u30E3\u30EC\u30F3\u30B8\u3092\u8A66\u3059"
    },
    ru: {
      title: "\u0417\u0430\u0434\u0430\u043D\u0438\u0435 \u0438\u0437 \u0442\u0440\u0435\u0445 \u0441\u043B\u043E\u0432",
      instruction: "\u0421\u043E\u0441\u0442\u0430\u0432\u044C\u0442\u0435 \u043E\u0440\u0438\u0433\u0438\u043D\u0430\u043B\u044C\u043D\u043E\u0435 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435, \u0438\u0441\u043F\u043E\u043B\u044C\u0437\u0443\u044F \u0432\u0441\u0435 \u0442\u0440\u0438 \u0441\u043B\u043E\u0432\u0430.",
      inputPlaceholder: "\u041D\u0430\u043F\u0438\u0448\u0438\u0442\u0435 \u0432\u0430\u0448\u0435 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435 \u0437\u0434\u0435\u0441\u044C\u2026",
      semanticTip: "\u041E\u0442\u0432\u0435\u0442\u044B \u043E\u0446\u0435\u043D\u0438\u0432\u0430\u044E\u0442\u0441\u044F \u043F\u043E \u0441\u043C\u044B\u0441\u043B\u0443 \u0438 \u0433\u0440\u0430\u043C\u043C\u0430\u0442\u0438\u0447\u0435\u0441\u043A\u043E\u0439 \u043F\u0440\u0430\u0432\u0438\u043B\u044C\u043D\u043E\u0441\u0442\u0438, \u0430 \u043D\u0435 \u043F\u043E \u0430\u0431\u0441\u043E\u043B\u044E\u0442\u043D\u043E\u043C\u0443 \u0441\u043E\u0432\u043F\u0430\u0434\u0435\u043D\u0438\u044E \u0441\u043B\u043E\u0432.",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u043C\u043E\u0449\u0438 \u0443 \u0430\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442\u0430",
      helpRequest: "\u041C\u043E\u0436\u0435\u0442\u0435 \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u0430\u0442\u044C \u0438\u0434\u0435\u0438 \u0438\u043B\u0438 \u043D\u0430\u043C\u0435\u043A\u0438, \u043A\u0430\u043A \u0441\u0432\u044F\u0437\u0430\u0442\u044C \u044D\u0442\u0438 \u0442\u0440\u0438 \u0441\u043B\u043E\u0432\u0430 \u0432 \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435, \u043D\u0435 \u0441\u043E\u0441\u0442\u0430\u0432\u043B\u044F\u044F \u0435\u0433\u043E \u0437\u0430 \u043C\u0435\u043D\u044F?",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441 \u2192",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u0437\u0430\u0434\u0430\u043D\u0438\u0435 \u0438\u0437 \u0442\u0440\u0435\u0445 \u0441\u043B\u043E\u0432. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0434\u0440\u0443\u0433\u043E\u0435!",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0435 \u0437\u0430\u0434\u0430\u043D\u0438\u0435"
    },
    el: {
      title: "\u03A0\u03C1\u03CC\u03BA\u03BB\u03B7\u03C3\u03B7 \u03C4\u03C1\u03B9\u03CE\u03BD \u03BB\u03AD\u03BE\u03B5\u03C9\u03BD",
      instruction: "\u0394\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AE\u03C3\u03C4\u03B5 \u03BC\u03B9\u03B1 \u03C0\u03C1\u03C9\u03C4\u03CC\u03C4\u03C5\u03C0\u03B7 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7 \u03C7\u03C1\u03B7\u03C3\u03B9\u03BC\u03BF\u03C0\u03BF\u03B9\u03CE\u03BD\u03C4\u03B1\u03C2 \u03BA\u03B1\u03B9 \u03C4\u03B9\u03C2 \u03C4\u03C1\u03B5\u03B9\u03C2 \u03BB\u03AD\u03BE\u03B5\u03B9\u03C2.",
      inputPlaceholder: "\u0393\u03C1\u03AC\u03C8\u03C4\u03B5 \u03C4\u03B7\u03BD \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03AE \u03C3\u03B1\u03C2 \u03B5\u03B4\u03CE\u2026",
      semanticTip: "\u039F\u03B9 \u03C0\u03C1\u03C9\u03C4\u03CC\u03C4\u03C5\u03C0\u03B5\u03C2 \u03B1\u03C0\u03B1\u03BD\u03C4\u03AE\u03C3\u03B5\u03B9\u03C2 \u03B1\u03BE\u03B9\u03BF\u03BB\u03BF\u03B3\u03BF\u03CD\u03BD\u03C4\u03B1\u03B9 \u03C9\u03C2 \u03C0\u03C1\u03BF\u03C2 \u03C4\u03BF \u03BD\u03CC\u03B7\u03BC\u03B1 \u03BA\u03B1\u03B9 \u03C4\u03B7 \u03B3\u03C1\u03B1\u03BC\u03BC\u03B1\u03C4\u03B9\u03BA\u03AE, \u03CC\u03C7\u03B9 \u03C9\u03C2 \u03C0\u03C1\u03BF\u03C2 \u03C4\u03B7\u03BD \u03B1\u03BA\u03C1\u03B9\u03B2\u03AE \u03B4\u03B9\u03B1\u03C4\u03CD\u03C0\u03C9\u03C3\u03B7.",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1 \u03B1\u03C0\u03CC \u03C4\u03BF\u03BD \u03B2\u03BF\u03B7\u03B8\u03CC",
      helpRequest: "\u039C\u03C0\u03BF\u03C1\u03B5\u03AF\u03C4\u03B5 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03B9\u03B4\u03AD\u03B5\u03C2 \u03B3\u03B9\u03B1 \u03C4\u03BF \u03C0\u03CE\u03C2 \u03BD\u03B1 \u03C3\u03C5\u03BD\u03B4\u03AD\u03C3\u03C9 \u03B1\u03C5\u03C4\u03AD\u03C2 \u03C4\u03B9\u03C2 \u03C4\u03C1\u03B5\u03B9\u03C2 \u03BB\u03AD\u03BE\u03B5\u03B9\u03C2 \u03C3\u03B5 \u03BC\u03B9\u03B1 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7 \u03C7\u03C9\u03C1\u03AF\u03C2 \u03BD\u03B1 \u03C4\u03B7 \u03B3\u03C1\u03AC\u03C8\u03B5\u03C4\u03B5 \u03B3\u03B9\u03B1 \u03BC\u03AD\u03BD\u03B1;",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7 \u2192",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03B1\u03C5\u03C4\u03AE\u03C2 \u03C4\u03B7\u03C2 \u03C0\u03C1\u03CC\u03BA\u03BB\u03B7\u03C3\u03B7\u03C2. \u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7!",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7 \u03C0\u03C1\u03CC\u03BA\u03BB\u03B7\u03C3\u03B7"
    },
    nl: {
      title: "Driewoordenuitdaging",
      instruction: "Maak een originele zin met alle drie de woorden.",
      inputPlaceholder: "Schrijf je zin hier\u2026",
      semanticTip: "Eigen zinnen worden beoordeeld op betekenis en grammatica, niet op letterlijke overeenkomst.",
      askForHelp: "Vraag assistent om hulp",
      helpRequest: "Kun je me idee\xEBn of hints geven om deze drie woorden te verbinden zonder de zin voor mij te schrijven?",
      skip: "Overslaan",
      submit: "Controleren",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag \u2192",
      generationFailed: "We konden deze driewoordenuitdaging niet maken. Probeer een andere!",
      tryAnother: "Probeer een andere uitdaging"
    },
    pl: {
      title: "Wyzwanie trzech s\u0142\xF3w",
      instruction: "U\u0142\xF3\u017C oryginalne zdanie, u\u017Cywaj\u0105c wszystkich trzech s\u0142\xF3w.",
      inputPlaceholder: "Wpisz tutaj swoje zdanie\u2026",
      semanticTip: "Oryginalne odpowiedzi s\u0105 oceniane pod k\u0105tem sensu i gramatyki, a nie dos\u0142ownego brzmienia.",
      askForHelp: "Popro\u015B asystenta o pomoc",
      helpRequest: "Czy mo\u017Cesz podsun\u0105\u0107 mi pomys\u0142, jak po\u0142\u0105czy\u0107 te trzy s\u0142owa w zdanie, nie pisz\u0105c go za mnie?",
      skip: "Pomi\u0144",
      submit: "Sprawd\u017A",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie \u2192",
      generationFailed: "Nie uda\u0142o si\u0119 wygenerowa\u0107 tego wyzwania trzech s\u0142\xF3w. Spr\xF3buj innego!",
      tryAnother: "Spr\xF3buj innego wyzwania"
    },
    ga: {
      title: "D\xFAshl\xE1n na dTr\xED Fhocal",
      instruction: "Cruthaigh abairt bhunaidh ag baint \xFAs\xE1ide as na tr\xED fhocal ar fad.",
      inputPlaceholder: "Scr\xEDobh d'abairt anseo\u2026",
      semanticTip: "D\xE9antar breithi\xFAnas ar fhreagra\xED bunaithe ar bhr\xED agus ar ghramadach, n\xED ar fhocla\xEDocht chruinn amh\xE1in.",
      askForHelp: "Iarr cabhair ar an gc\xFAnt\xF3ir",
      helpRequest: "An f\xE9idir leat smaointe a thabhairt dom maidir le conas na tr\xED fhocal seo a nascadh gan an abairt a scr\xEDobh dom?",
      skip: "Scipe\xE1il",
      submit: "Seol",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile \u2192",
      generationFailed: "N\xEDorbh fh\xE9idir an d\xFAshl\xE1n seo a ghini\xFAint. Bain triail as ceann eile!",
      tryAnother: "Bain triail as d\xFAshl\xE1n eile"
    },
    ar: {
      title: "\u062A\u062D\u062F\u064A \u0627\u0644\u0643\u0644\u0645\u0627\u062A \u0627\u0644\u062B\u0644\u0627\u062B",
      instruction: "\u0623\u0646\u0634\u0626 \u062C\u0645\u0644\u0629 \u0623\u0635\u0644\u064A\u0629 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0627\u0644\u0643\u0644\u0645\u0627\u062A \u0627\u0644\u062B\u0644\u0627\u062B \u0643\u0644\u0647\u0627.",
      inputPlaceholder: "\u0627\u0643\u062A\u0628 \u062C\u0645\u0644\u062A\u0643 \u0647\u0646\u0627\u2026",
      semanticTip: "\u064A\u062A\u0645 \u062A\u0642\u064A\u064A\u0645 \u0627\u0644\u0625\u062C\u0627\u0628\u0627\u062A \u0627\u0644\u0623\u0635\u0644\u064A\u0629 \u0628\u0646\u0627\u0621\u064B \u0639\u0644\u0649 \u0627\u0644\u0645\u0639\u0646\u0649 \u0648\u0627\u0644\u0642\u0648\u0627\u0639\u062F\u060C \u0648\u0644\u064A\u0633 \u0639\u0644\u0649 \u0627\u0644\u062A\u0637\u0627\u0628\u0642 \u0627\u0644\u062D\u0631\u0641\u064A.",
      askForHelp: "\u0627\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u0633\u0627\u0639\u062F",
      helpRequest: "\u0647\u0644 \u064A\u0645\u0643\u0646\u0643 \u0625\u0639\u0637\u0627\u0626\u064A \u0623\u0641\u0643\u0627\u0631\u064B\u0627 \u0623\u0648 \u062A\u0644\u0645\u064A\u062D\u0627\u062A \u062D\u0648\u0644 \u0643\u064A\u0641\u064A\u0629 \u0631\u0628\u0637 \u0647\u0630\u0647 \u0627\u0644\u0643\u0644\u0645\u0627\u062A \u0627\u0644\u062B\u0644\u0627\u062B \u0641\u064A \u062C\u0645\u0644\u0629 \u062F\u0648\u0646 \u0643\u062A\u0627\u0628\u062A\u0647\u0627 \u0644\u064A\u061F",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u062A\u062D\u0642\u0642",
      checking: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A \u2190",
      generationFailed: "\u062A\u0639\u0630\u0631 \u062A\u0648\u0644\u064A\u062F \u0647\u0630\u0627 \u0627\u0644\u062A\u062D\u062F\u064A. \u062C\u0631\u0628 \u062A\u062D\u062F\u064A\u064B\u0627 \u0622\u062E\u0631!",
      tryAnother: "\u062C\u0631\u0628 \u062A\u062D\u062F\u064A\u064B\u0627 \u0622\u062E\u0631"
    },
    hi: {
      title: "\u0924\u0940\u0928 \u0936\u092C\u094D\u0926\u094B\u0902 \u0915\u0940 \u091A\u0941\u0928\u094C\u0924\u0940",
      instruction: "\u0924\u0940\u0928\u094B\u0902 \u0936\u092C\u094D\u0926\u094B\u0902 \u0915\u093E \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0915\u0947 \u090F\u0915 \u092E\u094C\u0932\u093F\u0915 \u0935\u093E\u0915\u094D\u092F \u092C\u0928\u093E\u090F\u0902\u0964",
      inputPlaceholder: "\u092F\u0939\u093E\u0901 \u0905\u092A\u0928\u093E \u0935\u093E\u0915\u094D\u092F \u0932\u093F\u0916\u0947\u0902\u2026",
      semanticTip: "\u092E\u094C\u0932\u093F\u0915 \u0909\u0924\u094D\u0924\u0930\u094B\u0902 \u0915\u093E \u092E\u0942\u0932\u094D\u092F\u093E\u0902\u0915\u0928 \u0905\u0930\u094D\u0925 \u0914\u0930 \u0935\u094D\u092F\u093E\u0915\u0930\u0923 \u0915\u0947 \u0906\u0927\u093E\u0930 \u092A\u0930 \u0915\u093F\u092F\u093E \u091C\u093E\u0924\u093E \u0939\u0948, \u0938\u091F\u0940\u0915 \u0936\u092C\u094D\u0926\u094B\u0902 \u0915\u0947 \u092E\u093F\u0932\u093E\u0928 \u092A\u0930 \u0928\u0939\u0940\u0902\u0964",
      askForHelp: "\u0938\u0939\u093E\u092F\u0915 \u0938\u0947 \u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u0915\u094D\u092F\u093E \u0906\u092A \u092E\u0941\u091D\u0947 \u092E\u0947\u0930\u0947 \u0932\u093F\u090F \u0935\u093E\u0915\u094D\u092F \u0932\u093F\u0916\u0947 \u092C\u093F\u0928\u093E \u0907\u0928 \u0924\u0940\u0928 \u0936\u092C\u094D\u0926\u094B\u0902 \u0915\u094B \u091C\u094B\u0921\u093C\u0928\u0947 \u0915\u0947 \u0935\u093F\u091A\u093E\u0930 \u092F\u093E \u0938\u0902\u0915\u0947\u0924 \u0926\u0947 \u0938\u0915\u0924\u0947 \u0939\u0948\u0902?",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u093E\u0902\u091A\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u2192",
      generationFailed: "\u092F\u0939 \u091A\u0941\u0928\u094C\u0924\u0940 \u0924\u0948\u092F\u093E\u0930 \u0928\u0939\u0940\u0902 \u0939\u094B \u0938\u0915\u0940\u0964 \u0926\u0942\u0938\u0930\u0940 \u0906\u091C\u093C\u092E\u093E\u090F\u0902!",
      tryAnother: "\u0926\u0942\u0938\u0930\u0940 \u091A\u0941\u0928\u094C\u0924\u0940 \u0906\u091C\u093C\u092E\u093E\u090F\u0902"
    },
    zh: {
      title: "\u4E09\u8BCD\u9020\u53E5\u6311\u6218",
      instruction: "\u8BF7\u4F7F\u7528\u5168\u90E8\u4E09\u4E2A\u8BCD\u521B\u4F5C\u4E00\u4E2A\u5B8C\u6574\u7684\u53E5\u5B50\u3002",
      inputPlaceholder: "\u5728\u6B64\u8F93\u5165\u4F60\u7684\u53E5\u5B50\u2026",
      semanticTip: "\u7CFB\u7EDF\u5C06\u6839\u636E\u8BED\u4E49\u5408\u7406\u6027\u4E0E\u8BED\u6CD5\u8FDB\u884C\u8BC4\u5224\uFF0C\u800C\u975E\u673A\u68B0\u5339\u914D\u5B57\u53E5\u3002",
      askForHelp: "\u5411\u52A9\u624B\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u4F60\u80FD\u7ED9\u6211\u4E00\u4E9B\u6784\u601D\u6216\u8BED\u6CD5\u63D0\u793A\uFF0C\u6559\u6211\u5982\u4F55\u5C06\u8FD9\u4E09\u4E2A\u8BCD\u4E32\u8054\u6210\u53E5\u5417\uFF1F\u8BF7\u4E0D\u8981\u76F4\u63A5\u7ED9\u51FA\u5B8C\u6574\u53E5\u5B50\u3002",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u68C0\u67E5\u4E2D\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898 \u2192",
      generationFailed: "\u65E0\u6CD5\u751F\u6210\u6B64\u4E09\u8BCD\u6311\u6218\u3002\u8BF7\u5C1D\u8BD5\u53E6\u4E00\u4E2A\uFF01",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u4E2A\u6311\u6218"
    },
    nah: {
      title: "Eyi Tlahtolli Tlahtolyehyecoliztli",
      instruction: "Xikchihua se yancuic tlahtolcuezalli ika nochi eyi tlahtolli.",
      inputPlaceholder: "Nican xikihcuilo motlahtolcuezal\u2026",
      semanticTip: "Motlahtolcuezal moyehyekoa ika tlen quihtoznequi ihuan tlen cuali tlahtolli, ahmo ika san se tlahtolli.",
      askForHelp: "Xiktlahtlani tepalehuilli in tepalehuiani",
      helpRequest: "\xBFHuelis tinechmaka tlayehyecoliztli quenin nikcenquiztiz ninqueh eyi tlahtolli ahmo tlen techihchihuiliz?",
      skip: "Xikpano",
      submit: "Xikyehyeko",
      checking: "Moyehyekoa\u2026",
      tryAgain: "Okseppa xikchihua",
      nextQuestion: "Okse tlahtlanilli \u2192",
      generationFailed: "Ahmo ohuel omochihchiuh nin tlahtolyehyecoliztli. \xA1Xikyehyeko okse!",
      tryAnother: "Xikyehyeko okse tlahtolyehyecoliztli"
    },
    yua: {
      title: "\xD3oxp'\xE9el T'aan K'\xE1atchi'",
      instruction: "Meent junp'\xE9el t\xFAumben t'aan y\xE9etel tul\xE1akal le \xF3oxp'\xE9el t'aano'obo'.",
      inputPlaceholder: "Ts'\xEDibt a t'aan waye'\u2026",
      semanticTip: "A t'aano'ob yaan u yila'alo'ob tu beelil u na'ata'al y\xE9etel u gram\xE1tica, ma' ch\xE9en wa l\xE1ayli' t'aano'obo'.",
      askForHelp: "K'\xE1at \xE1antaj ti' le j-\xE1antajo'",
      helpRequest: "\xBFJe'el wa a ts'\xE1aik ten tula'an bix je'el in nuupik le \xF3oxp'\xE9el t'aana' mina'an a ts'\xEDibtik ten?",
      skip: "M\xE1ansik",
      submit: "T\xFAuxtik",
      checking: "U yila'al\u2026",
      tryAgain: "Ka'a meentej",
      nextQuestion: "U l\xE1ak' k'\xE1atchi' \u2192",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le k'\xE1atchi'a'. \xA1Je'el u p\xE1ajtal a w\xF3otik ul\xE1ak'!",
      tryAnother: "Y\xF3ot ul\xE1ak' k'\xE1atchi'"
    }
  };
  var DEFAULT_SUPPORT_LANG4 = "en";
  function getThreeWordChallengeCopy(supportLang = DEFAULT_SUPPORT_LANG4) {
    const normalized = String(supportLang || "").toLowerCase().trim();
    return THREE_WORD_CHALLENGE_I18N[normalized] || THREE_WORD_CHALLENGE_I18N.en;
  }

  // ../nosabos/nosabos/src/utils/naturalOrWeirdI18n.js
  var NATURAL_OR_WEIRD_I18N = {
    en: {
      title: "Natural or Weird?",
      instruction: "Decide if this sentence sounds natural in everyday use.",
      soundsNatural: "Sounds natural",
      soundsWeird: "Sounds weird",
      playAudio: "Listen to sentence",
      askForHelp: "Ask assistant for help",
      helpRequest: "Can you give me a hint on whether this sentence sounds natural or awkward without giving away the answer?",
      skip: "Skip",
      submit: "Submit",
      checking: "Checking\u2026",
      tryAgain: "Try again",
      nextQuestion: "Next question \u2192",
      generationFailed: "We couldn't generate a Natural or Weird question this time. Try another!",
      tryAnother: "Try another question"
    },
    es: {
      title: "\xBFNatural o extra\xF1o?",
      instruction: "Decide si esta oraci\xF3n suena natural en el uso cotidiano.",
      soundsNatural: "Suena natural",
      soundsWeird: "Suena extra\xF1o",
      playAudio: "Escuchar oraci\xF3n",
      askForHelp: "Pedir ayuda al asistente",
      helpRequest: "\xBFPuedes darme una pista sobre si esta oraci\xF3n suena natural o extra\xF1a sin decirme la respuesta?",
      skip: "Saltar",
      submit: "Comprobar",
      checking: "Comprobando\u2026",
      tryAgain: "Intentar de nuevo",
      nextQuestion: "Siguiente pregunta \u2192",
      generationFailed: "No pudimos generar esta pregunta de Natural o Extra\xF1o. \xA1Prueba con otra!",
      tryAnother: "Probar otra pregunta"
    },
    fr: {
      title: "Naturel ou bizarre ?",
      instruction: "D\xE9terminez si cette phrase semble naturelle au quotidien.",
      soundsNatural: "\xC7a semble naturel",
      soundsWeird: "\xC7a semble bizarre",
      playAudio: "\xC9couter la phrase",
      askForHelp: "Demander de l'aide \xE0 l'assistant",
      helpRequest: "Pouvez-vous me donner un indice pour savoir si cette phrase semble naturelle ou bizarre sans me donner la r\xE9ponse ?",
      skip: "Passer",
      submit: "Valider",
      checking: "V\xE9rification\u2026",
      tryAgain: "R\xE9essayer",
      nextQuestion: "Question suivante \u2192",
      generationFailed: "Impossible de g\xE9n\xE9rer cette question. Essayez-en une autre !",
      tryAnother: "Essayer une autre question"
    },
    de: {
      title: "Nat\xFCrlich oder seltsam?",
      instruction: "Entscheide, ob dieser Satz im Alltag nat\xFCrlich klingt.",
      soundsNatural: "Klingt nat\xFCrlich",
      soundsWeird: "Klingt seltsam",
      playAudio: "Satz anh\xF6ren",
      askForHelp: "Assistenten um Hilfe bitten",
      helpRequest: "Kannst du mir einen Tipp geben, ob dieser Satz nat\xFCrlich oder ungew\xF6hnlich klingt, ohne die Antwort zu verraten?",
      skip: "\xDCberspringen",
      submit: "\xDCberpr\xFCfen",
      checking: "Wird \xFCberpr\xFCft\u2026",
      tryAgain: "Erneut versuchen",
      nextQuestion: "N\xE4chste Frage \u2192",
      generationFailed: "Diese Aufgabe konnte nicht erstellt werden. Versuche eine andere!",
      tryAnother: "Andere Frage versuchen"
    },
    it: {
      title: "Naturale o strano?",
      instruction: "Decidi se questa frase suona naturale nell'uso quotidiano.",
      soundsNatural: "Suona naturale",
      soundsWeird: "Suona strano",
      playAudio: "Ascolta la frase",
      askForHelp: "Chiedi aiuto all'assistente",
      helpRequest: "Puoi darmi un indizio su quanto questa frase suoni naturale o strana senza svelare la risposta?",
      skip: "Salta",
      submit: "Verifica",
      checking: "Verifica in corso\u2026",
      tryAgain: "Riprova",
      nextQuestion: "Prossima domanda \u2192",
      generationFailed: "Impossibile generare questa domanda. Provane un'altra!",
      tryAnother: "Prova un'altra domanda"
    },
    pt: {
      title: "Natural ou estranho?",
      instruction: "Decida se esta frase soa natural no uso cotidiano.",
      soundsNatural: "Soa natural",
      soundsWeird: "Soa estranho",
      playAudio: "Ouvir frase",
      askForHelp: "Pedir ajuda ao assistente",
      helpRequest: "Pode me dar uma dica sobre se esta frase soa natural ou estranha sem me dar a resposta?",
      skip: "Pular",
      submit: "Enviar",
      checking: "Verificando\u2026",
      tryAgain: "Tentar novamente",
      nextQuestion: "Pr\xF3xima pergunta \u2192",
      generationFailed: "N\xE3o foi poss\xEDvel gerar esta pergunta. Tente outra!",
      tryAnother: "Tentar outra pergunta"
    },
    ja: {
      title: "\u81EA\u7136\uFF1F\u305D\u308C\u3068\u3082\u4E0D\u81EA\u7136\uFF1F",
      instruction: "\u3053\u306E\u6587\u304C\u65E5\u5E38\u4F1A\u8A71\u3068\u3057\u3066\u81EA\u7136\u304B\u3069\u3046\u304B\u3092\u5224\u65AD\u3057\u3066\u304F\u3060\u3055\u3044\u3002",
      soundsNatural: "\u81EA\u7136\u306B\u805E\u3053\u3048\u308B",
      soundsWeird: "\u4E0D\u81EA\u7136\u306B\u805E\u3053\u3048\u308B",
      playAudio: "\u97F3\u58F0\u3092\u8074\u304F",
      askForHelp: "\u30A2\u30B7\u30B9\u30BF\u30F3\u30C8\u306B\u30D2\u30F3\u30C8\u3092\u805E\u304F",
      helpRequest: "\u7B54\u3048\u3092\u76F4\u63A5\u8A00\u308F\u305A\u306B\u3001\u3053\u306E\u6587\u304C\u81EA\u7136\u304B\u4E0D\u81EA\u7136\u304B\u306E\u30D2\u30F3\u30C8\u3092\u6559\u3048\u3066\u304F\u308C\u307E\u3059\u304B\uFF1F",
      skip: "\u30B9\u30AD\u30C3\u30D7",
      submit: "\u56DE\u7B54\u3059\u308B",
      checking: "\u78BA\u8A8D\u4E2D\u2026",
      tryAgain: "\u3082\u3046\u4E00\u5EA6\u6311\u6226",
      nextQuestion: "\u6B21\u306E\u554F\u984C\u3078 \u2192",
      generationFailed: "\u554F\u984C\u3092\u751F\u6210\u3067\u304D\u307E\u305B\u3093\u3067\u3057\u305F\u3002\u5225\u306E\u554F\u984C\u3092\u304A\u8A66\u3057\u304F\u3060\u3055\u3044\u3002",
      tryAnother: "\u5225\u306E\u554F\u984C\u3092\u8A66\u3059"
    },
    ru: {
      title: "\u0415\u0441\u0442\u0435\u0441\u0442\u0432\u0435\u043D\u043D\u043E \u0438\u043B\u0438 \u0441\u0442\u0440\u0430\u043D\u043D\u043E?",
      instruction: "\u041E\u043F\u0440\u0435\u0434\u0435\u043B\u0438\u0442\u0435, \u0437\u0432\u0443\u0447\u0438\u0442 \u043B\u0438 \u044D\u0442\u043E \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435 \u0435\u0441\u0442\u0435\u0441\u0442\u0432\u0435\u043D\u043D\u043E \u0432 \u043F\u043E\u0432\u0441\u0435\u0434\u043D\u0435\u0432\u043D\u043E\u0439 \u0440\u0435\u0447\u0438.",
      soundsNatural: "\u0417\u0432\u0443\u0447\u0438\u0442 \u0435\u0441\u0442\u0435\u0441\u0442\u0432\u0435\u043D\u043D\u043E",
      soundsWeird: "\u0417\u0432\u0443\u0447\u0438\u0442 \u0441\u0442\u0440\u0430\u043D\u043D\u043E",
      playAudio: "\u041F\u0440\u043E\u0441\u043B\u0443\u0448\u0430\u0442\u044C \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435",
      askForHelp: "\u041F\u043E\u043F\u0440\u043E\u0441\u0438\u0442\u044C \u043F\u043E\u043C\u043E\u0449\u0438 \u0443 \u0430\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442\u0430",
      helpRequest: "\u041C\u043E\u0436\u0435\u0442\u0435 \u0434\u0430\u0442\u044C \u043F\u043E\u0434\u0441\u043A\u0430\u0437\u043A\u0443, \u0437\u0432\u0443\u0447\u0438\u0442 \u043B\u0438 \u044D\u0442\u043E \u043F\u0440\u0435\u0434\u043B\u043E\u0436\u0435\u043D\u0438\u0435 \u0435\u0441\u0442\u0435\u0441\u0442\u0432\u0435\u043D\u043D\u043E \u0438\u043B\u0438 \u0441\u0442\u0440\u0430\u043D\u043D\u043E, \u043D\u0435 \u0440\u0430\u0441\u043A\u0440\u044B\u0432\u0430\u044F \u043E\u0442\u0432\u0435\u0442\u0430?",
      skip: "\u041F\u0440\u043E\u043F\u0443\u0441\u0442\u0438\u0442\u044C",
      submit: "\u041F\u0440\u043E\u0432\u0435\u0440\u0438\u0442\u044C",
      checking: "\u041F\u0440\u043E\u0432\u0435\u0440\u043A\u0430\u2026",
      tryAgain: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0441\u043D\u043E\u0432\u0430",
      nextQuestion: "\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u0432\u043E\u043F\u0440\u043E\u0441 \u2192",
      generationFailed: "\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0441\u043E\u0437\u0434\u0430\u0442\u044C \u0432\u043E\u043F\u0440\u043E\u0441. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0434\u0440\u0443\u0433\u043E\u0439!",
      tryAnother: "\u041F\u043E\u043F\u0440\u043E\u0431\u043E\u0432\u0430\u0442\u044C \u0434\u0440\u0443\u0433\u043E\u0439 \u0432\u043E\u043F\u0440\u043E\u0441"
    },
    el: {
      title: "\u03A6\u03C5\u03C3\u03B9\u03BA\u03CC \u03AE \u03C0\u03B1\u03C1\u03AC\u03BE\u03B5\u03BD\u03BF;",
      instruction: "\u0391\u03C0\u03BF\u03C6\u03B1\u03C3\u03AF\u03C3\u03C4\u03B5 \u03B1\u03BD \u03B1\u03C5\u03C4\u03AE \u03B7 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7 \u03B1\u03BA\u03BF\u03CD\u03B3\u03B5\u03C4\u03B1\u03B9 \u03C6\u03C5\u03C3\u03B9\u03BA\u03AE \u03C3\u03C4\u03B7\u03BD \u03BA\u03B1\u03B8\u03B7\u03BC\u03B5\u03C1\u03B9\u03BD\u03AE \u03C7\u03C1\u03AE\u03C3\u03B7.",
      soundsNatural: "\u0391\u03BA\u03BF\u03CD\u03B3\u03B5\u03C4\u03B1\u03B9 \u03C6\u03C5\u03C3\u03B9\u03BA\u03CC",
      soundsWeird: "\u0391\u03BA\u03BF\u03CD\u03B3\u03B5\u03C4\u03B1\u03B9 \u03C0\u03B1\u03C1\u03AC\u03BE\u03B5\u03BD\u03BF",
      playAudio: "\u0391\u03BA\u03BF\u03CD\u03C3\u03C4\u03B5 \u03C4\u03B7\u03BD \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7",
      askForHelp: "\u0396\u03B7\u03C4\u03AE\u03C3\u03C4\u03B5 \u03B2\u03BF\u03AE\u03B8\u03B5\u03B9\u03B1 \u03B1\u03C0\u03CC \u03C4\u03BF\u03BD \u03B2\u03BF\u03B7\u03B8\u03CC",
      helpRequest: "\u039C\u03C0\u03BF\u03C1\u03B5\u03AF\u03C4\u03B5 \u03BD\u03B1 \u03BC\u03BF\u03C5 \u03B4\u03CE\u03C3\u03B5\u03C4\u03B5 \u03BC\u03B9\u03B1 \u03C5\u03C0\u03CC\u03B4\u03B5\u03B9\u03BE\u03B7 \u03B3\u03B9\u03B1 \u03C4\u03BF \u03B1\u03BD \u03B1\u03C5\u03C4\u03AE \u03B7 \u03C0\u03C1\u03CC\u03C4\u03B1\u03C3\u03B7 \u03B1\u03BA\u03BF\u03CD\u03B3\u03B5\u03C4\u03B1\u03B9 \u03C6\u03C5\u03C3\u03B9\u03BA\u03AE \u03AE \u03C0\u03B1\u03C1\u03AC\u03BE\u03B5\u03BD\u03B7 \u03C7\u03C9\u03C1\u03AF\u03C2 \u03BD\u03B1 \u03B1\u03C0\u03BF\u03BA\u03B1\u03BB\u03CD\u03C8\u03B5\u03C4\u03B5 \u03C4\u03B7\u03BD \u03B1\u03C0\u03AC\u03BD\u03C4\u03B7\u03C3\u03B7;",
      skip: "\u03A0\u03B1\u03C1\u03AC\u03BB\u03B5\u03B9\u03C8\u03B7",
      submit: "\u03A5\u03C0\u03BF\u03B2\u03BF\u03BB\u03AE",
      checking: "\u0388\u03BB\u03B5\u03B3\u03C7\u03BF\u03C2\u2026",
      tryAgain: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03BE\u03B1\u03BD\u03AC",
      nextQuestion: "\u0395\u03C0\u03CC\u03BC\u03B5\u03BD\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7 \u2192",
      generationFailed: "\u0394\u03B5\u03BD \u03AE\u03C4\u03B1\u03BD \u03B4\u03C5\u03BD\u03B1\u03C4\u03AE \u03B7 \u03B4\u03B7\u03BC\u03B9\u03BF\u03C5\u03C1\u03B3\u03AF\u03B1 \u03B1\u03C5\u03C4\u03AE\u03C2 \u03C4\u03B7\u03C2 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7\u03C2. \u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7!",
      tryAnother: "\u0394\u03BF\u03BA\u03B9\u03BC\u03AC\u03C3\u03C4\u03B5 \u03AC\u03BB\u03BB\u03B7 \u03B5\u03C1\u03CE\u03C4\u03B7\u03C3\u03B7"
    },
    nl: {
      title: "Natuurlijk of raar?",
      instruction: "Beslis of deze zin natuurlijk klinkt in het dagelijks leven.",
      soundsNatural: "Klinkt natuurlijk",
      soundsWeird: "Klinkt raar",
      playAudio: "Beluister zin",
      askForHelp: "Vraag assistent om hulp",
      helpRequest: "Kun je me een hint geven of deze zin natuurlijk of vreemd klinkt zonder het antwoord te verklappen?",
      skip: "Overslaan",
      submit: "Controleren",
      checking: "Controleren\u2026",
      tryAgain: "Opnieuw proberen",
      nextQuestion: "Volgende vraag \u2192",
      generationFailed: "We konden deze vraag niet maken. Probeer een andere!",
      tryAnother: "Probeer een andere vraag"
    },
    pl: {
      title: "Naturalne czy dziwne?",
      instruction: "Oce\u0144, czy to zdanie brzmi naturalnie w codziennym u\u017Cyciu.",
      soundsNatural: "Brzmi naturalnie",
      soundsWeird: "Brzmi dziwnie",
      playAudio: "Ods\u0142uchaj zdanie",
      askForHelp: "Popro\u015B asystenta o pomoc",
      helpRequest: "Czy mo\u017Cesz podpowiedzie\u0107 mi, czy to zdanie brzmi naturalnie czy dziwnie, nie zdradzaj\u0105c odpowiedzi?",
      skip: "Pomi\u0144",
      submit: "Sprawd\u017A",
      checking: "Sprawdzanie\u2026",
      tryAgain: "Spr\xF3buj ponownie",
      nextQuestion: "Nast\u0119pne pytanie \u2192",
      generationFailed: "Nie uda\u0142o si\u0119 wygenerowa\u0107 pytania. Spr\xF3buj innego!",
      tryAnother: "Spr\xF3buj innego pytania"
    },
    ga: {
      title: "N\xE1d\xFArtha n\xF3 Aisteach?",
      instruction: "D\xE9an cinneadh an bhfuil an abairt seo n\xE1d\xFArtha sa ghn\xE1thchaint.",
      soundsNatural: "Fuaimeann s\xE9 n\xE1d\xFArtha",
      soundsWeird: "Fuaimeann s\xE9 aisteach",
      playAudio: "\xC9ist leis an abairt",
      askForHelp: "Iarr cabhair ar an gc\xFAnt\xF3ir",
      helpRequest: "An f\xE9idir leat leid a thabhairt dom an bhfuil an abairt seo n\xE1d\xFArtha n\xF3 aisteach gan an freagra a thabhairt dom?",
      skip: "Scipe\xE1il",
      submit: "Seol",
      checking: "\xC1 sheice\xE1il\u2026",
      tryAgain: "Bain triail eile as",
      nextQuestion: "An ch\xE9ad cheist eile \u2192",
      generationFailed: "N\xEDorbh fh\xE9idir an cheist seo a ghini\xFAint. Bain triail as ceann eile!",
      tryAnother: "Bain triail as ceist eile"
    },
    ar: {
      title: "\u0637\u0628\u064A\u0639\u064A \u0623\u0645 \u063A\u0631\u064A\u0628\u061F",
      instruction: "\u062D\u062F\u062F \u0645\u0627 \u0625\u0630\u0627 \u0643\u0627\u0646\u062A \u0647\u0630\u0647 \u0627\u0644\u062C\u0645\u0644\u0629 \u062A\u0628\u062F\u0648 \u0637\u0628\u064A\u0639\u064A\u0629 \u0641\u064A \u0627\u0644\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0627\u0644\u064A\u0648\u0645\u064A.",
      soundsNatural: "\u064A\u0628\u062F\u0648 \u0637\u0628\u064A\u0639\u064A\u064B\u0627",
      soundsWeird: "\u064A\u0628\u062F\u0648 \u063A\u0631\u064A\u0628\u064B\u0627",
      playAudio: "\u0627\u0633\u062A\u0645\u0639 \u0625\u0644\u0649 \u0627\u0644\u062C\u0645\u0644\u0629",
      askForHelp: "\u0627\u0637\u0644\u0628 \u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u0633\u0627\u0639\u062F",
      helpRequest: "\u0647\u0644 \u064A\u0645\u0643\u0646\u0643 \u0625\u0639\u0637\u0627\u0626\u064A \u062A\u0644\u0645\u064A\u062D\u064B\u0627 \u0639\u0645\u0627 \u0625\u0630\u0627 \u0643\u0627\u0646\u062A \u0647\u0630\u0647 \u0627\u0644\u062C\u0645\u0644\u0629 \u062A\u0628\u062F\u0648 \u0637\u0628\u064A\u0639\u064A\u0629 \u0623\u0645 \u063A\u0631\u064A\u0628\u0629 \u062F\u0648\u0646 \u0625\u0639\u0637\u0627\u0626\u064A \u0627\u0644\u0625\u062C\u0627\u0628\u0629\u061F",
      skip: "\u062A\u062E\u0637\u064A",
      submit: "\u062A\u062D\u0642\u0642",
      checking: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0642\u0642\u2026",
      tryAgain: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      nextQuestion: "\u0627\u0644\u0633\u0624\u0627\u0644 \u0627\u0644\u062A\u0627\u0644\u064A \u2190",
      generationFailed: "\u062A\u0639\u0630\u0631 \u062A\u0648\u0644\u064A\u062F \u0647\u0630\u0627 \u0627\u0644\u0633\u0624\u0627\u0644. \u062C\u0631\u0628 \u0633\u0624\u0627\u0644\u0627\u064B \u0622\u062E\u0631!",
      tryAnother: "\u062C\u0631\u0628 \u0633\u0624\u0627\u0644\u0627\u064B \u0622\u062E\u0631"
    },
    hi: {
      title: "\u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u092F\u093E \u0905\u091C\u0940\u092C?",
      instruction: "\u0924\u092F \u0915\u0930\u0947\u0902 \u0915\u093F \u0915\u094D\u092F\u093E \u092F\u0939 \u0935\u093E\u0915\u094D\u092F \u0926\u0948\u0928\u093F\u0915 \u0909\u092A\u092F\u094B\u0917 \u092E\u0947\u0902 \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0932\u0917\u0924\u093E \u0939\u0948\u0964",
      soundsNatural: "\u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0932\u0917\u0924\u093E \u0939\u0948",
      soundsWeird: "\u0905\u091C\u0940\u092C \u0932\u0917\u0924\u093E \u0939\u0948",
      playAudio: "\u0935\u093E\u0915\u094D\u092F \u0938\u0941\u0928\u0947\u0902",
      askForHelp: "\u0938\u0939\u093E\u092F\u0915 \u0938\u0947 \u092E\u0926\u0926 \u092E\u093E\u0902\u0917\u0947\u0902",
      helpRequest: "\u0915\u094D\u092F\u093E \u0906\u092A \u092E\u0941\u091D\u0947 \u0909\u0924\u094D\u0924\u0930 \u092C\u0924\u093E\u090F \u092C\u093F\u0928\u093E \u0938\u0902\u0915\u0947\u0924 \u0926\u0947 \u0938\u0915\u0924\u0947 \u0939\u0948\u0902 \u0915\u093F \u092F\u0939 \u0935\u093E\u0915\u094D\u092F \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u0932\u0917\u0924\u093E \u0939\u0948 \u092F\u093E \u0905\u091C\u0940\u092C?",
      skip: "\u091B\u094B\u0921\u093C\u0947\u0902",
      submit: "\u091C\u093E\u0902\u091A\u0947\u0902",
      checking: "\u091C\u093E\u0902\u091A \u091C\u093E\u0930\u0940 \u0939\u0948\u2026",
      tryAgain: "\u092A\u0941\u0928\u0903 \u092A\u094D\u0930\u092F\u093E\u0938 \u0915\u0930\u0947\u0902",
      nextQuestion: "\u0905\u0917\u0932\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u2192",
      generationFailed: "\u092F\u0939 \u092A\u094D\u0930\u0936\u094D\u0928 \u0924\u0948\u092F\u093E\u0930 \u0928\u0939\u0940\u0902 \u0939\u094B \u0938\u0915\u093E\u0964 \u0926\u0942\u0938\u0930\u093E \u0906\u091C\u093C\u092E\u093E\u090F\u0902!",
      tryAnother: "\u0926\u0942\u0938\u0930\u093E \u092A\u094D\u0930\u0936\u094D\u0928 \u0906\u091C\u093C\u092E\u093E\u090F\u0902"
    },
    zh: {
      title: "\u5730\u9053\u8FD8\u662F\u522B\u626D\uFF1F",
      instruction: "\u8BF7\u5224\u65AD\u8FD9\u4E2A\u53E5\u5B50\u5728\u65E5\u5E38\u4F7F\u7528\u4E2D\u542C\u8D77\u6765\u662F\u5426\u5730\u9053\u81EA\u7136\u3002",
      soundsNatural: "\u542C\u8D77\u6765\u5F88\u5730\u9053",
      soundsWeird: "\u542C\u8D77\u6765\u5F88\u522B\u626D",
      playAudio: "\u6717\u8BFB\u53E5\u5B50",
      askForHelp: "\u5411\u52A9\u624B\u5BFB\u6C42\u5E2E\u52A9",
      helpRequest: "\u4F60\u80FD\u5426\u5728\u4E0D\u76F4\u63A5\u900F\u9732\u7B54\u6848\u7684\u524D\u63D0\u4E0B\uFF0C\u63D0\u793A\u6211\u8FD9\u4E2A\u53E5\u5B50\u662F\u5426\u81EA\u7136\u5730\u9053\uFF1F",
      skip: "\u8DF3\u8FC7",
      submit: "\u63D0\u4EA4",
      checking: "\u68C0\u67E5\u4E2D\u2026",
      tryAgain: "\u518D\u8BD5\u4E00\u6B21",
      nextQuestion: "\u4E0B\u4E00\u9898 \u2192",
      generationFailed: "\u65E0\u6CD5\u751F\u6210\u6B64\u9898\u76EE\u3002\u8BF7\u5C1D\u8BD5\u53E6\u4E00\u9898\uFF01",
      tryAnother: "\u5C1D\u8BD5\u53E6\u4E00\u9898"
    },
    nah: {
      title: "Cualli o Ahmo cuali?",
      instruction: "Xikyehyeko tla nin tlahtolli cualli caqui ipan tlen mochiuhqui.",
      soundsNatural: "Cualli caqui",
      soundsWeird: "Ahmo cualli caqui",
      playAudio: "Xikcaqui tlahtolli",
      askForHelp: "Xiktlahtlani tepalehuilli in tepalehuiani",
      helpRequest: "\xBFHuelis tinechmaka se tlanextilli tla nin tlahtolli cualli o ahmo cuali caqui ahmo tlen techilhuiz?",
      skip: "Xikpano",
      submit: "Xikyehyeko",
      checking: "Moyehyekoa\u2026",
      tryAgain: "Okseppa xikchihua",
      nextQuestion: "Okse tlahtlanilli \u2192",
      generationFailed: "Ahmo ohuel omochihchiuh nin tlahtlanilli. \xA1Xikyehyeko okse!",
      tryAnother: "Xikyehyeko okse tlahtlanilli"
    },
    yua: {
      title: "U j\xE9el wa K'aak'as?",
      instruction: "Y\xF3ot wa le t'aana' ma'alob u yu'uba'al ti' u kuxtal k'iin.",
      soundsNatural: "Ma'alob u yu'uba'al",
      soundsWeird: "K'aak'as u yu'uba'al",
      playAudio: "U'uy le t'aana'",
      askForHelp: "K'\xE1at \xE1antaj ti' le j-\xE1antajo'",
      helpRequest: "\xBFJe'el wa a ts'\xE1aik ten tula'an wa le t'aana' ma'alob wa k'aak'as mina'an a ts'\xEDibtik ten?",
      skip: "M\xE1ansik",
      submit: "T\xFAuxtik",
      checking: "U yila'al\u2026",
      tryAgain: "Ka'a meentej",
      nextQuestion: "U l\xE1ak' k'\xE1atchi' \u2192",
      generationFailed: "Ma' b\xE9eychaj u meenta'al le k'\xE1atchi'a'. \xA1Je'el u p\xE1ajtal a w\xF3otik ul\xE1ak'!",
      tryAnother: "Y\xF3ot ul\xE1ak' k'\xE1atchi'"
    }
  };
  var DEFAULT_SUPPORT_LANG5 = "en";
  function getNaturalOrWeirdCopy(supportLang = DEFAULT_SUPPORT_LANG5) {
    const normalized = String(supportLang || "").toLowerCase().trim();
    return NATURAL_OR_WEIRD_I18N[normalized] || NATURAL_OR_WEIRD_I18N.en;
  }

  // ../nosabos/nosabos/src/data/manualA1Agendas.js
  var FORM_LABEL_PREFIXES = Object.freeze({
    en: "Use in context",
    es: "Usa en contexto",
    pt: "Use em contexto",
    it: "Usa nel contesto",
    fr: "Utilise en contexte",
    de: "Im Kontext verwenden",
    ja: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528"
  });
  var agenda = (forms, application) => ({ forms, application });
  var MANUAL_A1_AGENDAS = Object.freeze({
    "lesson-a1-5-2": agenda(
      [
        "\xBFqu\xE9 d\xEDa es hoy?",
        "hoy es...",
        "ma\xF1ana es...",
        "ayer fue...",
        "el lunes",
        "los lunes"
      ],
      {
        label: {
          en: "Say what day it is and distinguish one day from a weekly routine",
          es: "Di qu\xE9 d\xEDa es y distingue un d\xEDa de una rutina semanal",
          pt: "Diga que dia \xE9 e diferencie um dia de uma rotina semanal",
          it: "Di che giorno \xE8 e distingui un giorno da una routine settimanale",
          fr: "Dis quel jour on est et distingue un jour d\u2019une routine hebdomadaire",
          de: "Den Wochentag nennen und einen einzelnen Tag von einer Wochenroutine unterscheiden",
          ja: "\u66DC\u65E5\u3092\u8A00\u3044\u3001\u7279\u5B9A\u306E\u4E00\u65E5\u3068\u6BCE\u9031\u306E\u7FD2\u6163\u3092\u533A\u5225\u3059\u308B",
          hi: "\u0926\u093F\u0928 \u092C\u0924\u093E\u090F\u0902 \u0914\u0930 \u0915\u093F\u0938\u0940 \u090F\u0915 \u0926\u093F\u0928 \u0915\u094B \u0938\u093E\u092A\u094D\u0924\u093E\u0939\u093F\u0915 \u0926\u093F\u0928\u091A\u0930\u094D\u092F\u093E \u0938\u0947 \u0905\u0932\u0917 \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
          ar: "\u0627\u0630\u0643\u0631 \u0627\u0644\u064A\u0648\u0645 \u0648\u0645\u064A\u0651\u0632 \u0628\u064A\u0646 \u064A\u0648\u0645 \u0648\u0627\u062D\u062F \u0648\u0631\u0648\u062A\u064A\u0646 \u0623\u0633\u0628\u0648\u0639\u064A",
          zh: "\u8BF4\u51FA\u661F\u671F\u51E0\uFF0C\u5E76\u533A\u5206\u67D0\u4E00\u5929\u548C\u6BCF\u5468\u60EF\u4F8B"
        },
        goal: "Answer what day it is and distinguish one occurrence from a weekly routine",
        examples: ["Hoy es lunes.", "Los lunes estudio."],
        activityBrief: "Ask about today, yesterday, and tomorrow, then contrast one event on Monday with a recurring Monday routine",
        evidence: "The learner gives three correct day answers and uses el lunes and los lunes in the matching contexts"
      }
    ),
    "lesson-a1-5-3": agenda(
      [
        "el lunes voy a...",
        "el martes tengo...",
        "los mi\xE9rcoles...",
        "el fin de semana...",
        "esta semana",
        "la pr\xF3xima semana"
      ],
      {
        label: {
          en: "Describe three plans on different days and ask one follow-up question",
          es: "Describe tres planes en d\xEDas distintos y haz una pregunta de seguimiento",
          pt: "Descreva tr\xEAs planos em dias diferentes e fa\xE7a uma pergunta de seguimento",
          it: "Descrivi tre programmi in giorni diversi e fai una domanda di approfondimento",
          fr: "D\xE9cris trois projets \xE0 des jours diff\xE9rents et pose une question de suivi",
          de: "Drei Pl\xE4ne an verschiedenen Tagen beschreiben und eine R\xFCckfrage stellen",
          ja: "\u7570\u306A\u308B\u66DC\u65E5\u306E\u4E88\u5B9A\u30923\u3064\u8AAC\u660E\u3057\u3001\u78BA\u8A8D\u306E\u8CEA\u554F\u30921\u3064\u3059\u308B",
          hi: "\u0905\u0932\u0917-\u0905\u0932\u0917 \u0926\u093F\u0928\u094B\u0902 \u0915\u0940 \u0924\u0940\u0928 \u092F\u094B\u091C\u0928\u093E\u090F\u0902 \u092C\u0924\u093E\u090F\u0902 \u0914\u0930 \u090F\u0915 \u0905\u0917\u0932\u093E \u0938\u0935\u093E\u0932 \u092A\u0942\u091B\u0947\u0902",
          ar: "\u0635\u0650\u0641 \u062B\u0644\u0627\u062B \u062E\u0637\u0637 \u0641\u064A \u0623\u064A\u0627\u0645 \u0645\u062E\u062A\u0644\u0641\u0629 \u0648\u0627\u0637\u0631\u062D \u0633\u0624\u0627\u0644 \u0645\u062A\u0627\u0628\u0639\u0629 \u0648\u0627\u062D\u062F\u064B\u0627",
          zh: "\u63CF\u8FF0\u4E09\u4E2A\u4E0D\u540C\u65E5\u671F\u7684\u8BA1\u5212\uFF0C\u5E76\u63D0\u51FA\u4E00\u4E2A\u540E\u7EED\u95EE\u9898"
        },
        goal: "Describe three weekly plans on different days and ask one follow-up question",
        examples: ["El lunes voy a trabajar.", "\xBFY el martes?"],
        activityBrief: "Build a three-day weekly plan one day at a time, then require one question about the other person's week",
        evidence: "The learner states three understandable day-plus-plan combinations and asks one relevant day question"
      }
    ),
    "lesson-a1-6-2": agenda(
      [
        "\xBFcu\xE1ndo es tu cumplea\xF1os?",
        "mi cumplea\xF1os es el...",
        "\xBFqu\xE9 fecha es hoy?",
        "hoy es el...",
        "en enero",
        "el cinco de mayo"
      ],
      {
        label: {
          en: "Ask for and give today\u2019s date and one birthday",
          es: "Pregunta y da la fecha de hoy y un cumplea\xF1os",
          pt: "Pergunte e diga a data de hoje e um anivers\xE1rio",
          it: "Chiedi e comunica la data di oggi e un compleanno",
          fr: "Demande et donne la date d\u2019aujourd\u2019hui et un anniversaire",
          de: "Nach dem heutigen Datum und einem Geburtstag fragen und beide nennen",
          ja: "\u4ECA\u65E5\u306E\u65E5\u4ED8\u3068\u8A95\u751F\u65E5\u3092\u5C0B\u306D\u3066\u7B54\u3048\u308B",
          hi: "\u0906\u091C \u0915\u0940 \u0924\u093E\u0930\u0940\u0916 \u0914\u0930 \u090F\u0915 \u091C\u0928\u094D\u092E\u0926\u093F\u0928 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u064A\u0648\u0645 \u0648\u0639\u0646 \u0639\u064A\u062F \u0645\u064A\u0644\u0627\u062F \u0648\u0627\u0630\u0643\u0631\u0647\u0645\u0627",
          zh: "\u8BE2\u95EE\u5E76\u8BF4\u51FA\u4ECA\u5929\u7684\u65E5\u671F\u548C\u4E00\u4E2A\u751F\u65E5"
        },
        goal: "Ask for and give today's date and one birthday",
        examples: ["Hoy es el cinco de mayo.", "Mi cumplea\xF1os es el doce de junio."],
        activityBrief: "Exchange today's date and a fictional birthday, prompting the day and month separately if needed",
        evidence: "The learner asks or answers both date questions with an understandable day and month"
      }
    ),
    "lesson-a1-6-3": agenda(
      [
        "\xBFcu\xE1ndo es...?",
        "es el...",
        "la cita es el...",
        "la fiesta es el...",
        "primero",
        "despu\xE9s"
      ],
      {
        label: {
          en: "Find the event and date in an invitation, then confirm the day",
          es: "Encuentra el evento y la fecha en una invitaci\xF3n y confirma el d\xEDa",
          pt: "Encontre o evento e a data em um convite e confirme o dia",
          it: "Trova l\u2019evento e la data in un invito, poi conferma il giorno",
          fr: "Trouve l\u2019\xE9v\xE9nement et la date dans une invitation, puis confirme le jour",
          de: "Ereignis und Datum in einer Einladung finden und den Tag best\xE4tigen",
          ja: "\u62DB\u5F85\u72B6\u304B\u3089\u884C\u4E8B\u3068\u65E5\u4ED8\u3092\u898B\u3064\u3051\u3001\u66DC\u65E5\u3092\u78BA\u8A8D\u3059\u308B",
          hi: "\u0928\u093F\u092E\u0902\u0924\u094D\u0930\u0923 \u092E\u0947\u0902 \u0915\u093E\u0930\u094D\u092F\u0915\u094D\u0930\u092E \u0914\u0930 \u0924\u093E\u0930\u0940\u0916 \u0916\u094B\u091C\u0947\u0902, \u092B\u093F\u0930 \u0926\u093F\u0928 \u0915\u0940 \u092A\u0941\u0937\u094D\u091F\u093F \u0915\u0930\u0947\u0902",
          ar: "\u0627\u0639\u062B\u0631 \u0639\u0644\u0649 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0648\u0627\u0644\u062A\u0627\u0631\u064A\u062E \u0641\u064A \u062F\u0639\u0648\u0629 \u062B\u0645 \u0623\u0643\u0651\u062F \u0627\u0644\u064A\u0648\u0645",
          zh: "\u4ECE\u9080\u8BF7\u4E2D\u627E\u51FA\u6D3B\u52A8\u548C\u65E5\u671F\uFF0C\u7136\u540E\u786E\u8BA4\u65E5\u671F"
        },
        goal: "Identify an event and its date in a short invitation, then confirm the day",
        examples: ["La fiesta es el ocho de julio.", "S\xED, es el s\xE1bado."],
        activityBrief: "Present a two-sentence invitation with one event and date, ask for both details, then run one confirmation turn",
        evidence: "The learner identifies the correct event and date and completes the confirmation",
        kind: "comprehension",
        evidenceType: "identify_and_respond"
      }
    ),
    "lesson-a1-7-2": agenda(
      [
        "\xBFqu\xE9 hora es?",
        "es la una",
        "son las...",
        "y cuarto",
        "y media",
        "menos cuarto",
        "a las..."
      ],
      {
        label: {
          en: "Read a three-item schedule and say each time",
          es: "Lee un horario de tres actividades y di cada hora",
          pt: "Leia um hor\xE1rio de tr\xEAs atividades e diga cada hora",
          it: "Leggi un programma di tre attivit\xE0 e di\u2019 ogni orario",
          fr: "Lis un programme de trois activit\xE9s et donne chaque heure",
          de: "Einen Plan mit drei Terminen lesen und jede Uhrzeit nennen",
          ja: "3\u9805\u76EE\u306E\u4E88\u5B9A\u8868\u3092\u8AAD\u307F\u3001\u305D\u308C\u305E\u308C\u306E\u6642\u523B\u3092\u8A00\u3046",
          hi: "\u0924\u0940\u0928 \u0917\u0924\u093F\u0935\u093F\u0927\u093F\u092F\u094B\u0902 \u0915\u0940 \u0938\u092E\u092F-\u0938\u093E\u0930\u0923\u0940 \u092A\u0922\u093C\u0947\u0902 \u0914\u0930 \u0939\u0930 \u0938\u092E\u092F \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u0642\u0631\u0623 \u062C\u062F\u0648\u0644\u064B\u0627 \u0645\u0646 \u062B\u0644\u0627\u062B\u0629 \u0628\u0646\u0648\u062F \u0648\u0627\u0630\u0643\u0631 \u0648\u0642\u062A \u0643\u0644 \u0648\u0627\u062D\u062F",
          zh: "\u9605\u8BFB\u5305\u542B\u4E09\u9879\u6D3B\u52A8\u7684\u65E5\u7A0B\u5E76\u8BF4\u51FA\u6BCF\u4E2A\u65F6\u95F4"
        },
        goal: "Read a three-item daily schedule and state each time",
        examples: ["La clase es a las dos y media.", "La cena es a las ocho."],
        activityBrief: "Present three familiar activities at an hour, half hour, and quarter hour, asking for one time at a time",
        evidence: "The learner correctly states all three scheduled times",
        kind: "comprehension",
        evidenceType: "identify"
      }
    ),
    "lesson-a1-7-3": agenda(
      [
        "\xBFa qu\xE9 hora puedes?",
        "puedo a las...",
        "no puedo a las...",
        "\xBFte va bien...?",
        "s\xED, perfecto",
        "mejor a las..."
      ],
      {
        label: {
          en: "Arrange and reschedule one appointment in a short exchange",
          es: "Acuerda y cambia una cita en un intercambio breve",
          pt: "Marque e remarque um compromisso em uma conversa curta",
          it: "Fissa e sposta un appuntamento in un breve scambio",
          fr: "Fixe puis d\xE9place un rendez-vous dans un court \xE9change",
          de: "In einem kurzen Gespr\xE4ch einen Termin vereinbaren und verschieben",
          ja: "\u77ED\u3044\u3084\u308A\u53D6\u308A\u3067\u4E88\u7D04\u3092\u6C7A\u3081\u3001\u5225\u306E\u6642\u9593\u306B\u5909\u66F4\u3059\u308B",
          hi: "\u091B\u094B\u091F\u0947 \u0938\u0902\u0935\u093E\u0926 \u092E\u0947\u0902 \u090F\u0915 \u092E\u0941\u0932\u093E\u0915\u093E\u0924 \u0924\u092F \u0915\u0930\u0947\u0902 \u0914\u0930 \u0909\u0938\u0915\u093E \u0938\u092E\u092F \u092C\u0926\u0932\u0947\u0902",
          ar: "\u062D\u062F\u0651\u062F \u0645\u0648\u0639\u062F\u064B\u0627 \u062B\u0645 \u063A\u064A\u0651\u0631\u0647 \u0641\u064A \u062D\u0648\u0627\u0631 \u0642\u0635\u064A\u0631",
          zh: "\u5728\u7B80\u77ED\u5BF9\u8BDD\u4E2D\u5B89\u6392\u5E76\u6539\u7EA6\u4E00\u6B21\u89C1\u9762"
        },
        goal: "Arrange, reject, and confirm one appointment time in a short exchange",
        examples: ["\xBFTe va bien a las tres?", "No puedo. Mejor a las cuatro."],
        activityBrief: "Offer one appointment time, require a conflict and alternative, then confirm the new time",
        evidence: "The learner asks about a time, rejects one option, proposes another, and confirms it"
      }
    ),
    "lesson-a1-8-2": agenda(
      [
        "mi madre se llama...",
        "tengo ... hermanos",
        "este es mi...",
        "\xBFqui\xE9n es...?",
        "\xBFtienes hermanos?",
        "vive en..."
      ],
      {
        label: {
          en: "Exchange three facts about close family members",
          es: "Intercambia tres datos sobre familiares cercanos",
          pt: "Troque tr\xEAs informa\xE7\xF5es sobre familiares pr\xF3ximos",
          it: "Scambia tre informazioni sui familiari stretti",
          fr: "\xC9change trois informations sur des proches",
          de: "Drei Angaben \xFCber enge Familienmitglieder austauschen",
          ja: "\u8FD1\u3044\u5BB6\u65CF\u306B\u3064\u3044\u30663\u3064\u306E\u60C5\u5831\u3092\u3084\u308A\u53D6\u308A\u3059\u308B",
          hi: "\u0915\u0930\u0940\u092C\u0940 \u092A\u0930\u093F\u0935\u093E\u0930 \u0915\u0947 \u0938\u0926\u0938\u094D\u092F\u094B\u0902 \u0915\u0947 \u092C\u093E\u0930\u0947 \u092E\u0947\u0902 \u0924\u0940\u0928 \u092C\u093E\u0924\u0947\u0902 \u0938\u093E\u091D\u093E \u0915\u0930\u0947\u0902",
          ar: "\u062A\u0628\u0627\u062F\u0644 \u062B\u0644\u0627\u062B \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0639\u0646 \u0623\u0641\u0631\u0627\u062F \u0627\u0644\u0623\u0633\u0631\u0629 \u0627\u0644\u0645\u0642\u0631\u0651\u0628\u064A\u0646",
          zh: "\u4EA4\u6D41\u5173\u4E8E\u8FD1\u4EB2\u7684\u4E09\u6761\u4FE1\u606F"
        },
        goal: "Exchange three facts about close family members",
        examples: ["Mi madre se llama Ana.", "Tengo dos hermanos."],
        activityBrief: "Ask and answer about a name, number of siblings, and where one family member lives",
        evidence: "The learner gives three understandable family facts and answers or asks one family question"
      }
    ),
    "lesson-a1-8-3": agenda(
      [
        "es el hermano de...",
        "es la hija de...",
        "su madre",
        "sus primos",
        "\xBFqui\xE9n es...?",
        "se llama..."
      ],
      {
        label: {
          en: "Identify three people from their family relationships",
          es: "Identifica a tres personas por sus relaciones familiares",
          pt: "Identifique tr\xEAs pessoas pelas rela\xE7\xF5es familiares",
          it: "Identifica tre persone dalle loro relazioni familiari",
          fr: "Identifie trois personnes gr\xE2ce \xE0 leurs liens familiaux",
          de: "Drei Personen anhand ihrer Familienbeziehungen erkennen",
          ja: "\u5BB6\u65CF\u95A2\u4FC2\u304B\u30893\u4EBA\u3092\u7279\u5B9A\u3059\u308B",
          hi: "\u092A\u093E\u0930\u093F\u0935\u093E\u0930\u093F\u0915 \u0938\u0902\u092C\u0902\u0927\u094B\u0902 \u0938\u0947 \u0924\u0940\u0928 \u0932\u094B\u0917\u094B\u0902 \u0915\u0940 \u092A\u0939\u091A\u093E\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u062D\u062F\u0651\u062F \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u062E\u0627\u0635 \u0645\u0646 \u062E\u0644\u0627\u0644 \u0639\u0644\u0627\u0642\u0627\u062A\u0647\u0645 \u0627\u0644\u0639\u0627\u0626\u0644\u064A\u0629",
          zh: "\u6839\u636E\u5BB6\u5EAD\u5173\u7CFB\u8BC6\u522B\u4E09\u4E2A\u4EBA"
        },
        goal: "Identify three people from a short family-tree description",
        examples: ["Luis es el hermano de Ana.", "\xBFQui\xE9n es la madre de Luis?"],
        activityBrief: "Describe a four-person family tree with three explicit relationships, then ask who each person is",
        evidence: "The learner correctly identifies three people or relationships",
        kind: "comprehension",
        evidenceType: "identify"
      }
    ),
    "lesson-a1-9-2": agenda(
      [
        "\xBFde qu\xE9 color es?",
        "es rojo / roja",
        "son rojos / rojas",
        "un c\xEDrculo azul",
        "una mesa blanca",
        "claro / oscuro"
      ],
      {
        label: {
          en: "Describe three objects using the correct color ending",
          es: "Describe tres objetos usando la terminaci\xF3n correcta del color",
          pt: "Descreva tr\xEAs objetos usando a termina\xE7\xE3o correta da cor",
          it: "Descrivi tre oggetti usando la desinenza corretta del colore",
          fr: "D\xE9cris trois objets avec la bonne terminaison de couleur",
          de: "Drei Gegenst\xE4nde mit der richtigen Farbendung beschreiben",
          ja: "\u8272\u306E\u8A9E\u5C3E\u3092\u6B63\u3057\u304F\u4F7F\u3063\u30663\u3064\u306E\u7269\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0930\u0902\u0917 \u0915\u0947 \u0938\u0939\u0940 \u0930\u0942\u092A \u0915\u093E \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0915\u0947 \u0924\u0940\u0928 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u093E \u0935\u0930\u094D\u0923\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u0635\u0650\u0641 \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u064A\u0627\u0621 \u0645\u0633\u062A\u062E\u062F\u0645\u064B\u0627 \u0627\u0644\u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u0635\u062D\u064A\u062D\u0629 \u0644\u0644\u0648\u0646",
          zh: "\u4F7F\u7528\u6B63\u786E\u7684\u989C\u8272\u8BCD\u5C3E\u63CF\u8FF0\u4E09\u4EF6\u7269\u54C1"
        },
        goal: "Describe three familiar objects with color words that agree in gender and number",
        examples: ["La mesa es blanca.", "Los libros son rojos."],
        activityBrief: "Present one masculine singular, one feminine singular, and one plural object and ask for its color",
        evidence: "The learner gives three understandable descriptions with the correct color form"
      }
    ),
    "lesson-a1-9-3": agenda(
      [
        "el libro rojo",
        "la puerta roja",
        "los libros rojos",
        "las puertas rojas",
        "\xBFde qu\xE9 color son?"
      ],
      {
        label: {
          en: "Match four color forms to singular and plural nouns",
          es: "Relaciona cuatro formas de color con sustantivos singulares y plurales",
          pt: "Associe quatro formas de cor a substantivos singulares e plurais",
          it: "Abbina quattro forme di colore a nomi singolari e plurali",
          fr: "Associe quatre formes de couleur \xE0 des noms singuliers et pluriels",
          de: "Vier Farbformen Singular- und Pluralnomen zuordnen",
          ja: "4\u3064\u306E\u8272\u306E\u5F62\u3092\u5358\u6570\u30FB\u8907\u6570\u306E\u540D\u8A5E\u306B\u5408\u308F\u305B\u308B",
          hi: "\u0930\u0902\u0917 \u0915\u0947 \u091A\u093E\u0930 \u0930\u0942\u092A\u094B\u0902 \u0915\u094B \u090F\u0915\u0935\u091A\u0928 \u0914\u0930 \u092C\u0939\u0941\u0935\u091A\u0928 \u0938\u0902\u091C\u094D\u091E\u093E\u0913\u0902 \u0938\u0947 \u092E\u093F\u0932\u093E\u090F\u0902",
          ar: "\u0637\u0627\u0628\u0642 \u0623\u0631\u0628\u0639\u0629 \u0623\u0634\u0643\u0627\u0644 \u0644\u0644\u0623\u0644\u0648\u0627\u0646 \u0645\u0639 \u0623\u0633\u0645\u0627\u0621 \u0645\u0641\u0631\u062F\u0629 \u0648\u062C\u0645\u0639",
          zh: "\u5C06\u56DB\u79CD\u989C\u8272\u5F62\u5F0F\u4E0E\u5355\u590D\u6570\u540D\u8BCD\u914D\u5BF9"
        },
        goal: "Match masculine, feminine, singular, and plural color forms to familiar nouns",
        examples: ["el libro rojo", "las puertas rojas"],
        activityBrief: "Give four noun phrases with the color ending missing and ask for the matching form one at a time",
        evidence: "The learner supplies the correct color form in at least three of four noun phrases",
        kind: "comprehension",
        evidenceType: "produce_or_choose"
      }
    ),
    "lesson-a1-10-2": agenda(
      [
        "tengo hambre",
        "tengo sed",
        "quiero...",
        "me gusta...",
        "no me gusta...",
        "para beber..."
      ],
      {
        label: {
          en: "Choose a meal and drink, then state one preference",
          es: "Elige una comida y una bebida y expresa una preferencia",
          pt: "Escolha uma refei\xE7\xE3o e uma bebida e diga uma prefer\xEAncia",
          it: "Scegli un pasto e una bevanda, poi esprimi una preferenza",
          fr: "Choisis un repas et une boisson, puis exprime une pr\xE9f\xE9rence",
          de: "Eine Mahlzeit und ein Getr\xE4nk w\xE4hlen und eine Vorliebe nennen",
          ja: "\u98DF\u4E8B\u3068\u98F2\u307F\u7269\u3092\u9078\u3073\u3001\u597D\u307F\u30921\u3064\u8FF0\u3079\u308B",
          hi: "\u090F\u0915 \u092D\u094B\u091C\u0928 \u0914\u0930 \u092A\u0947\u092F \u091A\u0941\u0928\u0947\u0902, \u092B\u093F\u0930 \u090F\u0915 \u092A\u0938\u0902\u0926 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u062E\u062A\u0631 \u0648\u062C\u0628\u0629 \u0648\u0634\u0631\u0627\u0628\u064B\u0627 \u062B\u0645 \u0627\u0630\u0643\u0631 \u062A\u0641\u0636\u064A\u0644\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627",
          zh: "\u9009\u62E9\u4E00\u4EFD\u9910\u98DF\u548C\u996E\u6599\uFF0C\u7136\u540E\u8868\u8FBE\u4E00\u4E2A\u504F\u597D"
        },
        goal: "Choose one familiar food and drink and state one preference",
        examples: ["Quiero pan y caf\xE9.", "Me gusta la fruta."],
        activityBrief: "Offer a small breakfast or lunch choice, elicit one food and drink, then ask what the learner likes",
        evidence: "The learner chooses one food and drink and gives one understandable like or dislike"
      }
    ),
    "lesson-a1-10-3": agenda(
      [
        "mi comida favorita es...",
        "me gusta...",
        "me gustan...",
        "prefiero...",
        "no como...",
        "\xBFqu\xE9 te gusta?"
      ],
      {
        label: {
          en: "Exchange two food preferences and one dislike",
          es: "Intercambia dos preferencias de comida y algo que no te gusta",
          pt: "Troque duas prefer\xEAncias alimentares e algo de que n\xE3o gosta",
          it: "Scambia due preferenze alimentari e un cibo che non piace",
          fr: "\xC9change deux pr\xE9f\xE9rences alimentaires et un aliment que tu n\u2019aimes pas",
          de: "Zwei Essensvorlieben und eine Abneigung austauschen",
          ja: "\u98DF\u3079\u7269\u306E\u597D\u307F\u30922\u3064\u3068\u82E6\u624B\u306A\u3082\u306E\u30921\u3064\u4F1D\u3048\u5408\u3046",
          hi: "\u0916\u093E\u0928\u0947 \u0915\u0940 \u0926\u094B \u092A\u0938\u0902\u0926 \u0914\u0930 \u090F\u0915 \u0928\u093E\u092A\u0938\u0902\u0926 \u0938\u093E\u091D\u093E \u0915\u0930\u0947\u0902",
          ar: "\u062A\u0628\u0627\u062F\u0644 \u062A\u0641\u0636\u064A\u0644\u064A\u0646 \u0644\u0644\u0637\u0639\u0627\u0645 \u0648\u0634\u064A\u0626\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627 \u0644\u0627 \u062A\u062D\u0628\u0647",
          zh: "\u4EA4\u6D41\u4E24\u4E2A\u98DF\u7269\u504F\u597D\u548C\u4E00\u4E2A\u4E0D\u559C\u6B22\u7684\u98DF\u7269"
        },
        goal: "Exchange two food preferences and one dislike using singular and plural forms",
        examples: ["Me gusta el pescado.", "Me gustan las frutas."],
        activityBrief: "Ask about a favorite food, a plural food category, and one disliked food, then reverse roles for one question",
        evidence: "The learner uses me gusta and me gustan appropriately and states one dislike"
      }
    ),
    "lesson-a1-11-2": agenda(
      [
        "para m\xED...",
        "quer\xEDa...",
        "me pone...",
        "\xBFqu\xE9 desea?",
        "\xBFalgo m\xE1s?",
        "la cuenta, por favor"
      ],
      {
        label: {
          en: "Order one dish and one drink, then ask for the bill",
          es: "Pide un plato y una bebida y luego solicita la cuenta",
          pt: "Pe\xE7a um prato e uma bebida e depois pe\xE7a a conta",
          it: "Ordina un piatto e una bevanda, poi chiedi il conto",
          fr: "Commande un plat et une boisson, puis demande l\u2019addition",
          de: "Ein Gericht und ein Getr\xE4nk bestellen und danach um die Rechnung bitten",
          ja: "\u6599\u7406\u3068\u98F2\u307F\u7269\u3092\u6CE8\u6587\u3057\u3001\u305D\u306E\u5F8C\u4F1A\u8A08\u3092\u983C\u3080",
          hi: "\u090F\u0915 \u0935\u094D\u092F\u0902\u091C\u0928 \u0914\u0930 \u092A\u0947\u092F \u092E\u0902\u0917\u093E\u090F\u0902, \u092B\u093F\u0930 \u092C\u093F\u0932 \u092E\u093E\u0902\u0917\u0947\u0902",
          ar: "\u0627\u0637\u0644\u0628 \u0637\u0628\u0642\u064B\u0627 \u0648\u0634\u0631\u0627\u0628\u064B\u0627 \u062B\u0645 \u0627\u0637\u0644\u0628 \u0627\u0644\u062D\u0633\u0627\u0628",
          zh: "\u70B9\u4E00\u9053\u83DC\u548C\u4E00\u676F\u996E\u6599\uFF0C\u7136\u540E\u7D22\u8981\u8D26\u5355"
        },
        goal: "Order one dish and one drink and ask for the bill politely",
        examples: ["Para m\xED, el pescado.", "La cuenta, por favor."],
        activityBrief: "Run a waiter-customer exchange with one dish, one drink, an anything-else turn, and a bill request",
        evidence: "The learner orders both items, responds to \xBFalgo m\xE1s?, and asks for the bill"
      }
    ),
    "lesson-a1-11-3": agenda(
      [
        "\xBFme trae la cuenta?",
        "creo que hay un error",
        "\xBFcu\xE1nto es?",
        "pago con tarjeta",
        "pago en efectivo",
        "el cambio",
        "gracias"
      ],
      {
        label: {
          en: "Check a bill, clarify one charge, and choose how to pay",
          es: "Revisa una cuenta, aclara un cargo y elige c\xF3mo pagar",
          pt: "Confira uma conta, esclare\xE7a uma cobran\xE7a e escolha como pagar",
          it: "Controlla il conto, chiarisci un addebito e scegli come pagare",
          fr: "V\xE9rifie l\u2019addition, clarifie un montant et choisis comment payer",
          de: "Eine Rechnung pr\xFCfen, einen Posten kl\xE4ren und die Zahlungsart w\xE4hlen",
          ja: "\u4F1A\u8A08\u3092\u78BA\u8A8D\u3057\u30011\u3064\u306E\u6599\u91D1\u306B\u3064\u3044\u3066\u5C0B\u306D\u3001\u652F\u6255\u3044\u65B9\u6CD5\u3092\u9078\u3076",
          hi: "\u092C\u093F\u0932 \u091C\u093E\u0902\u091A\u0947\u0902, \u090F\u0915 \u0936\u0941\u0932\u094D\u0915 \u0938\u094D\u092A\u0937\u094D\u091F \u0915\u0930\u0947\u0902 \u0914\u0930 \u092D\u0941\u0917\u0924\u093E\u0928 \u0915\u093E \u0924\u0930\u0940\u0915\u093E \u091A\u0941\u0928\u0947\u0902",
          ar: "\u0631\u0627\u062C\u0639 \u0627\u0644\u062D\u0633\u0627\u0628 \u0648\u0627\u0633\u062A\u0648\u0636\u062D \u0631\u0633\u0645\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627 \u0648\u0627\u062E\u062A\u0631 \u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639",
          zh: "\u6838\u5BF9\u8D26\u5355\u3001\u6F84\u6E05\u4E00\u9879\u6536\u8D39\u5E76\u9009\u62E9\u4ED8\u6B3E\u65B9\u5F0F"
        },
        goal: "Check a simple bill, clarify one charge, and choose how to pay",
        examples: ["Creo que hay un error.", "Pago con tarjeta."],
        activityBrief: "Present a three-item bill with one unexpected charge, answer one clarification, and ask for card or cash",
        evidence: "The learner identifies or questions the unexpected charge and states a payment method"
      }
    ),
    "lesson-a1-12-2": agenda(
      [
        "\xBFqu\xE9 es esto?",
        "esto es...",
        "\xBFd\xF3nde est\xE1...?",
        "est\xE1 en...",
        "hay...",
        "no hay..."
      ],
      {
        label: {
          en: "Identify and locate three classroom objects",
          es: "Identifica y ubica tres objetos del aula",
          pt: "Identifique e localize tr\xEAs objetos da sala de aula",
          it: "Identifica e localizza tre oggetti dell\u2019aula",
          fr: "Identifie et situe trois objets de la classe",
          de: "Drei Gegenst\xE4nde im Klassenzimmer erkennen und lokalisieren",
          ja: "\u6559\u5BA4\u306E\u7269\u30923\u3064\u7279\u5B9A\u3057\u3001\u5834\u6240\u3092\u8A00\u3046",
          hi: "\u0915\u0915\u094D\u0937\u093E \u0915\u0940 \u0924\u0940\u0928 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u0909\u0928\u0915\u093E \u0938\u094D\u0925\u093E\u0928 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u062D\u062F\u0651\u062F \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u064A\u0627\u0621 \u0641\u064A \u0627\u0644\u0641\u0635\u0644 \u0648\u0627\u0630\u0643\u0631 \u0623\u0645\u0627\u0643\u0646\u0647\u0627",
          zh: "\u8BC6\u522B\u5E76\u6307\u51FA\u4E09\u4EF6\u6559\u5BA4\u7269\u54C1\u7684\u4F4D\u7F6E"
        },
        goal: "Identify and locate three familiar classroom objects",
        examples: ["Esto es un cuaderno.", "El l\xE1piz est\xE1 en la mochila."],
        activityBrief: "Present three classroom objects, ask what each is, then ask where two of them are",
        evidence: "The learner names three objects and gives two understandable locations"
      }
    ),
    "lesson-a1-12-3": agenda(
      ["este", "esta", "ese", "esa", "aqu\xED", "all\xED", "\xBFqu\xE9 es eso?"],
      {
        label: {
          en: "Distinguish and name two nearby and two distant objects",
          es: "Distingue y nombra dos objetos cercanos y dos lejanos",
          pt: "Diferencie e nomeie dois objetos pr\xF3ximos e dois distantes",
          it: "Distingui e nomina due oggetti vicini e due lontani",
          fr: "Distingue et nomme deux objets proches et deux \xE9loign\xE9s",
          de: "Zwei nahe und zwei entfernte Gegenst\xE4nde unterscheiden und benennen",
          ja: "\u8FD1\u304F\u306E\u72692\u3064\u3068\u9060\u304F\u306E\u72692\u3064\u3092\u533A\u5225\u3057\u3066\u540D\u524D\u3092\u8A00\u3046",
          hi: "\u092A\u093E\u0938 \u0915\u0940 \u0926\u094B \u0914\u0930 \u0926\u0942\u0930 \u0915\u0940 \u0926\u094B \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u094B \u0905\u0932\u0917 \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u0928\u093E\u092E \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0645\u064A\u0651\u0632 \u0648\u0633\u0645\u0651\u0650 \u0634\u064A\u0626\u064A\u0646 \u0642\u0631\u064A\u0628\u064A\u0646 \u0648\u0634\u064A\u0626\u064A\u0646 \u0628\u0639\u064A\u062F\u064A\u0646",
          zh: "\u533A\u5206\u5E76\u8BF4\u51FA\u4E24\u4E2A\u8FD1\u5904\u548C\u4E24\u4E2A\u8FDC\u5904\u7684\u7269\u54C1"
        },
        goal: "Distinguish and name two nearby and two distant classroom objects",
        examples: ["Este libro est\xE1 aqu\xED.", "Esa mochila est\xE1 all\xED."],
        activityBrief: "Contrast masculine and feminine classroom objects in near and far positions, one object at a time",
        evidence: "The learner chooses an appropriate demonstrative for at least three of four objects"
      }
    ),
    "lesson-a1-13-2": agenda(
      [
        "\xBFd\xF3nde est\xE1...?",
        "est\xE1 en...",
        "encima de",
        "debajo de",
        "al lado de",
        "entre"
      ],
      {
        label: {
          en: "Ask for and give the location of three household objects",
          es: "Pregunta y da la ubicaci\xF3n de tres objetos de la casa",
          pt: "Pergunte e diga a localiza\xE7\xE3o de tr\xEAs objetos da casa",
          it: "Chiedi e indica la posizione di tre oggetti di casa",
          fr: "Demande et indique l\u2019emplacement de trois objets de la maison",
          de: "Nach dem Ort von drei Haushaltsgegenst\xE4nden fragen und ihn angeben",
          ja: "\u5BB6\u306E\u72693\u3064\u306E\u5834\u6240\u3092\u5C0B\u306D\u3066\u7B54\u3048\u308B",
          hi: "\u0918\u0930 \u0915\u0940 \u0924\u0940\u0928 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u093E \u0938\u094D\u0925\u093E\u0928 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0645\u0643\u0627\u0646 \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u064A\u0627\u0621 \u0641\u064A \u0627\u0644\u0645\u0646\u0632\u0644 \u0648\u0627\u0630\u0643\u0631\u0647",
          zh: "\u8BE2\u95EE\u5E76\u8BF4\u660E\u4E09\u4EF6\u5BB6\u5C45\u7269\u54C1\u7684\u4F4D\u7F6E"
        },
        goal: "Ask for and give the location of three household objects",
        examples: ["\xBFD\xF3nde est\xE1 la llave?", "Est\xE1 encima de la mesa."],
        activityBrief: "Place three familiar objects in different rooms or positions and alternate asking and answering where they are",
        evidence: "The learner asks one location question and gives three correct location phrases"
      }
    ),
    "lesson-a1-13-3": agenda(
      [
        "en la cocina hay...",
        "la cama est\xE1...",
        "a la derecha de",
        "a la izquierda de",
        "delante de",
        "detr\xE1s de"
      ],
      {
        label: {
          en: "Describe two rooms and the location of their furniture",
          es: "Describe dos habitaciones y la ubicaci\xF3n de sus muebles",
          pt: "Descreva dois c\xF4modos e a localiza\xE7\xE3o dos m\xF3veis",
          it: "Descrivi due stanze e la posizione dei mobili",
          fr: "D\xE9cris deux pi\xE8ces et l\u2019emplacement de leurs meubles",
          de: "Zwei R\xE4ume und die Position ihrer M\xF6bel beschreiben",
          ja: "2\u3064\u306E\u90E8\u5C4B\u3068\u5BB6\u5177\u306E\u4F4D\u7F6E\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0926\u094B \u0915\u092E\u0930\u094B\u0902 \u0914\u0930 \u0909\u0928\u0915\u0947 \u092B\u0930\u094D\u0928\u0940\u091A\u0930 \u0915\u0947 \u0938\u094D\u0925\u093E\u0928 \u0915\u093E \u0935\u0930\u094D\u0923\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u0635\u0650\u0641 \u063A\u0631\u0641\u062A\u064A\u0646 \u0648\u0645\u0648\u0627\u0642\u0639 \u0627\u0644\u0623\u062B\u0627\u062B \u0641\u064A\u0647\u0645\u0627",
          zh: "\u63CF\u8FF0\u4E24\u4E2A\u623F\u95F4\u53CA\u5176\u4E2D\u5BB6\u5177\u7684\u4F4D\u7F6E"
        },
        goal: "Describe two rooms and locate at least one piece of furniture in each",
        examples: ["En la cocina hay una mesa.", "El sof\xE1 est\xE1 delante de la ventana."],
        activityBrief: "Build a tiny two-room floor plan and ask for one room item and one relative furniture position in each room",
        evidence: "The learner names both rooms and gives two understandable furniture locations"
      }
    ),
    "lesson-a1-14-2": agenda(
      [
        "busco...",
        "quiero probarme...",
        "\xBFtiene esta...?",
        "\xBFqu\xE9 talla?",
        "me queda bien",
        "me queda mal",
        "\xBFcu\xE1nto cuesta?"
      ],
      {
        label: {
          en: "Ask for one clothing item by color and size",
          es: "Pide una prenda por color y talla",
          pt: "Pe\xE7a uma pe\xE7a de roupa por cor e tamanho",
          it: "Chiedi un capo indicando colore e taglia",
          fr: "Demande un v\xEAtement en pr\xE9cisant la couleur et la taille",
          de: "Nach einem Kleidungsst\xFCck in einer bestimmten Farbe und Gr\xF6\xDFe fragen",
          ja: "\u8272\u3068\u30B5\u30A4\u30BA\u3092\u6307\u5B9A\u3057\u3066\u670D\u30921\u7740\u983C\u3080",
          hi: "\u0930\u0902\u0917 \u0914\u0930 \u0906\u0915\u093E\u0930 \u0915\u0947 \u0905\u0928\u0941\u0938\u093E\u0930 \u090F\u0915 \u0915\u092A\u0921\u093C\u093E \u092E\u093E\u0902\u0917\u0947\u0902",
          ar: "\u0627\u0637\u0644\u0628 \u0642\u0637\u0639\u0629 \u0645\u0644\u0627\u0628\u0633 \u0628\u0644\u0648\u0646 \u0648\u0645\u0642\u0627\u0633 \u0645\u062D\u062F\u062F\u064A\u0646",
          zh: "\u6309\u989C\u8272\u548C\u5C3A\u7801\u8BE2\u95EE\u4E00\u4EF6\u8863\u7269"
        },
        goal: "Ask for, try on, and evaluate one clothing item by color and size",
        examples: ["Busco una chaqueta azul.", "Me queda bien."],
        activityBrief: "Run a shop exchange requiring an item, color, size, try-on response, and price question",
        evidence: "The learner requests a specific item, answers the fit question, and asks the price"
      }
    ),
    "lesson-a1-14-3": agenda(
      [
        "llevo...",
        "me pongo...",
        "combina con...",
        "para el fr\xEDo...",
        "para trabajar...",
        "mi ropa favorita..."
      ],
      {
        label: {
          en: "Choose and describe outfits for two situations",
          es: "Elige y describe ropa para dos situaciones",
          pt: "Escolha e descreva roupas para duas situa\xE7\xF5es",
          it: "Scegli e descrivi abiti per due situazioni",
          fr: "Choisis et d\xE9cris des tenues pour deux situations",
          de: "Kleidung f\xFCr zwei Situationen ausw\xE4hlen und beschreiben",
          ja: "2\u3064\u306E\u5834\u9762\u306B\u5408\u3046\u670D\u88C5\u3092\u9078\u3093\u3067\u8AAC\u660E\u3059\u308B",
          hi: "\u0926\u094B \u092A\u0930\u093F\u0938\u094D\u0925\u093F\u0924\u093F\u092F\u094B\u0902 \u0915\u0947 \u0932\u093F\u090F \u0915\u092A\u0921\u093C\u0947 \u091A\u0941\u0928\u0947\u0902 \u0914\u0930 \u0909\u0928\u0915\u093E \u0935\u0930\u094D\u0923\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u0627\u062E\u062A\u0631 \u0648\u0635\u0650\u0641 \u0645\u0644\u0627\u0628\u0633 \u0644\u0645\u0648\u0642\u0641\u064A\u0646",
          zh: "\u4E3A\u4E24\u4E2A\u573A\u666F\u9009\u62E9\u5E76\u63CF\u8FF0\u670D\u88C5"
        },
        goal: "Choose and describe an appropriate outfit for two simple situations",
        examples: ["Para el fr\xEDo, me pongo un abrigo.", "Llevo una camisa azul para trabajar."],
        activityBrief: "Give one weather context and one everyday event, asking what the learner wears and one color detail",
        evidence: "The learner chooses suitable clothing and describes one item in each situation"
      }
    ),
    "lesson-a1-15-2": agenda(
      [
        "me levanto",
        "me ducho",
        "me visto",
        "desayuno",
        "voy a...",
        "a las..."
      ],
      {
        label: {
          en: "Describe a four-step morning routine with a time",
          es: "Describe una rutina matutina de cuatro pasos con una hora",
          pt: "Descreva uma rotina matinal de quatro etapas com um hor\xE1rio",
          it: "Descrivi una routine mattutina di quattro fasi con un orario",
          fr: "D\xE9cris une routine du matin en quatre \xE9tapes avec une heure",
          de: "Eine Morgenroutine mit vier Schritten und einer Uhrzeit beschreiben",
          ja: "\u6642\u523B\u3092\u5165\u308C\u30664\u6BB5\u968E\u306E\u671D\u306E\u7FD2\u6163\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0938\u092E\u092F \u0915\u0947 \u0938\u093E\u0925 \u0938\u0941\u092C\u0939 \u0915\u0940 \u091A\u093E\u0930 \u091A\u0930\u0923\u094B\u0902 \u0935\u093E\u0932\u0940 \u0926\u093F\u0928\u091A\u0930\u094D\u092F\u093E \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0635\u0650\u0641 \u0631\u0648\u062A\u064A\u0646\u064B\u0627 \u0635\u0628\u0627\u062D\u064A\u064B\u0627 \u0645\u0646 \u0623\u0631\u0628\u0639 \u062E\u0637\u0648\u0627\u062A \u0645\u0639 \u0630\u0643\u0631 \u0648\u0642\u062A",
          zh: "\u63CF\u8FF0\u5305\u542B\u65F6\u95F4\u7684\u56DB\u6B65\u6668\u95F4\u65E5\u5E38"
        },
        goal: "Describe a four-step morning routine and include at least one time",
        examples: ["Me levanto a las siete.", "Despu\xE9s, me ducho."],
        activityBrief: "Prompt the learner through waking, washing, dressing, eating, and leaving, then ask for one time",
        evidence: "The learner produces four ordered morning actions and one understandable time"
      }
    ),
    "lesson-a1-15-3": agenda(
      [
        "por la ma\xF1ana",
        "luego",
        "despu\xE9s",
        "por la tarde",
        "por la noche",
        "antes de dormir"
      ],
      {
        label: {
          en: "Put five daily events in order from morning to night",
          es: "Ordena cinco actividades diarias de la ma\xF1ana a la noche",
          pt: "Coloque cinco atividades di\xE1rias em ordem da manh\xE3 \xE0 noite",
          it: "Metti in ordine cinque attivit\xE0 quotidiane dalla mattina alla sera",
          fr: "Mets cinq activit\xE9s quotidiennes dans l\u2019ordre du matin au soir",
          de: "F\xFCnf t\xE4gliche Ereignisse vom Morgen bis zum Abend ordnen",
          ja: "\u671D\u304B\u3089\u591C\u307E\u3067\u306E5\u3064\u306E\u65E5\u8AB2\u3092\u9806\u756A\u306B\u4E26\u3079\u308B",
          hi: "\u0938\u0941\u092C\u0939 \u0938\u0947 \u0930\u093E\u0924 \u0924\u0915 \u0915\u0940 \u092A\u093E\u0902\u091A \u0926\u0948\u0928\u093F\u0915 \u0917\u0924\u093F\u0935\u093F\u0927\u093F\u092F\u094B\u0902 \u0915\u094B \u0915\u094D\u0930\u092E \u092E\u0947\u0902 \u0930\u0916\u0947\u0902",
          ar: "\u0631\u062A\u0651\u0628 \u062E\u0645\u0633\u0629 \u0623\u0646\u0634\u0637\u0629 \u064A\u0648\u0645\u064A\u0629 \u0645\u0646 \u0627\u0644\u0635\u0628\u0627\u062D \u0625\u0644\u0649 \u0627\u0644\u0644\u064A\u0644",
          zh: "\u6309\u4ECE\u65E9\u5230\u665A\u7684\u987A\u5E8F\u6392\u5217\u4E94\u9879\u65E5\u5E38\u6D3B\u52A8"
        },
        goal: "Sequence five daily events from morning to night using time-of-day connectors",
        examples: ["Por la ma\xF1ana desayuno.", "Despu\xE9s trabajo.", "Por la noche ceno."],
        activityBrief: "Give five familiar routine actions out of order and ask the learner to rebuild the day with connectors",
        evidence: "The learner places all five events in a logical order and uses at least three time connectors",
        kind: "comprehension",
        evidenceType: "sequence_and_produce"
      }
    ),
    "lesson-a1-16-2": agenda(
      [
        "en primavera...",
        "en verano...",
        "en oto\xF1o...",
        "en invierno...",
        "hace...",
        "est\xE1..."
      ],
      {
        label: {
          en: "Compare the weather in two seasons",
          es: "Compara el tiempo en dos estaciones",
          pt: "Compare o tempo em duas esta\xE7\xF5es",
          it: "Confronta il tempo in due stagioni",
          fr: "Compare le temps pendant deux saisons",
          de: "Das Wetter in zwei Jahreszeiten vergleichen",
          ja: "2\u3064\u306E\u5B63\u7BC0\u306E\u5929\u6C17\u3092\u6BD4\u3079\u308B",
          hi: "\u0926\u094B \u090B\u0924\u0941\u0913\u0902 \u0915\u0947 \u092E\u094C\u0938\u092E \u0915\u0940 \u0924\u0941\u0932\u0928\u093E \u0915\u0930\u0947\u0902",
          ar: "\u0642\u0627\u0631\u0646 \u0627\u0644\u0637\u0642\u0633 \u0641\u064A \u0641\u0635\u0644\u064A\u0646",
          zh: "\u6BD4\u8F83\u4E24\u4E2A\u5B63\u8282\u7684\u5929\u6C14"
        },
        goal: "Describe and compare the weather in two different seasons",
        examples: ["En verano hace calor.", "En invierno hace fr\xEDo."],
        activityBrief: "Choose two contrasting seasons and ask for one weather expression in each plus one preferred season",
        evidence: "The learner gives an appropriate weather description for both seasons and states a preference"
      }
    ),
    "lesson-a1-16-3": agenda(
      [
        "\xBFqu\xE9 tiempo hace en...?",
        "en ... hace...",
        "hoy",
        "ma\xF1ana",
        "la temperatura",
        "... grados"
      ],
      {
        label: {
          en: "Compare two city forecasts and choose a destination",
          es: "Compara el pron\xF3stico de dos ciudades y elige un destino",
          pt: "Compare a previs\xE3o de duas cidades e escolha um destino",
          it: "Confronta le previsioni di due citt\xE0 e scegli una destinazione",
          fr: "Compare les pr\xE9visions de deux villes et choisis une destination",
          de: "Die Vorhersagen f\xFCr zwei St\xE4dte vergleichen und ein Reiseziel w\xE4hlen",
          ja: "2\u90FD\u5E02\u306E\u5929\u6C17\u4E88\u5831\u3092\u6BD4\u3079\u3001\u884C\u304D\u5148\u3092\u9078\u3076",
          hi: "\u0926\u094B \u0936\u0939\u0930\u094B\u0902 \u0915\u0947 \u092E\u094C\u0938\u092E \u092A\u0942\u0930\u094D\u0935\u093E\u0928\u0941\u092E\u093E\u0928 \u0915\u0940 \u0924\u0941\u0932\u0928\u093E \u0915\u0930\u0947\u0902 \u0914\u0930 \u090F\u0915 \u0917\u0902\u0924\u0935\u094D\u092F \u091A\u0941\u0928\u0947\u0902",
          ar: "\u0642\u0627\u0631\u0646 \u062A\u0648\u0642\u0639\u0627\u062A \u0627\u0644\u0637\u0642\u0633 \u0644\u0645\u062F\u064A\u0646\u062A\u064A\u0646 \u0648\u0627\u062E\u062A\u0631 \u0648\u062C\u0647\u0629",
          zh: "\u6BD4\u8F83\u4E24\u4E2A\u57CE\u5E02\u7684\u5929\u6C14\u9884\u62A5\u5E76\u9009\u62E9\u76EE\u7684\u5730"
        },
        goal: "Compare today's or tomorrow's weather in two cities and choose one destination",
        examples: ["En Madrid hace sol y hay veinte grados.", "Prefiero Madrid."],
        activityBrief: "Present two one-day city forecasts with different conditions and temperatures, then ask which city the learner chooses",
        evidence: "The learner identifies one condition in each city and gives an understandable choice",
        kind: "comprehension",
        evidenceType: "compare_and_choose"
      }
    ),
    "lesson-a1-17-2": agenda(
      [
        "\xBFte gusta...?",
        "me gusta...",
        "me gustan...",
        "me encanta...",
        "a m\xED tambi\xE9n",
        "a m\xED tampoco"
      ],
      {
        label: {
          en: "Exchange three preferences and respond with tambi\xE9n or tampoco",
          es: "Intercambia tres preferencias y responde con tambi\xE9n o tampoco",
          pt: "Troque tr\xEAs prefer\xEAncias e responda com tambi\xE9n ou tampoco",
          it: "Scambia tre preferenze e rispondi con tambi\xE9n o tampoco",
          fr: "\xC9change trois pr\xE9f\xE9rences et r\xE9ponds avec tambi\xE9n ou tampoco",
          de: "Drei Vorlieben austauschen und mit tambi\xE9n oder tampoco reagieren",
          ja: "\u597D\u307F\u30923\u3064\u4F1D\u3048\u5408\u3044\u3001tambi\xE9n \u307E\u305F\u306F tampoco \u3067\u53CD\u5FDC\u3059\u308B",
          hi: "\u0924\u0940\u0928 \u092A\u0938\u0902\u0926 \u0938\u093E\u091D\u093E \u0915\u0930\u0947\u0902 \u0914\u0930 tambi\xE9n \u092F\u093E tampoco \u0938\u0947 \u091C\u0935\u093E\u092C \u0926\u0947\u0902",
          ar: "\u062A\u0628\u0627\u062F\u0644 \u062B\u0644\u0627\u062B\u0629 \u062A\u0641\u0636\u064A\u0644\u0627\u062A \u0648\u0631\u062F\u0651 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 tambi\xE9n \u0623\u0648 tampoco",
          zh: "\u4EA4\u6D41\u4E09\u4E2A\u504F\u597D\uFF0C\u5E76\u7528 tambi\xE9n \u6216 tampoco \u56DE\u5E94"
        },
        goal: "Exchange three likes or dislikes and react with tambi\xE9n or tampoco",
        examples: ["Me gusta leer. \u2014 A m\xED tambi\xE9n.", "No me gusta correr. \u2014 A m\xED tampoco."],
        activityBrief: "Ask about three familiar activities or things, requiring one agreement with tambi\xE9n and one with tampoco",
        evidence: "The learner states three preferences and uses tambi\xE9n and tampoco in matching contexts"
      }
    ),
    "lesson-a1-17-3": agenda(
      [
        "mi ... favorito / favorita es...",
        "prefiero...",
        "odio...",
        "me gusta + infinitivo",
        "me gustan + plural",
        "porque..."
      ],
      {
        label: {
          en: "Explain two favorites and one dislike",
          es: "Explica dos cosas favoritas y algo que no te gusta",
          pt: "Explique duas coisas favoritas e algo de que n\xE3o gosta",
          it: "Spiega due cose preferite e una cosa che non piace",
          fr: "Explique deux choses pr\xE9f\xE9r\xE9es et une chose que tu n\u2019aimes pas",
          de: "Zwei Favoriten und eine Abneigung erkl\xE4ren",
          ja: "\u597D\u304D\u306A\u3082\u306E2\u3064\u3068\u5ACC\u3044\u306A\u3082\u306E1\u3064\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0926\u094B \u092A\u0938\u0902\u0926\u0940\u0926\u093E \u091A\u0940\u091C\u093C\u0947\u0902 \u0914\u0930 \u090F\u0915 \u0928\u093E\u092A\u0938\u0902\u0926 \u0938\u092E\u091D\u093E\u090F\u0902",
          ar: "\u0627\u0634\u0631\u062D \u0634\u064A\u0626\u064A\u0646 \u0645\u0641\u0636\u0644\u064A\u0646 \u0648\u0634\u064A\u0626\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627 \u0644\u0627 \u062A\u062D\u0628\u0647",
          zh: "\u8BF4\u660E\u4E24\u4E2A\u6700\u559C\u6B22\u7684\u4E8B\u7269\u548C\u4E00\u4E2A\u4E0D\u559C\u6B22\u7684\u4E8B\u7269"
        },
        goal: "Explain two favorites and one dislike using a noun, a plural, or an infinitive",
        examples: ["Mi comida favorita es la pizza.", "Me gusta bailar porque es divertido."],
        activityBrief: "Ask for a favorite food or object, a favorite activity, and one dislike, prompting a short porque reason once",
        evidence: "The learner states all three preferences and gives one understandable reason"
      }
    ),
    "lesson-a1-18-2": agenda(
      [
        "\xBFqu\xE9...?",
        "\xBFqui\xE9n...?",
        "\xBFd\xF3nde...?",
        "\xBFcu\xE1ndo...?",
        "\xBFc\xF3mo...?",
        "\xBFpor qu\xE9...?",
        "\xBFcu\xE1nto...?"
      ],
      {
        label: {
          en: "Ask five different information questions in a short interview",
          es: "Haz cinco preguntas de informaci\xF3n distintas en una entrevista breve",
          pt: "Fa\xE7a cinco perguntas de informa\xE7\xE3o diferentes em uma entrevista curta",
          it: "Fai cinque domande informative diverse in una breve intervista",
          fr: "Pose cinq questions d\u2019information diff\xE9rentes dans un court entretien",
          de: "In einem kurzen Interview f\xFCnf verschiedene Informationsfragen stellen",
          ja: "\u77ED\u3044\u30A4\u30F3\u30BF\u30D3\u30E5\u30FC\u3067\u7570\u306A\u308B\u60C5\u5831\u8CEA\u554F\u30925\u3064\u3059\u308B",
          hi: "\u091B\u094B\u091F\u0947 \u0938\u093E\u0915\u094D\u0937\u093E\u0924\u094D\u0915\u093E\u0930 \u092E\u0947\u0902 \u092A\u093E\u0902\u091A \u0905\u0932\u0917-\u0905\u0932\u0917 \u091C\u093E\u0928\u0915\u093E\u0930\u0940 \u0935\u093E\u0932\u0947 \u092A\u094D\u0930\u0936\u094D\u0928 \u092A\u0942\u091B\u0947\u0902",
          ar: "\u0627\u0637\u0631\u062D \u062E\u0645\u0633\u0629 \u0623\u0633\u0626\u0644\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0645\u062E\u062A\u0644\u0641\u0629 \u0641\u064A \u0645\u0642\u0627\u0628\u0644\u0629 \u0642\u0635\u064A\u0631\u0629",
          zh: "\u5728\u7B80\u77ED\u91C7\u8BBF\u4E2D\u63D0\u51FA\u4E94\u4E2A\u4E0D\u540C\u7684\u4FE1\u606F\u95EE\u9898"
        },
        goal: "Ask five different information questions in a short interview",
        examples: ["\xBFD\xF3nde vives?", "\xBFCu\xE1ndo trabajas?", "\xBFPor qu\xE9 estudias espa\xF1ol?"],
        activityBrief: "Run a five-question interview, requiring a different question word each time and answering each in one short sentence",
        evidence: "The learner forms five understandable questions with five different question words"
      }
    ),
    "lesson-a1-18-3": agenda(
      [
        "\xBFc\xF3mo te llamas?",
        "\xBFde d\xF3nde eres?",
        "\xBFd\xF3nde vives?",
        "\xBFqu\xE9 te gusta?",
        "\xBFcu\xE1ndo...?",
        "\xBFpor qu\xE9...?"
      ],
      {
        label: {
          en: "Complete a five-question personal-information exchange",
          es: "Completa un intercambio de cinco preguntas de informaci\xF3n personal",
          pt: "Complete uma troca de cinco perguntas de informa\xE7\xE3o pessoal",
          it: "Completa uno scambio di cinque domande personali",
          fr: "Compl\xE8te un \xE9change de cinq questions personnelles",
          de: "Einen Austausch mit f\xFCnf Fragen zu pers\xF6nlichen Angaben abschlie\xDFen",
          ja: "\u500B\u4EBA\u60C5\u5831\u306B\u3064\u3044\u30665\u3064\u8CEA\u554F\u3059\u308B\u3084\u308A\u53D6\u308A\u3092\u5B8C\u6210\u3055\u305B\u308B",
          hi: "\u0935\u094D\u092F\u0915\u094D\u0924\u093F\u0917\u0924 \u091C\u093E\u0928\u0915\u093E\u0930\u0940 \u0915\u0947 \u092A\u093E\u0902\u091A \u092A\u094D\u0930\u0936\u094D\u0928\u094B\u0902 \u0935\u093E\u0932\u093E \u0938\u0902\u0935\u093E\u0926 \u092A\u0942\u0930\u093E \u0915\u0930\u0947\u0902",
          ar: "\u0623\u0643\u0645\u0644 \u062D\u0648\u0627\u0631\u064B\u0627 \u0645\u0646 \u062E\u0645\u0633\u0629 \u0623\u0633\u0626\u0644\u0629 \u0639\u0646 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0634\u062E\u0635\u064A\u0629",
          zh: "\u5B8C\u6210\u5305\u542B\u4E94\u4E2A\u4E2A\u4EBA\u4FE1\u606F\u95EE\u9898\u7684\u4EA4\u6D41"
        },
        goal: "Complete a five-question exchange about name, origin, home, preferences, and routine",
        examples: ["\xBFDe d\xF3nde eres? \u2014 Soy de M\xE9xico.", "\xBFQu\xE9 te gusta? \u2014 Me gusta la m\xFAsica."],
        activityBrief: "Conduct a five-question personal-information exchange with one short answer per question, then switch roles for the final question",
        evidence: "The learner asks or answers five relevant personal-information questions understandably"
      }
    )
  });

  // ../nosabos/nosabos/src/data/manualB1B2Agendas.js
  var FORM_LABEL_PREFIXES2 = Object.freeze({
    en: "Use in context",
    es: "Usa en contexto",
    pt: "Use em contexto",
    it: "Usa nel contesto",
    fr: "Utilise en contexte",
    de: "Im Kontext verwenden",
    ja: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528"
  });
  var APPLICATION_LABEL_PREFIXES = Object.freeze({
    B1: {
      en: "Complete the connected task",
      es: "Completa la tarea conectada",
      pt: "Complete a tarefa conectada",
      it: "Completa il compito articolato",
      fr: "R\xE9alise la t\xE2che en plusieurs \xE9tapes",
      de: "Die zusammenh\xE4ngende Aufgabe abschlie\xDFen",
      ja: "\u3064\u306A\u304C\u308A\u306E\u3042\u308B\u8AB2\u984C\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u091C\u0941\u0921\u093C\u093E \u0939\u0941\u0906 \u0915\u093E\u0930\u094D\u092F \u092A\u0942\u0930\u093E \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u0627\u0644\u0645\u0647\u0645\u0629 \u0627\u0644\u0645\u062A\u0631\u0627\u0628\u0637\u0629",
      zh: "\u5B8C\u6210\u8FDE\u8D2F\u4EFB\u52A1"
    },
    B2: {
      en: "Develop and support the response",
      es: "Desarrolla y fundamenta la respuesta",
      pt: "Desenvolva e fundamente a resposta",
      it: "Sviluppa e sostieni la risposta",
      fr: "D\xE9veloppe et justifie la r\xE9ponse",
      de: "Die Antwort entwickeln und begr\xFCnden",
      ja: "\u56DE\u7B54\u3092\u5C55\u958B\u3057\u3001\u6839\u62E0\u3092\u793A\u3059",
      hi: "\u0909\u0924\u094D\u0924\u0930 \u0915\u094B \u0935\u093F\u0915\u0938\u093F\u0924 \u0915\u0930\u0947\u0902 \u0914\u0930 \u0909\u0938\u0915\u093E \u0938\u092E\u0930\u094D\u0925\u0928 \u0915\u0930\u0947\u0902",
      ar: "\u0637\u0648\u0651\u0631 \u0627\u0644\u0625\u062C\u0627\u0628\u0629 \u0648\u0627\u062F\u0639\u0645\u0647\u0627",
      zh: "\u5C55\u5F00\u5E76\u8BBA\u8BC1\u56DE\u7B54"
    }
  });
  var agenda2 = (level, forms, display, goal, examples, activityBrief, evidence, options = {}) => ({
    forms,
    application: {
      level,
      display,
      goal,
      examples,
      activityBrief,
      evidence,
      ...options
    }
  });
  var B1_B2_FOUNDATION_FORMS = Object.freeze({
    "lesson-b1-1-1": [
      "he / has / ha + participio",
      "hemos / han + participio",
      "hecho / dicho",
      "visto / escrito",
      "ya",
      "todav\xEDa no",
      "alguna vez",
      "nunca"
    ],
    "lesson-b1-2-1": [
      "estaba hablando",
      "estabas comiendo",
      "gerundio en -ando",
      "gerundio en -iendo",
      "leyendo",
      "durmiendo",
      "pidiendo",
      "estaba... cuando..."
    ],
    "lesson-b1-3-1": [
      "hablar\xE9 / comer\xE1s / vivir\xE1",
      "tendr\xE9",
      "har\xE9",
      "podr\xE9",
      "saldr\xE9",
      "ma\xF1ana",
      "el a\xF1o que viene",
      "pronto"
    ],
    "lesson-b1-4-1": [
      "m\xE1s / menos... que",
      "tan... como",
      "tanto... como",
      "el / la m\xE1s... de",
      "mejor / peor",
      "mayor / menor",
      "-\xEDsimo / -\xEDsima",
      "ambos / ambas"
    ],
    "lesson-b1-5-1": [
      "deber\xEDas",
      "tendr\xEDas que",
      "podr\xEDas",
      "te recomiendo que",
      "te aconsejo que",
      "lo mejor es que",
      "\xBFpor qu\xE9 no...?",
      "si yo fuera t\xFA..."
    ],
    "lesson-b1-6-1": [
      "\xBFpor qu\xE9 no...?",
      "\xBFqu\xE9 tal si...?",
      "podr\xEDamos",
      "deber\xEDamos",
      "\xBFte parece si...?",
      "vamos a...",
      "hay que...",
      "otra idea ser\xEDa..."
    ],
    "lesson-b1-7-1": [
      "hablar\xEDa / comer\xEDas / vivir\xEDa",
      "tendr\xEDa",
      "har\xEDa",
      "podr\xEDa",
      "me gustar\xEDa",
      "\xBFpodr\xEDas...?",
      "si fuera...",
      "en tu lugar..."
    ],
    "lesson-b1-8-1": [
      "el vuelo",
      "la maleta",
      "el pasaporte",
      "el alojamiento",
      "la reserva",
      "el billete / boleto",
      "la aduana",
      "el embarque"
    ],
    "lesson-b1-9-1": [
      "el medio ambiente",
      "el cambio clim\xE1tico",
      "el reciclaje",
      "la contaminaci\xF3n",
      "los residuos",
      "la energ\xEDa renovable",
      "sostenible",
      "se deber\xEDa..."
    ],
    "lesson-b1-10-1": [
      "la tradici\xF3n",
      "la costumbre",
      "la fiesta / el festival",
      "el desfile",
      "la gastronom\xEDa",
      "celebrar / festejar",
      "disfrazarse",
      "solemos celebrar..."
    ],
    "lesson-b1-11-1": [
      "las noticias",
      "el titular",
      "el reportaje",
      "el peri\xF3dico",
      "la entrevista",
      "la fuente",
      "las redes sociales",
      "seg\xFAn..."
    ],
    "lesson-b1-12-1": [
      "creo que",
      "pienso que",
      "me parece que",
      "en mi opini\xF3n",
      "desde mi punto de vista",
      "estoy de acuerdo",
      "estoy en contra",
      "no creo que"
    ],
    "lesson-b1-13-1": [
      "la queja / el reclamo",
      "el reembolso",
      "no funciona",
      "est\xE1 roto",
      "defectuoso",
      "devolver / cambiar",
      "me gustar\xEDa...",
      "\xBFser\xEDa posible...?"
    ],
    "lesson-b1-14-1": [
      "alguna vez",
      "nunca",
      "una vez",
      "hace... a\xF1os",
      "he probado",
      "he visitado",
      "primero / luego",
      "al final"
    ],
    "lesson-b1-15-1": [
      "quiz\xE1s",
      "tal vez",
      "a lo mejor",
      "probablemente",
      "seguramente",
      "es probable que",
      "es posible que",
      "debe de..."
    ],
    "lesson-b2-1-1": [
      "hab\xEDa hablado",
      "hab\xEDas comido",
      "hab\xEDa + participio",
      "ya hab\xEDa...",
      "todav\xEDa no hab\xEDa...",
      "antes de que...",
      "cuando ocurri\xF3...",
      "para entonces..."
    ],
    "lesson-b2-2-1": [
      "ser + participio + por",
      "fue construido por...",
      "se venden...",
      "se considera...",
      "est\xE1 cerrado / cerrada",
      "fue aprobado / aprobada",
      "se utiliza para...",
      "por parte de..."
    ],
    "lesson-b2-3-1": [
      "dijo que",
      "coment\xF3 que",
      "a\xF1adi\xF3 que",
      "pregunt\xF3 si",
      "pregunt\xF3 qu\xE9 / cu\xE1ndo",
      "pidi\xF3 que",
      "sugiri\xF3 que",
      "aquel d\xEDa / all\xED"
    ],
    "lesson-b2-4-1": [
      "que",
      "quien / quienes",
      "el / la que",
      "el / la cual",
      "cuyo / cuya",
      "donde",
      "con quien",
      "en el que"
    ],
    "lesson-b2-5-1": [
      "t\xFA / usted",
      "hola / buenos d\xEDas",
      "\xBFqu\xE9 tal? / \xBFc\xF3mo est\xE1?",
      "un beso / atentamente",
      "\xBFpuedes...?",
      "\xBFle importar\xEDa...?",
      "quiero... / quisiera...",
      "te env\xEDo... / adjunto..."
    ],
    "lesson-b2-6-1": [
      "la empresa",
      "el departamento",
      "el cargo",
      "el presupuesto",
      "el contrato",
      "el cliente / proveedor",
      "la reuni\xF3n",
      "le agradecer\xEDa que..."
    ],
    "lesson-b2-7-1": [
      "la investigaci\xF3n",
      "el experimento",
      "la hip\xF3tesis",
      "los datos",
      "el descubrimiento",
      "la inteligencia artificial",
      "se demostr\xF3 que",
      "debido a / por lo tanto"
    ],
    "lesson-b2-8-1": [
      "la desigualdad",
      "la pobreza",
      "los derechos",
      "la justicia",
      "la inmigraci\xF3n",
      "la discriminaci\xF3n",
      "la solidaridad",
      "es injusto que..."
    ],
    "lesson-b2-9-1": [
      "la novela / el cuento",
      "el autor / la autora",
      "la obra",
      "la pintura / escultura",
      "el g\xE9nero",
      "la trama",
      "el personaje",
      "se trata de..."
    ],
    "lesson-b2-10-1": [
      "el gobierno",
      "las elecciones",
      "el partido",
      "la ley",
      "el ciudadano / ciudadana",
      "el derecho",
      "votar / gobernar",
      "la democracia"
    ],
    "lesson-b2-11-1": [
      "la salud / el bienestar",
      "la dieta / alimentaci\xF3n",
      "el ejercicio",
      "el estr\xE9s",
      "el descanso",
      "los h\xE1bitos",
      "el sue\xF1o",
      "es bueno que..."
    ],
    "lesson-b2-12-1": [
      "la libertad",
      "la felicidad",
      "la justicia",
      "el \xE9xito",
      "la verdad",
      "el significado",
      "el prop\xF3sito",
      "lo importante / lo dif\xEDcil"
    ]
  });
  var MANUAL_B1_B2_AGENDAS = Object.freeze({
    "lesson-b1-1-2": agenda2(
      "B1",
      [
        "\xBFalguna vez has...?",
        "s\xED, ya he...",
        "no, todav\xEDa no he...",
        "nunca he...",
        "esta semana he...",
        "\xBFcu\xE1ndo fue?",
        "fui / hice..."
      ],
      "\xBFAlguna vez has...? \u2192 he / no he... \u2192 \xBFcu\xE1ndo? \u2192 detalle",
      "Exchange three life experiences and follow one answer with a specific past detail",
      ["\xBFAlguna vez has viajado solo?", "S\xED, fui a Per\xFA el a\xF1o pasado."],
      "Ask about three experiences, require present perfect answers, then move one answer into a dated preterite detail",
      "The learner answers three experience questions and adds one coherent specific-past detail"
    ),
    "lesson-b1-1-3": agenda2(
      "B1",
      [
        "he logrado...",
        "he aprendido...",
        "he terminado...",
        "todav\xEDa no he...",
        "el a\xF1o pasado...",
        "primero...",
        "al final..."
      ],
      "he logrado... \u2192 el a\xF1o pasado... \u2192 primero... \u2192 al final...",
      "Describe one achievement and connect the resulting experience to a specific past sequence",
      ["He aprendido a cocinar.", "El a\xF1o pasado hice mi primer plato."],
      "Prompt one achievement, when it began, two steps in the process, and the final result",
      "The learner distinguishes the current achievement from at least two specific past events"
    ),
    "lesson-b1-2-2": agenda2(
      "B1",
      [
        "estaba + gerundio",
        "mientras...",
        "cuando...",
        "de repente...",
        "llov\xEDa",
        "la gente...",
        "ocurri\xF3..."
      ],
      "estaba... \u2192 mientras... \u2192 de repente... \u2192 ocurri\xF3...",
      "Describe two simultaneous background actions and the event that interrupted them",
      ["Estaba caminando mientras llov\xEDa.", "De repente, ocurri\xF3 un accidente."],
      "Build a three-part scene with two ongoing actions followed by one interrupting event",
      "The learner uses two background actions and one clearly completed interruption"
    ),
    "lesson-b1-2-3": agenda2(
      "B1",
      [
        "era...",
        "estaba...",
        "hab\xEDa...",
        "mientras...",
        "de repente...",
        "entonces...",
        "al final..."
      ],
      "era / estaba / hab\xEDa... \u2192 de repente... \u2192 entonces... \u2192 al final...",
      "Set a past scene and narrate a short event through its conclusion",
      ["Era de noche y hab\xEDa poca gente.", "De repente, se apagaron las luces."],
      "Elicit place, conditions, people, one sudden event, its consequence, and the ending",
      "The learner provides three background details and links the event, consequence, and ending"
    ),
    "lesson-b1-3-2": agenda2(
      "B1",
      [
        "viajar\xE9...",
        "habr\xE1...",
        "llover\xE1...",
        "creo que...",
        "probablemente...",
        "el a\xF1o que viene...",
        "dentro de..."
      ],
      "creo que... \u2192 probablemente... \u2192 habr\xE1 / ser\xE1... \u2192 raz\xF3n",
      "Make three future predictions and explain the reason for one",
      ["Creo que habr\xE1 m\xE1s tecnolog\xEDa.", "Probablemente trabajaremos menos porque..."],
      "Ask for one personal, one social, and one weather or technology prediction, then challenge one with why",
      "The learner produces three future forms and supports one prediction with a reason"
    ),
    "lesson-b1-3-3": agenda2(
      "B1",
      [
        "voy a...",
        "har\xE9...",
        "quiz\xE1s...",
        "ser\xE1...",
        "\xBFqu\xE9 har\xE1s?",
        "depender\xE1 de...",
        "si..., entonces..."
      ],
      "voy a... / har\xE9... \u2192 quiz\xE1s... \u2192 depender\xE1 de... \u2192 si..., entonces...",
      "Distinguish a planned future action from a prediction and a possibility",
      ["Voy a estudiar ma\xF1ana.", "Quiz\xE1s estudiar\xE9 en otro pa\xEDs."],
      "Present a fixed plan, an uncertain possibility, and one condition that could change the result",
      "The learner marks the plan, prediction, and conditional possibility with appropriate forms"
    ),
    "lesson-b1-4-2": agenda2(
      "B1",
      [
        "m\xE1s... que",
        "menos... que",
        "tan... como",
        "mejor / peor",
        "ambos...",
        "en cambio...",
        "prefiero... porque..."
      ],
      "ambos... \u2192 m\xE1s / menos... que \u2192 en cambio... \u2192 prefiero... porque...",
      "Compare two options on three criteria and choose one with a reason",
      ["Ambos son econ\xF3micos.", "Este es m\xE1s r\xE1pido; en cambio, aquel es m\xE1s c\xF3modo."],
      "Give two familiar options and three criteria, requiring one similarity, two contrasts, and a final preference",
      "The learner makes three accurate comparisons and supports a clear choice"
    ),
    "lesson-b1-4-3": agenda2(
      "B1",
      [
        "el / la m\xE1s...",
        "el / la mejor...",
        "el / la peor...",
        "-\xEDsimo / -\xEDsima",
        "de todos...",
        "por un lado...",
        "por otro lado..."
      ],
      "por un lado... \u2192 por otro lado... \u2192 el mejor de... \u2192 elegir\xEDa...",
      "Rank three options and defend the best choice with a balanced comparison",
      ["Es el m\xE1s barato de todos.", "Por otro lado, es lent\xEDsimo."],
      "Ask the learner to rank three options, name one extreme quality, acknowledge a drawback, and select the best",
      "The learner uses a superlative, an intensified adjective, a contrast, and a defended choice"
    ),
    "lesson-b1-5-2": agenda2(
      "B1",
      [
        "deber\xEDas...",
        "podr\xEDas...",
        "te recomiendo que...",
        "lo mejor es que...",
        "\xBFpor qu\xE9 no...?",
        "si yo fuera t\xFA...",
        "porque..."
      ],
      "problema \u2192 deber\xEDas / podr\xEDas... \u2192 te recomiendo que... \u2192 porque...",
      "Give two different pieces of advice and explain which one is best",
      ["Podr\xEDas hablar con ella.", "Te recomiendo que descanses porque..."],
      "Present one everyday problem, elicit a soft option and a stronger recommendation, then ask which is preferable",
      "The learner gives two distinct suggestions and supports the preferred one"
    ),
    "lesson-b1-5-3": agenda2(
      "B1",
      [
        "el problema es que...",
        "una opci\xF3n ser\xEDa...",
        "otra posibilidad es...",
        "la ventaja es...",
        "la desventaja es...",
        "yo que t\xFA...",
        "solucionar\xEDa..."
      ],
      "problema \u2192 dos opciones \u2192 ventaja / desventaja \u2192 yo que t\xFA...",
      "Evaluate two solutions to a problem and make a final recommendation",
      ["Una opci\xF3n ser\xEDa cambiar de horario.", "La desventaja es que cuesta m\xE1s."],
      "Define a problem, compare two possible solutions with one tradeoff each, and close with advice",
      "The learner presents two options, one advantage or disadvantage, and a justified recommendation"
    ),
    "lesson-b1-6-2": agenda2(
      "B1",
      [
        "\xBFqu\xE9 tal si...?",
        "podr\xEDamos...",
        "\xBFte parece si...?",
        "vamos a...",
        "prefiero...",
        "otra idea ser\xEDa...",
        "porque..."
      ],
      "\xBFqu\xE9 tal si...? \u2192 alternativa \u2192 preferencia + raz\xF3n \u2192 acuerdo",
      "Negotiate a shared plan by proposing, revising, and agreeing on an option",
      ["\xBFQu\xE9 tal si vamos el s\xE1bado?", "Prefiero el domingo porque trabajo."],
      "Require an initial suggestion, a conflicting preference, an alternative, and a final agreement",
      "The learner proposes two options, explains one preference, and reaches an explicit agreement"
    ),
    "lesson-b1-6-3": agenda2(
      "B1",
      [
        "me parece bien",
        "vale, de acuerdo",
        "lo siento, pero...",
        "no puedo...",
        "mejor...",
        "entonces quedamos...",
        "\xBFte viene bien?"
      ],
      "propuesta \u2192 rechazo cort\xE9s \u2192 alternativa \u2192 entonces quedamos...",
      "Accept one suggestion, decline another politely, and confirm a revised plan",
      ["Lo siento, pero no puedo el viernes.", "Entonces quedamos el s\xE1bado."],
      "Cycle through one acceptable and one impossible plan, requiring a polite refusal and a confirmed alternative",
      "The learner accepts, declines with a reason, proposes an alternative, and confirms it"
    ),
    "lesson-b1-7-2": agenda2(
      "B1",
      [
        "\xBFpodr\xEDa...?",
        "me gustar\xEDa...",
        "\xBFser\xEDa posible...?",
        "si fuera posible...",
        "har\xEDa...",
        "en tu lugar...",
        "preferir\xEDa..."
      ],
      "petici\xF3n cort\xE9s \u2192 condici\xF3n \u2192 respuesta \u2192 alternativa",
      "Make a polite request, respond to a condition, and offer an alternative",
      ["\xBFSer\xEDa posible cambiar la fecha?", "Si fuera posible, preferir\xEDa el lunes."],
      "Use a service or workplace request that cannot be granted exactly, prompting a conditional alternative",
      "The learner makes a softened request and negotiates one acceptable alternative"
    ),
    "lesson-b1-7-3": agenda2(
      "B1",
      [
        "me encantar\xEDa...",
        "querr\xEDa...",
        "podr\xEDa...",
        "yo que t\xFA...",
        "ser\xEDa mejor...",
        "si tuviera...",
        "elegir\xEDa..."
      ],
      "deseo \u2192 posibilidad \u2192 consejo \u2192 elecci\xF3n hipot\xE9tica",
      "Connect a wish, a hypothetical possibility, and advice in one discussion",
      ["Me encantar\xEDa vivir cerca del mar.", "Si tuviera tiempo, viajar\xEDa m\xE1s."],
      "Ask about one wish, what would make it possible, and what advice the learner would give another person",
      "The learner uses the conditional for a wish, a hypothetical result, and one piece of advice"
    ),
    "lesson-b1-8-2": agenda2(
      "B1",
      [
        "tengo una reserva",
        "quisiera facturar...",
        "\xBFd\xF3nde est\xE1 la puerta...?",
        "el vuelo est\xE1 retrasado",
        "\xBFa qu\xE9 hora sale?",
        "el equipaje de mano",
        "\xBFhay alg\xFAn problema?"
      ],
      "reserva \u2192 equipaje \u2192 puerta / hora \u2192 retraso \u2192 soluci\xF3n",
      "Complete an airport check-in and respond to one travel complication",
      ["Tengo una reserva a nombre de Ruiz.", "\xBFA qu\xE9 hora sale el vuelo?"],
      "Run check-in through reservation, baggage, gate, and departure time, then introduce a delay or baggage issue",
      "The learner completes the check-in information and asks for a relevant solution to the complication"
    ),
    "lesson-b1-8-3": agenda2(
      "B1",
      [
        "quisiera reservar...",
        "\xBFhay disponibilidad?",
        "\xBFqu\xE9 incluye?",
        "la confirmaci\xF3n",
        "\xBFc\xF3mo llego a...?",
        "\xBFqu\xE9 me recomienda?",
        "podr\xEDa visitar..."
      ],
      "reserva \u2192 detalles \u2192 confirmaci\xF3n \u2192 direcci\xF3n \u2192 recomendaci\xF3n",
      "Book accommodation and ask for directions and one local recommendation",
      ["\xBFHay disponibilidad para dos noches?", "\xBFQu\xE9 me recomienda visitar?"],
      "Require dates or duration, included services, confirmation, directions, and one recommendation",
      "The learner secures the key booking details and asks two relevant destination questions"
    ),
    "lesson-b1-9-2": agenda2(
      "B1",
      [
        "hay que...",
        "deber\xEDamos...",
        "se deber\xEDa...",
        "debido a...",
        "por eso...",
        "reducir...",
        "reciclar..."
      ],
      "problema \u2192 debido a... \u2192 por eso... \u2192 dos soluciones",
      "Explain one environmental problem and propose two practical solutions",
      ["Hay contaminaci\xF3n debido al tr\xE1fico.", "Por eso, deber\xEDamos usar el transporte p\xFAblico."],
      "Identify a local cause and consequence, then require one personal and one community solution",
      "The learner links cause and consequence and proposes two distinct actions"
    ),
    "lesson-b1-9-3": agenda2(
      "B1",
      [
        "el problema principal es...",
        "una causa es...",
        "como consecuencia...",
        "una soluci\xF3n ser\xEDa...",
        "propongo que...",
        "porque...",
        "si..., entonces..."
      ],
      "problema \u2192 causa \u2192 consecuencia \u2192 propuesta \u2192 resultado esperado",
      "Present an environmental problem-solution argument with an expected result",
      ["Una causa es el exceso de residuos.", "Si reciclamos m\xE1s, entonces..."],
      "Use a short article scenario to elicit the problem, one cause, one effect, a proposal, and its likely result",
      "The learner produces a coherent five-part problem-solution chain"
    ),
    "lesson-b1-10-2": agenda2(
      "B1",
      [
        "se celebra...",
        "solemos...",
        "cada a\xF1o...",
        "la gente...",
        "durante...",
        "consiste en...",
        "es t\xEDpico..."
      ],
      "cu\xE1ndo se celebra \u2192 qu\xE9 hace la gente \u2192 en qu\xE9 consiste \u2192 por qu\xE9 importa",
      "Describe a celebration through its date, customs, and meaning",
      ["Se celebra cada a\xF1o en agosto.", "La tradici\xF3n consiste en..."],
      "Ask when the celebration occurs, what people usually do, one typical element, and why it matters",
      "The learner gives four connected details about one celebration"
    ),
    "lesson-b1-10-3": agenda2(
      "B1",
      [
        "ambas celebraciones...",
        "mientras que...",
        "a diferencia de...",
        "en cambio...",
        "se parece a...",
        "una tradici\xF3n...",
        "representa..."
      ],
      "semejanza \u2192 mientras que... \u2192 diferencia \u2192 significado",
      "Compare two celebrations and explain one cultural meaning",
      ["Ambas celebraciones re\xFAnen a las familias.", "En cambio, una dura varios d\xEDas."],
      "Present two short cultural descriptions and require one similarity, two differences, and one interpretation",
      "The learner compares both celebrations accurately and explains one meaningful custom"
    ),
    "lesson-b1-11-2": agenda2(
      "B1",
      [
        "seg\xFAn...",
        "dicen que...",
        "informa que...",
        "al parecer...",
        "el titular...",
        "la fuente...",
        "ocurri\xF3..."
      ],
      "titular \u2192 seg\xFAn la fuente... \u2192 qu\xE9 ocurri\xF3 \u2192 reacci\xF3n",
      "Report the main event from a headline and attribute it to a source",
      ["Seg\xFAn el peri\xF3dico, ocurri\xF3 ayer.", "Al parecer, no hubo heridos."],
      "Give a headline and summary, asking for the event, source, one uncertain detail, and a reaction",
      "The learner reports the event, attributes the information, and marks uncertainty appropriately"
    ),
    "lesson-b1-11-3": agenda2(
      "B1",
      [
        "es un hecho que...",
        "seg\xFAn la fuente...",
        "en mi opini\xF3n...",
        "parece que...",
        "no est\xE1 confirmado",
        "sin embargo...",
        "la evidencia..."
      ],
      "hecho \u2192 fuente \u2192 dato no confirmado \u2192 opini\xF3n \u2192 reacci\xF3n",
      "Separate facts, uncertain claims, and opinion in a short news report",
      ["Es un hecho que la reuni\xF3n ocurri\xF3.", "No est\xE1 confirmado qui\xE9n particip\xF3."],
      "Present five statements from a short report and ask the learner to classify and restate each type",
      "The learner identifies at least one fact, one uncertain claim, and one opinion and attributes a source",
      { kind: "comprehension", evidenceType: "classify_and_respond" }
    ),
    "lesson-b1-12-2": agenda2(
      "B1",
      [
        "creo que...",
        "en mi opini\xF3n...",
        "estoy de acuerdo",
        "no estoy de acuerdo",
        "entiendo tu punto, pero...",
        "porque...",
        "por ejemplo..."
      ],
      "opini\xF3n \u2192 raz\xF3n \u2192 ejemplo \u2192 acuerdo / desacuerdo cort\xE9s",
      "State and support an opinion and respond politely to another view",
      ["En mi opini\xF3n, es una buena idea porque...", "Entiendo tu punto, pero..."],
      "Ask for a position, reason, example, and response to one contrasting opinion",
      "The learner supports a clear view and responds to disagreement without abandoning the topic"
    ),
    "lesson-b1-12-3": agenda2(
      "B1",
      [
        "mi argumento es...",
        "la raz\xF3n principal es...",
        "por ejemplo...",
        "sin embargo...",
        "no creo que...",
        "estoy de acuerdo en parte",
        "en conclusi\xF3n..."
      ],
      "argumento \u2192 raz\xF3n + ejemplo \u2192 objeci\xF3n \u2192 respuesta \u2192 conclusi\xF3n",
      "Build a short argument and answer one respectful challenge",
      ["La raz\xF3n principal es el costo.", "Estoy de acuerdo en parte; sin embargo..."],
      "Structure a mini-debate with a claim, support, one challenge supplied by the tutor, and a conclusion",
      "The learner maintains a coherent position through support, concession, response, and conclusion"
    ),
    "lesson-b1-13-2": agenda2(
      "B1",
      [
        "quisiera presentar una queja",
        "no funciona",
        "est\xE1 roto / defectuoso",
        "me gustar\xEDa...",
        "\xBFser\xEDa posible...?",
        "un cambio",
        "un reembolso"
      ],
      "problema espec\xEDfico \u2192 efecto \u2192 petici\xF3n cort\xE9s \u2192 cambio / reembolso",
      "Make a polite complaint and request a specific remedy",
      ["El aparato no funciona.", "\xBFSer\xEDa posible recibir un reembolso?"],
      "Require product or service details, the exact problem, its consequence, and a chosen remedy",
      "The learner describes the problem clearly and makes one appropriately softened request"
    ),
    "lesson-b1-13-3": agenda2(
      "B1",
      [
        "entiendo el problema",
        "lo siento por...",
        "puedo ofrecerle...",
        "preferir\xEDa...",
        "acepto...",
        "no es suficiente",
        "gracias por su ayuda"
      ],
      "queja \u2192 reconocimiento \u2192 oferta \u2192 contraoferta \u2192 acuerdo",
      "Resolve a complaint by evaluating an offer and negotiating an acceptable outcome",
      ["Puedo ofrecerle un cambio.", "Preferir\xEDa un reembolso."],
      "Switch roles through complaint acknowledgment, first offer, customer response, revised offer, and closure",
      "The learner responds to the complaint and negotiates through to an explicit resolution"
    ),
    "lesson-b1-14-2": agenda2(
      "B1",
      [
        "\xBFalguna vez has...?",
        "s\xED, he...",
        "no, nunca he...",
        "\xBFcu\xE1ndo fue?",
        "\xBFqu\xE9 pas\xF3?",
        "primero...",
        "luego..."
      ],
      "experiencia \u2192 cu\xE1ndo \u2192 qu\xE9 pas\xF3 \u2192 primero / luego",
      "Ask about an experience and narrate two specific events from it",
      ["\xBFAlguna vez has perdido un vuelo?", "S\xED. Primero llegu\xE9 tarde y luego..."],
      "Use one experience question, then require time, setting, and two ordered past actions",
      "The learner moves accurately from present perfect experience framing into a specific past narrative"
    ),
    "lesson-b1-14-3": agenda2(
      "B1",
      [
        "hace... a\xF1os",
        "estaba...",
        "de repente...",
        "entonces...",
        "por eso...",
        "al final...",
        "aprend\xED que..."
      ],
      "contexto \u2192 acci\xF3n en curso \u2192 giro \u2192 consecuencia \u2192 aprendizaje",
      "Narrate a memorable experience and explain what was learned",
      ["Hace dos a\xF1os estaba viajando cuando...", "Al final, aprend\xED que..."],
      "Prompt a dated setting, background action, turning point, consequence, ending, and reflection",
      "The learner tells a linked narrative with appropriate past framing and a clear lesson"
    ),
    "lesson-b1-15-2": agenda2(
      "B1",
      [
        "quiz\xE1s est\xE9...",
        "a lo mejor est\xE1...",
        "debe de estar...",
        "es posible que...",
        "no creo que...",
        "probablemente...",
        "porque..."
      ],
      "tres hip\xF3tesis \u2192 grado de certeza \u2192 evidencia \u2192 explicaci\xF3n preferida",
      "Propose three explanations for a puzzling situation and rank their likelihood",
      ["Quiz\xE1s est\xE9 enfermo.", "Debe de estar en casa porque las luces est\xE1n encendidas."],
      "Give a mystery with three clues, require three differently weighted hypotheses, and select the best explanation",
      "The learner expresses three levels of probability and supports the leading hypothesis with evidence"
    ),
    "lesson-b1-15-3": agenda2(
      "B1",
      [
        "seguro que...",
        "seguramente...",
        "probablemente...",
        "quiz\xE1s...",
        "es poco probable que...",
        "dudo que...",
        "no puede ser que..."
      ],
      "seguro \u2192 probable \u2192 posible \u2192 poco probable \u2192 duda",
      "Order five predictions from most to least certain and justify two positions",
      ["Seguramente llegar\xE1 pronto.", "Dudo que llegue hoy."],
      "Present five predictions about one scenario, ask for a certainty ranking, then challenge the top and bottom choices",
      "The learner uses at least four distinct certainty frames and justifies two rankings"
    ),
    "lesson-b2-1-2": agenda2(
      "B2",
      [
        "cuando llegu\xE9, ya hab\xEDa...",
        "antes de...",
        "despu\xE9s de...",
        "todav\xEDa no hab\xEDa...",
        "para entonces...",
        "una vez que...",
        "resulta que..."
      ],
      "resultado \u2192 ya hab\xEDa... \u2192 antes / despu\xE9s \u2192 revelaci\xF3n",
      "Reconstruct an event by distinguishing what had and had not happened beforehand",
      ["Cuando llegu\xE9, ya hab\xEDan salido.", "Para entonces, todav\xEDa no hab\xEDa recibido el mensaje."],
      "Reveal a final situation and four timeline clues, requiring the learner to reconstruct the earlier sequence",
      "The learner orders the prior events and consistently marks their relation to the later reference point"
    ),
    "lesson-b2-1-3": agenda2(
      "B2",
      [
        "anteriormente...",
        "hab\xEDa...",
        "una vez que...",
        "hasta que...",
        "cuando ocurri\xF3...",
        "posteriormente...",
        "finalmente..."
      ],
      "anteriormente \u2192 hab\xEDa... \u2192 evento central \u2192 posteriormente \u2192 finalmente",
      "Build and explain a complex timeline with earlier, central, and later events",
      ["Anteriormente hab\xEDa trabajado all\xED.", "Posteriormente, cambi\xF3 de puesto."],
      "Provide six events from two time layers out of order and ask for a coherent retelling with temporal framing",
      "The learner reconstructs the full timeline without confusing the earlier-past and main-past layers"
    ),
    "lesson-b2-2-2": agenda2(
      "B2",
      [
        "se fabrica...",
        "es fabricado por...",
        "fue creado para...",
        "se utiliza para...",
        "est\xE1 compuesto de...",
        "mediante...",
        "como resultado..."
      ],
      "materia prima \u2192 proceso \u2192 agente \u2192 uso \u2192 resultado",
      "Explain a process using impersonal, passive, and result-focused structures",
      ["Se fabrica con materiales reciclados.", "El sistema fue creado por un equipo internacional."],
      "Ask for five stages of a familiar production or technical process, varying who or what receives focus",
      "The learner uses at least two passive strategies and keeps agreement and process order accurate"
    ),
    "lesson-b2-2-3": agenda2(
      "B2",
      [
        "la empresa produce...",
        "se produce...",
        "fue aprobado por...",
        "se considera...",
        "est\xE1 terminado...",
        "se decidi\xF3 que...",
        "el informe fue..."
      ],
      "activa \u2192 pasiva \u2192 impersonal \u2192 justificaci\xF3n de registro",
      "Reformulate active statements into passive or impersonal language and justify the register choice",
      ["La empresa publica el informe. \u2192 El informe es publicado por la empresa."],
      "Give four active workplace or news statements and require two passive and two impersonal rewrites plus one style explanation",
      "The learner produces four accurate reformulations and explains one focus or register effect"
    ),
    "lesson-b2-3-2": agenda2(
      "B2",
      [
        "me dijo que...",
        "me pregunt\xF3 si...",
        "coment\xF3 que...",
        "a\xF1adi\xF3 que...",
        "pidi\xF3 que...",
        "seg\xFAn explic\xF3...",
        "neg\xF3 que..."
      ],
      "mensaje original \u2192 dijo / pregunt\xF3 / pidi\xF3 que... \u2192 fuente",
      "Retell a conversation while distinguishing statements, questions, and requests",
      ["Me pregunt\xF3 si pod\xEDa ir.", "Pidi\xF3 que envi\xE1ramos el documento."],
      "Present a six-line dialogue with two statements, two questions, and one request, then ask for a sourced retelling",
      "The learner reports each speech act with appropriate tense, pronoun, and reporting verb"
    ),
    "lesson-b2-3-3": agenda2(
      "B2",
      [
        "dijo que hab\xEDa...",
        "anunci\xF3 que har\xEDa...",
        "pregunt\xF3 d\xF3nde...",
        "neg\xF3 haber...",
        "aclar\xF3 que...",
        "al d\xEDa siguiente...",
        "aquel d\xEDa..."
      ],
      "cita \u2192 cambio de tiempo / persona / lugar \u2192 relato coherente",
      "Convert direct quotations into a coherent reported account with tense and reference shifts",
      ["\xABIr\xE9 ma\xF1ana\xBB. \u2192 Anunci\xF3 que ir\xEDa al d\xEDa siguiente."],
      "Supply five quotations containing past, future, person, place, and time references and require one continuous report",
      "The learner applies the required backshift and deixis changes without losing source meaning"
    ),
    "lesson-b2-4-2": agenda2(
      "B2",
      [
        "que...",
        "quien...",
        "donde...",
        "con quien...",
        "en el que...",
        "cuyo / cuya...",
        "lo que..."
      ],
      "dos ideas \u2192 relativo adecuado \u2192 una oraci\xF3n precisa",
      "Combine related statements using varied relative forms and explain the chosen connector",
      ["Conoc\xED a la autora. Su libro gan\xF3. \u2192 Conoc\xED a la autora cuyo libro gan\xF3."],
      "Give five statement pairs involving people, place, possession, and prepositions, then request combined versions",
      "The learner combines at least four pairs accurately and explains one relative-form choice"
    ),
    "lesson-b2-4-3": agenda2(
      "B2",
      [
        "el cual / la cual...",
        "lo que...",
        "cuyo / cuya...",
        "mediante el cual...",
        "..., que,...",
        "en el que...",
        "a quien..."
      ],
      "oraci\xF3n compleja \u2192 referente \u2192 informaci\xF3n esencial / adicional \u2192 par\xE1frasis",
      "Unpack complex relative clauses and reformulate them without losing reference or emphasis",
      ["El acuerdo, mediante el cual se resolvi\xF3 el conflicto, fue firmado ayer."],
      "Present four dense sentences, ask who or what each relative refers to, then require a clearer paraphrase",
      "The learner resolves every reference and preserves essential versus additional information",
      { kind: "comprehension", evidenceType: "analyze_and_reformulate" }
    ),
    "lesson-b2-5-2": agenda2(
      "B2",
      [
        "hola / estimado se\xF1or...",
        "\xBFpuedes...? / \xBFpodr\xEDa...?",
        "t\xFA / usted",
        "quiero... / le agradecer\xEDa que...",
        "gracias / un cordial saludo",
        "oye... / disculpe...",
        "te env\xEDo... / adjunto..."
      ],
      "mismo mensaje \u2192 versi\xF3n informal \u2192 versi\xF3n formal \u2192 cambios justificados",
      "Deliver the same request in informal and formal registers and explain the changes",
      ["\xBFPuedes envi\xE1rmelo? / \xBFPodr\xEDa envi\xE1rmelo, por favor?"],
      "Give one request scenario and two audiences, requiring complete openings, request wording, and closings for each",
      "The learner produces two coherent versions and identifies at least two register changes"
    ),
    "lesson-b2-5-3": agenda2(
      "B2",
      [
        "es adecuado para...",
        "resulta demasiado informal",
        "suena excesivamente formal",
        "en este contexto...",
        "convendr\xEDa...",
        "reformular\xEDa...",
        "ser\xEDa mejor decir..."
      ],
      "contexto + audiencia \u2192 evaluaci\xF3n de registro \u2192 reformulaci\xF3n",
      "Evaluate whether three messages fit their contexts and reformulate the weakest one",
      ["Resulta demasiado informal para una solicitud oficial.", "Ser\xEDa mejor decir..."],
      "Present a friend message, workplace request, and formal complaint with one mismatch, then require diagnosis and revision",
      "The learner evaluates all three registers and produces a context-appropriate reformulation",
      { kind: "comprehension", evidenceType: "evaluate_and_rewrite" }
    ),
    "lesson-b2-6-2": agenda2(
      "B2",
      [
        "el orden del d\xEDa...",
        "el objetivo es...",
        "seg\xFAn el informe...",
        "propongo que...",
        "estoy de acuerdo, pero...",
        "queda pendiente...",
        "el pr\xF3ximo paso es..."
      ],
      "objetivo \u2192 actualizaci\xF3n \u2192 propuesta \u2192 objeci\xF3n \u2192 decisi\xF3n \u2192 pr\xF3ximo paso",
      "Lead a focused meeting update from objective through decision and next step",
      ["Seg\xFAn el informe, las ventas aumentaron.", "Queda pendiente confirmar el plazo."],
      "Simulate a six-turn meeting with one update, proposal, concern, decision, responsibility, and next step",
      "The learner structures the meeting clearly and closes with an assigned or explicit next action"
    ),
    "lesson-b2-6-3": agenda2(
      "B2",
      [
        "nuestra propuesta es...",
        "las condiciones son...",
        "estar\xEDamos dispuestos a...",
        "siempre que...",
        "sin embargo...",
        "llegar a un acuerdo",
        "el plazo ser\xEDa..."
      ],
      "propuesta \u2192 condiciones \u2192 concesi\xF3n \u2192 contrapropuesta \u2192 acuerdo",
      "Negotiate a proposal through conditions, concession, and a documented agreement",
      ["Estar\xEDamos dispuestos a aceptar, siempre que cambie el plazo."],
      "Set two conflicting priorities and require an opening proposal, condition, concession, counterproposal, and close",
      "The learner protects a priority, makes a meaningful concession, and reaches a precise agreement"
    ),
    "lesson-b2-7-2": agenda2(
      "B2",
      [
        "consiste en...",
        "funciona mediante...",
        "se basa en...",
        "los datos muestran que...",
        "debido a...",
        "por lo tanto...",
        "permite..."
      ],
      "principio \u2192 mecanismo \u2192 datos \u2192 causa \u2192 resultado",
      "Explain how a technology works and connect evidence to its result",
      ["Funciona mediante sensores.", "Los datos muestran que reduce el consumo."],
      "Ask for the technology's purpose, mechanism, one data point, causal explanation, and practical result",
      "The learner gives a technically coherent explanation and links evidence to the stated result"
    ),
    "lesson-b2-7-3": agenda2(
      "B2",
      [
        "la evidencia indica que...",
        "podr\xEDa...",
        "es probable que...",
        "no est\xE1 demostrado que...",
        "seg\xFAn los datos...",
        "a largo plazo...",
        "una limitaci\xF3n es..."
      ],
      "evidencia \u2192 predicci\xF3n \u2192 l\xEDmite \u2192 efecto a largo plazo",
      "Distinguish evidence from speculation and defend a qualified technology prediction",
      ["Seg\xFAn los datos, ya mejora la precisi\xF3n.", "A largo plazo podr\xEDa..., aunque..."],
      "Provide two evidence statements and two speculative claims, requiring classification, prediction, and one limitation",
      "The learner grounds the prediction in evidence and explicitly qualifies uncertainty or limitation"
    ),
    "lesson-b2-8-2": agenda2(
      "B2",
      [
        "el problema afecta a...",
        "una causa es...",
        "la iniciativa busca...",
        "el objetivo principal...",
        "hasta ahora ha logrado...",
        "ser\xEDa necesario...",
        "para mejorar..."
      ],
      "problema \u2192 poblaci\xF3n afectada \u2192 iniciativa \u2192 resultado \u2192 mejora",
      "Assess a community initiative by its problem, goal, result, and needed improvement",
      ["La iniciativa busca reducir la desigualdad.", "Para mejorar, ser\xEDa necesario..."],
      "Present a short initiative profile and ask for affected group, cause, goal, result, and one recommendation",
      "The learner accurately summarizes the initiative and proposes a relevant improvement",
      { kind: "comprehension", evidenceType: "assess_and_recommend" }
    ),
    "lesson-b2-8-3": agenda2(
      "B2",
      [
        "sostengo que...",
        "la evidencia muestra...",
        "debido a...",
        "aunque...",
        "una posible objeci\xF3n es...",
        "responder\xEDa que...",
        "propongo que..."
      ],
      "tesis \u2192 evidencia \u2192 concesi\xF3n \u2192 objeci\xF3n \u2192 respuesta \u2192 propuesta",
      "Argue for social change using evidence and a response to one objection",
      ["Sostengo que debe cambiar porque...", "Una posible objeci\xF3n es...; responder\xEDa que..."],
      "Require a claim, supporting evidence, causal link, concession, tutor-supplied objection, response, and action",
      "The learner sustains the argument through evidence and addresses the objection directly"
    ),
    "lesson-b2-9-2": agenda2(
      "B2",
      [
        "se caracteriza por...",
        "surgi\xF3 en...",
        "su estilo...",
        "influy\xF3 en...",
        "mientras que...",
        "a diferencia de...",
        "ambos movimientos..."
      ],
      "origen \u2192 rasgo definitorio \u2192 influencia \u2192 semejanza \u2192 diferencia",
      "Compare two artistic movements through period, defining features, and influence",
      ["Ambos movimientos rompieron con la tradici\xF3n.", "A diferencia del primero..."],
      "Provide two concise movement profiles and ask for timeline, defining feature, influence, similarity, and contrast",
      "The learner compares both movements with accurate contextual and stylistic support",
      { kind: "comprehension", evidenceType: "compare_and_explain" }
    ),
    "lesson-b2-9-3": agenda2(
      "B2",
      [
        "la obra refleja...",
        "representa...",
        "en su contexto...",
        "los valores de...",
        "funciona como s\xEDmbolo de...",
        "se puede interpretar como...",
        "debido a..."
      ],
      "detalle de la obra \u2192 s\xEDmbolo \u2192 contexto \u2192 valor \u2192 interpretaci\xF3n",
      "Interpret how a work reflects cultural values and historical context",
      ["La figura funciona como s\xEDmbolo de libertad.", "En su contexto, representa..."],
      "Present a short work description with three observable details, requiring symbol, context, value, and interpretation",
      "The learner grounds the interpretation in at least two details rather than giving an unsupported opinion"
    ),
    "lesson-b2-10-2": agenda2(
      "B2",
      [
        "desde mi punto de vista...",
        "por un lado...",
        "por otro lado...",
        "si bien...",
        "sin embargo...",
        "seg\xFAn...",
        "no creo que..."
      ],
      "posici\xF3n \u2192 dos perspectivas \u2192 fuente \u2192 concesi\xF3n \u2192 conclusi\xF3n",
      "Present a balanced political view with source attribution and concession",
      ["Si bien la medida ayuda, tambi\xE9n tiene costos.", "Seg\xFAn el informe..."],
      "Ask for a position, the strongest point on each side, one source, a concession, and final judgment",
      "The learner represents both sides fairly before reaching a supported conclusion"
    ),
    "lesson-b2-10-3": agenda2(
      "B2",
      [
        "propongo que...",
        "beneficiar\xEDa a...",
        "se podr\xEDa...",
        "una preocupaci\xF3n es...",
        "para responder a eso...",
        "el primer paso ser\xEDa...",
        "los ciudadanos podr\xEDan..."
      ],
      "acci\xF3n \u2192 beneficio \u2192 preocupaci\xF3n \u2192 respuesta \u2192 primer paso",
      "Propose a civic action, explain its benefit, and answer one practical concern",
      ["Propongo que se ampl\xEDe el programa.", "Para responder a esa preocupaci\xF3n..."],
      "Use a local issue to require an action, beneficiaries, implementation method, concern, response, and first step",
      "The learner presents an actionable proposal and responds specifically to the concern"
    ),
    "lesson-b2-11-2": agenda2(
      "B2",
      [
        "seg\xFAn...",
        "convendr\xEDa...",
        "es importante que...",
        "deber\xEDas...",
        "adem\xE1s...",
        "en cambio...",
        "mantener un equilibrio"
      ],
      "situaci\xF3n \u2192 evidencia \u2192 dos recomendaciones \u2192 contraste \u2192 equilibrio",
      "Create a balanced health recommendation supported by the person's situation",
      ["Seg\xFAn tus h\xE1bitos, convendr\xEDa dormir m\xE1s.", "Adem\xE1s, es importante que..."],
      "Give a lifestyle profile with competing needs, asking for two recommendations, one contrast, and a balanced priority",
      "The learner tailors the advice to the evidence and avoids a one-dimensional solution"
    ),
    "lesson-b2-11-3": agenda2(
      "B2",
      [
        "influye en...",
        "est\xE1 relacionado con...",
        "si..., entonces...",
        "tanto... como...",
        "a corto plazo...",
        "a largo plazo...",
        "el plan incluir\xEDa..."
      ],
      "factores conectados \u2192 efecto inmediato \u2192 efecto futuro \u2192 plan integrado",
      "Explain how four wellbeing factors interact and propose an integrated plan",
      ["El sue\xF1o influye en el estr\xE9s.", "El plan incluir\xEDa tanto descanso como ejercicio."],
      "Require links among sleep, nutrition, movement, and stress, then a short- and long-term plan",
      "The learner explains at least three relationships and proposes a plan addressing all four factors"
    ),
    "lesson-b2-12-2": agenda2(
      "B2",
      [
        "lo importante es...",
        "significa...",
        "desde esta perspectiva...",
        "depende de...",
        "se puede considerar...",
        "por ejemplo...",
        "en cambio..."
      ],
      "concepto \u2192 definici\xF3n \u2192 ejemplo \u2192 perspectiva alternativa \u2192 matiz",
      "Define an abstract concept and examine it from two perspectives",
      ["La libertad significa...", "Desde otra perspectiva, depende de..."],
      "Choose one abstract concept, require a definition, example, alternate perspective, and qualified conclusion",
      "The learner develops the concept beyond a personal preference and acknowledges a meaningful alternative"
    ),
    "lesson-b2-12-3": agenda2(
      "B2",
      [
        "en otras palabras...",
        "el autor sostiene que...",
        "se refiere a...",
        "sin embargo...",
        "esto implica que...",
        "desde mi punto de vista...",
        "matizar\xEDa que..."
      ],
      "tesis ajena \u2192 par\xE1frasis \u2192 implicaci\xF3n \u2192 objeci\xF3n \u2192 postura matizada",
      "Paraphrase a philosophical claim, explain its implication, and offer a nuanced response",
      ["En otras palabras, el autor sostiene que...", "Matizar\xEDa esa idea porque..."],
      "Present a short philosophical passage, ask for plain-language paraphrase, implication, limitation, and response",
      "The learner preserves the original claim while adding a distinct, qualified evaluation",
      { kind: "comprehension", evidenceType: "paraphrase_and_evaluate" }
    )
  });

  // ../nosabos/nosabos/src/data/manualC1C2Agendas.js
  var FORM_LABEL_PREFIXES3 = Object.freeze({
    en: "Use precisely in context",
    es: "Usa con precisi\xF3n en contexto",
    pt: "Use com precis\xE3o em contexto",
    it: "Usa con precisione nel contesto",
    fr: "Utilise avec pr\xE9cision en contexte",
    de: "Pr\xE4zise im Kontext verwenden",
    ja: "\u6587\u8108\u306B\u5FDC\u3058\u3066\u6B63\u78BA\u306B\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0938\u091F\u0940\u0915 \u0930\u0942\u092A \u0938\u0947 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0628\u062F\u0642\u0629 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u51C6\u786E\u4F7F\u7528"
  });
  var APPLICATION_LABEL_PREFIXES2 = Object.freeze({
    C1: {
      en: "Deliver the structured response",
      es: "Desarrolla la respuesta estructurada",
      pt: "Desenvolva a resposta estruturada",
      it: "Sviluppa la risposta strutturata",
      fr: "D\xE9veloppe la r\xE9ponse structur\xE9e",
      de: "Die strukturierte Antwort ausf\xFChren",
      ja: "\u69CB\u6210\u306E\u6574\u3063\u305F\u5FDC\u7B54\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0938\u0902\u0930\u091A\u093F\u0924 \u0909\u0924\u094D\u0924\u0930 \u092A\u094D\u0930\u0938\u094D\u0924\u0941\u0924 \u0915\u0930\u0947\u0902",
      ar: "\u0642\u062F\u0651\u0645 \u0627\u0644\u0627\u0633\u062A\u062C\u0627\u0628\u0629 \u0627\u0644\u0645\u0646\u0638\u0645\u0629",
      zh: "\u5B8C\u6210\u7ED3\u6784\u6E05\u6670\u7684\u56DE\u7B54"
    },
    C2: {
      en: "Craft and adapt the precise response",
      es: "Elabora y adapta la respuesta precisa",
      pt: "Elabore e adapte a resposta precisa",
      it: "Elabora e adatta la risposta precisa",
      fr: "\xC9labore et adapte la r\xE9ponse pr\xE9cise",
      de: "Die pr\xE4zise Antwort ausarbeiten und anpassen",
      ja: "\u7CBE\u5BC6\u306A\u5FDC\u7B54\u3092\u7DF4\u308A\u3001\u6587\u8108\u306B\u5408\u308F\u305B\u308B",
      hi: "\u0938\u091F\u0940\u0915 \u0909\u0924\u094D\u0924\u0930 \u0924\u0948\u092F\u093E\u0930 \u0915\u0930\u0947\u0902 \u0914\u0930 \u0909\u0938\u0947 \u0905\u0928\u0941\u0915\u0942\u0932\u093F\u0924 \u0915\u0930\u0947\u0902",
      ar: "\u0635\u064F\u063A \u0627\u0644\u0627\u0633\u062A\u062C\u0627\u0628\u0629 \u0627\u0644\u062F\u0642\u064A\u0642\u0629 \u0648\u0643\u064A\u0651\u0641\u0647\u0627",
      zh: "\u7EC4\u7EC7\u5E76\u8C03\u6574\u7CBE\u51C6\u7684\u56DE\u7B54"
    }
  });
  var agenda3 = (level, forms, goal, examples, activityBrief, evidence, options = {}) => ({
    forms,
    application: {
      level,
      goal,
      examples,
      activityBrief,
      evidence,
      ...options
    }
  });
  var C1_C2_FOUNDATION_FORMS = Object.freeze({
    "lesson-c1-1-1": [
      "quiero que...",
      "espero que...",
      "dudo que...",
      "me alegra que...",
      "es importante que...",
      "cuando + subjuntivo",
      "para que...",
      "a menos que..."
    ],
    "lesson-c1-2-1": [
      "quer\xEDa que...",
      "esperaba que...",
      "dudaba que...",
      "ojal\xE1 pudiera...",
      "como si fuera...",
      "hablara / hablase",
      "hubiera + participio",
      "de haberlo sabido..."
    ],
    "lesson-c1-3-1": [
      "si tengo..., har\xE9...",
      "si tuviera..., har\xEDa...",
      "si hubiera tenido..., habr\xEDa...",
      "a menos que...",
      "en caso de que...",
      "siempre que...",
      "con tal de que...",
      "de + infinitivo"
    ],
    "lesson-c1-4-1": [
      "echar de menos",
      "darse cuenta de",
      "valer la pena",
      "tener ganas de",
      "ponerse las pilas",
      "hacerse el / la tonto/a",
      "dar la lata",
      "dar igual"
    ],
    "lesson-c1-5-1": [
      "plantear una tesis",
      "sostener que...",
      "los datos indican que...",
      "cabe se\xF1alar que...",
      "por consiguiente...",
      "no obstante...",
      "en cuanto a...",
      "se concluye que..."
    ],
    "lesson-c1-6-1": [
      "le agradecer\xEDa que...",
      "quedo a la espera de...",
      "adjunto / adjunta...",
      "respecto a...",
      "seg\xFAn lo acordado...",
      "convendr\xEDa...",
      "propongo que...",
      "un cordial saludo"
    ],
    "lesson-c1-7-1": [
      "sostengo que...",
      "considero que...",
      "estoy a favor de...",
      "estoy en contra de...",
      "si bien...",
      "aunque...",
      "por un lado... por otro...",
      "no creo que..."
    ],
    "lesson-c1-8-1": [
      "los valores",
      "las costumbres",
      "la identidad",
      "la tradici\xF3n",
      "la modernidad",
      "el estereotipo",
      "la diversidad",
      "suele / tiende a..."
    ],
    "lesson-c1-9-1": [
      "el narrador / la narradora",
      "la focalizaci\xF3n",
      "la met\xE1fora",
      "el s\xEDmbolo",
      "el tono",
      "la imagen",
      "el ritmo",
      "la iron\xEDa"
    ],
    "lesson-c1-10-1": [
      "en primer lugar...",
      "a continuaci\xF3n...",
      "ahora bien...",
      "por lo tanto...",
      "en cambio...",
      "respecto a...",
      "dicho esto...",
      "en definitiva..."
    ],
    "lesson-c2-1-1": [
      "meter la pata",
      "costar un ojo de la cara",
      "estar en las nubes",
      "echar una mano",
      "no tener pelos en la lengua",
      "tomar el pelo",
      "ser pan comido",
      "estar pez"
    ],
    "lesson-c2-2-1": [
      "el carro / el coche / el auto",
      "la computadora / el ordenador",
      "el celular / el m\xF3vil",
      "el jugo / el zumo",
      "la papa / la patata",
      "t\xFA tienes / vos ten\xE9s / usted tiene",
      "vosotros habl\xE1is / ustedes hablan",
      "vos habl\xE1s / com\xE9s / viv\xEDs"
    ],
    "lesson-c2-3-1": [
      "solicitar / pedir",
      "adquirir / conseguir",
      "comenzar / empezar",
      "no obstante / pero",
      "cabe destacar que...",
      "dicho esto...",
      "por ende...",
      "se + verbo impersonal"
    ],
    "lesson-c2-4-1": [
      "la met\xE1fora",
      "el s\xEDmil",
      "la hip\xE9rbole",
      "la iron\xEDa",
      "la personificaci\xF3n",
      "la an\xE1fora",
      "la pregunta ret\xF3rica",
      "la ant\xEDtesis"
    ],
    "lesson-c2-5-1": [
      "se entiende por...",
      "en virtud de...",
      "presenta s\xEDntomas de...",
      "el diagn\xF3stico indica...",
      "seg\xFAn el presupuesto...",
      "la inversi\xF3n supone...",
      "en t\xE9rminos t\xE9cnicos...",
      "en lenguaje llano..."
    ],
    "lesson-c2-6-1": [
      "delgado / flaco / esquel\xE9tico",
      "barato / econ\xF3mico / cutre",
      "bonito / lindo / hermoso",
      "sugerir / insistir / exigir",
      "ser / estar",
      "por / para",
      "indicativo / subjuntivo",
      "literal / ir\xF3nico"
    ],
    "lesson-c2-7-1": [
      "A mal tiempo, buena cara",
      "M\xE1s vale tarde que nunca",
      "Buen provecho / Que aproveche",
      "Lo siento mucho",
      "Mi m\xE1s sentido p\xE9same",
      "\xA1Salud!",
      "brindemos por...",
      "\xBFnos tuteamos?"
    ],
    "lesson-c2-8-1": [
      "o sea...",
      "pues...",
      "es que...",
      "a ver...",
      "total, que...",
      "resulta que...",
      "digo / quiero decir...",
      "mejor dicho..."
    ]
  });
  var MANUAL_C1_C2_AGENDAS = Object.freeze({
    "lesson-c1-1-2": agenda3(
      "C1",
      [
        "espero que...",
        "ojal\xE1...",
        "me alegra que...",
        "lamento que...",
        "es posible que...",
        "no creo que...",
        "conviene que..."
      ],
      "Express hopes, emotional reactions, reservations, and advice about a friend's plans",
      ["Espero que te vaya bien", "No creo que sea f\xE1cil, pero conviene que lo intentes"],
      "Present three decisions a friend is considering; elicit a connected response containing a hope, reaction, reservation, and recommendation",
      "The learner uses at least five target frames, maintains subjunctive control, and distinguishes emotion, possibility, doubt, and advice"
    ),
    "lesson-c1-1-3": agenda3(
      "C1",
      [
        "aunque es...",
        "aunque sea...",
        "cuando tenga...",
        "para que...",
        "sin que...",
        "a menos que...",
        "siempre que..."
      ],
      "Negotiate a plan while choosing mood to distinguish facts, possibilities, purposes, and conditions",
      ["Aunque es caro, iremos", "Aunque sea caro, iremos", "Iremos cuando tengamos tiempo"],
      "Negotiate a shared plan with one known obstacle and two uncertain conditions; require the learner to explain each indicative or subjunctive choice",
      "The learner completes the plan with at least five frames and explains how mood changes certainty or communicative intent"
    ),
    "lesson-c1-2-2": agenda3(
      "C1",
      [
        "quisiera...",
        "me gustar\xEDa que...",
        "\xBFser\xEDa posible que...?",
        "preferir\xEDa que...",
        "le agradecer\xEDa que...",
        "ojal\xE1 pudiera...",
        "si no fuera mucha molestia..."
      ],
      "Make and negotiate delicate requests with an appropriate degree of distance and politeness",
      ["Quisiera cambiar la fecha", "Si no fuera mucha molestia, le agradecer\xEDa que lo revisara"],
      "Role-play requesting three changes from a landlord, professor, or manager; vary urgency, power distance, and degree of imposition",
      "The learner uses at least five softening frames and adjusts formality without making the request unclear"
    ),
    "lesson-c1-2-3": agenda3(
      "C1",
      [
        "ojal\xE1 hubiera...",
        "si hubiera..., habr\xEDa...",
        "me arrepiento de haber...",
        "lament\xE9 que...",
        "como si nada hubiera pasado...",
        "de haber sabido...",
        "habr\xEDa preferido que..."
      ],
      "Reflect on an unreal past by connecting regret, consequence, and an alternative course of action",
      ["De haberlo sabido, habr\xEDa actuado de otra manera", "Ojal\xE1 hubiera pedido ayuda"],
      "Give the learner a consequential past decision; elicit what happened, what they regret, an unreal alternative, and its likely result",
      "The learner produces a coherent reflection with at least five frames and keeps past time relationships clear"
    ),
    "lesson-c1-3-2": agenda3(
      "C1",
      [
        "si pudiera...",
        "si tuviera...",
        "de ser as\xED...",
        "en caso de que...",
        "siempre que...",
        "a condici\xF3n de que...",
        "salvo que..."
      ],
      "Evaluate a difficult proposal by setting hypothetical conditions, safeguards, and exceptions",
      ["De ser as\xED, lo aceptar\xEDa", "Estar\xEDa de acuerdo siempre que hubiera garant\xEDas"],
      "Present a proposal with benefits and risks; require acceptance, rejection, or revision under at least three explicit conditions",
      "The learner uses at least five conditional frames and makes the relationship between condition and consequence unambiguous"
    ),
    "lesson-c1-3-3": agenda3(
      "C1",
      [
        "si hubiera..., habr\xEDa...",
        "de haber...",
        "si no fuera por...",
        "aun si...",
        "suponiendo que...",
        "siempre y cuando...",
        "en el supuesto de que..."
      ],
      "Reason across past and present time frames to explain how one changed condition would affect an outcome",
      ["Si hubiera aceptado, ahora estar\xEDa all\xED", "Aun si lo hubi\xE9ramos sabido, no habr\xEDa cambiado nada"],
      "Analyze a past decision with a present consequence, test two counterfactual alternatives, and defend the most plausible one",
      "The learner produces at least three logically consistent condition\u2013result chains using five or more target frames"
    ),
    "lesson-c1-4-2": agenda3(
      "C1",
      [
        "echar de menos",
        "tener ganas de",
        "darse cuenta de",
        "ponerse las pilas",
        "dar igual",
        "tomar el pelo",
        "no tener pelos en la lengua"
      ],
      "Use idioms naturally in an informal conversation without forcing or misregistering them",
      ["Me di cuenta de que me estaba tomando el pelo", "Tendremos que ponernos las pilas"],
      "Role-play catching up with a friend about work, relationships, and plans; introduce contexts that naturally license the idioms",
      "The learner uses at least five idioms with the intended meaning and keeps the overall conversation natural"
    ),
    "lesson-c1-4-3": agenda3(
      "C1",
      [
        "no dar pie con bola",
        "quedarse de piedra",
        "estar entre la espada y la pared",
        "ir al grano",
        "salir por la tangente",
        "ser la gota que colma el vaso",
        "dar en el clavo"
      ],
      "Infer unfamiliar idioms from context and use them to retell a conflict with precise figurative meaning",
      ["Me qued\xE9 de piedra", "Su respuesta fue la gota que colm\xF3 el vaso"],
      "Present a short conflict containing four idioms, ask the learner to infer them, then retell and resolve the conflict using five target idioms",
      "The learner explains the figurative meanings and uses at least five idioms consistently in the retelling",
      { kind: "comprehension", evidenceType: "infer_and_reproduce" }
    ),
    "lesson-c1-5-2": agenda3(
      "C1",
      [
        "sostengo que...",
        "la evidencia muestra que...",
        "seg\xFAn...",
        "esto se debe a...",
        "sin embargo...",
        "una limitaci\xF3n es...",
        "por lo tanto..."
      ],
      "Defend an academic claim with evidence, causal reasoning, a limitation, and a qualified conclusion",
      ["La evidencia muestra que...", "Sin embargo, una limitaci\xF3n es..."],
      "Provide a research question and two short findings; elicit a thesis defense that cites both findings and acknowledges one limitation",
      "The learner develops a traceable claim\u2013evidence\u2013reasoning chain with at least five target frames"
    ),
    "lesson-c1-5-3": agenda3(
      "C1",
      [
        "el autor sostiene que...",
        "se basa en...",
        "presupone que...",
        "no distingue entre...",
        "en cambio...",
        "puede interpretarse como...",
        "en s\xEDntesis..."
      ],
      "Analyze and paraphrase a dense argument while separating its claim, assumptions, evidence, and limitations",
      ["El autor sostiene que...", "El argumento presupone que..."],
      "Present a short abstract; ask for a plain-language paraphrase, one hidden assumption, one limitation, and an objective synthesis",
      "The learner preserves the source claim, identifies a defensible assumption or limitation, and uses at least five frames",
      { kind: "comprehension", evidenceType: "paraphrase_and_evaluate" }
    ),
    "lesson-c1-6-2": agenda3(
      "C1",
      [
        "\xBFser\xEDa posible...?",
        "debido a...",
        "propongo reprogramar...",
        "\xBFle vendr\xEDa bien...?",
        "confirmo que...",
        "quedo pendiente de...",
        "disculpe las molestias..."
      ],
      "Reschedule a professional commitment while explaining the constraint, offering options, and confirming next steps",
      ["Debido a un imprevisto, propongo reprogramar la reuni\xF3n", "\xBFLe vendr\xEDa bien el jueves?"],
      "Role-play a call or exchange in which the learner must reschedule, offer two viable alternatives, respond to a constraint, and confirm",
      "The learner completes the rescheduling with at least five frames, appropriate formality, and a mutually clear outcome"
    ),
    "lesson-c1-6-3": agenda3(
      "C1",
      [
        "nuestro objetivo es...",
        "propongo que...",
        "\xBFqu\xE9 opinan?",
        "entiendo su preocupaci\xF3n...",
        "para resumir...",
        "quedamos en que...",
        "el siguiente paso ser\xE1..."
      ],
      "Lead a concise planning meeting by framing the goal, eliciting views, resolving a concern, and assigning next steps",
      ["Nuestro objetivo es acordar prioridades", "Quedamos en que el siguiente paso ser\xE1..."],
      "Simulate a meeting with competing priorities; require an opening, input invitation, response to disagreement, summary, and action assignment",
      "The learner leads all five meeting stages and uses at least five frames with clear ownership and deadlines"
    ),
    "lesson-c1-7-2": agenda3(
      "C1",
      [
        "mi tesis es que...",
        "la evidencia principal es...",
        "por ejemplo...",
        "esto demuestra que...",
        "concedo que...",
        "sin embargo...",
        "por lo tanto..."
      ],
      "Build a persuasive argument with a thesis, relevant evidence, explanation, concession, and conclusion",
      ["Mi tesis es que...", "Concedo que existe un riesgo; sin embargo..."],
      "Give a debatable claim and three evidence cards of unequal strength; require the learner to select, explain, concede, and conclude",
      "The learner constructs a coherent argument, uses evidence rather than assertion, and deploys at least five frames"
    ),
    "lesson-c1-7-3": agenda3(
      "C1",
      [
        "entiendo el argumento de que...",
        "si bien...",
        "no obstante...",
        "esa conclusi\xF3n presupone que...",
        "los datos no demuestran que...",
        "una explicaci\xF3n alternativa es...",
        "por eso mantengo que..."
      ],
      "Rebut an opposing position fairly by conceding its strongest point and challenging its evidence or assumption",
      ["Si bien el argumento es v\xE1lido en parte...", "Una explicaci\xF3n alternativa es..."],
      "Present a strong opposing argument; require a fair summary, concession, critique of one assumption or inference, alternative explanation, and position",
      "The learner avoids distortion, addresses the argument's logic, and uses at least five rebuttal frames"
    ),
    "lesson-c1-8-2": agenda3(
      "C1",
      [
        "se suele...",
        "tiende a...",
        "a diferencia de...",
        "mientras que...",
        "esto refleja...",
        "desde esta perspectiva...",
        "no se puede generalizar..."
      ],
      "Compare two cultural practices while interpreting values and explicitly limiting generalizations",
      ["A diferencia de..., se suele...", "Esto refleja..., aunque no se puede generalizar"],
      "Provide two accounts of a social practice; ask for similarities, differences, possible values, and a caution against stereotyping",
      "The learner makes a supported comparison using at least five frames and distinguishes observations from generalizations"
    ),
    "lesson-c1-8-3": agenda3(
      "C1",
      [
        "el texto da por sentado que...",
        "refleja la perspectiva de...",
        "omite...",
        "puede interpretarse como...",
        "conviene distinguir entre...",
        "no todas las personas...",
        "en su contexto..."
      ],
      "Identify cultural assumptions in a text and offer a contextualized interpretation without essentializing a group",
      ["El texto da por sentado que...", "Conviene distinguir entre la pr\xE1ctica y el estereotipo"],
      "Present a short culturally situated article; require an assumption, omitted perspective, contextual factor, and revised interpretation",
      "The learner supports each inference from the text and uses at least five frames without treating a group as uniform",
      { kind: "comprehension", evidenceType: "critical_interpretation" }
    ),
    "lesson-c1-9-2": agenda3(
      "C1",
      [
        "el narrador sugiere que...",
        "la imagen evoca...",
        "el tono pasa de... a...",
        "el s\xEDmbolo representa...",
        "la met\xE1fora refuerza...",
        "el contraste entre... y...",
        "el ritmo crea..."
      ],
      "Interpret a literary passage by linking specific stylistic choices to meaning and reader effect",
      ["La imagen evoca...", "El contraste refuerza la sensaci\xF3n de..."],
      "Present a short passage; ask the learner to identify three devices, cite their textual basis, and explain their combined effect",
      "The learner makes at least three evidence-based interpretations and uses five or more analytical frames",
      { kind: "comprehension", evidenceType: "textual_analysis" }
    ),
    "lesson-c1-9-3": agenda3(
      "C1",
      [
        "a diferencia de...",
        "mientras que...",
        "ambos textos...",
        "en el primer texto...",
        "en el segundo...",
        "esta elecci\xF3n produce...",
        "en conjunto..."
      ],
      "Compare two authors' styles and defend which choices create the stronger effect",
      ["Ambos textos tratan..., mientras que...", "Esta elecci\xF3n produce un efecto m\xE1s..."],
      "Provide two short treatments of the same event; require comparison of voice, imagery, rhythm, and effect with a justified judgment",
      "The learner supports the comparison with details from both texts and uses at least five frames",
      { kind: "comprehension", evidenceType: "comparative_analysis" }
    ),
    "lesson-c1-10-2": agenda3(
      "C1",
      [
        "para empezar...",
        "el punto central es...",
        "por una parte...",
        "ahora bien...",
        "esto se debe a...",
        "por consiguiente...",
        "en definitiva..."
      ],
      "Deliver a structured extended opinion whose progression remains clear from thesis through qualification to conclusion",
      ["El punto central es...", "Ahora bien, conviene considerar..."],
      "Ask for a two-minute response to a complex question with an opening thesis, two linked reasons, one qualification, and conclusion",
      "The learner sustains a traceable structure, uses at least five markers accurately, and avoids list-like disconnected speech"
    ),
    "lesson-c1-10-3": agenda3(
      "C1",
      [
        "en s\xEDntesis...",
        "en otras palabras...",
        "respecto a...",
        "dicho esto...",
        "conviene matizar que...",
        "de ah\xED que...",
        "en \xFAltima instancia..."
      ],
      "Synthesize a complex discussion, reformulate its key point, and preserve an important qualification",
      ["En otras palabras...", "Conviene matizar que..."],
      "Present two related positions and one exception; require a concise synthesis for an audience that has not heard the discussion",
      "The learner accurately combines both positions, retains the exception, and uses at least five cohesive frames",
      { kind: "mediation", evidenceType: "synthesize_and_reframe" }
    ),
    "lesson-c2-1-2": agenda3(
      "C2",
      [
        "no tener pelos en la lengua",
        "tomar el pelo",
        "estar hecho polvo",
        "ni de broma",
        "\xA1qu\xE9 va!",
        "me da igual",
        "a fin de cuentas..."
      ],
      "Sustain an idiomatic informal exchange while interpreting figurative intent and avoiding register clashes",
      ["\xA1Qu\xE9 va, ni de broma!", "A fin de cuentas, me da igual"],
      "Role-play a fast informal exchange involving teasing, refusal, fatigue, and a blunt opinion; ask for one later formal paraphrase",
      "The learner uses at least five idiomatic expressions naturally and accurately reformulates their meaning in neutral Spanish"
    ),
    "lesson-c2-1-3": agenda3(
      "C2",
      [
        "salirse con la suya",
        "andar con pies de plomo",
        "no tener ni pies ni cabeza",
        "dar en el clavo",
        "tirar la casa por la ventana",
        "estar en el ajo",
        "poner el dedo en la llaga"
      ],
      "Infer, explain, and redeploy unfamiliar idioms while preserving their connotation and conversational force",
      ["Hay que andar con pies de plomo", "Has puesto el dedo en la llaga"],
      "Embed five idioms in a story with sufficient contextual clues; require inference, neutral paraphrase, and a new story using the expressions",
      "The learner infers at least four meanings and uses five idioms with the intended connotation in a new context",
      { kind: "comprehension", evidenceType: "infer_paraphrase_and_transfer" }
    ),
    "lesson-c2-2-2": agenda3(
      "C2",
      [
        "vos ten\xE9s / t\xFA tienes",
        "ven\xED / ven",
        "decime / dime",
        "vosotros habl\xE1is / ustedes hablan",
        "\xBFqu\xE9 tal? / \xBFqu\xE9 onda?",
        "vale / \xF3rale / dale",
        "calle: /ka\u029De/ / /ka\u0283e/"
      ],
      "Adapt pronouns, imperatives, vocabulary, and expected pronunciation across three regional interlocutors",
      ["Vos ten\xE9s raz\xF3n; decime qu\xE9 pas\xF3", "Vale, decidme cu\xE1ndo lleg\xE1is"],
      "Simulate exchanges with speakers from the River Plate, Mexico, and Spain; require appropriate recognition and controlled adaptation without caricature",
      "The learner recognizes all seven contrasts and consistently adapts at least five regional choices to the interlocutor"
    ),
    "lesson-c2-2-3": agenda3(
      "C2",
      [
        "vos",
        "t\xFA",
        "usted",
        "vosotros / vosotras",
        "ustedes",
        "computadora / ordenador",
        "carro / coche / auto"
      ],
      "Compare regional systems and choose an appropriate variety and register for each audience",
      ["Con un colega peninsular usar\xEDa...", "En el R\xEDo de la Plata es habitual..."],
      "Present messages from three regions and three relationships; require identification, explanation, and audience-appropriate reformulation",
      "The learner correctly attributes the main regional cues and adapts each message without treating one variety as the default",
      { kind: "mediation", evidenceType: "identify_explain_and_adapt" }
    ),
    "lesson-c2-3-2": agenda3(
      "C2",
      [
        "\xBFme pasas...?",
        "\xBFme har\xEDas el favor de...?",
        "le agradecer\xEDa que...",
        "ser\xEDa conveniente...",
        "cabe se\xF1alar que...",
        "dicho sea de paso...",
        "no obstante..."
      ],
      "Transform the same message across intimate, neutral, professional, and formal registers without changing its core intent",
      ["\xBFMe pasas el documento?", "Le agradecer\xEDa que me remitiera el documento"],
      "Give one request, one disagreement, and one correction; require four audience-specific versions and an explanation of the linguistic changes",
      "The learner produces clearly differentiated registers and explains at least three lexical or grammatical choices"
    ),
    "lesson-c2-3-3": agenda3(
      "C2",
      [
        "como si...",
        "se dir\xEDa que...",
        "convertido / convertida en...",
        "lejos de...",
        "apenas...",
        "no solo... sino...",
        "y, sin embargo..."
      ],
      "Transform a literal description into expressive prose while controlling imagery, rhythm, and restraint",
      ["La ciudad despert\xF3 como si...", "Lejos de callarse, el viento..."],
      "Start with a plain description; require two stylistic versions for different moods, followed by a concise explanation of the effects created",
      "The learner uses at least five frames, creates internally consistent imagery, and can justify the stylistic choices"
    ),
    "lesson-c2-4-2": agenda3(
      "C2",
      [
        "\xBFhasta cu\xE1ndo...?",
        "no se trata de... sino de...",
        "imaginemos por un momento...",
        "todos sabemos que...",
        "si no actuamos...",
        "hoy...; ma\xF1ana...",
        "por eso les propongo..."
      ],
      "Craft a persuasive speech using rhetorical devices strategically rather than decoratively",
      ["No se trata de elegir entre..., sino de...", "\xBFHasta cu\xE1ndo aceptaremos...?"],
      "Assign a public issue and audience; require a hook, contrast, image, objection, and call to action in a short speech",
      "The learner uses at least five frames, matches devices to persuasive purpose, and maintains a coherent argument"
    ),
    "lesson-c2-4-3": agenda3(
      "C2",
      [
        "el autor apela a...",
        "la repetici\xF3n enfatiza...",
        "la met\xE1fora presenta... como...",
        "esta formulaci\xF3n oculta...",
        "el efecto buscado es...",
        "resulta persuasivo porque...",
        "sin embargo, pierde fuerza cuando..."
      ],
      "Evaluate how rhetoric shapes an audience while separating persuasive effect from argumentative validity",
      ["La met\xE1fora presenta el problema como...", "Resulta persuasivo; sin embargo..."],
      "Present a short persuasive passage; require device identification, audience effect, hidden assumption, validity judgment, and revised wording",
      "The learner supports the analysis from the text, distinguishes effect from evidence, and uses at least five frames",
      { kind: "comprehension", evidenceType: "rhetorical_evaluation" }
    ),
    "lesson-c2-5-2": agenda3(
      "C2",
      [
        "de conformidad con...",
        "queda sujeto a...",
        "presenta indicios de...",
        "se recomienda realizar...",
        "la partida presupuestaria...",
        "el rendimiento de la inversi\xF3n...",
        "los resultados son compatibles con..."
      ],
      "Use specialized collocations accurately while keeping legal, medical, and financial claims appropriately qualified",
      ["Queda sujeto a las condiciones...", "Los resultados son compatibles con, pero no confirman..."],
      "Provide three short professional cases; require a precise summary of each and correction of deliberately overconfident wording",
      "The learner uses at least five collocations accurately and does not overstate obligation, diagnosis, or certainty"
    ),
    "lesson-c2-5-3": agenda3(
      "C2",
      [
        "en t\xE9rminos t\xE9cnicos...",
        "dicho de forma sencilla...",
        "esto significa que...",
        "no implica necesariamente que...",
        "la consecuencia pr\xE1ctica es...",
        "para un p\xFAblico no especializado...",
        "sin perder precisi\xF3n..."
      ],
      "Mediate a specialized text for an expert and a lay audience without distorting its certainty or practical implications",
      ["Dicho de forma sencilla, esto significa que...", "No implica necesariamente que..."],
      "Give a dense excerpt; require an expert summary, a plain-language explanation, one practical consequence, and one limitation",
      "Both versions preserve the source's meaning and certainty while using audience-appropriate terminology and five target frames",
      { kind: "mediation", evidenceType: "dual_audience_mediation" }
    ),
    "lesson-c2-6-2": agenda3(
      "C2",
      [
        "no es lo mismo... que...",
        "sugiere que...",
        "implica que...",
        "da a entender que...",
        "m\xE1s bien...",
        "hasta cierto punto...",
        "apenas..."
      ],
      "Distinguish fine shades of meaning and explain how a lexical or grammatical choice alters the implied stance",
      ["No lo afirma; m\xE1s bien, da a entender que...", "Es v\xE1lido hasta cierto punto"],
      "Present near-equivalent statements with different connotations; require ranking, interpretation, and context-appropriate selection",
      "The learner explains at least four meaningful distinctions and uses five or more frames without flattening them into synonyms"
    ),
    "lesson-c2-6-3": agenda3(
      "C2",
      [
        "no es que...",
        "dicho sea con reservas...",
        "sin \xE1nimo de...",
        "me temo que...",
        "quiz\xE1 convendr\xEDa...",
        "curiosamente...",
        "con cierta iron\xEDa..."
      ],
      "Deliver the same criticism diplomatically, ironically, and directly, then explain the interpersonal effect of each version",
      ["Sin \xE1nimo de desmerecer el trabajo...", "No es que est\xE9 mal; quiz\xE1 convendr\xEDa..."],
      "Give a sensitive criticism scenario; require three register-and-stance versions for different relationships plus an explanation of risks",
      "The learner creates three clearly distinct effects, uses at least five frames, and accurately explains the implied attitude"
    ),
    "lesson-c2-7-2": agenda3(
      "C2",
      [
        "con permiso...",
        "disculpe que...",
        "\xBFle importa si...?",
        "muchas felicidades",
        "que lo pasen bien",
        "brindemos por...",
        "gracias por recibirme"
      ],
      "Navigate a social occasion by selecting culturally and relationally appropriate openings, wishes, permissions, and closings",
      ["Con permiso, \xBFle importa si...?", "Brindemos por..."],
      "Simulate arrival, a delicate interruption, a toast, and departure at gatherings with different formality levels",
      "The learner completes all four social moves using at least five appropriate expressions and adjusts address consistently"
    ),
    "lesson-c2-7-3": agenda3(
      "C2",
      [
        "como dice el refr\xE1n...",
        "hace referencia a...",
        "en este contexto...",
        "para quien no conozca...",
        "no debe interpretarse literalmente...",
        "equivale aproximadamente a...",
        "conviene evitar..."
      ],
      "Explain a cultural allusion or saying to an outsider while preserving context, connotation, and variation",
      ["Como dice el refr\xE1n..., que en este contexto...", "No debe interpretarse literalmente"],
      "Present a culturally dense exchange; require explanation of two allusions, a cautious cross-cultural equivalent, and advice against one misreading",
      "The learner makes the references accessible without claiming exact equivalence or presenting a practice as universal",
      { kind: "mediation", evidenceType: "cultural_mediation" }
    ),
    "lesson-c2-8-2": agenda3(
      "C2",
      [
        "claro / ya / aj\xE1",
        "exactamente...",
        "bueno, pero...",
        "perdona que te interrumpa...",
        "sigue, sigue...",
        "\xBFme explico?",
        "digo / quiero decir..."
      ],
      "Manage a fast multi-party exchange through backchanneling, polite interruption, clarification, and self-repair",
      ["Perdona que te interrumpa...", "Digo, quiero decir que..."],
      "Simulate an overlapping discussion with topic shifts and one misunderstanding; require the learner to enter, yield, repair, and redirect",
      "The learner performs all four discourse-management moves naturally and uses at least five target expressions"
    ),
    "lesson-c2-8-3": agenda3(
      "C2",
      [
        "a lo que iba...",
        "dicho de otro modo...",
        "no encuentro la palabra, pero...",
        "viene a ser...",
        "en resumidas cuentas...",
        "retomando lo anterior...",
        "el caso es que..."
      ],
      "Sustain spontaneous extended speech by paraphrasing around gaps, repairing structure, and returning smoothly to the main thread",
      ["No encuentro la palabra, pero viene a ser...", "Retomando lo anterior..."],
      "Elicit an unprepared story with two imposed interruptions and one unavailable key word; require recovery and a concise final synthesis",
      "The learner maintains comprehensibility, recovers from all disruptions, and uses at least five discourse-repair frames naturally"
    )
  });

  // ../nosabos/nosabos/src/data/manualPreA1Agendas.js
  var FORM_LABEL_PREFIXES4 = Object.freeze({
    en: "Use in context",
    es: "Usa en contexto",
    pt: "Use em contexto",
    it: "Usa nel contesto",
    fr: "Utilise en contexte",
    de: "Im Kontext verwenden",
    ja: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528"
  });
  var MANUAL_APPLICATION_LABELS = Object.freeze({
    "lesson-pre-a1-1-2": {
      pt: "Identifique e nomeie dois membros da fam\xEDlia extensa",
      it: "Identifica e nomina due membri della famiglia allargata",
      fr: "Identifie et nomme deux membres de la famille \xE9largie",
      de: "Zwei Mitglieder der erweiterten Familie erkennen und benennen",
      ja: "\u89AA\u621A\u30922\u4EBA\u898B\u5206\u3051\u3066\u540D\u524D\u3092\u8A00\u3046",
      hi: "\u0935\u093F\u0938\u094D\u0924\u0943\u0924 \u092A\u0930\u093F\u0935\u093E\u0930 \u0915\u0947 \u0926\u094B \u0938\u0926\u0938\u094D\u092F\u094B\u0902 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u0928\u093E\u092E \u092C\u0924\u093E\u090F\u0902",
      ar: "\u062A\u0639\u0631\u0651\u0641 \u0639\u0644\u0649 \u0641\u0631\u062F\u064A\u0646 \u0645\u0646 \u0627\u0644\u0639\u0627\u0626\u0644\u0629 \u0627\u0644\u0645\u0645\u062A\u062F\u0629 \u0648\u0633\u0645\u0651\u0650\u0647\u0645\u0627",
      zh: "\u8BC6\u522B\u5E76\u8BF4\u51FA\u4E24\u4F4D\u5927\u5BB6\u5EAD\u6210\u5458"
    },
    "lesson-pre-a1-1-3": {
      pt: "Identifique uma pessoa conhecida com mi + palavra de pessoa",
      it: "Identifica una persona conosciuta con mi + parola di persona",
      fr: "Identifie une personne connue avec mi + mot d\xE9signant une personne",
      de: "Eine vertraute Person mit mi + Personenwort benennen",
      ja: "mi\uFF0B\u4EBA\u3092\u8868\u3059\u5358\u8A9E\u3067\u8EAB\u8FD1\u306A\u4EBA\u30921\u4EBA\u793A\u3059",
      hi: "mi + \u0935\u094D\u092F\u0915\u094D\u0924\u093F-\u0938\u0942\u091A\u0915 \u0936\u092C\u094D\u0926 \u0938\u0947 \u0915\u093F\u0938\u0940 \u092A\u0930\u093F\u091A\u093F\u0924 \u0935\u094D\u092F\u0915\u094D\u0924\u093F \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      ar: "\u062D\u062F\u0651\u062F \u0634\u062E\u0635\u064B\u0627 \u0645\u0623\u0644\u0648\u0641\u064B\u0627 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 mi + \u0643\u0644\u0645\u0629 \u062A\u062F\u0644 \u0639\u0644\u0649 \u0634\u062E\u0635",
      zh: "\u7528 mi + \u4EBA\u7269\u8BCD\u6307\u8BA4\u4E00\u4F4D\u719F\u6089\u7684\u4EBA"
    },
    "lesson-pre-a1-2-2": {
      pt: "Reconhe\xE7a e diga quantidades de seis a dez",
      it: "Riconosci e pronuncia quantit\xE0 da sei a dieci",
      fr: "Reconnais et dis des quantit\xE9s de six \xE0 dix",
      de: "Mengen von sechs bis zehn erkennen und nennen",
      ja: "6\u304B\u308910\u307E\u3067\u306E\u6570\u91CF\u3092\u898B\u5206\u3051\u3066\u8A00\u3046",
      hi: "\u091B\u0939 \u0938\u0947 \u0926\u0938 \u0924\u0915 \u0915\u0940 \u092E\u093E\u0924\u094D\u0930\u093E\u0913\u0902 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u092C\u094B\u0932\u0947\u0902",
      ar: "\u062A\u0639\u0631\u0651\u0641 \u0639\u0644\u0649 \u0627\u0644\u0643\u0645\u064A\u0627\u062A \u0645\u0646 \u0633\u062A\u0629 \u0625\u0644\u0649 \u0639\u0634\u0631\u0629 \u0648\u0642\u0644\u0647\u0627",
      zh: "\u8BC6\u522B\u5E76\u8BF4\u51FA\u516D\u5230\u5341\u7684\u6570\u91CF"
    },
    "lesson-pre-a1-2-3": {
      pt: "Responda a \xBFcu\xE1ntos hay? com um n\xFAmero e um objeto",
      it: "Rispondi a \xBFcu\xE1ntos hay? con un numero e un oggetto",
      fr: "R\xE9ponds \xE0 \xBFcu\xE1ntos hay? avec un nombre et un objet",
      de: "\xBFcu\xE1ntos hay? mit einer Zahl und einem Gegenstand beantworten",
      ja: "\xBFcu\xE1ntos hay? \u306B\u6570\u5B57\u3068\u7269\u3067\u7B54\u3048\u308B",
      hi: "\xBFcu\xE1ntos hay? \u0915\u093E \u0909\u0924\u094D\u0924\u0930 \u090F\u0915 \u0938\u0902\u0916\u094D\u092F\u093E \u0914\u0930 \u0935\u0938\u094D\u0924\u0941 \u0938\u0947 \u0926\u0947\u0902",
      ar: "\u0623\u062C\u0628 \u0639\u0646 \xBFcu\xE1ntos hay? \u0628\u0639\u062F\u062F \u0648\u0634\u064A\u0621",
      zh: "\u7528\u6570\u5B57\u548C\u7269\u54C1\u56DE\u7B54 \xBFcu\xE1ntos hay?"
    },
    "lesson-pre-a1-3-2": {
      pt: "Escolha uma despedida para mais tarde hoje ou amanh\xE3",
      it: "Scegli un saluto per pi\xF9 tardi oggi o per domani",
      fr: "Choisis une formule d\u2019au revoir pour plus tard ou demain",
      de: "Eine Verabschiedung f\xFCr sp\xE4ter heute oder morgen w\xE4hlen",
      ja: "\u4ECA\u65E5\u307E\u305F\u306F\u660E\u65E5\u306B\u5408\u3046\u5225\u308C\u306E\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0906\u091C \u092C\u093E\u0926 \u092E\u0947\u0902 \u092F\u093E \u0915\u0932 \u0915\u0947 \u0932\u093F\u090F \u0935\u093F\u0926\u093E\u0908 \u0915\u093E \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0648\u062F\u0627\u0639 \u0644\u0648\u0642\u062A \u0644\u0627\u062D\u0642 \u0627\u0644\u064A\u0648\u0645 \u0623\u0648 \u0644\u0644\u063A\u062F",
      zh: "\u9009\u62E9\u9002\u5408\u4ECA\u5929\u7A0D\u540E\u6216\u660E\u5929\u7684\u544A\u522B\u8BED"
    },
    "lesson-pre-a1-3-3": {
      pt: "Complete uma troca de sauda\xE7\xE3o e bem-estar",
      it: "Completa uno scambio di saluti e domande sul benessere",
      fr: "Compl\xE8te un \xE9change de salutations et de nouvelles",
      de: "Einen Begr\xFC\xDFungs- und Befindlichkeitsaustausch vervollst\xE4ndigen",
      ja: "\u6328\u62F6\u3068\u8ABF\u5B50\u3092\u5C0B\u306D\u308B\u3084\u308A\u53D6\u308A\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0905\u092D\u093F\u0935\u093E\u0926\u0928 \u0914\u0930 \u0939\u093E\u0932-\u091A\u093E\u0932 \u0915\u093E \u0938\u0902\u0935\u093E\u0926 \u092A\u0942\u0930\u093E \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u062A\u0628\u0627\u062F\u0644\u064B\u0627 \u0644\u0644\u062A\u062D\u064A\u0629 \u0648\u0627\u0644\u0633\u0624\u0627\u0644 \u0639\u0646 \u0627\u0644\u062D\u0627\u0644",
      zh: "\u5B8C\u6210\u4E00\u6BB5\u95EE\u5019\u548C\u8BE2\u95EE\u8FD1\u51B5\u7684\u5BF9\u8BDD"
    },
    "lesson-pre-a1-4-2": {
      pt: "Escolha uma frase de d\xFAvida ou falta de compreens\xE3o",
      it: "Scegli una frase per esprimere dubbio o mancata comprensione",
      fr: "Choisis une phrase de doute ou d\u2019incompr\xE9hension",
      de: "Eine Wendung f\xFCr Unsicherheit oder fehlendes Verst\xE4ndnis w\xE4hlen",
      ja: "\u4E0D\u78BA\u304B\u3055\u3084\u7406\u89E3\u3067\u304D\u306A\u3044\u3053\u3068\u3092\u8868\u3059\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0905\u0928\u093F\u0936\u094D\u091A\u093F\u0924\u0924\u093E \u092F\u093E \u0938\u092E\u091D \u0928 \u0906\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0644\u0644\u0634\u0643 \u0623\u0648 \u0644\u0639\u062F\u0645 \u0627\u0644\u0641\u0647\u0645",
      zh: "\u9009\u62E9\u8868\u8FBE\u4E0D\u786E\u5B9A\u6216\u4E0D\u7406\u89E3\u7684\u77ED\u8BED"
    },
    "lesson-pre-a1-4-3": {
      pt: "Reaja naturalmente a uma boa not\xEDcia, uma m\xE1 not\xEDcia e uma instru\xE7\xE3o",
      it: "Reagisci in modo naturale a una buona notizia, una cattiva notizia e un\u2019istruzione",
      fr: "R\xE9agis naturellement \xE0 une bonne nouvelle, une mauvaise nouvelle et une consigne",
      de: "Nat\xFCrlich auf gute Nachrichten, schlechte Nachrichten und eine Anweisung reagieren",
      ja: "\u826F\u3044\u77E5\u3089\u305B\u3001\u60AA\u3044\u77E5\u3089\u305B\u3001\u6307\u793A\u306B\u81EA\u7136\u306B\u53CD\u5FDC\u3059\u308B",
      hi: "\u0905\u091A\u094D\u091B\u0940 \u0916\u092C\u0930, \u092C\u0941\u0930\u0940 \u0916\u092C\u0930 \u0914\u0930 \u0928\u093F\u0930\u094D\u0926\u0947\u0936 \u092A\u0930 \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u092A\u094D\u0930\u0924\u093F\u0915\u094D\u0930\u093F\u092F\u093E \u0926\u0947\u0902",
      ar: "\u062A\u0641\u0627\u0639\u0644 \u0628\u0635\u0648\u0631\u0629 \u0637\u0628\u064A\u0639\u064A\u0629 \u0645\u0639 \u062E\u0628\u0631 \u062C\u064A\u062F \u0648\u062E\u0628\u0631 \u0633\u064A\u0626 \u0648\u062A\u0639\u0644\u064A\u0645\u0627\u062A",
      zh: "\u81EA\u7136\u56DE\u5E94\u597D\u6D88\u606F\u3001\u574F\u6D88\u606F\u548C\u6307\u4EE4"
    },
    "lesson-pre-a1-5-2": {
      pt: "Escolha uma desculpa ou frase para chamar a aten\xE7\xE3o conforme a situa\xE7\xE3o",
      it: "Scegli una scusa o una frase per richiamare l\u2019attenzione adatta alla situazione",
      fr: "Choisis une excuse ou une formule pour attirer l\u2019attention selon la situation",
      de: "Eine passende Entschuldigung oder Aufmerksamkeitsformel w\xE4hlen",
      ja: "\u72B6\u6CC1\u306B\u5408\u3046\u8B1D\u7F6A\u307E\u305F\u306F\u547C\u3073\u304B\u3051\u306E\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0938\u094D\u0925\u093F\u0924\u093F \u0915\u0947 \u0905\u0928\u0941\u0938\u093E\u0930 \u092E\u093E\u092B\u093C\u0940 \u092F\u093E \u0927\u094D\u092F\u093E\u0928 \u0906\u0915\u0930\u094D\u0937\u093F\u0924 \u0915\u0930\u0928\u0947 \u0935\u093E\u0932\u093E \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0627\u0639\u062A\u0630\u0627\u0631 \u0623\u0648 \u0644\u0641\u062A \u0627\u0646\u062A\u0628\u0627\u0647 \u062A\u0646\u0627\u0633\u0628 \u0627\u0644\u0645\u0648\u0642\u0641",
      zh: "\u6839\u636E\u60C5\u5883\u9009\u62E9\u9053\u6B49\u8BED\u6216\u5F15\u8D77\u6CE8\u610F\u7684\u77ED\u8BED"
    },
    "lesson-pre-a1-5-3": {
      pt: "Complete dois pares diferentes de agradecimento e resposta",
      it: "Completa due coppie diverse di ringraziamento e risposta",
      fr: "Compl\xE8te deux \xE9changes diff\xE9rents de remerciement et de r\xE9ponse",
      de: "Zwei verschiedene Dankes- und Antwortpaare vervollst\xE4ndigen",
      ja: "\u7570\u306A\u308B\u611F\u8B1D\u3068\u8FD4\u7B54\u306E\u7D44\u307F\u5408\u308F\u305B\u30922\u3064\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0927\u0928\u094D\u092F\u0935\u093E\u0926 \u0914\u0930 \u0909\u0924\u094D\u0924\u0930 \u0915\u0947 \u0926\u094B \u0905\u0932\u0917-\u0905\u0932\u0917 \u091C\u094B\u0921\u093C\u0947 \u092A\u0942\u0930\u0947 \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u0632\u0648\u062C\u064A\u0646 \u0645\u062E\u062A\u0644\u0641\u064A\u0646 \u0645\u0646 \u0627\u0644\u0634\u0643\u0631 \u0648\u0627\u0644\u0631\u062F",
      zh: "\u5B8C\u6210\u4E24\u7EC4\u4E0D\u540C\u7684\u611F\u8C22\u4E0E\u56DE\u5E94"
    },
    "lesson-pre-a1-6-2": {
      pt: "Identifique qual objeto pessoal est\xE1 presente ou ausente",
      it: "Identifica quale oggetto personale \xE8 presente o manca",
      fr: "Identifie l\u2019objet personnel pr\xE9sent ou manquant",
      de: "Erkennen, welcher pers\xF6nliche Gegenstand vorhanden ist oder fehlt",
      ja: "\u3042\u308B\u6301\u3061\u7269\u3068\u306A\u3044\u6301\u3061\u7269\u3092\u898B\u5206\u3051\u308B",
      hi: "\u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0915\u093F \u0915\u094C\u0928-\u0938\u0940 \u0928\u093F\u091C\u0940 \u0935\u0938\u094D\u0924\u0941 \u092E\u094C\u091C\u0942\u0926 \u0939\u0948 \u092F\u093E \u0917\u093E\u092F\u092C \u0939\u0948",
      ar: "\u062D\u062F\u0651\u062F \u0627\u0644\u063A\u0631\u0636 \u0627\u0644\u0634\u062E\u0635\u064A \u0627\u0644\u0645\u0648\u062C\u0648\u062F \u0623\u0648 \u0627\u0644\u0645\u0641\u0642\u0648\u062F",
      zh: "\u8BC6\u522B\u54EA\u4EF6\u4E2A\u4EBA\u7269\u54C1\u5B58\u5728\u6216\u7F3A\u5931"
    },
    "lesson-pre-a1-6-3": {
      pt: "Pe\xE7a uma comida e uma bebida usando por favor",
      it: "Ordina un cibo e una bevanda usando por favor",
      fr: "Commande un aliment et une boisson avec por favor",
      de: "Ein Essen und ein Getr\xE4nk mit por favor bestellen",
      ja: "por favor \u3092\u4F7F\u3063\u3066\u98DF\u3079\u7269\u3068\u98F2\u307F\u7269\u30921\u3064\u305A\u3064\u6CE8\u6587\u3059\u308B",
      hi: "por favor \u0915\u0947 \u0938\u093E\u0925 \u090F\u0915 \u0916\u093E\u0926\u094D\u092F \u0935\u0938\u094D\u0924\u0941 \u0914\u0930 \u090F\u0915 \u092A\u0947\u092F \u092E\u0902\u0917\u093E\u090F\u0902",
      ar: "\u0627\u0637\u0644\u0628 \u0637\u0639\u0627\u0645\u064B\u0627 \u0648\u0634\u0631\u0627\u0628\u064B\u0627 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 por favor",
      zh: "\u7528 por favor \u70B9\u4E00\u79CD\u98DF\u7269\u548C\u4E00\u79CD\u996E\u6599"
    },
    "lesson-pre-a1-7-2": {
      pt: "Identifique quatro cores adicionais em objetos conhecidos",
      it: "Identifica quattro colori aggiuntivi su oggetti familiari",
      fr: "Identifie quatre couleurs suppl\xE9mentaires sur des objets familiers",
      de: "Vier weitere Farben an vertrauten Gegenst\xE4nden erkennen",
      ja: "\u8EAB\u8FD1\u306A\u7269\u306B\u3042\u308B4\u3064\u306E\u8FFD\u52A0\u306E\u8272\u3092\u898B\u5206\u3051\u308B",
      hi: "\u092A\u0930\u093F\u091A\u093F\u0924 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u092A\u0930 \u091A\u093E\u0930 \u0905\u0924\u093F\u0930\u093F\u0915\u094D\u0924 \u0930\u0902\u0917 \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      ar: "\u062D\u062F\u0651\u062F \u0623\u0631\u0628\u0639\u0629 \u0623\u0644\u0648\u0627\u0646 \u0625\u0636\u0627\u0641\u064A\u0629 \u0639\u0644\u0649 \u0623\u0634\u064A\u0627\u0621 \u0645\u0623\u0644\u0648\u0641\u0629",
      zh: "\u8BC6\u522B\u719F\u6089\u7269\u54C1\u4E0A\u7684\u56DB\u79CD\u5176\u4ED6\u989C\u8272"
    },
    "lesson-pre-a1-7-3": {
      pt: "Escolha e nomeie uma cor neutra",
      it: "Scegli e nomina un colore neutro",
      fr: "Choisis et nomme une couleur neutre",
      de: "Eine neutrale Farbe w\xE4hlen und benennen",
      ja: "\u4E2D\u9593\u8272\u3092\u9078\u3093\u3067\u540D\u524D\u3092\u8A00\u3046",
      hi: "\u090F\u0915 \u0924\u091F\u0938\u094D\u0925 \u0930\u0902\u0917 \u091A\u0941\u0928\u0947\u0902 \u0914\u0930 \u0909\u0938\u0915\u093E \u0928\u093E\u092E \u092C\u0924\u093E\u090F\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0644\u0648\u0646\u064B\u0627 \u0645\u062D\u0627\u064A\u062F\u064B\u0627 \u0648\u0627\u0630\u0643\u0631 \u0627\u0633\u0645\u0647",
      zh: "\u9009\u62E9\u5E76\u8BF4\u51FA\u4E00\u79CD\u4E2D\u6027\u8272"
    },
    "lesson-pre-a1-8-2": {
      pt: "Pergunte o nome de um colega e de um adulto",
      it: "Chiedi il nome a un coetaneo e a un adulto",
      fr: "Demande son nom \xE0 un camarade et \xE0 un adulte",
      de: "Einen Gleichaltrigen und einen Erwachsenen nach dem Namen fragen",
      ja: "\u540C\u5E74\u4EE3\u306E\u4EBA\u3068\u5927\u4EBA\u306B\u540D\u524D\u3092\u5C0B\u306D\u308B",
      hi: "\u0915\u093F\u0938\u0940 \u0939\u092E\u0909\u092E\u094D\u0930 \u0914\u0930 \u0915\u093F\u0938\u0940 \u0935\u092F\u0938\u094D\u0915 \u0938\u0947 \u0909\u0928\u0915\u093E \u0928\u093E\u092E \u092A\u0942\u091B\u0947\u0902",
      ar: "\u0627\u0633\u0623\u0644 \u0634\u062E\u0635\u064B\u0627 \u0645\u0646 \u0623\u0642\u0631\u0627\u0646\u0643 \u0648\u0634\u062E\u0635\u064B\u0627 \u0628\u0627\u0644\u063A\u064B\u0627 \u0639\u0646 \u0627\u0633\u0645\u0647\u0645\u0627",
      zh: "\u8BE2\u95EE\u540C\u9F84\u4EBA\u548C\u6210\u5E74\u4EBA\u7684\u59D3\u540D"
    },
    "lesson-pre-a1-8-3": {
      pt: "Complete duas trocas de prazer em conhecer",
      it: "Completa due scambi per dire piacere di conoscerti",
      fr: "Compl\xE8te deux \xE9changes pour dire enchant\xE9",
      de: "Zwei Kennenlern-Austausche vervollst\xE4ndigen",
      ja: "\u300C\u306F\u3058\u3081\u307E\u3057\u3066\u300D\u306E\u3084\u308A\u53D6\u308A\u30922\u3064\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u092E\u093F\u0932\u0915\u0930 \u0916\u0941\u0936\u0940 \u0939\u0941\u0908 \u0935\u093E\u0932\u0947 \u0926\u094B \u0938\u0902\u0935\u093E\u0926 \u092A\u0942\u0930\u0947 \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u062D\u0648\u0627\u0631\u064A\u0646 \u0644\u0644\u062A\u0639\u0628\u064A\u0631 \u0639\u0646 \u0633\u0631\u0648\u0631 \u0627\u0644\u0644\u0642\u0627\u0621",
      zh: "\u5B8C\u6210\u4E24\u6BB5\u201C\u5F88\u9AD8\u5174\u8BA4\u8BC6\u4F60\u201D\u7684\u5BF9\u8BDD"
    },
    "lesson-a1-1-2": {
      pt: "Complete um encontro de quatro turnos com as frases exigidas",
      it: "Completa un incontro di quattro turni con le frasi richieste",
      fr: "Compl\xE8te une rencontre en quatre tours avec les phrases demand\xE9es",
      de: "Ein Kennenlernen in vier Gespr\xE4chsz\xFCgen mit den vorgegebenen Wendungen abschlie\xDFen",
      ja: "\u6307\u5B9A\u3055\u308C\u305F\u8868\u73FE\u30674\u30BF\u30FC\u30F3\u306E\u521D\u5BFE\u9762\u4F1A\u8A71\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0906\u0935\u0936\u094D\u092F\u0915 \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936\u094B\u0902 \u0915\u0947 \u0938\u093E\u0925 \u091A\u093E\u0930 \u092C\u093E\u0930\u0940 \u0915\u0940 \u092E\u0941\u0932\u093E\u0915\u093E\u0924 \u092A\u0942\u0930\u0940 \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u0644\u0642\u0627\u0621\u064B \u0645\u0646 \u0623\u0631\u0628\u0639 \u0645\u062F\u0627\u062E\u0644\u0627\u062A \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0627\u0644\u0639\u0628\u0627\u0631\u0627\u062A \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629",
      zh: "\u4F7F\u7528\u6307\u5B9A\u77ED\u8BED\u5B8C\u6210\u56DB\u8F6E\u521D\u6B21\u89C1\u9762\u5BF9\u8BDD"
    },
    "lesson-a1-1-3": {
      pt: "Escolha linguagem informal ou cort\xEAs para dois primeiros encontros",
      it: "Scegli un linguaggio informale o cortese per due primi incontri",
      fr: "Choisis un registre familier ou poli pour deux premi\xE8res rencontres",
      de: "F\xFCr zwei erste Begegnungen lockere oder h\xF6fliche Sprache w\xE4hlen",
      ja: "2\u3064\u306E\u521D\u5BFE\u9762\u5834\u9762\u3067\u304F\u3060\u3051\u305F\u8868\u73FE\u304B\u4E01\u5BE7\u306A\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0926\u094B \u092A\u0939\u0932\u0940 \u092E\u0941\u0932\u093E\u0915\u093E\u0924\u094B\u0902 \u0915\u0947 \u0932\u093F\u090F \u0905\u0928\u094C\u092A\u091A\u093E\u0930\u093F\u0915 \u092F\u093E \u0935\u093F\u0928\u092E\u094D\u0930 \u092D\u093E\u0937\u093E \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0644\u063A\u0629 \u0639\u0641\u0648\u064A\u0629 \u0623\u0648 \u0645\u0647\u0630\u0628\u0629 \u0644\u0645\u0648\u0642\u0641\u064A\u0646 \u0645\u0646 \u0627\u0644\u0644\u0642\u0627\u0621 \u0627\u0644\u0623\u0648\u0644",
      zh: "\u4E3A\u4E24\u4E2A\u521D\u6B21\u89C1\u9762\u573A\u666F\u9009\u62E9\u968F\u610F\u6216\u793C\u8C8C\u7684\u8868\u8FBE"
    },
    "lesson-a1-3-2": {
      pt: "Use os n\xFAmeros 11\u201330 para quantidades e um pre\xE7o",
      it: "Usa i numeri 11\u201330 per quantit\xE0 e un prezzo",
      fr: "Utilise les nombres 11\u201330 pour des quantit\xE9s et un prix",
      de: "Die Zahlen 11\u201330 f\xFCr Mengen und einen Preis verwenden",
      ja: "11\uFF5E30\u306E\u6570\u5B57\u3092\u6570\u91CF\u3068\u4FA1\u683C\u306B\u4F7F\u3046",
      hi: "\u092E\u093E\u0924\u094D\u0930\u093E\u0913\u0902 \u0914\u0930 \u090F\u0915 \u0915\u0940\u092E\u0924 \u0915\u0947 \u0932\u093F\u090F 11\u201330 \u0915\u0940 \u0938\u0902\u0916\u094D\u092F\u093E\u0913\u0902 \u0915\u093E \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
      ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0623\u0639\u062F\u0627\u062F 11\u201330 \u0644\u0644\u0643\u0645\u064A\u0627\u062A \u0648\u0644\u0633\u0639\u0631 \u0648\u0627\u062D\u062F",
      zh: "\u4F7F\u752811\u201330\u8868\u793A\u6570\u91CF\u548C\u4E00\u4E2A\u4EF7\u683C"
    },
    "lesson-a1-3-3": {
      pt: "Pergunte e diga uma idade e um n\xFAmero de telefone curto",
      it: "Chiedi e comunica un\u2019et\xE0 e un breve numero di telefono",
      fr: "Demande et donne un \xE2ge et un num\xE9ro de t\xE9l\xE9phone court",
      de: "Nach einem Alter und einer kurzen Telefonnummer fragen und beides angeben",
      ja: "\u5E74\u9F62\u3068\u77ED\u3044\u96FB\u8A71\u756A\u53F7\u3092\u5C0B\u306D\u3066\u7B54\u3048\u308B",
      hi: "\u0909\u092E\u094D\u0930 \u0914\u0930 \u091B\u094B\u091F\u093E \u092B\u093C\u094B\u0928 \u0928\u0902\u092C\u0930 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u092C\u0924\u093E\u090F\u0902",
      ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0639\u0645\u0631 \u0648\u0631\u0642\u0645 \u0647\u0627\u062A\u0641 \u0642\u0635\u064A\u0631 \u0648\u0627\u0630\u0643\u0631\u0647\u0645\u0627",
      zh: "\u8BE2\u95EE\u5E76\u8BF4\u51FA\u5E74\u9F84\u548C\u7B80\u77ED\u7535\u8BDD\u53F7\u7801"
    },
    "lesson-a1-4-2": {
      pt: "Pergunte um pre\xE7o e entenda o total e o troco",
      it: "Chiedi un prezzo e comprendi il totale e il resto",
      fr: "Demande un prix et comprends le total et la monnaie",
      de: "Nach einem Preis fragen und Gesamtbetrag und Wechselgeld verstehen",
      ja: "\u4FA1\u683C\u3092\u5C0B\u306D\u3001\u5408\u8A08\u3068\u304A\u91E3\u308A\u3092\u7406\u89E3\u3059\u308B",
      hi: "\u0915\u0940\u092E\u0924 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u0915\u0941\u0932 \u0930\u093E\u0936\u093F \u0935 \u092C\u093E\u0915\u0940 \u092A\u0948\u0938\u0947 \u0938\u092E\u091D\u0947\u0902",
      ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0627\u0644\u0633\u0639\u0631 \u0648\u0627\u0641\u0647\u0645 \u0627\u0644\u0645\u062C\u0645\u0648\u0639 \u0648\u0627\u0644\u0628\u0627\u0642\u064A",
      zh: "\u8BE2\u95EE\u4EF7\u683C\u5E76\u7406\u89E3\u603B\u4EF7\u548C\u627E\u96F6"
    },
    "lesson-a1-4-3": {
      pt: "Associe os n\xFAmeros 31\u2013100 a pontua\xE7\xF5es, pessoas, pre\xE7os e objetos",
      it: "Abbina i numeri 31\u2013100 a punteggi, persone, prezzi e oggetti",
      fr: "Associe les nombres 31\u2013100 \xE0 des scores, personnes, prix et objets",
      de: "Die Zahlen 31\u2013100 Punkten, Personen, Preisen und Gegenst\xE4nden zuordnen",
      ja: "31\uFF5E100\u306E\u6570\u5B57\u3092\u5F97\u70B9\u3001\u4EBA\u6570\u3001\u4FA1\u683C\u3001\u7269\u306E\u6570\u306B\u5BFE\u5FDC\u3055\u305B\u308B",
      hi: "31\u2013100 \u0915\u0940 \u0938\u0902\u0916\u094D\u092F\u093E\u0913\u0902 \u0915\u094B \u0905\u0902\u0915, \u0932\u094B\u0917, \u0915\u0940\u092E\u0924\u0947\u0902 \u0914\u0930 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0938\u0947 \u092E\u093F\u0932\u093E\u090F\u0902",
      ar: "\u0637\u0627\u0628\u0642 \u0627\u0644\u0623\u0639\u062F\u0627\u062F 31\u2013100 \u0645\u0639 \u0627\u0644\u0646\u0642\u0627\u0637 \u0648\u0627\u0644\u0623\u0634\u062E\u0627\u0635 \u0648\u0627\u0644\u0623\u0633\u0639\u0627\u0631 \u0648\u0627\u0644\u0623\u0634\u064A\u0627\u0621",
      zh: "\u5C0631\u2013100\u4E0E\u5206\u6570\u3001\u4EBA\u6570\u3001\u4EF7\u683C\u548C\u7269\u54C1\u6570\u91CF\u914D\u5BF9"
    },
    "lesson-pre-a1-f-1": {
      pt: "Escolha uma frase inicial para sauda\xE7\xE3o, cortesia ou resposta",
      it: "Scegli una frase iniziale per salutare, essere cortese o rispondere",
      fr: "Choisis une phrase de base pour saluer, \xEAtre poli ou r\xE9pondre",
      de: "Eine erste Wendung zum Begr\xFC\xDFen, f\xFCr H\xF6flichkeit oder zum Antworten w\xE4hlen",
      ja: "\u6328\u62F6\u3001\u4E01\u5BE7\u8868\u73FE\u3001\u8FD4\u7B54\u306B\u4F7F\u3046\u57FA\u672C\u30D5\u30EC\u30FC\u30BA\u3092\u9078\u3076",
      hi: "\u0905\u092D\u093F\u0935\u093E\u0926\u0928, \u0936\u093F\u0937\u094D\u091F\u093E\u091A\u093E\u0930 \u092F\u093E \u0909\u0924\u094D\u0924\u0930 \u0915\u0947 \u0932\u093F\u090F \u0936\u0941\u0930\u0941\u0906\u0924\u0940 \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0623\u0633\u0627\u0633\u064A\u0629 \u0644\u0644\u062A\u062D\u064A\u0629 \u0623\u0648 \u0627\u0644\u0645\u062C\u0627\u0645\u0644\u0629 \u0623\u0648 \u0627\u0644\u0631\u062F",
      zh: "\u9009\u62E9\u7528\u4E8E\u95EE\u5019\u3001\u793C\u8C8C\u8868\u8FBE\u6216\u56DE\u5E94\u7684\u5165\u95E8\u77ED\u8BED"
    },
    "lesson-pre-a1-f-2": {
      pt: "Identifique uma pessoa e um lugar com aqu\xED ou all\xED",
      it: "Identifica una persona e un luogo con aqu\xED o all\xED",
      fr: "Identifie une personne et un lieu avec aqu\xED ou all\xED",
      de: "Eine Person und einen Ort mit aqu\xED oder all\xED benennen",
      ja: "aqu\xED \u307E\u305F\u306F all\xED \u3092\u4F7F\u3063\u3066\u4EBA\u3068\u5834\u6240\u3092\u793A\u3059",
      hi: "aqu\xED \u092F\u093E all\xED \u0938\u0947 \u090F\u0915 \u0935\u094D\u092F\u0915\u094D\u0924\u093F \u0914\u0930 \u0938\u094D\u0925\u093E\u0928 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      ar: "\u062D\u062F\u0651\u062F \u0634\u062E\u0635\u064B\u0627 \u0648\u0645\u0643\u0627\u0646\u064B\u0627 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 aqu\xED \u0623\u0648 all\xED",
      zh: "\u7528 aqu\xED \u6216 all\xED \u6307\u8BA4\u4E00\u4E2A\u4EBA\u548C\u4E00\u4E2A\u5730\u70B9"
    },
    "lesson-pre-a1-f-3": {
      pt: "Expresse um desejo e uma necessidade imediata",
      it: "Esprimi un desiderio e un bisogno immediato",
      fr: "Exprime un souhait et un besoin imm\xE9diat",
      de: "Einen Wunsch und ein unmittelbares Bed\xFCrfnis ausdr\xFCcken",
      ja: "\u6B32\u3057\u3044\u3082\u306E\u3068\u4ECA\u5FC5\u8981\u306A\u3082\u306E\u30921\u3064\u305A\u3064\u8868\u73FE\u3059\u308B",
      hi: "\u090F\u0915 \u0907\u091A\u094D\u091B\u093E \u0914\u0930 \u090F\u0915 \u0924\u0924\u094D\u0915\u093E\u0932 \u0906\u0935\u0936\u094D\u092F\u0915\u0924\u093E \u0935\u094D\u092F\u0915\u094D\u0924 \u0915\u0930\u0947\u0902",
      ar: "\u0639\u0628\u0651\u0631 \u0639\u0646 \u0631\u063A\u0628\u0629 \u0648\u0627\u062D\u062F\u0629 \u0648\u062D\u0627\u062C\u0629 \u0641\u0648\u0631\u064A\u0629 \u0648\u0627\u062D\u062F\u0629",
      zh: "\u8868\u8FBE\u4E00\u4E2A\u613F\u671B\u548C\u4E00\u4E2A\u5373\u65F6\u9700\u6C42"
    },
    "lesson-pre-a1-f-4": {
      pt: "Siga uma indica\xE7\xE3o de tempo e uma dire\xE7\xE3o simples",
      it: "Segui un\u2019indicazione di tempo e una direzione semplice",
      fr: "Suis une indication de temps et une direction simple",
      de: "Einem Zeithinweis und einer einfachen Richtungsangabe folgen",
      ja: "\u6642\u9593\u306E\u5408\u56F3\u3068\u7C21\u5358\u306A\u65B9\u5411\u6307\u793A\u306B\u5F93\u3046",
      hi: "\u0938\u092E\u092F \u0915\u0947 \u090F\u0915 \u0938\u0902\u0915\u0947\u0924 \u0914\u0930 \u090F\u0915 \u0938\u0930\u0932 \u0926\u093F\u0936\u093E-\u0928\u093F\u0930\u094D\u0926\u0947\u0936 \u0915\u093E \u092A\u093E\u0932\u0928 \u0915\u0930\u0947\u0902",
      ar: "\u0627\u062A\u0628\u0639 \u0625\u0634\u0627\u0631\u0629 \u0632\u0645\u0646\u064A\u0629 \u0648\u0627\u062D\u062F\u0629 \u0648\u0627\u062A\u062C\u0627\u0647\u064B\u0627 \u0628\u0633\u064A\u0637\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627",
      zh: "\u9075\u5FAA\u4E00\u4E2A\u65F6\u95F4\u63D0\u793A\u548C\u4E00\u4E2A\u7B80\u5355\u65B9\u5411\u6307\u793A"
    }
  });
  var agenda4 = (forms, application) => ({ forms, application });
  var MANUAL_PRE_A1_AGENDAS = Object.freeze({
    "lesson-pre-a1-1-2": agenda4(
      ["abuelo", "abuela", "beb\xE9", "t\xEDo", "t\xEDa"],
      {
        en: "Identify and name two extended-family members",
        es: "Identifica y nombra a dos familiares",
        goal: "Identify and name at least two extended-family members",
        examples: ["Es mi abuela.", "Es mi t\xEDo."],
        activityBrief: "Show or describe two family relationships and ask the learner to name them",
        evidence: "The learner correctly names at least two extended-family members"
      }
    ),
    "lesson-pre-a1-1-3": agenda4(
      ["amigo", "amiga", "vecino", "vecina", "ni\xF1o", "ni\xF1a"],
      {
        en: "Identify one familiar person with mi + person word",
        es: "Identifica a una persona con mi + palabra de persona",
        goal: "Identify one familiar person using mi plus a people word",
        examples: ["Mi amiga.", "Mi vecino."],
        activityBrief: "Present one familiar person and help the learner identify the relationship with a two-word chunk",
        evidence: "The learner produces an understandable mi plus person phrase"
      }
    ),
    "lesson-pre-a1-2-2": agenda4(
      ["seis", "siete", "ocho", "nueve", "diez"],
      {
        en: "Recognize and say quantities from six to ten",
        es: "Reconoce y di cantidades del seis al diez",
        goal: "Recognize and produce quantities from six to ten",
        examples: ["seis libros", "nueve sillas"],
        activityBrief: "Present three small quantities from six to ten and ask the learner to identify or say each number",
        evidence: "The learner correctly recognizes or produces at least three numbers from six to ten"
      }
    ),
    "lesson-pre-a1-2-3": agenda4(
      ["un libro", "dos libros", "tres sillas", "cuatro mesas", "\xBFcu\xE1ntos hay?"],
      {
        en: "Answer \xBFcu\xE1ntos hay? with a number and an object",
        es: "Responde \xBFcu\xE1ntos hay? con un n\xFAmero y un objeto",
        goal: "Answer a quantity question with a number and a familiar object",
        examples: ["Dos libros.", "Cuatro mesas."],
        activityBrief: "Ask one quantity question at a time about familiar objects and elicit a number-plus-object answer",
        evidence: "The learner gives two understandable number-plus-object answers"
      }
    ),
    "lesson-pre-a1-3-2": agenda4(
      ["adi\xF3s", "hasta luego", "hasta ma\xF1ana", "nos vemos", "chao"],
      {
        en: "Choose a farewell for later today or tomorrow",
        es: "Elige una despedida para m\xE1s tarde o ma\xF1ana",
        goal: "Choose an appropriate farewell for two simple time contexts",
        examples: ["Hasta luego.", "Hasta ma\xF1ana."],
        activityBrief: "Give a later-today context and a tomorrow context, asking for one appropriate farewell in each",
        evidence: "The learner chooses an appropriate farewell in both contexts"
      }
    ),
    "lesson-pre-a1-3-3": agenda4(
      ["hola", "\xBFc\xF3mo est\xE1s?", "bien, gracias", "\xBFy t\xFA?", "bienvenido"],
      {
        en: "Complete a greeting and wellbeing exchange",
        es: "Completa un saludo y un intercambio de bienestar",
        goal: "Complete a short greeting and wellbeing exchange",
        examples: ["Hola. \xBFC\xF3mo est\xE1s?", "Bien, gracias. \xBFY t\xFA?"],
        activityBrief: "Run a three-turn arrival exchange using a greeting, a wellbeing question, and a short response",
        evidence: "The learner supplies the appropriate greeting or response in three consecutive turns"
      }
    ),
    "lesson-pre-a1-4-2": agenda4(
      ["no s\xE9", "quiz\xE1s", "tal vez", "m\xE1s o menos", "no entiendo"],
      {
        en: "Choose a phrase for uncertainty or lack of understanding",
        es: "Elige una frase de duda o falta de comprensi\xF3n",
        goal: "Distinguish uncertainty from not knowing and not understanding",
        examples: ["Quiz\xE1s.", "No s\xE9.", "No entiendo."],
        activityBrief: "Give one maybe, one unknown, and one comprehension situation and ask for the matching short response",
        evidence: "The learner chooses an appropriate response for at least two different situations"
      }
    ),
    "lesson-pre-a1-4-3": agenda4(
      ["entiendo", "claro", "vale", "bien", "mal", "qu\xE9 bien"],
      {
        en: "React naturally to good news, bad news, and an instruction",
        es: "Reacciona a una buena noticia, una mala noticia y una instrucci\xF3n",
        goal: "Use three different short reactions in matching contexts",
        examples: ["\xA1Qu\xE9 bien!", "Mal.", "Vale."],
        activityBrief: "Give three tiny contexts\u2014good news, bad news, and a simple instruction\u2014and elicit a different reaction",
        evidence: "The learner gives three context-appropriate short reactions"
      }
    ),
    "lesson-pre-a1-5-2": agenda4(
      ["perd\xF3n", "lo siento", "disculpe", "con permiso"],
      {
        en: "Choose an apology or attention phrase for the situation",
        es: "Elige una disculpa o frase de atenci\xF3n seg\xFAn la situaci\xF3n",
        goal: "Distinguish apologizing, getting attention, and passing by",
        examples: ["Lo siento.", "Disculpe.", "Con permiso."],
        activityBrief: "Give one bumping-into-someone situation, one attention situation, and one passing-by situation",
        evidence: "The learner chooses the appropriate phrase in at least two different situations"
      }
    ),
    "lesson-pre-a1-5-3": agenda4(
      ["muchas gracias", "de nada", "no hay problema", "con gusto", "no es nada"],
      {
        en: "Complete two different thank-you and response pairs",
        es: "Completa dos pares distintos de agradecimiento y respuesta",
        goal: "Complete two courtesy exchanges using different responses",
        examples: ["Muchas gracias. \u2014 De nada.", "Gracias. \u2014 Con gusto."],
        activityBrief: "Model one thank-you exchange, then prompt two new exchanges that require different courtesy responses",
        evidence: "The learner completes two exchanges with two different appropriate courtesy responses"
      }
    ),
    "lesson-pre-a1-6-2": agenda4(
      ["llave", "tel\xE9fono", "cartera", "bolso", "libro", "l\xE1piz"],
      {
        en: "Identify which personal item is present or missing",
        es: "Identifica qu\xE9 objeto personal est\xE1 o falta",
        goal: "Identify familiar personal items in a bag or missing-item context",
        examples: ["Mi tel\xE9fono.", "Falta la llave."],
        activityBrief: "Describe a bag with three familiar items, then ask which item is present or missing",
        evidence: "The learner correctly identifies at least three personal items",
        kind: "comprehension",
        evidenceType: "identify"
      }
    ),
    "lesson-pre-a1-6-3": agenda4(
      ["agua", "caf\xE9", "t\xE9", "leche", "pan", "comida"],
      {
        en: "Order one food and one drink with por favor",
        es: "Pide una comida y una bebida con por favor",
        goal: "Order one familiar food and one familiar drink politely",
        examples: ["Caf\xE9, por favor.", "Pan, por favor."],
        activityBrief: "Offer a tiny caf\xE9 menu and ask the learner to request one drink and one food item",
        evidence: "The learner makes two understandable item-plus-por-favor requests"
      }
    ),
    "lesson-pre-a1-7-2": agenda4(
      ["verde", "naranja", "morado", "rosa"],
      {
        en: "Identify four additional colors on familiar objects",
        es: "Identifica cuatro colores adicionales en objetos conocidos",
        goal: "Identify and name four additional colors",
        examples: ["libro verde", "mesa naranja"],
        activityBrief: "Pair each new color with a familiar object and ask the learner to identify the color",
        evidence: "The learner correctly names at least three of the four colors"
      }
    ),
    "lesson-pre-a1-7-3": agenda4(
      ["negro", "blanco", "gris", "marr\xF3n"],
      {
        en: "Choose and name a neutral color",
        es: "Elige y nombra un color neutro",
        goal: "Recognize and use black, white, gray, and brown",
        examples: ["puerta blanca", "mesa marr\xF3n"],
        activityBrief: "Present familiar objects in neutral colors and ask the learner to name or choose the color",
        evidence: "The learner correctly uses at least three neutral color words"
      }
    ),
    "lesson-pre-a1-8-2": agenda4(
      ["\xBFc\xF3mo te llamas?", "\xBFc\xF3mo se llama?", "\xBFy t\xFA?", "tu nombre"],
      {
        en: "Ask a peer and an adult for their name",
        es: "Pregunta el nombre de un compa\xF1ero y de un adulto",
        goal: "Ask for a name using one casual and one polite question",
        examples: ["\xBFC\xF3mo te llamas?", "\xBFC\xF3mo se llama?"],
        activityBrief: "Present one peer and one adult context and ask the learner to choose and produce the appropriate name question",
        evidence: "The learner produces the casual and polite name questions in the matching contexts"
      }
    ),
    "lesson-pre-a1-8-3": agenda4(
      ["mucho gusto", "encantado", "encantada", "igualmente", "un placer"],
      {
        en: "Complete two nice-to-meet-you exchanges",
        es: "Completa dos intercambios de mucho gusto",
        goal: "Use and respond to a nice-to-meet-you expression",
        examples: ["Mucho gusto. \u2014 Igualmente.", "Encantada. \u2014 Un placer."],
        activityBrief: "Run two first-meeting closings and require a greeting response rather than another introduction",
        evidence: "The learner appropriately opens or responds to two nice-to-meet-you exchanges"
      }
    ),
    "lesson-a1-1-2": agenda4(
      [
        "hola",
        "me llamo",
        "\xBFc\xF3mo te llamas?",
        "mucho gusto",
        "\xBFc\xF3mo est\xE1s?",
        "bien, gracias",
        "hasta luego"
      ],
      {
        en: "Complete a four-turn meeting with the required phrases",
        es: "Completa un encuentro de cuatro turnos con las frases requeridas",
        goal: "Complete a four-turn first meeting using a greeting, names, wellbeing, and a closing",
        examples: [
          "Hola. Me llamo Ana.",
          "Mucho gusto. \xBFC\xF3mo est\xE1s?",
          "Bien, gracias. Hasta luego."
        ],
        activityBrief: "Run exactly four short turns: greeting, name exchange, wellbeing exchange, and closing; prompt only the missing phrase",
        evidence: "The learner completes all four stages with an understandable required phrase"
      }
    ),
    "lesson-a1-1-3": agenda4(
      [
        "hola",
        "buenos d\xEDas",
        "\xBFc\xF3mo est\xE1s?",
        "\xBFc\xF3mo est\xE1 usted?",
        "\xBFc\xF3mo te llamas?",
        "\xBFc\xF3mo se llama?"
      ],
      {
        en: "Choose casual or polite language for two first meetings",
        es: "Elige lenguaje casual o cort\xE9s para dos encuentros",
        goal: "Distinguish casual and polite greeting and name questions",
        examples: ["Hola. \xBFC\xF3mo est\xE1s?", "Buenos d\xEDas. \xBFC\xF3mo est\xE1 usted?"],
        activityBrief: "Present a peer context and an adult-stranger context, requiring the matching greeting and question in each",
        evidence: "The learner chooses the appropriate register in both contexts"
      }
    ),
    "lesson-a1-3-2": agenda4(
      ["hay doce", "hay veinte", "son quince", "cuesta veinticinco", "\xBFcu\xE1ntos hay?"],
      {
        en: "Use numbers 11\u201330 for quantities and a price",
        es: "Usa los n\xFAmeros 11\u201330 para cantidades y un precio",
        goal: "State two quantities and one price using numbers 11\u201330",
        examples: ["Hay doce libros.", "Cuesta veinticinco."],
        activityBrief: "Ask two how-many questions and one simple price question using authored numbers from 11 to 30",
        evidence: "The learner produces two correct quantities and one understandable price"
      }
    ),
    "lesson-a1-3-3": agenda4(
      ["mi n\xFAmero es", "\xBFcu\xE1l es tu n\xFAmero?", "tengo veinte a\xF1os", "\xBFcu\xE1ntos a\xF1os tienes?"],
      {
        en: "Ask for and give an age and a short phone number",
        es: "Pregunta y da una edad y un n\xFAmero de tel\xE9fono corto",
        goal: "Ask for and give one age and one short phone number",
        examples: ["Tengo veinte a\xF1os.", "Mi n\xFAmero es 21 15 30."],
        activityBrief: "Use fictional information: exchange one age and one short grouped phone number",
        evidence: "The learner asks for or gives both an age and a short phone number"
      }
    ),
    "lesson-a1-4-2": agenda4(
      ["\xBFcu\xE1nto cuesta?", "cuesta cuarenta", "son cincuenta pesos", "cambio, por favor"],
      {
        en: "Ask a price and understand the total and change",
        es: "Pregunta un precio y entiende el total y el cambio",
        goal: "Ask for a price, state a total, and request change",
        examples: ["\xBFCu\xE1nto cuesta?", "Son cincuenta pesos."],
        activityBrief: "Run a tiny purchase with one price question, one total from 31 to 100, and one change request",
        evidence: "The learner completes the price question and responds correctly to the total"
      }
    ),
    "lesson-a1-4-3": agenda4(
      ["treinta puntos", "sesenta personas", "noventa pesos", "cien libros"],
      {
        en: "Match numbers 31\u2013100 to scores, people, prices, and objects",
        es: "Relaciona n\xFAmeros 31\u2013100 con puntos, personas, precios y objetos",
        goal: "Interpret and produce numbers 31\u2013100 in four concrete contexts",
        examples: ["Sesenta personas.", "Noventa pesos."],
        activityBrief: "Present a score, a headcount, a price, and an object quantity; ask for one number phrase at a time",
        evidence: "The learner correctly interprets or produces at least three of the four number phrases"
      }
    ),
    "lesson-pre-a1-f-1": agenda4(
      ["hola", "buenos d\xEDas", "adi\xF3s", "gracias", "por favor", "s\xED", "no", "no s\xE9"],
      {
        en: "Choose a starter phrase for greeting, courtesy, or response",
        es: "Elige una frase inicial de saludo, cortes\xEDa o respuesta",
        goal: "Use high-frequency starter phrases in matching situations",
        examples: ["Buenos d\xEDas.", "S\xED, por favor.", "No s\xE9."],
        activityBrief: "Cycle through a greeting, a polite request, a yes/no choice, and an unknown-answer situation",
        evidence: "The learner gives an appropriate phrase in four different starter situations"
      }
    ),
    "lesson-pre-a1-f-2": agenda4(
      ["mam\xE1", "pap\xE1", "amigo", "casa", "escuela", "trabajo", "aqu\xED", "all\xED"],
      {
        en: "Identify a person and a place with aqu\xED or all\xED",
        es: "Identifica una persona y un lugar con aqu\xED o all\xED",
        goal: "Identify familiar people and places using here and there",
        examples: ["Mam\xE1 est\xE1 aqu\xED.", "La escuela est\xE1 all\xED."],
        activityBrief: "Present two familiar people and two familiar places, asking where each one is",
        evidence: "The learner correctly identifies at least one person and two places"
      }
    ),
    "lesson-pre-a1-f-3": agenda4(
      ["quiero", "necesito", "tengo", "voy", "ayuda", "agua", "comida", "ba\xF1o"],
      {
        en: "Express one want and one immediate need",
        es: "Expresa un deseo y una necesidad inmediata",
        goal: "Use quiero or necesito with an immediate essential",
        examples: ["Quiero agua.", "Necesito ayuda."],
        activityBrief: "Give one choice situation and one help situation, eliciting a two-word want or need phrase",
        evidence: "The learner produces one understandable quiero phrase and one necesito phrase"
      }
    ),
    "lesson-pre-a1-f-4": agenda4(
      [
        "hoy",
        "ma\xF1ana",
        "ahora",
        "aqu\xED",
        "all\xED",
        "izquierda",
        "derecha",
        "recto",
        "autob\xFAs",
        "taxi"
      ],
      {
        en: "Follow one time cue and one simple direction",
        es: "Sigue una indicaci\xF3n de tiempo y una direcci\xF3n sencilla",
        goal: "Recognize basic time, transport, and direction words",
        examples: ["Ahora, a la derecha.", "Taxi aqu\xED."],
        activityBrief: "Give one when choice, one transport choice, and two one-step directions",
        evidence: "The learner correctly responds to a time cue, a transport word, and two directions"
      }
    )
  });

  // ../nosabos/nosabos/src/utils/lessonCurriculum.js
  var INVALID_OBJECTIVE_LABELS = /* @__PURE__ */ new Set([
    "form",
    "use",
    "form and use",
    "pattern recycling",
    "micro-drills",
    "micro drills",
    "general vocabulary and grammar",
    "comprehensive review",
    "lesson focus"
  ]);
  var SUPPORT_GRAMMAR_TERMS = Object.freeze({
    "present perfect": {
      es: "pret\xE9rito perfecto",
      pt: "pret\xE9rito perfeito",
      it: "passato prossimo",
      fr: "pass\xE9 compos\xE9",
      de: "Perfekt",
      ja: "\u73FE\u5728\u5B8C\u4E86\u5F62",
      hi: "\u0935\u0930\u094D\u0924\u092E\u093E\u0928 \u092A\u0942\u0930\u094D\u0923 \u0915\u093E\u0932",
      ar: "\u0627\u0644\u0645\u0636\u0627\u0631\u0639 \u0627\u0644\u062A\u0627\u0645",
      zh: "\u73B0\u5728\u5B8C\u6210\u65F6"
    },
    "past continuous": {
      es: "pasado continuo",
      pt: "passado cont\xEDnuo",
      it: "passato progressivo",
      fr: "pass\xE9 continu",
      de: "Verlaufsform der Vergangenheit",
      ja: "\u904E\u53BB\u9032\u884C\u5F62",
      hi: "\u092D\u0942\u0924\u0915\u093E\u0932 \u0928\u093F\u0930\u0902\u0924\u0930",
      ar: "\u0627\u0644\u0645\u0627\u0636\u064A \u0627\u0644\u0645\u0633\u062A\u0645\u0631",
      zh: "\u8FC7\u53BB\u8FDB\u884C\u65F6"
    },
    "future tense": {
      es: "tiempo futuro",
      pt: "tempo futuro",
      it: "tempo futuro",
      fr: "futur",
      de: "Futur",
      ja: "\u672A\u6765\u5F62",
      hi: "\u092D\u0935\u093F\u0937\u094D\u092F \u0915\u093E\u0932",
      ar: "\u0632\u0645\u0646 \u0627\u0644\u0645\u0633\u062A\u0642\u0628\u0644",
      zh: "\u5C06\u6765\u65F6"
    },
    "past perfect": {
      es: "pluscuamperfecto",
      pt: "mais-que-perfeito",
      it: "trapassato prossimo",
      fr: "plus-que-parfait",
      de: "Plusquamperfekt",
      ja: "\u904E\u53BB\u5B8C\u4E86\u5F62",
      hi: "\u092A\u0942\u0930\u094D\u0923 \u092D\u0942\u0924\u0915\u093E\u0932",
      ar: "\u0627\u0644\u0645\u0627\u0636\u064A \u0627\u0644\u062A\u0627\u0645",
      zh: "\u8FC7\u53BB\u5B8C\u6210\u65F6"
    },
    "passive voice": {
      es: "voz pasiva",
      pt: "voz passiva",
      it: "forma passiva",
      fr: "voix passive",
      de: "Passiv",
      ja: "\u53D7\u52D5\u614B",
      hi: "\u0915\u0930\u094D\u092E\u0935\u093E\u091A\u094D\u092F",
      ar: "\u0627\u0644\u0645\u0628\u0646\u064A \u0644\u0644\u0645\u062C\u0647\u0648\u0644",
      zh: "\u88AB\u52A8\u8BED\u6001"
    },
    "reported speech": {
      es: "estilo indirecto",
      pt: "discurso indireto",
      it: "discorso indiretto",
      fr: "discours indirect",
      de: "indirekte Rede",
      ja: "\u9593\u63A5\u8A71\u6CD5",
      hi: "\u0905\u092A\u094D\u0930\u0924\u094D\u092F\u0915\u094D\u0937 \u0915\u0925\u0928",
      ar: "\u0627\u0644\u0643\u0644\u0627\u0645 \u0627\u0644\u0645\u0646\u0642\u0648\u0644",
      zh: "\u95F4\u63A5\u5F15\u8BED"
    },
    "relative clauses": {
      es: "oraciones de relativo",
      pt: "ora\xE7\xF5es relativas",
      it: "frasi relative",
      fr: "propositions relatives",
      de: "Relativs\xE4tze",
      ja: "\u95A2\u4FC2\u7BC0",
      hi: "\u0938\u0902\u092C\u0902\u0927\u0935\u093E\u091A\u0915 \u0909\u092A\u0935\u093E\u0915\u094D\u092F",
      ar: "\u0627\u0644\u062C\u0645\u0644 \u0627\u0644\u0645\u0648\u0635\u0648\u0644\u0629",
      zh: "\u5173\u7CFB\u4ECE\u53E5"
    },
    "present subjunctive": {
      es: "presente de subjuntivo",
      pt: "presente do subjuntivo",
      it: "congiuntivo presente",
      fr: "subjonctif pr\xE9sent",
      de: "Konjunktiv Pr\xE4sens",
      ja: "\u63A5\u7D9A\u6CD5\u73FE\u5728",
      hi: "\u0935\u0930\u094D\u0924\u092E\u093E\u0928 \u0938\u0902\u092D\u093E\u0935\u0928\u093E\u0930\u094D\u0925\u0915",
      ar: "\u0635\u064A\u063A\u0629 \u0627\u0644\u0634\u0631\u0637 \u0641\u064A \u0627\u0644\u0645\u0636\u0627\u0631\u0639",
      zh: "\u73B0\u5728\u865A\u62DF\u5F0F"
    },
    "past subjunctive": {
      es: "pasado de subjuntivo",
      pt: "pret\xE9rito do subjuntivo",
      it: "congiuntivo passato",
      fr: "subjonctif pass\xE9",
      de: "Konjunktiv Vergangenheit",
      ja: "\u63A5\u7D9A\u6CD5\u904E\u53BB",
      hi: "\u092D\u0942\u0924\u0915\u093E\u0932 \u0938\u0902\u092D\u093E\u0935\u0928\u093E\u0930\u094D\u0925\u0915",
      ar: "\u0635\u064A\u063A\u0629 \u0627\u0644\u0634\u0631\u0637 \u0641\u064A \u0627\u0644\u0645\u0627\u0636\u064A",
      zh: "\u8FC7\u53BB\u865A\u62DF\u5F0F"
    },
    subjunctive: {
      es: "subjuntivo",
      pt: "subjuntivo",
      it: "congiuntivo",
      fr: "subjonctif",
      de: "Konjunktiv",
      ja: "\u63A5\u7D9A\u6CD5",
      hi: "\u0938\u0902\u092D\u093E\u0935\u0928\u093E\u0930\u094D\u0925\u0915",
      ar: "\u0635\u064A\u063A\u0629 \u0627\u0644\u0634\u0631\u0637",
      zh: "\u865A\u62DF\u5F0F"
    },
    infinitive: {
      es: "infinitivo",
      pt: "infinitivo",
      it: "infinito",
      fr: "infinitif",
      de: "Infinitiv",
      ja: "\u4E0D\u5B9A\u8A5E",
      hi: "\u0915\u094D\u0930\u093F\u092F\u093E \u0915\u093E \u092E\u0942\u0932 \u0930\u0942\u092A",
      ar: "\u0627\u0644\u0645\u0635\u062F\u0631",
      zh: "\u4E0D\u5B9A\u5F0F"
    }
  });
  var INVALID_LESSON_OBJECTIVE_LABELS = Object.freeze([
    ...INVALID_OBJECTIVE_LABELS
  ]);

  // ../nosabos/nosabos/src/utils/delightQuestionVariants.js
  var DELIGHT_VARIANTS = [
    {
      id: "sentence_detective",
      label: "Sentence Detective",
      icon: "\u{1F50E}",
      description: "Find the broken word and repair it."
    },
    {
      id: "dialogue_fork",
      label: "Dialogue Fork",
      icon: "\u{1F4AC}",
      description: "Choose the most natural reply."
    },
    {
      id: "sentence_shapeshifter",
      label: "Sentence Shapeshifter",
      icon: "\u2728",
      description: "Transform a sentence without losing its meaning."
    },
    {
      id: "word_neighborhoods",
      label: "Word Neighborhoods",
      icon: "\u{1F3D8}\uFE0F",
      description: "Sort words into the groups where they belong."
    },
    {
      id: "morphology_forge",
      label: "Morphology Forge",
      icon: "\u2692\uFE0F",
      description: "Build the right word from meaningful pieces."
    },
    {
      id: "three_clue_mystery",
      label: "Three-Clue Mystery",
      icon: "\u{1F575}\uFE0F",
      description: "Name the word with as few clues as possible."
    },
    {
      id: "listen_difference",
      label: "Listen for the Difference",
      icon: "\u{1F3A7}",
      description: "Hear the detail that changes the meaning."
    },
    {
      id: "three_word_challenge",
      label: "Three-Word Challenge",
      icon: "\u{1F3A8}",
      description: "Create an original sentence from three cues."
    },
    {
      id: "natural_or_weird",
      label: "Natural or Weird?",
      icon: "\u{1F300}",
      description: "Trust your ear, then uncover the repair."
    }
  ];
  var DELIGHT_VARIANT_IDS = DELIGHT_VARIANTS.map(({ id }) => id);
  var LANGUAGE_NAMES = {
    ar: "Egyptian Arabic",
    zh: "Mandarin Chinese",
    de: "German",
    el: "Greek",
    en: "English",
    es: "Spanish",
    fr: "French",
    ga: "Irish",
    hi: "Hindi",
    it: "Italian",
    ja: "Japanese",
    nah: "Eastern Huasteca Nahuatl",
    nl: "Dutch",
    pl: "Polish",
    pt: "Brazilian Portuguese",
    ru: "Russian",
    yua: "Yucatec Maya"
  };
  function getDelightLanguageName(code = "en") {
    return LANGUAGE_NAMES[code] || code;
  }

  // ../nosabos/nosabos/src/utils/assistantLanguagePolicy.js
  function buildAssistantLanguagePolicy({
    supportLanguageName,
    targetLanguageName
  }) {
    const support = String(supportLanguageName || "the support language").trim();
    const target = String(targetLanguageName || "the target language").trim();
    return [
      `LANGUAGE CONTRACT: Write every learner-facing sentence in ${support}.`,
      `Use ${target} only for exact exercise words, answers, or examples that the learner is studying.`,
      `Do not use English or any other third language unless it is ${support} or ${target}.`,
      `Translate all headings, grammar terms, labels, definitions, glosses, and parenthetical explanations into ${support}.`,
      `Before responding, silently rewrite any third-language prose into ${support}.`
    ].join(" ");
  }
  function buildExerciseAssistancePolicy() {
    return [
      "DIRECT ASSISTANCE: The learner explicitly requested help solving the current exercise.",
      "Start with the exact answer and the concrete selections or steps to enter it, then briefly explain why it works.",
      "Use only the provided sentence, word bank, options, and answer material. Do not invent an option or ask the learner to find a piece that is not offered.",
      "For word assembly, name the available pieces in order, the assembled word, and the completed sentence.",
      "If no offered solution works, say the exercise is inconsistent and suggest skipping or refreshing it; do not pretend it is solvable.",
      "Do not withhold the answer, give a nudge, or turn the request into a guessing question. This is direct assistance, even if the request template calls it a hint."
    ].join(" ");
  }

  // <stdin>
  function build(op, p) {
    const { question, response = {}, targetLang = "es", supportLang = "en", revealedClues = 1 } = p;
    let prefix = "";
    const setAssistantSupportText = (v) => prefix = v;
    const detectiveCopy = getSentenceDetectiveCopy(supportLang);
    const dialogueForkCopy = getDialogueForkCopy(supportLang);
    const sentenceShapeshifterCopy = getSentenceShapeshifterCopy(supportLang);
    const wordNeighborhoodsCopy = getWordNeighborhoodsCopy(supportLang);
    const morphologyForgeCopy = getMorphologyForgeCopy(supportLang);
    const threeClueMysteryCopy = getThreeClueMysteryCopy(supportLang);
    const listenDifferenceCopy = getListenDifferenceCopy(supportLang);
    const threeWordChallengeCopy = getThreeWordChallengeCopy(supportLang);
    const naturalOrWeirdCopy = getNaturalOrWeirdCopy(supportLang);
    if (op === "assistant") {
      const targetName = getDelightLanguageName(targetLang);
      const supportName = getDelightLanguageName(supportLang);
      const levelHint = question?.questionLevel ? `This question was generated at CEFR ${question.questionLevel}.` : "";
      const instruction = [
        "You are a helpful, encouraging language study buddy.",
        `The learner is practicing ${targetName}; their support/UI language is ${supportName}.`,
        levelHint,
        buildExerciseAssistancePolicy(),
        buildAssistantLanguagePolicy({
          supportLanguageName: supportName,
          targetLanguageName: targetName
        }),
        `Explain and guide directly in ${supportName}. Clearly explain the required grammar or vocabulary, provide the relevant words/phrases in ${targetName} with translations in ${supportName}, and guide the learner to successfully answer the question.`,
        question.variant === "three_clue_mystery" ? "Keep replies clear, direct, and concise (\u2264 80 words)." : "Keep replies concise (\u2264 60 words).",
        "Use concise Markdown when helpful (bullets, **bold**)."
      ].join(" ");
      const questionContext = question.variant === "sentence_detective" ? formatSentenceDetectiveCopy(detectiveCopy.helpRequest, {
        sentence: question.sentence
      }) : question.variant === "dialogue_fork" ? formatDialogueForkCopy(dialogueForkCopy.helpRequest, {
        speaker: question.speaker || "Speaker",
        line: question.line || ""
      }) : question.variant === "sentence_shapeshifter" ? formatSentenceShapeshifterCopy(sentenceShapeshifterCopy.helpRequest, {
        source: question.source || "",
        constraint: question.constraint || ""
      }) : question.variant === "word_neighborhoods" ? formatWordNeighborhoodsCopy(wordNeighborhoodsCopy.helpRequest, {
        groups: (question.groups || []).map((g) => g.label).join(", ")
      }) : question.variant === "morphology_forge" ? "Show the exact offered pieces to select, in order, and the completed sentence. Explain the solution directly." : question.variant === "three_clue_mystery" ? formatThreeClueMysteryCopy(threeClueMysteryCopy.helpRequest, {
        clues: (question.clues || []).slice(0, revealedClues || 1).join(" | ")
      }) : question.variant === "listen_difference" ? listenDifferenceCopy.helpRequest : question.variant === "three_word_challenge" ? threeWordChallengeCopy.helpRequest : question.variant === "natural_or_weird" ? naturalOrWeirdCopy.helpRequest : question.instruction || "Help me with this question.";
      let variantContext = "";
      if (question.variant === "sentence_detective") {
        variantContext = [
          `Exercise: Sentence Detective`,
          `Sentence with error: "${question.sentence || ""}"`,
          `Incorrect word: "${question.wrongToken || ""}"`,
          `Correct repair: "${question.answer || ""}"`,
          `Task: Explain which word is incorrect ("${question.wrongToken || ""}"), why it is wrong, and provide the correct repair word ("${question.answer || ""}") with a clear explanation.`
        ].join("\n");
      } else if (question.variant === "dialogue_fork") {
        variantContext = [
          `Exercise: Dialogue Fork (Conversational Reply)`,
          `Speaker prompt: ${question.speaker ? `${question.speaker}: ` : ""}"${question.line || ""}"`,
          `Options: ${(question.options || []).map((opt, i) => `${i + 1}. "${opt}"`).join(", ")}`,
          `Correct reply: "${question.options?.[question.answerIndex] || ""}"`,
          `Task: Recommend the best reply ("${question.options?.[question.answerIndex] || ""}") and explain why it is the most natural and appropriate conversational response in ${targetName}.`
        ].join("\n");
      } else if (question.variant === "sentence_shapeshifter") {
        variantContext = [
          `Exercise: Sentence Shapeshifter`,
          `Original sentence: "${question.source || ""}"`,
          `Transformation rule: "${question.constraint || ""}"`,
          `Expected answer: "${question.answer || ""}"`,
          `Task: Guide the learner on how to transform the sentence according to the rule ("${question.constraint || ""}") in ${targetName}. Provide the target words/phrases and guide them to form the complete sentence ("${question.answer || ""}").`
        ].join("\n");
      } else if (question.variant === "word_neighborhoods") {
        const groupsDesc = (question.groups || []).map((g) => `- "${g.label}": [${(g.items || []).join(", ")}]`).join("\n");
        variantContext = [
          `Exercise: Word Neighborhoods (Sorting words into categories)`,
          `Categories & target words:`,
          groupsDesc,
          `Task: Explain the categories clearly and guide the learner on where the words belong with helpful definitions or translations.`
        ].join("\n");
      } else if (question.variant === "morphology_forge") {
        variantContext = [
          `Exercise: Morphology Forge (Building words from morphemes)`,
          `Sentence: "${question.sentence || ""}"`,
          `Target word to build: "${question.answerWord || ""}"`,
          `Correct morpheme pieces: ${(question.answerPieces || []).join(" + ")}`,
          `Available pieces: ${(question.pieces || []).join(", ")}`,
          `Task: Explain how to build the target word ("${question.answerWord || ""}") using the morpheme pieces (${(question.answerPieces || []).join(" + ")}), explaining their grammatical function or meaning.`
        ].join("\n");
      } else if (question.variant === "three_clue_mystery") {
        const revealedList = (question.clues || []).slice(0, revealedClues || 1);
        const cluesDesc = revealedList.map((c, i) => `Clue ${i + 1}: "${c}"`).join("\n");
        const allCluesDesc = (question.clues || []).map((c, i) => `Clue ${i + 1}: "${c}"`).join("\n");
        variantContext = [
          `Exercise: Three-Clue Mystery`,
          `Mystery word (correct answer): "${question.answer || ""}"`,
          question.acceptableAnswers?.length ? `Acceptable alternative answers: ${question.acceptableAnswers.map((a) => `"${a}"`).join(", ")}` : "",
          question.example ? `Example sentence with answer: "${question.example}"` : "",
          `Clues currently revealed to the learner (${revealedList.length} of ${question.clues?.length || 3}):`,
          cluesDesc,
          question.clues && question.clues.length > revealedList.length ? `All clues for context:
${allCluesDesc}` : "",
          `Task: Provide the answer directly to the learner ("${question.answer || ""}") and explain the reasoning behind it in ${supportName}. Do NOT withhold the answer or just provide vague hints/clues. Clearly state the answer word in ${targetName} along with its meaning in ${supportName}, then explain step-by-step how the clues point to this answer so the learner is not stuck. If helpful, mention the example sentence.`
        ].filter(Boolean).join("\n");
      } else if (question.variant === "listen_difference") {
        variantContext = [
          `Exercise: Listen for the Difference (Minimal Pairs & Phonetics)`,
          `Spoken target audio: "${question.audioText || ""}"`,
          `Available options: ${(question.options || []).map((opt, i) => `${i + 1}. "${opt}"`).join(", ")}`,
          `Correct option: Option ${typeof question.answerIndex === "number" ? question.answerIndex + 1 : 1} ("${question.options?.[question.answerIndex] || ""}")`,
          `Key phonetic/grammatical distinction: "${question.contrast || ""}"`,
          `Task: Explain the correct option ("${question.options?.[question.answerIndex] || ""}") and point out the key sound or grammatical distinction to listen for.`
        ].join("\n");
      } else if (question.variant === "three_word_challenge") {
        variantContext = [
          `Exercise: Three-Word Challenge (Creative Sentence Construction)`,
          `Required cue words: ${(question.cues || []).map((c, i) => `${i + 1}. "${c}"`).join(", ")}`,
          `Valid sample answers: ${(question.sampleAnswers || []).map((a) => `"${a}"`).join(", ")}`,
          `Task: Provide a natural example sentence in ${targetName} connecting all 3 words with its translation in ${supportName} to guide the learner.`
        ].join("\n");
      } else if (question.variant === "natural_or_weird") {
        variantContext = [
          `Exercise: Natural or Weird? (Intuition & Idiomatic Nuance)`,
          `Target sentence: "${question.sentence || ""}"`,
          `Correct status: ${question.isNatural ? "NATURAL (authentic everyday phrasing)" : "WEIRD / AWKWARD (unnatural phrasing or grammatical mistake)"}`,
          question.correction ? `Proper correction/repair if weird: "${question.correction}"` : "",
          question.explanation ? `Nuance explanation: "${question.explanation}"` : "",
          `Task: Explain clearly whether the sentence is natural or weird in everyday ${targetName}, why native speakers say it that way, and provide the natural phrasing.`
        ].filter(Boolean).join("\n");
      } else {
        variantContext = `Exercise: ${question.variant || "General practice"}
Content: "${question.line || question.sentence || question.source || question.instruction || ""}"`;
      }
      const prompt = `${instruction}

${variantContext}

Learner request:
${questionContext}`;
      const solution = question.variant === "morphology_forge" ? `**${question.answerPieces.join(" + ")} \u2192 ${question.answerWord}**

${question.sentence.replace("___", question.answerWord)}

` : "";
      setAssistantSupportText(solution);
      return { prompt, prefix };
    }
    if (op === "explanation") {
      const targetName = getDelightLanguageName(targetLang);
      const supportName = getDelightLanguageName(supportLang);
      const variantDetails = question.variant === "sentence_detective" ? [
        `Original sentence with error: "${question.sentence || ""}"`,
        `The incorrect word was: "${question.wrongToken || question.tokens?.[question.incorrectIndex] || ""}"`,
        `The student selected: "${question.tokens?.[response?.tokenIndex] || ""}" replaced with "${response?.replacement || ""}"`,
        `The correct repair is: "${question.answer || ""}"`,
        question.correctedSentence ? `Full correct sentence: "${question.correctedSentence}"` : ""
      ] : question.variant === "dialogue_fork" ? [
        `Speaker "${question.speaker || "Speaker"}" said: "${question.line || ""}"`,
        `The student selected: "${question.options?.[response?.selectedIndex] || ""}"`,
        `The natural and correct reply is: "${question.options?.[question.answerIndex] || ""}"`
      ] : question.variant === "sentence_shapeshifter" ? [
        `Original source sentence: "${question.source || ""}"`,
        `Transformation constraint: "${question.constraint || ""}"`,
        `The student typed: "${response?.text || ""}"`,
        `Expected correct transformation: "${question.answer || ""}"`,
        question.acceptableAnswers?.length ? `Acceptable alternatives: ${question.acceptableAnswers.map((a) => `"${a}"`).join(", ")}` : ""
      ] : question.variant === "word_neighborhoods" ? [
        `Category groups: ${(question.groups || []).map((g) => `${g.label}: ${g.items.join(", ")}`).join("; ")}`,
        `Student placed words as: ${(question.groups || []).map((g, idx) => `${g.label}: ${Object.entries(response?.assignments || {}).filter(([, groupIndex]) => Number(groupIndex) === idx).map(([word]) => word).join(", ") || "(empty)"}`).join("; ")}`
      ] : question.variant === "morphology_forge" ? [
        `Sentence with blank: "${question.sentence || ""}"`,
        `Expected correct forged word: "${question.answerWord || (question.answerPieces || []).join("")}"`,
        `Target word morphemes: ${(question.answerPieces || []).join(" + ")}`,
        `Student assembled pieces: ${(response?.pieceIndices || []).map((idx) => question.pieces?.[idx]).join(" + ") || "(none)"}`,
        `Student formed word: "${(response?.pieceIndices || []).map((idx) => question.pieces?.[idx]).join("")}"`
      ] : question.variant === "three_clue_mystery" ? [
        `Mystery Clues: ${(question.clues || []).map((c, i) => `Clue ${i + 1}: "${c}"`).join("; ")}`,
        `Expected correct target word: "${question.answer || ""}"`,
        question.example ? `Example sentence: "${question.example}"` : "",
        `Student guessed: "${response?.text || ""}"`
      ] : [
        `Question: "${question.sentence || question.source || question.line || ""}"`,
        `Correct answer: "${question.answer || question.options?.[question.answerIndex] || ""}"`
      ];
      const prompt = [
        `You are a helpful language tutor teaching ${targetName}. A student answered an exercise incorrectly.`,
        buildAssistantLanguagePolicy({
          supportLanguageName: supportName,
          targetLanguageName: targetName
        }),
        `Question variant: ${question.variant || "Dialogue Fork"}`,
        ...variantDetails,
        "",
        `IMPORTANT: Provide your entire explanation in ${supportName}.`,
        `Provide a brief, encouraging explanation (2-3 sentences) in ${supportName} that:`,
        `1. Explains why the student's selected answer was not the best choice`,
        `2. Clarifies why the correct response fits best naturally`,
        `3. Gives a friendly tip to remember it`,
        `Keep it concise, supportive, and focused on learning. Write in ${supportName}.`
      ].filter(Boolean).join("\n");
      return { prompt, prefix };
    }
    throw Error(op);
  }
  var api = { run(op, json) {
    return JSON.stringify(build(op, JSON.parse(json)));
  } };
  return __toCommonJS(stdin_exports);
})();

OriginalPracticeAssistance.api;
